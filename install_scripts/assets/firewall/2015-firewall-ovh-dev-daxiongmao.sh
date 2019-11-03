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
#####
# Authors: Guillaume Diaz (all versions) + Julien Rialland (contributor to v1.4)
#

# -------------------------------- #
#   LOCATION OF LINUX SOFTWARES    #
# -------------------------------- #
MODPROBE=`which modprobe`
IPTABLES=`which iptables`
IP6TABLES=`which ip6tables`

# This enable system logger and related functions
if [ -e /etc/debian_version ]; then
    . /lib/lsb/init-functions
elif [ -e /etc/init.d/functions ] ; then
    . /etc/init.d/functions
fi
if [ -r /etc/default/rcS ]; then
  . /etc/default/rcS
fi

# --------------------- #
#   COMMON VARIABLES    #
# --------------------- #
# network configuration

INT_ETH="eth0"

IP_LAN_VPN_PRV="192.168.15.0/24"
INT_VPN=tun0
VPN_PORT="8080"
VPN_PROTOCOL="udp"



# ------------------------------------------------------------------------------
# Common functions
# ------------------------------------------------------------------------------


# usage:   sourceIpFiltering <portNumber> <protocol>
#          sourceIpFiltering 7792 udp
function sourceIpFiltering() {
    SOURCE_PORT=$1
    PROTOCOL=$2

    ##########
    # List of allowed IP @
    ##########        
    # Remote IP @
    $IPTABLES -A INPUT -p $PROTOCOL --dport $SOURCE_PORT -s 5.39.81.23 -j ACCEPT

    # LAN
    if [ ! -z "$IP_LAN_V4" ] ; then
        $IPTABLES -A INPUT -p $PROTOCOL --dport $SOURCE_PORT -s $IP_LAN_V4 -j ACCEPT
    fi

    # VPN
    if [ ! -z "$IP_LAN_VPN_PRV" ] ; then
        $IPTABLES -A INPUT -p $PROTOCOL --dport $SOURCE_PORT -s $IP_LAN_VPN_PRV -j ACCEPT
    fi
    if [ ! -z "$IP_LAN_VPN_PRO" ] ; then
        $IPTABLES -A INPUT -p $PROTOCOL --dport $SOURCE_PORT -s $IP_LAN_VPN_PRO -j ACCEPT
    fi   

    # Accept localhost
    $IPTABLES -A INPUT -p $PROTOCOL --dport $SOURCE_PORT -s 127.0.0.1/24 -j ACCEPT

    ##########
    # Drop all the rest
    ##########
    $IPTABLES -A INPUT -p $PROTOCOL --dport $SOURCE_PORT -s 0.0.0.0/0 -j DROP
}



# ------------------------------------------------------------------------------
# Port forwarding setup
# ------------------------------------------------------------------------------

function allowForwardingFromTo {
    log_progress_msg "Allow forwarding from/to specific source IP@ and networks"
     
    # Remote IP @
    # TODO add luxembourg remote IP @
    $IPTABLES -A FORWARD -s 5.39.81.23 -j ACCEPT

    # LAN
    if [ ! -z "$IP_LAN_V4" ] ; then
        $IPTABLES -A FORWARD -s $IP_LAN_V4 -j ACCEPT
    fi

    # VPN
    if [ ! -z "$IP_LAN_VPN_PRV" ] ; then
        $IPTABLES -A FORWARD -s $IP_LAN_VPN_PRV -j ACCEPT
    fi
    if [ ! -z "$IP_LAN_VPN_PRO" ] ; then
        $IPTABLES -A FORWARD -s $IP_LAN_VPN_PRO -j ACCEPT
    fi   
}

# usage:   forwardPort <sourcePort> <protocol> <target server> <targetPort>
#          forwardPort 7792 udp
function forwardPort {
    SOURCE_PORT=$1
    PROTOCOL=$2
    TARGET_SERVER=$3
    TARGET_PORT=$4

    $IPTABLES -A INPUT -p $PROTOCOL --dport $SOURCE_PORT -j ACCEPT
    $IPTABLES -A OUTPUT -p $PROTOCOL --dport $TARGET_PORT -j ACCEPT
    $IPTABLES -A PREROUTING -t nat -p $PROTOCOL --dport $SOURCE_PORT -j DNAT --to $TARGET_SERVER:$TARGET_PORT
}

function forward {
    log_daemon_msg "Port forwarding rules"

    allowForwardingFromTo

    # FORWARD rules
    log_progress_msg "Forwarding from/to specific source IP@ and networks"

    XINXIONGMAO=192.168.15.6
    forwardPort 41200 tcp $XINXIONGMAO 41200
    forwardPort 37350 udp $XINXIONGMAO 37350

    log_end_msg 0
}



# ------------------------------------------------------------------------------
# Required rules
# ------------------------------------------------------------------------------

# To enable networking modules in the current OS
function enableModules {
    log_progress_msg "Enable networking modules"
    
    # OVH modprobe is already done!
    ### IPv4
#    $MODPROBE ip_tables
#    $MODPROBE iptable_filter
#    $MODPROBE iptable_mangle
    # Allow to use state match
#    $MODPROBE ip_conntrack
    # Allow NAT
#    $MODPROBE iptable_nat
    ### IPv6
#    $MODPROBE ip6_tables
#    $MODPROBE ip6table_filter
#    $MODPROBE ip6table_mangle
    ### Allow active / passive FTP
#    $MODPROBE ip_conntrack_ftp
#    $MODPROBE ip_nat_ftp
    ### Allow log limits
#    $MODPROBE ipt_limit


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
    # Port forwarding in general
    echo 1 > /proc/sys/net/ipv4/ip_forward
    echo 1 > /proc/sys/net/ipv6/conf/all/forwarding
}

# To flush old rules and setup the default policy
function defaultPolicy {
    log_progress_msg "Flush existing rules"
    $IP6TABLES -F
    $IP6TABLES -X   
    $IPTABLES -F
    $IPTABLES -X
    # Filter rules
    $IPTABLES -t filter -F
    $IPTABLES -t filter -X
    # delete NAT rules
    $IPTABLES -t nat -F
    $IPTABLES -t nat -X
    # delete MANGLE rules (packets modifications)
    $IPTABLES -t mangle -F
    $IPTABLES -t mangle -X
    $IP6TABLES -t mangle -F
    $IP6TABLES -t mangle -X
    
    log_progress_msg "Set default policy"
    # IPv4
    $IPTABLES -P INPUT DROP
    $IPTABLES -P FORWARD DROP
    $IPTABLES -P OUTPUT ACCEPT
    # IPv6
    $IP6TABLES -P INPUT DROP
    $IP6TABLES -P FORWARD DROP
    $IP6TABLES -P OUTPUT ACCEPT

    log_progress_msg "Set common security filters"
    # Reject invalid packets
    $IPTABLES -A INPUT -p tcp -m state --state INVALID -m comment --comment "Reject invalid TCP" -j DROP
    $IPTABLES -A INPUT -p udp -m state --state INVALID -m comment --comment "Reject invalid UDP" -j DROP
    $IPTABLES -A INPUT -p icmp -m state --state INVALID -m comment --comment "Reject invalid ICMP" -j DROP
    $IPTABLES -A OUTPUT -p tcp -m state --state INVALID -m comment --comment "Reject invalid TCP" -j DROP
    $IPTABLES -A OUTPUT -p udp -m state --state INVALID -m comment --comment "Reject invalid UDP" -j DROP
    $IPTABLES -A OUTPUT -p icmp -m state --state INVALID -m comment --comment "Reject invalid ICMP" -j DROP
    $IPTABLES -A FORWARD -p tcp -m state --state INVALID -m comment --comment "Reject invalid TCP" -j DROP
    $IPTABLES -A FORWARD -p udp -m state --state INVALID -m comment --comment "Reject invalid UDP" -j DROP
    
    $IP6TABLES -A INPUT -p tcp -m state --state INVALID -m comment --comment "Reject invalid TCP" -j DROP
    $IP6TABLES -A INPUT -p udp -m state --state INVALID -m comment --comment "Reject invalid UDP" -j DROP
    $IP6TABLES -A INPUT -p icmpv6 -m state --state INVALID -m comment --comment "Reject invalid ICMP6" -j DROP
    $IP6TABLES -A OUTPUT -p tcp -m state --state INVALID -m comment --comment "Reject invalid TCP" -j DROP
    $IP6TABLES -A OUTPUT -p udp -m state --state INVALID -m comment --comment "Reject invalid UDP" -j DROP
    $IP6TABLES -A OUTPUT -p icmpv6 -m state --state INVALID -m comment --comment "Reject invalid ICMP6" -j DROP
    $IP6TABLES -A FORWARD -p tcp -m state --state INVALID -m comment --comment "Reject invalid TCP" -j DROP
    $IP6TABLES -A FORWARD -p udp -m state --state INVALID -m comment --comment "Reject invalid UDP" -j DROP

    # Reserved addresses. We shouldn't received any packets from them!
    $IPTABLES -A INPUT -s 10.0.0.0/8 -m comment --comment "Do not allow foreign LAN - class A" -j DROP
    $IPTABLES -A INPUT -s 169.254.0.0/16 -m comment --comment "Do not allow weired LAN - 169.254.0.0/16" -j DROP
    
    ## Localhost
    $IPTABLES -A INPUT ! -i lo -s 127.0.0.0/24 -m comment --comment "Reject none loopback on 'lo'" -j DROP  
    $IPTABLES -A OUTPUT ! -o lo -d 127.0.0.0/24 -m comment --comment "Reject none loopback on 'lo'" -j DROP
    $IPTABLES -A FORWARD -s 127.0.0.0/24 -m comment --comment "Reject none loopback on 'lo'" -j DROP

    $IP6TABLES -A INPUT ! -i lo -s ::1/128 -m comment --comment "Reject none loopback on 'lo'" -j DROP
    $IP6TABLES -A OUTPUT ! -o lo -d ::1/128 -m comment --comment "Reject none loopback on 'lo'" -j DROP
    $IP6TABLES -A FORWARD -s ::1/128 -m comment --comment "Reject none loopback on 'lo'" -j DROP
    
    ## IPv6 security
    # No IPv4 -> IPv6 tunneling
    $IP6TABLES -A INPUT -s 2002::/16 -m comment --comment "Reject 6to4 tunnels" -j DROP
    $IP6TABLES -A FORWARD -s 2002::/16 -m comment --comment "Reject 6to4 tunnels" -j DROP
    $IP6TABLES -A INPUT -s 2001:0::/32 -m comment --comment "Reject Teredo tunnels" -j DROP
    $IP6TABLES -A FORWARD -s 2001:0::/32 -m comment --comment "Reject Teredo tunnels" -j DROP
    
    # Block IPv6 protocol in IPv4 frames
    $IPTABLES -A INPUT -p 41 -m comment --comment "Block IPv6 protocol in IPv4 frames" -j DROP
    $IPTABLES -A OUTPUT -p 41 -m comment --comment "Block IPv6 protocol in IPv4 frames" -j DROP
    $IPTABLES -A FORWARD -p 41 -m comment --comment "Block IPv6 protocol in IPv4 frames" -j DROP


    log_progress_msg "Keep ESTABLISHED, RELATED connections"
    $IPTABLES -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    $IPTABLES -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
    $IPTABLES -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

    $IP6TABLES -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    $IP6TABLES -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
    $IP6TABLES -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT 

    if [ ! -z "$IP_LAN_V4" ] 
    then
        log_progress_msg "Allow LAN communication - IP v4 - Network: $IP_LAN_V4"
        $IPTABLES -A INPUT -s $IP_LAN_V4 -d $IP_LAN_V4 -m comment --comment "local LAN" -j ACCEPT
        $IPTABLES -A OUTPUT -s $IP_LAN_V4 -d $IP_LAN_V4 -m comment --comment "local LAN" -j ACCEPT
    fi
    if [ ! -z "$IP_LAN_V6" ] 
    then
        log_progress_msg "Allow LAN communication - IP v6 - Network: $IP_LAN_V6"
        $IP6TABLES -A INPUT -s $IP_LAN_V6 -d $IP_LAN_V6 -m comment --comment "local LAN" -j ACCEPT
        $IP6TABLES -A OUTPUT -s $IP_LAN_V6 -d $IP_LAN_V6 -m comment --comment "local LAN" -j ACCEPT
    fi

    
    log_progress_msg "Enable common protocols: DHCP, DNS, FTP (passive/active)"
    ## DHCP client >> Broadcast IP request 
    $IPTABLES -A INPUT -p udp --sport 67:68 --dport 67:68 -m comment --comment "DHCP" -j ACCEPT 
    $IPTABLES -A OUTPUT -p udp --sport 67:68 --dport 67:68 -m comment --comment "DHCP" -j ACCEPT 

    # DNS (udp)
    $IPTABLES -A INPUT -p udp --sport 53 -m comment --comment "DNS UDP sPort" -j ACCEPT
    $IPTABLES -A OUTPUT -p udp --sport 53 -m comment --comment "DNS UDP sPort" -j ACCEPT
    $IPTABLES -A INPUT -p udp --dport 53 -m comment --comment "DNS UDP dPort" -j ACCEPT
    $IPTABLES -A OUTPUT -p udp --dport 53 -m comment --comment "DNS UDP dPort" -j ACCEPT
    # IP v6 DNS
    $IP6TABLES -A INPUT -p udp --sport 53 -m comment --comment "DNS6 UDP sPort" -j ACCEPT
    $IP6TABLES -A OUTPUT -p udp --sport 53 -m comment --comment "DNS6 UDP sPort" -j ACCEPT
    $IP6TABLES -A INPUT -p udp --dport 53 -m comment --comment "DNS6 UDP dPort" -j ACCEPT
    $IP6TABLES -A OUTPUT -p udp --dport 53 -m comment --comment "DNS6 UDP dPort" -j ACCEPT

    # DNS SEC
    # Established, related input are already accepted earlier
    $IPTABLES -A OUTPUT -p tcp --sport 53 -m comment --comment "DNS Sec TCP sPort" -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 53 -m comment --comment "DNS Sec TCP dPort" -j ACCEPT
    # DNS SEC IP v6
    $IP6TABLES -A OUTPUT -p tcp --dport 53 -m comment --comment "DNS Sec TCP dPort" -j ACCEPT
    $IP6TABLES -A OUTPUT -p tcp --dport 53 -m comment --comment "DNS Sec TCP dPort" -j ACCEPT
    
    
    echo "     !!! If you lost Internet after running the script, please check your /etc/resolv.conf file"
    echo "         Make sure you are not using 127.0.0.1 as default nameserver"

    # FTP requests  
    # FTP data transfer
    $IPTABLES -A OUTPUT -p tcp --dport 20 -m comment --comment "FTP data" -j ACCEPT
    $IP6TABLES -A OUTPUT -p tcp --dport 20 -m comment --comment "FTP data" -j ACCEPT  
    # FTP control (command)
    $IPTABLES -A OUTPUT -p tcp --dport 21 -m comment --comment "FTP command" -j ACCEPT
    $IP6TABLES -A OUTPUT -p tcp --dport 21 -m comment --comment "FTP command" -j ACCEPT  

    # NTP
    $IPTABLES -A INPUT -p udp --sport 123 -m state --state ESTABLISHED -m comment --comment "NTP (UDP)" -j ACCEPT
    $IPTABLES -A INPUT -p tcp --sport 123 -m state --state ESTABLISHED -m comment --comment "NTP (TCP)" -j ACCEPT

    $IPTABLES -A OUTPUT -p udp --dport 123 -m state --state NEW,ESTABLISHED -m comment --comment "NTP (UDP)" -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 123 -m state --state NEW,ESTABLISHED -m comment --comment "NTP (TCP)" -j ACCEPT
}




# Security rules
# Networking protocols enforcement
function protocolEnforcement {
    log_progress_msg " Security protection"
    # ICMP packets should not be fragmented
    $IPTABLES -A INPUT --fragment -p icmp -m comment --comment "no ICMP fragments" -j DROP    
    # Limit ICMP Flood
    $IPTABLES -A INPUT -p icmp -m limit --limit 1/s --limit-burst 1 -m comment --comment "ICMP flood protection" -j ACCEPT
    #$IPTABLES -A OUTPUT -p icmp -m limit --limit 1/s --limit-burst 1 -j ACCEPT
    $IPTABLES -A OUTPUT -p icmp --icmp-type 0 -m comment --comment "echo reply" -j ACCEPT
    $IPTABLES -A OUTPUT -p icmp --icmp-type 3 -m comment --comment "destination unreachable" -j ACCEPT
    $IPTABLES -A OUTPUT -p icmp --icmp-type 8 -m comment --comment "echo request" -j ACCEPT    
    # Avoid common attacks ... but blocks ping
    #$IPTABLES -A OUTPUT -p icmp --icmp-type 3 -j DROP

    
    log_progress_msg " ... Layer 2: ICMP v6 "
    # Feedback for problems
    $IP6TABLES -A INPUT -p icmpv6 --icmpv6-type 1 -m comment --comment "destination unreachable" -j ACCEPT
    $IP6TABLES -A INPUT -p icmpv6 --icmpv6-type 2 -m comment --comment "packet too big" -j ACCEPT
    $IP6TABLES -A INPUT -p icmpv6 --icmpv6-type 3 -m comment --comment "time exceeded" -j ACCEPT
    $IP6TABLES -A INPUT -p icmpv6 --icmpv6-type 4 -m comment --comment "parameter problem" -j ACCEPT
    
    # Router and neighbor discovery 
    $IP6TABLES -A INPUT -p icmpv6 --icmpv6-type 133 -m comment --comment "router sollicitation" -j ACCEPT
    $IP6TABLES -A INPUT -p icmpv6 --icmpv6-type 134 -m comment --comment "router advertisement" -j ACCEPT
    $IP6TABLES -A INPUT -p icmpv6 --icmpv6-type 135 -m comment --comment "neighbor sollicitation" -j ACCEPT
    $IP6TABLES -A INPUT -p icmpv6 --icmpv6-type 136 -m comment --comment "neighbor advertisement" -j ACCEPT
    
    $IP6TABLES -A OUTPUT -p icmpv6 --icmpv6-type 133 -m comment --comment "router sollicitation" -j ACCEPT
    $IP6TABLES -A OUTPUT -p icmpv6 --icmpv6-type 134 -m comment --comment "router advertisement" -j ACCEPT
    $IP6TABLES -A OUTPUT -p icmpv6 --icmpv6-type 135 -m comment --comment "neighbor sollicitation" -j ACCEPT
    $IP6TABLES -A OUTPUT -p icmpv6 --icmpv6-type 136 -m comment --comment "neighbor advertisement" -j ACCEPT
    
    # Ping requests
    $IP6TABLES -A INPUT -p icmpv6 --icmpv6-type 128 -m comment --comment "echo request" -j ACCEPT
    $IP6TABLES -A OUTPUT -p icmpv6 --icmpv6-type 128 -m comment --comment "echo request" -j ACCEPT

    $IP6TABLES -A INPUT -p icmpv6 --icmpv6-type 129 -m comment --comment "echo reply" -j ACCEPT
    $IP6TABLES -A OUTPUT -p icmpv6 --icmpv6-type 129 -m comment --comment "echo reply" -j ACCEPT
    
    
    log_progress_msg " ... Layer 4: TCP # check packets conformity"
    # INCOMING packets check
    # All new incoming TCP should be SYN first
    $IPTABLES -A INPUT -p tcp ! --syn -m state --state NEW -m comment --comment "new TCP connection check" -j DROP
    # Avoid SYN Flood (max 3 SYN packets / second. Then Drop all requests !!)
    $IPTABLES -A INPUT -p tcp --syn -m limit --limit 1/s --limit-burst 3 -m comment --comment "avoid TCP SYN flood" -j ACCEPT
    # Avoid fragment packets
    $IPTABLES -A INPUT -f -m comment --comment "no fragments" -j DROP
    # Check TCP flags -- flag 64, 128 = bogues
    $IPTABLES -A INPUT -p tcp --tcp-option 64 -j DROP
    $IPTABLES -A INPUT -p tcp --tcp-option 128 -j DROP


    log_progress_msg " ... Layer 4: TCP # Avoid NMAP Scans"
    # XMAS-NULL
    $IPTABLES -A INPUT -p tcp --tcp-flags ALL NONE -m comment --comment "attack XMAS-NULL" -j DROP
    # XMAS-TREE
    $IPTABLES -A INPUT -p tcp --tcp-flags ALL ALL -m comment --comment "attack XMAS-tree" -j DROP
    # Stealth XMAS Scan
    $IPTABLES -A INPUT -p tcp --tcp-flags ALL FIN,PSH,URG -m comment --comment "attack XMAS stealth" -j DROP

    # SYN/RST Scan
    $IPTABLES -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -m comment --comment "scan SYN/RST" -j DROP
    # SYN/FIN Scan
    $IPTABLES -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -m comment --comment "scan SYN/FIN" -j DROP
    # SYN/ACK Scan
    #$IPTABLES -A INPUT -p tcp --tcp-flags ALL ACK -j DROP
    $IPTABLES -A INPUT -p tcp --tcp-flags SYN,ACK SYN,ACK -m comment --comment "scan SYN/ACK" -j DROP
    # FIN/RST Scan
    $IPTABLES -A INPUT -p tcp --tcp-flags FIN,RST FIN,RST -m comment --comment "scan FIN/RST" -j DROP
    # FIN/ACK Scan
    $IPTABLES -A INPUT -p tcp -m tcp --tcp-flags FIN,ACK FIN -m comment --comment "scan FIN/ACK" -j DROP
    # ACK/URG Scan
    $IPTABLES -A INPUT -p tcp --tcp-flags ACK,URG URG -m comment --comment "scan ACK/URG" -j DROP
    # FIN/URG/PSH Scan
    $IPTABLES -A INPUT -p tcp --tcp-flags FIN,URG,PSH FIN,URG,PSH -m comment --comment "scan FIN/URG/PSH" -j DROP
    # XMAS-PSH Scan
    $IPTABLES -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -m comment --comment "scan XMAS/PSH" -j DROP
    # End TCP connection
    $IPTABLES -A INPUT -p tcp --tcp-flags ALL FIN -m comment --comment "end TCP connection flag" -j DROP
    # Ports scans
    $IPTABLES -A INPUT -p tcp --tcp-flags FIN,SYN,RST,ACK SYN -m comment --comment "common scan FIN/SYN/RST/ACK SYN" -j DROP
    $IPTABLES -A INPUT -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -m comment --comment "common scan FIN/SYN/RST/ACK/PSH/URG NONE" -j DROP
}



# ------------------------------------------------------------------------------
# INCOMING rules
# ------------------------------------------------------------------------------
function incomingPortFiltering {
    log_daemon_msg "Firewall INPUT filtering"

    #################
    # Remote access
    #################
    # SSH
    $IPTABLES -A INPUT -p tcp -m limit --limit 3/min --limit-burst 3 --dport 22 -m comment --comment "SSH" -j ACCEPT 
    $IP6TABLES -A INPUT -p tcp -m limit --limit 3/min --limit-burst 3 --dport 22 -m comment --comment "SSH" -j ACCEPT

    # SSH custom port Daxiongmao
    $IPTABLES -A INPUT -p tcp -m limit --limit 3/min --limit-burst 3 --dport 2200 -m comment --comment "SSH" -j ACCEPT 
    $IP6TABLES -A INPUT -p tcp -m limit --limit 3/min --limit-burst 3 --dport 2200 -m comment --comment "SSH" -j ACCEPT

    # Remote desktop 
    #$IPTABLES -A INPUT -p tcp --dport 4000 -m comment --comment "NoMachine LAN server" -j ACCEPT
    #$IPTABLES -A INPUT -p tcp --dport 4080 -m comment --comment "NoMachine HTTP server" -j ACCEPT
    #$IPTABLES -A INPUT -p tcp --dport 4443 -m comment --comment "NoMachine HTTPS server" -j ACCEPT
    #$IPTABLES -A INPUT -p udp --dport 4011:4999 -m comment --comment "NoMachine server UDP feed" -j ACCEPT
    
    #################
    # WEB
    #################
    # HTTP, HTTPS  
    $IPTABLES -A INPUT -p tcp --dport 80 -m comment --comment "HTTP" -j ACCEPT
    $IPTABLES -A INPUT -p tcp --dport 443 -m comment --comment "HTTPS" -j ACCEPT

    # Web server (HTTP alt)
    #$IPTABLES -A INPUT -p tcp --dport 8080 -m comment --comment "HTTP alt." -j ACCEPT
    #$IPTABLES -A INPUT -p tcp --dport 8443 -m comment --comment "HTTPS alt." -j ACCEPT

    # JEE server      
    #$IPTABLES -A INPUT -p tcp --dport 4848 -m comment --comment "Glassfish admin" -j ACCEPT
    #$IPTABLES -A INPUT -p tcp --dport 1527 -m comment --comment "Glassfish security manager" -j ACCEPT
    #$IPTABLES -A INPUT -p tcp --dport 9990 -m comment --comment "JBoss admin" -j ACCEPT

    # Software quality
    #$IPTABLES -A INPUT -p tcp --dport 9000 -m comment --comment "Sonarqube" -j ACCEPT
    #sourceIpFiltering 9000 tcp

    #################
    # Database
    #################
    # TODO re-enable source IP filtering once Luxembourg IP @ is known
    #sourceIpFiltering 3306 tcp
    $IPTABLES -A INPUT -p tcp --dport 3306 -m comment --comment "MySQL" -j ACCEPT
    #$IPTABLES -A INPUT -p tcp --dport 5432 -m comment --comment "PostgreSQL" -j ACCEPT


    #################
    # IT
    #################
    # File-share
    #$IPTABLES -A INPUT -p tcp --dport 135 -m comment --comment "DCE endpoint resolution" -j ACCEPT
    #$IPTABLES -A INPUT -p udp --dport 137 -m comment --comment "NetBIOS Name Service" -j ACCEPT
    #$IPTABLES -A INPUT -p udp --dport 138 -m comment --comment "NetBIOS Datagram" -j ACCEPT
    #$IPTABLES -A INPUT -p tcp --dport 139 -m comment --comment "NetBIOS Session" -j ACCEPT
    #$IPTABLES -A INPUT -p tcp --dport 445 -m comment --comment "SMB over TCP" -j ACCEPT

    #sourceIpFiltering 135 udp
    #sourceIpFiltering 137 udp
    #sourceIpFiltering 138 udp
    #sourceIpFiltering 139 tcp
    #sourceIpFiltering 445 tcp


    # LDAP
    #$IPTABLES -A INPUT -p tcp --dport 389 -m comment --comment "LDAP + LDAP startTLS" -j ACCEPT
    #$IPTABLES -A INPUT -p tcp --dport 636 -m comment --comment "LDAPS" -j ACCEPT

    # IT tools
    #$IPTABLES -A INPUT -p tcp --dport 10000 -m comment --comment "Webmin services" -j ACCEPT 
    #$IPTABLES -A INPUT -p tcp --dport 20000 -m comment --comment "Webmin users" -j ACCEPT

    #$IPTABLES -A INPUT -p tcp --dport 10050 -m comment --comment "Zabbix agent" -j ACCEPT
    #$IPTABLES -A INPUT -p tcp --dport 10051 -m comment --comment "Zabbix server" -j ACCEPT
    #$IPTABLES -A INPUT -p tcp --dport 3030 -m comment --comment "Dashboard (zabbix)" -j ACCEPT

    # ElasticSearch, Logstash, Kibana
    #$IPTABLES -A INPUT -p tcp --dport 9200 -m comment --comment "ElasticSearch HTTP" -j ACCEPT
    #$IPTABLES -A INPUT -p tcp --dport 9300 -m comment --comment "ElasticSearch Transport" -j ACCEPT
    #$IPTABLES -A INPUT -p tcp --dport 54328 -m comment --comment "ElasticSearch Multicasting" -j ACCEPT
    #$IPTABLES -A INPUT -p udp --dport 54328 -m comment --comment "ElasticSearch Multicasting" -j ACCEPT

    #################
    # Java
    #################
    #$IPTABLES -A INPUT -p tcp --dport 1099 -m comment --comment "JMX" -j ACCEPT

    #################
    # Messaging
    #################
    # Open MQ (bundled with Glassfish)
    #$IPTABLES -A INPUT -p tcp --dport 7676 -m comment --comment "OpenMQ" -j ACCEPT
    
    # ActiveMQ server
    #$IPTABLES -A INPUT -p tcp --dport 8161 -m comment --comment "ActiveMQ HTTP console" -j ACCEPT
    #$IPTABLES -A INPUT -p tcp --dport 8162 -m comment --comment "ActiveMQ HTTPS console" -j ACCEPT
    #$IPTABLES -A INPUT -p tcp --dport 11099 -m comment --comment "ActiveMQ JMX" -j ACCEPT
    #$IPTABLES -A INPUT -p tcp --dport 61616 -m comment --comment "ActiveMQ JMS Queues" -j ACCEPT

    # Rabbit MQ
    #$IPTABLES -A INPUT -p tcp --dport 15672 -m comment --comment "RabbitMQ HTTP console" -j ACCEPT
    #$IPTABLES -A INPUT -p tcp --dport 5672 -m comment --comment "RabbitMQ data" -j ACCEPT
       
    ## TODO example of IP @ filtering       
    #sourceIpFiltering 8088 udp


    ##########################
    # Common input to reject
    ##########################
    $IPTABLES -A INPUT -p udp --sport 57621 --dport 57621 -m comment --comment "Spotify network scan DROP" -j DROP
    $IPTABLES -A INPUT -p udp --sport 17500 --dport 17500 -m comment --comment "Dropbox network scan DROP" -j DROP


    log_end_msg 0
}



# ------------------------------------------------------------------------------
# OUTGOING rules
# ------------------------------------------------------------------------------
function outgoingPortFiltering {
    log_daemon_msg "Firewall OUTPUT filtering"

    ##############
    # Main ports
    ##############
    # Remote Control
    $IPTABLES -A OUTPUT -p tcp --dport 22 -m comment --comment "SSH" -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 23 -m comment --comment "Telnet" -j ACCEPT
    # Web
    $IPTABLES -A OUTPUT -p tcp --dport 80 -m comment --comment "HTTP" -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 443 -m comment --comment "HTTPS" -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 8080 -m comment --comment "HTTP alt." -j ACCEPT
    # Core Linux services
    $IPTABLES -A OUTPUT -p tcp --dport 135 -m comment --comment "RPC (Remote Procedure Call)" -j ACCEPT

    ##############
    # Remote control
    ##############
    $IPTABLES -A OUTPUT -p tcp --dport 3389 -m comment --comment "Microsoft RDP" -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 5900 -m comment --comment "VNC" -j ACCEPT

    $IPTABLES -A OUTPUT -p tcp --dport 4000 -m comment --comment "NoMachine LAN" -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 4080 -m comment --comment "NoMachine HTTP" -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 4443 -m comment --comment "NoMachine HTTPS" -j ACCEPT
    $IPTABLES -A OUTPUT -p udp --dport 4011:4999 -m comment --comment "NoMachine data feed" -j ACCEPT

    ##############
    # VMware products
    ##############
    # https://myServer:9443/vsphere-client
    $IPTABLES -A OUTPUT -p tcp --dport 9443 -m comment --comment "VMware vsphere web client" -j ACCEPT 
    
    ##############
    # Communication
    ##############
    # Email
    $IPTABLES -A OUTPUT -p tcp --dport 25 -m comment --comment "SMTP" -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 110 -m comment --comment "POP3" -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 143 -m comment --comment "IMAP" -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 993 -m comment --comment "IMAP over SSL" -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 995 -m comment --comment "POP over SSL" -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 587 -m comment --comment "SMTP SSL (gmail)" -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 465 -m comment --comment "SMTP SSL (gmail)" -j ACCEPT
    
    $IPTABLES -A OUTPUT -p tcp --dport 1863 -m comment --comment "MSN" -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 5060 -m comment --comment "SIP -VoIP-" -j ACCEPT
    $IPTABLES -A OUTPUT -p udp --dport 5060 -m comment --comment "SIP -VoIP-" -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 5061 -m comment --comment "MS Lync" -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 5222 -m comment --comment "Google talk" -j ACCEPT

    ##############
    # I.T
    ##############
    # Domain
    $IPTABLES -A OUTPUT -p tcp --dport 113 -m comment --comment "Kerberos" -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 389 -m comment --comment "LDAP" -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 636 -m comment --comment "LDAP over SSL" -j ACCEPT
    # Network Services
    $IPTABLES -A OUTPUT -p tcp --dport 43 -m comment --comment "WhoIs" -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 427 -m comment --comment "Service Location Protocol" -j ACCEPT
    $IPTABLES -A OUTPUT -p udp --dport 1900 -m comment --comment "UPnP - Peripheriques reseau" -j ACCEPT
    # Webmin 
    $IPTABLES -A OUTPUT -p tcp --dport 10000 -m comment --comment "Services and configuration" -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 20000 -m comment --comment "Users management" -j ACCEPT
    # Zabbix
    $IPTABLES -A OUTPUT -p tcp --dport 10050 -m comment --comment "Zabbix agent" -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 10051 -m comment --comment "Zabbix server" -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 3030 -m comment --comment "Dashboard (zabbix)" -j ACCEPT
    # ELK (ElasticSearch, Logstash, Kibana)
    $IPTABLES -A OUTPUT -p tcp --dport 9200 -m comment --comment "ElasticSearch HTTP console" -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 9300 -m comment --comment "ElasticSearch Transport" -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 54328 -m comment --comment "ElasticSearch Multicasting" -j ACCEPT
    $IPTABLES -A OUTPUT -p udp --dport 54328 -m comment --comment "ElasticSearch Multicasting" -j ACCEPT

    ##############
    # File share
    ##############
    $IPTABLES -A OUTPUT -p tcp --sport 135 -m state --state ESTABLISHED -m comment --comment "DCE endpoint resolution" -j ACCEPT
    $IPTABLES -A OUTPUT -p udp --dport 137 -m comment --comment "NetBios Name Service" -j ACCEPT
    $IPTABLES -A OUTPUT -p udp --dport 138 -m comment --comment "NetBios Data Exchange" -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 139 -m comment --comment "NetBios Session + Samba" -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 445 -m comment --comment "CIFS - Partage Win2K and more" -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 548 -m comment --comment "Apple file sharing" -j ACCEPT
    ##############
    # Development
    ##############    
    # Java
    $IPTABLES -A OUTPUT -p tcp --dport 1099 -m comment --comment "JMX" -j ACCEPT
    # Version control
    $IPTABLES -A OUTPUT -p tcp --dport 3690 -m comment --comment "SVN" -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 9418 -m comment --comment "GIT" -j ACCEPT
    # Database 
    $IPTABLES -A OUTPUT -p tcp --dport 3306 -m comment --comment "MySQL" -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 5432 -m comment --comment "Postgresql" -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 1433 -m comment --comment "Microsoft SQL server" -j ACCEPT
    $IPTABLES -A OUTPUT -p udp --dport 1433 -m comment --comment "Microsoft SQL server" -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 1434 -m comment --comment "Microsoft SQL server 2005" -j ACCEPT
    $IPTABLES -A OUTPUT -p udp --dport 1434 -m comment --comment "Microsoft SQL server 2005" -j ACCEPT
    # JEE server    
    $IPTABLES -A OUTPUT -p tcp --dport 4848 -m comment --comment "Glassfish admin" -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 1527 -m comment --comment "Glassfish4 security manager" -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 9990 -m comment --comment "Jboss admin" -j ACCEPT
    # Open MQ (bundled with Glassfish)
    $IPTABLES -A OUTPUT -p tcp --dport 7676 -m comment --comment "OpenMQ" -j ACCEPT
    # ActiveMQ server
    $IPTABLES -A OUTPUT -p tcp --dport 8161 -m comment --comment "ActiveMQ HTTP console" -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 8162 -m comment --comment "ActiveMQ HTTPS console" -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 11099 -m comment --comment "ActiveMQ JMX" -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 61616 -m comment --comment "ActiveMQ JMS queues" -j ACCEPT
    # Rabbit MQ
    $IPTABLES -A OUTPUT -p tcp --dport 15672 -m comment --comment "RabbitMQ HTTP console" -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 5672 -m comment --comment "RabbitMQ data" -j ACCEPT
    # Software quality
    $IPTABLES -A OUTPUT -p tcp --dport 9000 -m comment --comment "Sonarqube" -j ACCEPT

    ################################
    # Blizzard Diablo 3
    ################################
    # Battle.net Desktop Application
    $IPTABLES -A OUTPUT -p tcp --dport 1119 -m comment --comment "Battle.net Desktop Application" -j ACCEPT
    $IPTABLES -A OUTPUT -p udp --dport 1119 -m comment --comment "Battle.net Desktop Application" -j ACCEPT
    # Blizzard Downloader
    $IPTABLES -A OUTPUT -p tcp --dport 1120 -m comment --comment "Blizzard Downloader" -j ACCEPT
    $IPTABLES -A OUTPUT -p udp --dport 1120 -m comment --comment "Blizzard Downloader" -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 3724 -m comment --comment "Blizzard Downloader" -j ACCEPT
    $IPTABLES -A OUTPUT -p udp --dport 3724 -m comment --comment "Blizzard Downloader" -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 4000 -m comment --comment "Blizzard Downloader" -j ACCEPT
    $IPTABLES -A OUTPUT -p udp --dport 4000 -m comment --comment "Blizzard Downloader" -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 6112:6114 -m comment --comment "Blizzard Downloader" -j ACCEPT
    $IPTABLES -A OUTPUT -p udp --dport 6112:6114 -m comment --comment "Blizzard Downloader" -j ACCEPT
    # Diablo 3
    $IPTABLES -A OUTPUT -p udp --dport 6115:6120 -m comment --comment "Diablo 3" -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 6115:6120 -m comment --comment "Diablo 3" -j ACCEPT

    log_end_msg 0
}



# ------------------------------------------------------------------------------
# VPN configuration
# ------------------------------------------------------------------------------
function vpn {      
    if [[ ! -z "$IP_LAN_VPN_PRV" || ! -z "$IP_LAN_VPN_PRO" ]]
    then
        log_daemon_msg "VPN init"

        # Allow VPN connections through $INT_VPN
        # Hint: if you do not accept all RELATED,ESTABLISHED connections then you must allow the source port
        $IPTABLES -A INPUT -p $VPN_PROTOCOL --dport $VPN_PORT -m comment --comment "VPN incoming" -j ACCEPT
        $IPTABLES -A OUTPUT -p $VPN_PROTOCOL --dport $VPN_PORT -m comment --comment "VPN outgoing" -j ACCEPT
        $IPTABLES -A OUTPUT -p $VPN_PROTOCOL --sport $VPN_PORT -m comment --comment "VPN outgoing" -j ACCEPT

        # Allow VPN packets type INPUT,OUTPUT,FORWARD
        $IPTABLES -A INPUT -i $INT_VPN -m state ! --state INVALID -m comment --comment "Unvalid VPN packet" -j ACCEPT
        $IPTABLES -A OUTPUT -o $INT_VPN -m state ! --state INVALID -m comment --comment "Unvalid VPN packet" -j ACCEPT
        $IPTABLES -A FORWARD -o $INT_VPN -m state ! --state INVALID -m comment --comment "Unvalid VPN packet" -j ACCEPT

        # Allow forwarding
        log_daemon_msg "Enable forwarding"
        if [ ! -z "$INT_ETH" ] ; then
            $IPTABLES -A FORWARD -i $INT_VPN -o $INT_ETH -m comment --comment "Forwarding ETH <> VPN" -j ACCEPT
            $IPTABLES -A FORWARD -i $INT_ETH -o $INT_VPN -m comment --comment "Forwarding ETH <> VPN" -j ACCEPT
        fi
        if [ ! -z "$INT_WLAN" ] ; then
            $IPTABLES -A FORWARD -i $INT_VPN -o $INT_WLAN -m comment --comment "Forwarding WLAN <> VPN" -j ACCEPT
            $IPTABLES -A FORWARD -i $INT_WLAN -o $INT_VPN -m comment --comment "Forwarding WLAN <> VPN" -j ACCEPT
        fi            
        log_end_msg 0


        if [ ! -z "$IP_LAN_VPN_PRV" ]
        then
            log_daemon_msg "VPN to $IP_LAN_VPN_PRV"
            # Allow packets to be send from|to the VPN network
            $IPTABLES -A FORWARD -s $IP_LAN_VPN_PRV -m comment --comment "Remote LAN (PRV) <> VPN" -j ACCEPT
            # Allow packet to go/from the VPN network to the LAN
            if [ ! -z "$INT_ETH" ] ; then
                $IPTABLES -t nat -A POSTROUTING -s $IP_LAN_VPN_PRV -o $INT_ETH -j MASQUERADE
            fi
            if [ ! -z "$INT_WLAN" ] ; then
                $IPTABLES -t nat -A POSTROUTING -s $IP_LAN_VPN_PRV -o $INT_WLAN -j MASQUERADE
            fi
            # Allow VPN client <-> client communication
            $IPTABLES -A INPUT -s $IP_LAN_VPN_PRV -d $IP_LAN_VPN_PRV -m state ! --state INVALID -j ACCEPT
            $IPTABLES -A OUTPUT -s $IP_LAN_VPN_PRV -d $IP_LAN_VPN_PRV -m state ! --state INVALID -j ACCEPT
            log_end_msg 0
        fi

        if [ ! -z "$IP_LAN_VPN_PRO" ]
        then
            log_daemon_msg "VPN to $IP_LAN_VPN_PRO"
            # Allow packets to be send from|to the VPN network
            $IPTABLES -A FORWARD -s $IP_LAN_VPN_PRO -m comment --comment "Remote LAN (PRV) <> VPN" -j ACCEPT
            # Allow packet to go/from the VPN network to the LAN
            if [ ! -z "$INT_ETH" ] ; then
                $IPTABLES -t nat -A POSTROUTING -s $IP_LAN_VPN_PRO -o $INT_ETH -j MASQUERADE
            fi
            if [ ! -z "$INT_WLAN" ] ; then
                $IPTABLES -t nat -A POSTROUTING -s $IP_LAN_VPN_PRO -o $INT_WLAN -j MASQUERADE
            fi
            # Allow VPN client <-> client communication
            $IPTABLES -A INPUT -s $IP_LAN_VPN_PRO -d $IP_LAN_VPN_PRO -m state ! --state INVALID -j ACCEPT
            $IPTABLES -A OUTPUT -s $IP_LAN_VPN_PRO -d $IP_LAN_VPN_PRO -m state ! --state INVALID -j ACCEPT
            log_end_msg 0
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
        #route add -net 192.168.15.0/24 gw 192.168.1.45
    fi
}



# ------------------------------------------------------------------------------
# LOGGING
# ------------------------------------------------------------------------------
function logDropped {
    log_daemon_msg "Firewall log dropped packets"
    $IPTABLES -N LOGGING
    $IPTABLES -A INPUT -j LOGGING
    #$IPTABLES -A OUTPUT -j LOGGING
    $IPTABLES -A LOGGING -m limit --limit 2/min -j LOG --log-prefix "iptables - dropped: " --log-level 4
    $IPTABLES -A LOGGING -j DROP
    log_end_msg 0
}





echo " "
echo " "
echo "# --------------------- #"
echo "#    FW START script    #"
echo "# --------------------- #"
echo "Network interfaces"
if [ ! -z "$INT_ETH" ] ; then
    echo "   - $INT_ETH"
fi
if [ ! -z "$INT_WLAN" ] ; then
    echo "   - $INT_WLAN"
fi

###### Required stuff
log_daemon_msg "Firewall init (DROP input but SSH, DROP output but few ports)"
enableModules
defaultPolicy
protocolEnforcement
log_end_msg 0


###### Port filtering (input | output | forwarding)
incomingPortFiltering
#outgoingPortFiltering

###### Forward
forward

###### VPN
vpn

###### Log dropped packets
logDropped

echo " "
echo " "
