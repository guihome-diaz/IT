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
# Base configuration
# ------------------------------------------------------------------------------

# To flush old rules
function clearPolicies {
    log_progress_msg "Flush existing rules"
    ipt46 -F
    ipt46 -X
    # delete MANGLE rules (packets modifications)
    ipt46 -t mangle -F
    ipt46 -t mangle -X
    # delete NAT rules
    ipt4 -t nat -F
    ipt4 -t nat -X
}

function setDefaultPolicies {
    # It's better to set a default ALLOW and DROP other packages at the end
    # This avoid locking yourself up when you clear the rules
    log_progress_msg "Set default policy IPv4, IPv6: accept all "
    ipt46 -P INPUT ACCEPT
    ipt46 -P FORWARD ACCEPT
    ipt46 -P OUTPUT ACCEPT
}

# Basic security settings
function basicProtection {    
    log_progress_msg "Set common security filters"
    ipt46 -A INPUT -m state --state INVALID -m comment --comment "Invalid input" -j DROP
    ipt46 -A OUTPUT -m state --state INVALID -m comment --comment "Invalid input" -j DROP
    ipt46 -A FORWARD -m state --state INVALID -m comment --comment "Invalid forward" -j DROP

    # Ensure TCP connection requests start with SYN flag
    ipt46 -A INPUT -p tcp -m state --state NEW ! --syn -m comment --comment "Invalid conn request" -j DROP
    ipt46 -A OUTPUT -p tcp -m state --state NEW ! --syn -m comment --comment "Invalid conn request" -j DROP

    ####################
    ####### IPv4 #######
    ####################
    ## Localhost
    ipt4 -A INPUT ! -i lo -s 127.0.0.0/24 -m comment --comment "Reject none loopback on 'lo'" -j DROP  
    ipt4 -A OUTPUT ! -o lo -d 127.0.0.0/24 -m comment --comment "Reject none loopback on 'lo'" -j DROP

    ####################
    ####### IPv6 #######
    ####################
    # Allow localhost traffic. This rule is for all protocols.
    #ipt6 -A INPUT -s ::1 -d ::1 -j ACCEPT
    #ipt6 -A INPUT ! -i lo -s ::1 -m comment --comment "Reject none loopback on 'lo'" -j DROP
    #ipt6 -A OUTPUT ! -o lo -d ::1 -m comment --comment "Reject none loopback on 'lo'" -j DROP

    # Allow Link-Local addresses
    ipt6 -A INPUT -s fe80::/10 -j ACCEPT
    ipt6 -A OUTPUT -s fe80::/10 -j ACCEPT
    # Normally, link-local packets should NOT be forwarded and don't need an entry in the FORWARD rule.
    # However, when bridging in Linux (e.g. in Xen or OpenWRT), the FORWARD rule is needed:
    ipt6 -A FORWARD -s fe80::/10 -j ACCEPT

    # Allow multicast
    ipt6 -A INPUT -d ff00::/8 -j ACCEPT
    ipt6 -A INPUT -s ff00::/8 -j ACCEPT
    ipt6 -A OUTPUT -d ff00::/8 -j ACCEPT
    ipt6 -A OUTPUT -s ff00::/8 -j ACCEPT
}

# Networking protocols enforcement
function protocolsEnforcement {
    ####### IPv4 #######
    log_progress_msg " ... Layer 2: ICMP v4"
    # ICMP packets should not be fragmented
    ipt4 -A INPUT --fragment -p icmp -m comment --comment "no ICMP fragments" -j DROP    
    # SMURF attack protection
    ipt4 -A INPUT -p icmp -m icmp --icmp-type address-mask-request -m comment --comment "address-mask-request" -j DROP
    ipt4 -A INPUT -p icmp -m icmp --icmp-type timestamp-request -m comment --comment "timestamp-request" -j DROP
    # Limit ICMP Flood
    ipt4 -A INPUT -p icmp -m limit --limit 1/s --limit-burst 1 -m comment --comment "ICMP flood protection" -j ACCEPT    
    ipt4 -A OUTPUT -p icmp --icmp-type 0 -m comment --comment "echo reply" -j ACCEPT
    ipt4 -A OUTPUT -p icmp --icmp-type 3 -m comment --comment "destination unreachable" -j ACCEPT
    ipt4 -A OUTPUT -p icmp --icmp-type 8 -m comment --comment "echo request" -j ACCEPT    


    ####### IPv6 #######
    log_progress_msg " ... Layer 2: ICMP v6 "
    # Don't DROP ICMP6 a lot of things are happening over there! It might completly block the connection if you DROP icmp6
    # Avoid ICMP flood
    ipt6 -A INPUT -p icmpv6 -m limit --limit 2/second --limit-burst 2 -j ACCEPT
    # Accept the rest
    ipt6 -A OUTPUT -p icmpv6 -j ACCEPT  
    ipt6 -A FORWARD -p icmpv6 -j ACCEPT  


    log_progress_msg " ... Layer 4: TCP # check packets conformity"
    # INCOMING packets check
    # All new incoming TCP should be SYN first
    ipt46 -A INPUT -p tcp ! --syn -m state --state NEW -m comment --comment "new TCP connection check" -j DROP
    # Avoid SYN Flood (max 3 SYN packets / second. Then Drop all requests !!)
    ipt46 -A INPUT -p tcp --syn -m limit --limit 1/s --limit-burst 3 -m comment --comment "avoid TCP SYN flood" -j ACCEPT
    # Avoid fragment packets
    ipt46 -A INPUT -f -m comment --comment "no fragments" -j DROP
    # Check TCP flags -- flag 64, 128 = bogues
    ipt46 -A INPUT -p tcp --tcp-option 64 -j DROP
    ipt46 -A INPUT -p tcp --tcp-option 128 -j DROP


    log_progress_msg " ... Layer 4: TCP # Avoid NMAP Scans"
    # XMAS-NULL
    ipt46 -A INPUT -p tcp --tcp-flags ALL NONE -m comment --comment "attack XMAS-NULL" -j DROP
    # XMAS-TREE
    ipt46 -A INPUT -p tcp --tcp-flags ALL ALL -m comment --comment "attack XMAS-tree" -j DROP
    # Stealth XMAS Scan
    ipt46 -A INPUT -p tcp --tcp-flags ALL FIN,PSH,URG -m comment --comment "attack XMAS stealth" -j DROP
    # SYN/RST Scan
    ipt46 -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -m comment --comment "scan SYN/RST" -j DROP
    # SYN/FIN Scan
    ipt46 -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -m comment --comment "scan SYN/FIN" -j DROP
    # SYN/ACK Scan
    #iptables -A INPUT -p tcp --tcp-flags ALL ACK -j DROP
    ipt46 -A INPUT -p tcp --tcp-flags SYN,ACK SYN,ACK -m comment --comment "scan SYN/ACK" -j DROP
    # FIN/RST Scan
    ipt46 -A INPUT -p tcp --tcp-flags FIN,RST FIN,RST -m comment --comment "scan FIN/RST" -j DROP
    # FIN/ACK Scan
    ipt46 -A INPUT -p tcp -m tcp --tcp-flags FIN,ACK FIN -m comment --comment "scan FIN/ACK" -j DROP
    # ACK/URG Scan
    ipt46 -A INPUT -p tcp --tcp-flags ACK,URG URG -m comment --comment "scan ACK/URG" -j DROP
    # FIN/URG/PSH Scan
    ipt46 -A INPUT -p tcp --tcp-flags FIN,URG,PSH FIN,URG,PSH -m comment --comment "scan FIN/URG/PSH" -j DROP
    # XMAS-PSH Scan
    ipt46 -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -m comment --comment "scan XMAS/PSH" -j DROP
    # End TCP connection
    ipt46 -A INPUT -p tcp --tcp-flags ALL FIN -m comment --comment "end TCP connection flag" -j DROP
    # Ports scans
    ipt46 -A INPUT -p tcp --tcp-flags FIN,SYN,RST,ACK SYN -m comment --comment "common scan FIN/SYN/RST/ACK SYN" -j DROP
    ipt46 -A INPUT -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -m comment --comment "common scan FIN/SYN/RST/ACK/PSH/URG NONE" -j DROP
}

function keepEstablishedRelatedConnections {
    log_progress_msg "Keep ESTABLISHED, RELATED connections"
    ipt46 -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    ipt46 -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
    ipt46 -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
}

# Core protocols that need to be enabled: DHCP, DNS, NTP, FTP
function allowBaseCommunications {    
    log_progress_msg "Enable common protocols: DHCP, DNS, NTP, FTP (passive/active)"
    ## DHCP client >> Broadcast IP request 
    ipt46 -A INPUT -p udp --sport 67:68 --dport 67:68 -m comment --comment "DHCP" -j ACCEPT 
    ipt46 -A OUTPUT -p udp --sport 67:68 --dport 67:68 -m comment --comment "DHCP" -j ACCEPT 

    # DNS (udp)
    ipt46 -A INPUT -p udp --sport 53 -m comment --comment "DNS UDP sPort" -j ACCEPT
    ipt46 -A OUTPUT -p udp --sport 53 -m comment --comment "DNS UDP sPort" -j ACCEPT

    ipt46 -A INPUT -p udp --dport 53 -m comment --comment "DNS UDP dPort" -j ACCEPT
    ipt46 -A OUTPUT -p udp --dport 53 -m comment --comment "DNS UDP dPort" -j ACCEPT
    
    # DNS SEC
    # Established, related input are already accepted earlier
    ipt46 -A OUTPUT -p tcp --sport 53 -m comment --comment "DNS Sec TCP sPort" -j ACCEPT
    ipt46 -A OUTPUT -p tcp --dport 53 -m comment --comment "DNS Sec TCP dPort" -j ACCEPT

    #TODO
    echo "     !!! If you lost Internet after running the script, please check your /etc/resolv.conf file"
    echo "         Make sure you are not using 127.0.0.1 as default nameserver"

    # FTP data transfer
    ipt46 -A OUTPUT -p tcp --dport 20 -m comment --comment "FTP data" -j ACCEPT
    # FTP control (command)
    ipt46 -A OUTPUT -p tcp --dport 21 -m comment --comment "FTP command" -j ACCEPT

    # NTP
    ipt46 -A INPUT -p udp --sport 123 -m state --state ESTABLISHED -m comment --comment "NTP (UDP)" -j ACCEPT
    ipt46 -A INPUT -p tcp --sport 123 -m state --state ESTABLISHED -m comment --comment "NTP (TCP)" -j ACCEPT
    ipt46 -A OUTPUT -p udp --dport 123 -m state --state NEW,ESTABLISHED -m comment --comment "NTP (UDP)" -j ACCEPT
    ipt46 -A OUTPUT -p tcp --dport 123 -m state --state NEW,ESTABLISHED -m comment --comment "NTP (TCP)" -j ACCEPT
}

function blockIp4Ip6Tunnels {
    ## IPv6 security
    # No IPv4 -> IPv6 tunneling
    ipt6 -A INPUT -s 2002::/16 -m comment --comment "Reject 6to4 tunnels" -j DROP
    ipt6 -A FORWARD -s 2002::/16 -m comment --comment "Reject 6to4 tunnels" -j DROP
    ipt6 -A INPUT -s 2001:0::/32 -m comment --comment "Reject Teredo tunnels" -j DROP
    ipt6 -A FORWARD -s 2001:0::/32 -m comment --comment "Reject Teredo tunnels" -j DROP
    
    # Block IPv6 protocol in IPv4 frames
    ipt4 -A INPUT -p 41 -m comment --comment "Block IPv6 protocol in IPv4 frames" -j DROP
    ipt4 -A OUTPUT -p 41 -m comment --comment "Block IPv6 protocol in IPv4 frames" -j DROP
    ipt4 -A FORWARD -p 41 -m comment --comment "Block IPv6 protocol in IPv4 frames" -j DROP
}

# ------------------------------------------------------------------------------
# IPv4
# ------------------------------------------------------------------------------

# Reject incoming packet from not allowed networks
function filterNetworksIpv4 {
    log_progress_msg "Reject unexpected packets"
    # Reserved addresses. We shouldn't received any packets from them!
    ipt4 -A INPUT -s 10.0.0.0/8 -m comment --comment "foreign LAN - class A" -j DROP
    ipt4 -A INPUT -s 172.16.0.0/16 -m comment --comment "foreign LAN - class B" -j DROP
    ipt4 -A INPUT -s 192.168.0.0/16 -m comment --comment "foreign LAN - class C" -j DROP
    ipt4 -A INPUT -s 169.254.0.0/16 -m comment --comment "Zero Conf addresses" -j DROP
}

# To allow LAN communications
# Usage: allowIpv4LAN <String: LAN>
#        allowIpv4LAN "192.168.15.0/24"
function allowIpv4LAN {
    IP_LAN_V4=$1
    log_progress_msg "Allow LAN communication - IP v4 - Network: $IP_LAN_V4"
    echo "   !! Opening LAN communication (ipv4) : $IP_LAN_V4"
    ipt4 -A INPUT -s $IP_LAN_V4 -d $IP_LAN_V4 -m comment --comment "LAN $IP_LAN_V4" -j ACCEPT
    ipt4 -A OUTPUT -s $IP_LAN_V4 -d $IP_LAN_V4 -m comment --comment "LAN $IP_LAN_V4" -j ACCEPT
}


# ------------------------------------------------------------------------------
# IPv6
# ------------------------------------------------------------------------------

function blockRoutingHeaderIpv6 {
    # Filter all packets that have RH0 headers:
    ipt6 -A INPUT -m rt --rt-type 0 -j DROP
    ipt6 -A FORWARD -m rt --rt-type 0 -j DROP
    ipt6 -A OUTPUT -m rt --rt-type 0 -j DROP
}

# To allow LAN communications
# Usage: allowIpv6LAN <String: LAN>
#        allowIpv6LAN "2a02:678:421:8400::0/64"
function allowIpv6LAN {
    IP_LAN_V6=$1
    log_progress_msg "Allow LAN communication - IP v6 - Network: $IP_LAN_V6"
    echo "   !! Opening LAN communication (ipv6) : $IP_LAN_V6"
    ipt6 -A INPUT -s $IP_LAN_V6 -d $IP_LAN_V6 -m comment --comment "LAN $IP_LAN_V6" -j ACCEPT
    ipt6 -A OUTPUT -s $IP_LAN_V6 -d $IP_LAN_V6 -m comment --comment "LAN $IP_LAN_V6" -j ACCEPT
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

    log_progress_msg "Outside >> Host | allow input: $DEST_PROTOCOL $DEST_PORT - $RULE_COMMENT"
    if [[ ! -z "$LIMIT" ]]
    then
        ipt46 -A INPUT -p $DEST_PROTOCOL --dport $DEST_PORT -m limit --limit 3/min --limit-burst 10 -m comment --comment "$RULE_COMMENT" -j ACCEPT
    else 
        ipt46 -A INPUT -p $DEST_PROTOCOL --dport $DEST_PORT -m comment --comment "$RULE_COMMENT" -j ACCEPT
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

    log_progress_msg "Outside << Host | allow output: $DEST_PROTOCOL $DEST_PORT - $RULE_COMMENT"
    ipt46 -A OUTPUT -p $DEST_PROTOCOL --dport $DEST_PORT -m comment --comment "$RULE_COMMENT" -j ACCEPT
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
    ipt4 -A FORWARD -s $SOURCE_IP -m comment --comment "$COMMENT" -j ACCEPT
}
function allowForwardingFromIpv6 {
    SOURCE_IP=$1
    COMMENT=$2

    log_progress_msg "Allow forward packets from source: $SOURCE_IP"
    ipt6 -A FORWARD -s $SOURCE_IP -m comment --comment "$COMMENT" -j ACCEPT
}

# usage:   forwardPortIpv4 <sourcePort> <protocol> <target server> <targetPort> <comment>
#          forwardPortIpv4 8090 udp 192.168.15.4 8080 "Tomcat code.vehco.com"
function forwardPortIpv4 {
    SOURCE_PORT=$1
    PROTOCOL=$2
    TARGET_SERVER=$3
    TARGET_PORT=$4
    COMMENT=$5

    log_progress_msg "Forward incoming $PROTOCOL $SOURCE_PORT to $TARGET_SERVER:$TARGET_PORT - $COMMENT"

    # Allow incoming on SOURCE port
    ipt4 -A INPUT -p $PROTOCOL --dport $SOURCE_PORT -m comment --comment "$COMMENT"-j ACCEPT
    # Allow outgoing on TARGET port
    ipt4 -A OUTPUT -p $PROTOCOL --dport $TARGET_PORT -m comment --comment "$COMMENT" -j ACCEPT
    # Forward data: Source <-> Target
    ipt4 -A PREROUTING -t nat -p $PROTOCOL --dport $SOURCE_PORT -m comment --comment "$COMMENT" -j DNAT --to $TARGET_SERVER:$TARGET_PORT
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
        ipt4 -A INPUT -p $PROTOCOL --dport $SOURCE_PORT -s $allowClient -m comment --comment "src IP filter, allow: $allowClient:$SOURCE_PORT" -j ACCEPT
    done

    ### Drop all the rest
    ipt4 -A INPUT -p $PROTOCOL --dport $SOURCE_PORT -s 0.0.0.0/0 -m comment --comment "src IP filter, block access to: $SOURCE_PORT" -j DROP
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
        ipt6 -A INPUT -p $PROTOCOL --dport $SOURCE_PORT -s $allowClient -m comment --comment "src IP filter, allow: $allowClient:$SOURCE_PORT" -j ACCEPT
    done

    ### Drop all the rest
    ipt6 -A INPUT -p $PROTOCOL --dport $SOURCE_PORT -m comment --comment "src IP filter, block access to: $SOURCE_PORT" -j DROP
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
    log_progress_msg "Init VPN"
    ipt46 -A INPUT -p $VPN_PROTOCOL --dport $VPN_PORT -m comment --comment "VPN incoming" -j ACCEPT
    ipt46 -A OUTPUT -p $VPN_PROTOCOL --dport $VPN_PORT -m comment --comment "VPN outgoing" -j ACCEPT
    ipt46 -A OUTPUT -p $VPN_PROTOCOL --sport $VPN_PORT -m comment --comment "VPN outgoing" -j ACCEPT
    # Allow VPN packets type INPUT,OUTPUT,FORWARD
    ipt46 -A INPUT -i $INT_VPN -m state ! --state INVALID -m comment --comment "Invalid VPN packet" -j ACCEPT
    ipt46 -A OUTPUT -o $INT_VPN -m state ! --state INVALID -m comment --comment "Invalid VPN packet" -j ACCEPT
    ipt46 -A FORWARD -o $INT_VPN -m state ! --state INVALID -m comment --comment "Invalid VPN packet" -j ACCEPT

    ######
    # Allow forwarding
    ######
    log_progress_msg "Enable forwarding form $INT_VPN /to/ $INT_LOCAL"
    ipt46 -A FORWARD -i $INT_VPN -o $INT_LOCAL -m comment --comment "Forwarding $INT_LOCAL <> VPN" -j ACCEPT
    ipt46 -A FORWARD -i $INT_LOCAL -o $INT_VPN -m comment --comment "Forwarding $INT_LOCAL <> VPN" -j ACCEPT

    ######
    # Allow local LAN / remote LAN communication through VPN
    ######
    if [[ ! -z "$VPN_LAN" ]]
    then
        log_progress_msg "Enable forwarding form $INT_VPN /to/ $INT_LOCAL"
        # Allow packets to be send from|to the VPN network
        ipt4 -A FORWARD -s $VPN_LAN -m comment --comment "VPN remote LAN ($VPN_LAN)" -j ACCEPT
        # Allow packet to go/from the VPN network to the LAN
        ipt4 -t nat -A POSTROUTING -s $VPN_LAN -o $INT_LOCAL -j MASQUERADE


        log_progress_msg "Allow VPN client to client communication"
        # Allow VPN client <-> client communication
        ipt4 -A INPUT -s $VPN_LAN -d $VPN_LAN -m state ! --state INVALID -j ACCEPT
        ipt4 -A OUTPUT -s $VPN_LAN -d $VPN_LAN -m state ! --state INVALID -j ACCEPT
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
    ipt4 -N logging_v4
    # Apply chain rules to...
    ipt4 -A INPUT -j logging_v4
    ipt4 -A OUTPUT -j logging_v4
    # Rules to apply
    ipt4 -A logging_v4 -m limit --limit 10/min -j LOG --log-prefix "IPv4 - dropped: " --log-level 4
    ipt4 -A logging_v4 -j DROP

    ############ IPv6
    log_progress_msg "Firewall log dropped packets (ip v6)"
    # Create log chain
    ipt6 -N logging_v6
    # Apply chain rules to...
    ipt6 -A INPUT -j logging_v6
    ipt6 -A OUTPUT -j logging_v6
    # Rules to apply
    ipt6 -A logging_v6 -m limit --limit 10/min -j LOG --log-prefix "IPv6 - dropped: " --log-level 4
    ipt6 -A logging_v6 -j DROP

    log_end_msg 0
}

