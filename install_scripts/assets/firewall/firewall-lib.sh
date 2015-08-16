#!/bin/bash
# FIREWALL startup script
# Copyright (C) 2015 Guillaume Diaz [guillaume @ qin-diaz.com]
##################################
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
##################################
#
#   version 1.0 - September 2008
#           1.1 - November 2009
#                  >> Network security (Chalmers) + english translation
#   version 1.2 - January 2010
#                  >> Add some protections against flooding
#   version 1.3 - June 2013 
#                  >> Add VPN support
#                  >> Tweaking incoming 80 / 443 / 8080 rules
#   version 1.4 - October 2013
#                  >> Simplifications thanks to Julien Rialland (VEHCO)
#   version 1.5 - June 2014
#                  >> Add IPv6 support + some updates to match http://daxiongmao.eu/wiki
#   version 1.6 - April 2015
#                  >> Improving log using 'log_' functions
#                  >> Adjusting IPv6 rules as well as DNS, FTP, VPN + simpler ESTABLISHED, RELATED
#   version 1.7 - June 2015
#                  >> Improving DNS
#                  >> Add comments on all ports
#   version 1.8 - August 2015
#                  >> Bug fixes and new features for IPv6
#                  >> Extracting some function into a dedicated file (library)
#                  >> Same behaviours for IPv4 and IPv6
#####
# Authors: Guillaume Diaz (all versions) + Julien Rialland (contributor to v1.4)


# This enable system logger and related functions
if [ -e /etc/debian_version ]; then
    . /lib/lsb/init-functions
elif [ -e /etc/init.d/functions ] ; then
    . /etc/init.d/functions
fi
if [ -r /etc/default/rcS ]; then
  . /etc/default/rcS
fi


# ------------------------------------------------------------------------------
# IPv4 ; IPv6 functions
# ------------------------------------------------------------------------------
IPTABLES=`which iptables`
IP6TABLES=`which ip6tables`

# This functions have been created by Dimitri Gribenko
function ipt4 {
    [ "$DO_IPV4" = "1" ] && $IPTABLES "$@"
}
function ipt6 {
    [ "$DO_IPV6" = "1" ] && $IP6TABLES "$@"
}
function ipt46 {
    ipt4 "$@"
    ipt6 "$@"
}

# ------------------------------------------------------------------------------
# Modules ; Network settings
# ------------------------------------------------------------------------------

# To enable networking modules in the current OS
function enableModules {
    log_progress_msg "Enable networking modules"
    ### IPv4
    modprobe ip_tables
    modprobe iptable_filter
    modprobe iptable_mangle
    # Allow to use state match
    modprobe ip_conntrack
    # Allow NAT
    modprobe iptable_nat
    ### IPv6
    modprobe ip6_tables
    modprobe ip6table_filter
    modprobe ip6table_mangle
    ### Allow active / passive FTP
    modprobe ip_conntrack_ftp
    modprobe ip_nat_ftp
    ### Allow log limits
    modprobe ipt_limit


    log_progress_msg "Protocols enforcement"
    # Avoid broadcast echo
    echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts
    # avoid TCP SYN Cookie
    echo 1 > /proc/sys/net/ipv4/tcp_syncookies
    # protection against bogus responses
    echo 1 > /proc/sys/net/ipv4/icmp_ignore_bogus_error_responses
    # Avoid IP Spoofing (discard non routable IP@)
    for f in /proc/sys/net/ipv4/conf/*/rp_filter; do echo 1 > $f; done
    # Avoid ICMP redirect
    echo 0 > /proc/sys/net/ipv4/conf/all/accept_redirects
    echo 0 > /proc/sys/net/ipv4/conf/all/send_redirects
    echo 0 > /proc/sys/net/ipv6/conf/all/accept_redirects
    # Avoid Source Routed
    echo 0 > /proc/sys/net/ipv4/conf/all/accept_source_route
    echo 0 > /proc/sys/net/ipv6/conf/all/accept_source_route
    # Check TCP window 
    echo 1 > /proc/sys/net/ipv4/tcp_window_scaling
    # Avoid DoS
    echo 30 > /proc/sys/net/ipv4/tcp_fin_timeout
    echo 1800 > /proc/sys/net/ipv4/tcp_keepalive_time
    # Adjust TTL value
    echo 64 > /proc/sys/net/ipv4/ip_default_ttl


    # Enable port forwarding in general
    # (i) Some might argue that it should only be done by routers... 
    #     Since I'm using a VPN, I like to access both networks and exchange data between them. 
    #     That's why port forwarding is enable.
    echo 1 > /proc/sys/net/ipv4/ip_forward
    #echo 0 > /proc/sys/net/ipv6/conf/all/forwarding
}



# ------------------------------------------------------------------------------
# IPv4 base configuration
# ------------------------------------------------------------------------------

# To flush old rules
function clearPolicyIpv4 {
    log_progress_msg "Flush existing rules ; IPv4"
    iptables -F
    iptables -X
    # Filter rules
    iptables -t filter -F
    iptables -t filter -X
    # delete NAT rules
    iptables -t nat -F
    iptables -t nat -X
    # delete MANGLE rules (packets modifications)
    iptables -t mangle -F
    iptables -t mangle -X
}

function setDefaultPolicyIpv4 {
    # It's better to set a default ALLOW and DROP other packages at the end
    # This avoid locking yourself up when you clear the rules
    log_progress_msg "Set default policy IPv4"
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
}

# Basic IPv4 security settings
function basicProtectionIpv4 {
    log_progress_msg "Reject invalid IPv4 packets"    
    iptables -A INPUT -m state --state INVALID -m comment --comment "Invalid input" -j DROP
    iptables -A OUTPUT -m state --state INVALID -m comment --comment "Invalid input" -j DROP
    iptables -A FORWARD -m state --state INVALID -m comment --comment "Invalid forward" -j DROP

    # Ensure TCP connection requests start with SYN flag
    iptables -A INPUT -p tcp -m state --state NEW ! --syn -m comment --comment "Invalid conn request" -j DROP
    iptables -A OUTPUT -p tcp -m state --state NEW ! --syn -m comment --comment "Invalid conn request" -j DROP

    ## Localhost
    iptables -A INPUT ! -i lo -s 127.0.0.0/24 -m comment --comment "Reject none loopback on 'lo'" -j DROP  
    iptables -A OUTPUT ! -o lo -d 127.0.0.0/24 -m comment --comment "Reject none loopback on 'lo'" -j DROP
    iptables -A FORWARD -s 127.0.0.0/24 -m comment --comment "Reject none loopback on 'lo'" -j DROP    
}

# Networking protocols enforcement
function protocolEnforcementIpv4 {
    log_progress_msg " Security protection - ICMP"
    # ICMP packets should not be fragmented
    iptables -A INPUT --fragment -p icmp -m comment --comment "no ICMP fragments" -j DROP    
    # SMURF attack protection
    iptables -A INPUT -p icmp -m icmp --icmp-type address-mask-request -m comment --comment "address-mask-request" -j DROP
    iptables -A INPUT -p icmp -m icmp --icmp-type timestamp-request -m comment --comment "timestamp-request" -j DROP
    # Limit ICMP Flood
    iptables -A INPUT -p icmp -m limit --limit 1/s --limit-burst 1 -m comment --comment "ICMP flood protection" -j ACCEPT    
    iptables -A OUTPUT -p icmp --icmp-type 0 -m comment --comment "echo reply" -j ACCEPT
    iptables -A OUTPUT -p icmp --icmp-type 3 -m comment --comment "destination unreachable" -j ACCEPT
    iptables -A OUTPUT -p icmp --icmp-type 8 -m comment --comment "echo request" -j ACCEPT    


    log_progress_msg " ... Layer 4: TCP # check packets conformity"
    # INCOMING packets check
    # All new incoming TCP should be SYN first
    iptables -A INPUT -p tcp ! --syn -m state --state NEW -m comment --comment "new TCP connection check" -j DROP
    # Avoid SYN Flood (max 3 SYN packets / second. Then Drop all requests !!)
    iptables -A INPUT -p tcp --syn -m limit --limit 1/s --limit-burst 3 -m comment --comment "avoid TCP SYN flood" -j ACCEPT
    # Avoid fragment packets
    iptables -A INPUT -f -m comment --comment "no fragments" -j DROP
    # Check TCP flags -- flag 64, 128 = bogues
    iptables -A INPUT -p tcp --tcp-option 64 -j DROP
    iptables -A INPUT -p tcp --tcp-option 128 -j DROP


    log_progress_msg " ... Layer 4: TCP # Avoid NMAP Scans"
    # XMAS-NULL
    iptables -A INPUT -p tcp --tcp-flags ALL NONE -m comment --comment "attack XMAS-NULL" -j DROP
    # XMAS-TREE
    iptables -A INPUT -p tcp --tcp-flags ALL ALL -m comment --comment "attack XMAS-tree" -j DROP
    # Stealth XMAS Scan
    iptables -A INPUT -p tcp --tcp-flags ALL FIN,PSH,URG -m comment --comment "attack XMAS stealth" -j DROP
    # SYN/RST Scan
    iptables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -m comment --comment "scan SYN/RST" -j DROP
    # SYN/FIN Scan
    iptables -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -m comment --comment "scan SYN/FIN" -j DROP
    # SYN/ACK Scan
    #iptables -A INPUT -p tcp --tcp-flags ALL ACK -j DROP
    iptables -A INPUT -p tcp --tcp-flags SYN,ACK SYN,ACK -m comment --comment "scan SYN/ACK" -j DROP
    # FIN/RST Scan
    iptables -A INPUT -p tcp --tcp-flags FIN,RST FIN,RST -m comment --comment "scan FIN/RST" -j DROP
    # FIN/ACK Scan
    iptables -A INPUT -p tcp -m tcp --tcp-flags FIN,ACK FIN -m comment --comment "scan FIN/ACK" -j DROP
    # ACK/URG Scan
    iptables -A INPUT -p tcp --tcp-flags ACK,URG URG -m comment --comment "scan ACK/URG" -j DROP
    # FIN/URG/PSH Scan
    iptables -A INPUT -p tcp --tcp-flags FIN,URG,PSH FIN,URG,PSH -m comment --comment "scan FIN/URG/PSH" -j DROP
    # XMAS-PSH Scan
    iptables -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -m comment --comment "scan XMAS/PSH" -j DROP
    # End TCP connection
    iptables -A INPUT -p tcp --tcp-flags ALL FIN -m comment --comment "end TCP connection flag" -j DROP
    # Ports scans
    iptables -A INPUT -p tcp --tcp-flags FIN,SYN,RST,ACK SYN -m comment --comment "common scan FIN/SYN/RST/ACK SYN" -j DROP
    iptables -A INPUT -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -m comment --comment "common scan FIN/SYN/RST/ACK/PSH/URG NONE" -j DROP
}

function keepEstablishedRelatedIpv4 {
    log_progress_msg "Keep ESTABLISHED, RELATED connections - IPv4"
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
    iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
}

# Core protocols that need to be enabled: DHCP, DNS, NTP, FTP
function commonProtocolIpv4 {
    if [ ! -z "$IP_LAN_V4" ] 
    then

        log_progress_msg "Allow LAN communication - IP v4 - Network: $IP_LAN_V4"
        echo "   !! Opening LAN communication (ipv4) : $IP_LAN_V4"
        iptables -A INPUT -s $IP_LAN_V4 -d $IP_LAN_V4 -m comment --comment "local LAN" -j ACCEPT
        iptables -A OUTPUT -s $IP_LAN_V4 -d $IP_LAN_V4 -m comment --comment "local LAN" -j ACCEPT
    fi
    
    log_progress_msg "Enable common protocols: DHCP, DNS, NTP, FTP (passive/active)"
    ## DHCP client >> Broadcast IP request 
    iptables -A INPUT -p udp --sport 67:68 --dport 67:68 -m comment --comment "DHCP" -j ACCEPT 
    iptables -A OUTPUT -p udp --sport 67:68 --dport 67:68 -m comment --comment "DHCP" -j ACCEPT 

    # DNS (udp)
    iptables -A INPUT -p udp --sport 53 -m comment --comment "DNS UDP sPort" -j ACCEPT
    iptables -A OUTPUT -p udp --sport 53 -m comment --comment "DNS UDP sPort" -j ACCEPT

    iptables -A INPUT -p udp --dport 53 -m comment --comment "DNS UDP dPort" -j ACCEPT
    iptables -A OUTPUT -p udp --dport 53 -m comment --comment "DNS UDP dPort" -j ACCEPT
    
    # DNS SEC
    # Established, related input are already accepted earlier
    iptables -A OUTPUT -p tcp --sport 53 -m comment --comment "DNS Sec TCP sPort" -j ACCEPT
    iptables -A OUTPUT -p tcp --dport 53 -m comment --comment "DNS Sec TCP dPort" -j ACCEPT

    echo "     !!! If you lost Internet after running the script, please check your /etc/resolv.conf file"
    echo "         Make sure you are not using 127.0.0.1 as default nameserver"

    # FTP data transfer
    iptables -A OUTPUT -p tcp --dport 20 -m comment --comment "FTP data" -j ACCEPT
    # FTP control (command)
    iptables -A OUTPUT -p tcp --dport 21 -m comment --comment "FTP command" -j ACCEPT

    # NTP
    iptables -A INPUT -p udp --sport 123 -m state --state ESTABLISHED -m comment --comment "NTP (UDP)" -j ACCEPT
    iptables -A INPUT -p tcp --sport 123 -m state --state ESTABLISHED -m comment --comment "NTP (TCP)" -j ACCEPT
    iptables -A OUTPUT -p udp --dport 123 -m state --state NEW,ESTABLISHED -m comment --comment "NTP (UDP)" -j ACCEPT
    iptables -A OUTPUT -p tcp --dport 123 -m state --state NEW,ESTABLISHED -m comment --comment "NTP (TCP)" -j ACCEPT
}

# Reject incoming packet from not allowed networks
function filterNetworksIpv4 {
    log_progress_msg "Reject unexpected packets"
    # Reserved addresses. We shouldn't received any packets from them!
    iptables -A INPUT -s 10.0.0.0/8 -m comment --comment "foreign LAN - class A" -j DROP
    iptables -A INPUT -s 172.16.0.0/16 -m comment --comment "foreign LAN - class B" -j DROP
    iptables -A INPUT -s 192.168.0.0/16 -m comment --comment "foreign LAN - class C" -j DROP
    iptables -A INPUT -s 169.254.0.0/16 -m comment --comment "Zero Conf addresses" -j DROP
}





# ------------------------------------------------------------------------------
# IPv6 base configuration
# ------------------------------------------------------------------------------

# To flush old rules
function clearPolicyIpv6 {
    log_progress_msg "Flush existing rules"
    ip6tables -F
    ip6tables -X   
    # delete MANGLE rules (packets modifications)
    ip6tables -t mangle -F
    ip6tables -t mangle -X
}

function setDefaultPolicyIpv6 {
    # It's better to set a default ALLOW and DROP other packages at the end
    # This avoid locking yourself up when you clear the rules
    log_progress_msg "Set default policy IPv6"
    ip6tables -P INPUT ACCEPT
    ip6tables -P FORWARD ACCEPT
    ip6tables -P OUTPUT ACCEPT
}


# Basic IPv6 security settings
function basicProtectionIpv6 {

    log_progress_msg "Set common security filters"
    # Reject invalid packets
    ip6tables -A INPUT -m state --state INVALID -m comment --comment "Invalid input" -j DROP
    ip6tables -A OUTPUT -m state --state INVALID -m comment --comment "Invalid input" -j DROP
    ip6tables -A FORWARD -m state --state INVALID -m comment --comment "Invalid forward" -j DROP

    # Ensure TCP connection requests start with SYN flag
    ip6tables -A INPUT -p tcp -m state --state NEW ! --syn -m comment --comment "Invalid conn request" -j DROP
    ip6tables -A OUTPUT -p tcp -m state --state NEW ! --syn -m comment --comment "Invalid conn request" -j DROP

    # Allow localhost traffic. This rule is for all protocols.
    # ip6tables -A INPUT -s ::1 -d ::1 -j ACCEPT
    ip6tables -A INPUT ! -i lo -s ::1 -m comment --comment "Reject none loopback on 'lo'" -j DROP
    ip6tables -A OUTPUT ! -o lo -d ::1 -m comment --comment "Reject none loopback on 'lo'" -j DROP

    # Allow Link-Local addresses
    ip6tables -A INPUT -s fe80::/10 -j ACCEPT
    ip6tables -A OUTPUT -s fe80::/10 -j ACCEPT
    # Normally, link-local packets should NOT be forwarded and don't need an entry in the FORWARD rule.
    # However, when bridging in Linux (e.g. in Xen or OpenWRT), the FORWARD rule is needed:
    ip6tables -A FORWARD -s fe80::/10 -j ACCEPT

    # Allow multicast
    ip6tables -A INPUT -d ff00::/8 -j ACCEPT
    ip6tables -A INPUT -s ff00::/8 -j ACCEPT
    ip6tables -A OUTPUT -d ff00::/8 -j ACCEPT
    ip6tables -A OUTPUT -s ff00::/8 -j ACCEPT
}


# Networking protocols enforcement
function protocolEnforcementIpv6 {

    log_progress_msg " ... Layer 2: ICMP v6 "
    # Don't DROP ICMP6 a lot of things are happening over there! It might completly block the connection if you DROP icmp6

    # Avoid ICMP flood
    ip6tables -A INPUT -p icmpv6 -m limit --limit 2/second --limit-burst 2 -j ACCEPT

    ip6tables -A OUTPUT -p icmpv6 -j ACCEPT  
    ip6tables -A FORWARD -p icmpv6 -j ACCEPT     
}

function keepEstablishedRelatedIpv6 {
    log_progress_msg "Keep ESTABLISHED, RELATED connections - IPv4"
    ip6tables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    ip6tables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
    ip6tables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
}

# Core protocols that need to be enabled: DHCP, DNS, NTP, FTP
function commonProtocolIpv6 {
    if [ ! -z "$IP_LAN_V6" ] 
    then
        log_progress_msg "Allow LAN communication - IP v6 - Network: $IP_LAN_V6"
        echo "   !! Opening LAN communication (ipv6) : $IP_LAN_V6"
        ip6tables -A INPUT -s $IP_LAN_V6 -d $IP_LAN_V6 -m comment --comment "local LAN" -j ACCEPT
        ip6tables -A OUTPUT -s $IP_LAN_V6 -d $IP_LAN_V6 -m comment --comment "local LAN" -j ACCEPT
    fi
    
    log_progress_msg "Enable common protocols: DNS, NTP, FTP (passive/active)"
    # IP v6 DNS
    ip6tables -A INPUT -p udp --sport 53 -m comment --comment "DNS6 UDP sPort" -j ACCEPT
    ip6tables -A OUTPUT -p udp --sport 53 -m comment --comment "DNS6 UDP sPort" -j ACCEPT
    ip6tables -A INPUT -p udp --dport 53 -m comment --comment "DNS6 UDP dPort" -j ACCEPT
    ip6tables -A OUTPUT -p udp --dport 53 -m comment --comment "DNS6 UDP dPort" -j ACCEPT

    # DNS SEC IP v6
    ip6tables -A OUTPUT -p tcp --dport 53 -m comment --comment "DNS Sec TCP dPort" -j ACCEPT
    ip6tables -A OUTPUT -p tcp --dport 53 -m comment --comment "DNS Sec TCP dPort" -j ACCEPT

    # FTP requests  
    # FTP data transfer
    ip6tables -A OUTPUT -p tcp --dport 20 -m comment --comment "FTP data" -j ACCEPT  
    # FTP control (command)
    ip6tables -A OUTPUT -p tcp --dport 21 -m comment --comment "FTP command" -j ACCEPT  

    # NTP
    ip6tables -A INPUT -p udp --sport 123 -m state --state ESTABLISHED -m comment --comment "NTP (UDP)" -j ACCEPT
    ip6tables -A INPUT -p tcp --sport 123 -m state --state ESTABLISHED -m comment --comment "NTP (TCP)" -j ACCEPT
    ip6tables -A OUTPUT -p udp --dport 123 -m state --state NEW,ESTABLISHED -m comment --comment "NTP (UDP)" -j ACCEPT
    ip6tables -A OUTPUT -p tcp --dport 123 -m state --state NEW,ESTABLISHED -m comment --comment "NTP (TCP)" -j ACCEPT
}

function blockRoutingHeaderIpv6 {
    # Filter all packets that have RH0 headers:
    ip6tables -A INPUT -m rt --rt-type 0 -j DROP
    ip6tables -A FORWARD -m rt --rt-type 0 -j DROP
    ip6tables -A OUTPUT -m rt --rt-type 0 -j DROP
}

function blockIp6Tunnels {
    ## IPv6 security
    # No IPv4 -> IPv6 tunneling
    ip6tables -A INPUT -s 2002::/16 -m comment --comment "Reject 6to4 tunnels" -j DROP
    ip6tables -A FORWARD -s 2002::/16 -m comment --comment "Reject 6to4 tunnels" -j DROP
    ip6tables -A INPUT -s 2001:0::/32 -m comment --comment "Reject Teredo tunnels" -j DROP
    ip6tables -A FORWARD -s 2001:0::/32 -m comment --comment "Reject Teredo tunnels" -j DROP
    
    # Block IPv6 protocol in IPv4 frames
    iptables -A INPUT -p 41 -m comment --comment "Block IPv6 protocol in IPv4 frames" -j DROP
    iptables -A OUTPUT -p 41 -m comment --comment "Block IPv6 protocol in IPv4 frames" -j DROP
    iptables -A FORWARD -p 41 -m comment --comment "Block IPv6 protocol in IPv4 frames" -j DROP
}


# ------------------------------------------------------------------------------
# INCOMING rules
# ------------------------------------------------------------------------------

# usage:   inputFiltering <String:protocol> <Int:port> <String:comment> <Boolean:limit[optional]>
#
#    ex:   inputFiltering tcp 22 SSH true
#          inputFiltering tcp 3306 MySQL
function inputFiltering {
    DEST_PROTOCOL=$1
    DEST_PORT=$2
    RULE_COMMENT=$3
    LIMIT=$4

    log_progress_msg " >> allow input >> $DEST_PROTOCOL $DEST_PORT - $RULE_COMMENT"
    if [[ ! -z "$LIMIT" ]]
    then
        iptables -A INPUT -p $DEST_PROTOCOL  -m limit --limit 3/min --limit-burst 10 --dport $DEST_PORT -m comment --comment "$RULE_COMMENT" -j ACCEPT 
        ip6tables -A INPUT -p $DEST_PROTOCOL  -m limit --limit 3/min --limit-burst 10 --dport $DEST_PORT -m comment --comment "$RULE_COMMENT" -j ACCEPT
    else 
        iptables -A INPUT -p $DEST_PROTOCOL --dport $DEST_PORT -m comment --comment "$RULE_COMMENT" -j ACCEPT 
        ip6tables -A INPUT -p $DEST_PROTOCOL --dport $DEST_PORT -m comment --comment "$RULE_COMMENT" -j ACCEPT
    fi
}



# ------------------------------------------------------------------------------
# OUTGOING rules
# ------------------------------------------------------------------------------

# usage:   outputFiltering <protocol> <port> <comment>
#
#    ex:   outputFiltering tcp 22 "SSH"
#          outputFiltering tcp 3306
function outputFiltering {
    DEST_PROTOCOL=$1
    DEST_PORT=$2
    RULE_COMMENT=$3

    log_progress_msg " << allow output << $DEST_PROTOCOL $DEST_PORT - $RULE_COMMENT"
    iptables -A OUTPUT -p $DEST_PROTOCOL --dport $DEST_PORT -m comment --comment "$RULE_COMMENT" -j ACCEPT 
    ip6tables -A OUTPUT -p $DEST_PROTOCOL --dport $DEST_PORT -m comment --comment "$RULE_COMMENT" -j ACCEPT
}


# ------------------------------------------------------------------------------
# Port forwarding
# ------------------------------------------------------------------------------

# usage:   outputFiltering <sourceIP> <port> <comment>
#
#    ex:   allowForwardingFromIpv4 192.168.15.0/24 "LAN"
#          allowForwardingFromIpv4 5.39.81.23 "Personal server"
function allowForwardingFromIpv4 {
    SOURCE_IP=$1
    COMMENT=$2

    log_progress_msg "Allow forward packets from source: $SOURCE_IP"
    iptables -A FORWARD -s $SOURCE_IP -m comment --comment "$COMMENT" -j ACCEPT
}
function allowForwardingFromIpv6 {
    SOURCE_IP=$1
    COMMENT=$2

    log_progress_msg "Allow forward packets from source: $SOURCE_IP"
    ip6tables -A FORWARD -s $SOURCE_IP -m comment --comment "$COMMENT" -j ACCEPT
}

# usage:   forwardPortIpv4 <sourcePort> <protocol> <target server> <targetPort> <comment>
#          forwardPortIpv4 8090 udp 192.168.15.4 8080 "Tomcat code.vehco.com"
function forwardPortIpv4 {
    SOURCE_PORT=$1
    PROTOCOL=$2
    TARGET_SERVER=$3
    TARGET_PORT=$4
    COMMENT=$5

    log_progress_msg "Forward incoming $PROTOCOL $SOURCE_PORT to $TARGET_SERVER:$TARGET_PORT"

    # Allow incoming on SOURCE port
    iptables -A INPUT -p $PROTOCOL --dport $SOURCE_PORT -j ACCEPT
    # Allow outgoing on TARGET port
    iptables -A OUTPUT -p $PROTOCOL --dport $TARGET_PORT -j ACCEPT
    # Forward data: Source <-> Target
    iptables -A PREROUTING -t nat -p $PROTOCOL --dport $SOURCE_PORT -j DNAT --to $TARGET_SERVER:$TARGET_PORT
}


# ------------------------------------------------------------------------------
# Source IP filtering
# ------------------------------------------------------------------------------

# usage:   sourceIpFilteringIpv4 <portNumber> <protocol> <Array: list of allowed IPs>
#    ex:   sourceIpFilteringIpv4 8080 tcp ("5.39.81.23" "172.16.100.0/24")
function sourceIpFilteringIpv4() {
    SOURCE_PORT=$1
    PROTOCOL=$2
    ALLOW_CLIENTS=$3

    log_progress_msg " >|source IP@ filter|> $PROTOCOL $SOURCE_PORT"
    ### List of allowed IP @
    for allowClient in "${ALLOW_CLIENTS[@]}"
    do
        iptables -A INPUT -p $PROTOCOL --dport $SOURCE_PORT -s $allowClient -m comment --comment "src IP filter, allow: $allowClient:$SOURCE_PORT" -j ACCEPT
    done

    ### Drop all the rest
    iptables -A INPUT -p $PROTOCOL --dport $SOURCE_PORT -s 0.0.0.0/0 -m comment --comment "src IP filter, block access to: $SOURCE_PORT" -j DROP
}


# usage:   sourceIpFilteringIpv6 <portNumber> <protocol> <Array: list of allowed IPs>
function sourceIpFilteringIpv6() {
    SOURCE_PORT=$1
    PROTOCOL=$2
    ALLOW_CLIENTS=$3

    log_progress_msg " >|source IP@ filter|> $PROTOCOL $SOURCE_PORT"
    ### List of allowed IP @
    for allowClient in "${ALLOW_CLIENTS[@]}"
    do
        ip6tables -A INPUT -p $PROTOCOL --dport $SOURCE_PORT -s $allowClient -m comment --comment "src IP filter, allow: $allowClient:$SOURCE_PORT" -j ACCEPT
    done

    ### Drop all the rest
    ip6tables -A INPUT -p $PROTOCOL --dport $SOURCE_PORT -m comment --comment "src IP filter, block access to: $SOURCE_PORT" -j DROP
}




# ------------------------------------------------------------------------------
# VPN configuration
# ------------------------------------------------------------------------------
# usage:   vpn <String:vpn interface> <Int:vpn port> <String:vpn protocol> <String:local interface> <String:remote LAN [optional]>
#     ex   vpn tun0 8080 udp eth0
#     ex   vpn tun0 8080 udp eth0 192.168.15.0/24
function vpn {   
    INT_VPN=$1
    VPN_PORT=$2
    VPN_PROTOCOL=$3 
    INT_LOCAL=$4
    VPN_LAN=$5

    log_daemon_msg "Setting up VPN rules" 

    #####
    # Allow VPN connections through $INT_VPN
    # Hint: if you do not accept all RELATED,ESTABLISHED connections then you must allow the source port
    #####
    log_progress_msg "Init VPN IPv4"
    iptables -A INPUT -p $VPN_PROTOCOL --dport $VPN_PORT -m comment --comment "VPN incoming" -j ACCEPT
    iptables -A OUTPUT -p $VPN_PROTOCOL --dport $VPN_PORT -m comment --comment "VPN outgoing" -j ACCEPT
    iptables -A OUTPUT -p $VPN_PROTOCOL --sport $VPN_PORT -m comment --comment "VPN outgoing" -j ACCEPT
    # Allow VPN packets type INPUT,OUTPUT,FORWARD
    iptables -A INPUT -i $INT_VPN -m state ! --state INVALID -m comment --comment "Unvalid VPN packet" -j ACCEPT
    iptables -A OUTPUT -o $INT_VPN -m state ! --state INVALID -m comment --comment "Unvalid VPN packet" -j ACCEPT
    iptables -A FORWARD -o $INT_VPN -m state ! --state INVALID -m comment --comment "Unvalid VPN packet" -j ACCEPT


    log_progress_msg "Init VPN IPv6"
    ip6tables -A INPUT -p $VPN_PROTOCOL --dport $VPN_PORT -m comment --comment "VPN incoming" -j ACCEPT
    ip6tables -A OUTPUT -p $VPN_PROTOCOL --dport $VPN_PORT -m comment --comment "VPN outgoing" -j ACCEPT
    ip6tables -A OUTPUT -p $VPN_PROTOCOL --sport $VPN_PORT -m comment --comment "VPN outgoing" -j ACCEPT
    # Allow VPN packets type INPUT,OUTPUT,FORWARD
    ip6tables -A INPUT -i $INT_VPN -m state ! --state INVALID -m comment --comment "Unvalid VPN packet" -j ACCEPT
    ip6tables -A OUTPUT -o $INT_VPN -m state ! --state INVALID -m comment --comment "Unvalid VPN packet" -j ACCEPT
    ip6tables -A FORWARD -o $INT_VPN -m state ! --state INVALID -m comment --comment "Unvalid VPN packet" -j ACCEPT


    ######
    # Allow forwarding
    ######
    log_progress_msg "Enable forwarding form $INT_VPN /to/ $INT_LOCAL"
    iptables -A FORWARD -i $INT_VPN -o $INT_LOCAL -m comment --comment "Forwarding $INT_LOCAL <> VPN" -j ACCEPT
    iptables -A FORWARD -i $INT_LOCAL -o $INT_VPN -m comment --comment "Forwarding $INT_LOCAL <> VPN" -j ACCEPT

    ip6tables -A FORWARD -i $INT_VPN -o $INT_LOCAL -m comment --comment "Forwarding $INT_LOCAL <> VPN" -j ACCEPT
    ip6tables -A FORWARD -i $INT_LOCAL -o $INT_VPN -m comment --comment "Forwarding $INT_LOCAL <> VPN" -j ACCEPT


    ######
    # Allow local LAN / remote LAN communication through VPN
    ######
    if [[ ! -z "$VPN_LAN" ]]
    then
        log_progress_msg "Enable forwarding form $INT_VPN /to/ $INT_LOCAL"
        # Allow packets to be send from|to the VPN network
        iptables -A FORWARD -s $VPN_LAN -m comment --comment "VPN remote LAN ($VPN_LAN)" -j ACCEPT
        # Allow packet to go/from the VPN network to the LAN
        iptables -t nat -A POSTROUTING -s $VPN_LAN -o $INT_LOCAL -j MASQUERADE


        log_progress_msg "Allow VPN client to client communication"
        # Allow VPN client <-> client communication
        iptables -A INPUT -s $VPN_LAN -d $VPN_LAN -m state ! --state INVALID -j ACCEPT
        iptables -A OUTPUT -s $VPN_LAN -d $VPN_LAN -m state ! --state INVALID -j ACCEPT
    fi 


    ####### Add route(s) to remote network(s)
    # You must add a new route for each network you'd like to access through the VPN server!
    # The VPN server must be able to reach the remote network! (otherwise it cannot acts as a GW !)
    # route add -net <network>/<mask> gw <VPN_SERVER_ETH_IP>
    #
    # !! This information should be pushed by the server !! 
    # If not you can either add it manually over here (= in Iptables) or in the OpenVPN client conf.
    #######
    #echo "      ... add VPN route between VPN LAN and current location"
    #route add -net 192.168.12.0/24 gw 192.168.1.45

    log_end_msg 0
}



# ------------------------------------------------------------------------------
# LOGGING
# ------------------------------------------------------------------------------
function logDropped {
    
    ############ IPv4
    log_daemon_msg "Firewall log dropped packets (ip v4)"
    # Create log chain
    iptables -N logging_v4
    # Apply chain rules to...
    iptables -A INPUT -j logging_v4
    iptables -A OUTPUT -j logging_v4
    # Rules to apply
    iptables -A logging_v4 -m limit --limit 10/min -j LOG --log-prefix "IPv4 - dropped: " --log-level 4
    #iptables -A logging_v4 -j LOG --log-prefix "IPv4 - dropped: " --log-level 4
    iptables -A logging_v4 -j DROP

    ############ IPv6
    log_progress_msg "Firewall log dropped packets (ip v6)"
    # Create log chain
    ip6tables -N logging_v6
    # Apply chain rules to...
    ip6tables -A INPUT -j logging_v6
    ip6tables -A OUTPUT -j logging_v6
    # Rules to apply
    ip6tables -A logging_v6 -m limit --limit 10/min -j LOG --log-prefix "IPv4 - dropped: " --log-level 4
    #ip6tables -A logging_v6 -j LOG --log-prefix "IPv6 - dropped: " --log-level 4
    ip6tables -A logging_v6 -j DROP

    log_end_msg 0
}

