#!/bin/bash
# Firewall -- Packet level filtering
#   --> IPTABLES Rules
#   version 1.0 - Septembre 2008
#           1.1 - Novembre 2009
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
#
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
INT_ETH=`ifconfig -a | sed -n 's/^\([^ ]\+\).*/\1/p' \
         | grep -Fvx -e lo | grep -Fvx -e wlan0 \
         | grep -Fvx -e tun0 | grep -Fvx -e tunl0 | grep -Fvx -e docker0 \
         | grep -Fvx -e ip6tnl0 | grep -Fvx -e sit0 | grep -Fvx -e bond0 | grep -Fvx -e dummy0`
INT_WLAN=`ifconfig -a | sed -n 's/^\([^ ]\+\).*/\1/p' \
         | grep -Fvx -e lo | grep -Fvx -e eth0 \
         | grep -Fvx -e tun0 | grep -Fvx -e tunl0 | grep -Fvx -e docker0 \
         | grep -Fvx -e ip6tnl0 | grep -Fvx -e sit0 | grep -Fvx -e bond0 | grep -Fvx -e dummy0`

IP_LAN_V4="myLocalNetwork"
IP_LAN_V6=""
IP_LAN_VPN_PRV=""
IP_LAN_VPN_PRO=""

INT_VPN=tun0
VPN_PORT="8080"
VPN_PROTOCOL="udp"



# ------------------------------------------------------------------------------
# Common functions
# ------------------------------------------------------------------------------

function soureIpFiltering() {
    SOURCE_PORT=$1

    # usage:   sourceIpFiltering <portNumber>

    ##########
    # List of allowed IP @
    ##########        
    # Remote IP @
    $IPTABLES -A INPUT -p tcp --dport $SOURCE_PORT -s 5.39.81.23 -j ACCEPT
    # LAN
    $IPTABLES -A INPUT -p tcp --dport $SOURCE_PORT -s 192.168.1.0/24 -j ACCEPT
    # Accept localhost
    $IPTABLES -A INPUT -p tcp --dport $SOURCE_PORT -s 127.0.0.1/24 -j ACCEPT

    ##########
    # Drop all the rest
    ##########
    $IPTABLES -A INPUT -p tcp --dport $SOURCE_PORT -s 0.0.0.0/0 -j DROP
}



# ------------------------------------------------------------------------------
# Port forwarding setup
# ------------------------------------------------------------------------------
function forward {
    log_daemon_msg "Firewall FORWARD rules"

    REMOTE_WEB_SERVER=90.83.80.91


    #############################
    # Allow forwarding to...
    #
    # Here you need to set the list of targets. 
    # Ex:    remote user ---> MyServer ---> Target server
    #############################
    ### Remote servers
    $IPTABLES -A FORWARD -s $REMOTE_WEB_SERVER -j ACCEPT 

    ### LAN 
    if [ ! -z "$IP_LAN_V4" ] ; then
        $IPTABLES -A FORWARD -s $IP_LAN_V4 -j ACCEPT
    fi

    ### VPN
    if [ ! -z "$IP_LAN_VPN_PRV" ] ; then
        $IPTABLES -A FORWARD -s $IP_LAN_VPN_PRV -j ACCEPT
    fi

    #############################
    # FORWARD rules
    #############################
    forwardTcpPort 10022 $REMOTE_WEB_SERVER 22
    forwardTcpPort 10080 $REMOTE_WEB_SERVER 80
    forwardTcpPort 13306 $REMOTE_WEB_SERVER 3306

    log_end_msg 0
}

# usage:   forwardTcpPort <sourcePort> <targetServer> <targetPort>
function forwardTcpPort() {
    SOURCE_PORT=$1
    TARGET_SERVER=$2
    TARGET_PORT=$3
    $IPTABLES -A PREROUTING -t nat -p tcp --dport $SOURCE_PORT -j DNAT --to $TARGET_SERVER:$TARGET_PORT
}



# ------------------------------------------------------------------------------
# Required rules
# ------------------------------------------------------------------------------

# To enable networking modules in the current OS
function enableModules {
    log_progress_msg "Enable networking modules"
    ### IPv4
    $MODPROBE ip_tables
    $MODPROBE iptable_filter
    $MODPROBE iptable_mangle
    # Allow to use state match
    $MODPROBE ip_conntrack
    # Allow NAT
    $MODPROBE iptable_nat
    ### IPv6
    $MODPROBE ip6_tables
    $MODPROBE ip6table_filter
    $MODPROBE ip6table_mangle
    ### Allow active / passive FTP
    $MODPROBE ip_conntrack_ftp
    $MODPROBE ip_nat_ftp
    ### Allow log limits
    $MODPROBE ipt_limit


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
    $IPTABLES -P OUTPUT DROP            
    # IPv6
    $IP6TABLES -P INPUT DROP
    $IP6TABLES -P FORWARD DROP
    $IP6TABLES -P OUTPUT DROP


    log_progress_msg "Set common security filters"
    # Reject invalid packets
    $IPTABLES -A INPUT -p tcp -m state --state INVALID -j DROP
    $IPTABLES -A INPUT -p udp -m state --state INVALID -j DROP
    $IPTABLES -A INPUT -p icmp -m state --state INVALID -j DROP
    $IPTABLES -A OUTPUT -p tcp -m state --state INVALID -j DROP
    $IPTABLES -A OUTPUT -p udp -m state --state INVALID -j DROP
    $IPTABLES -A OUTPUT -p icmp -m state --state INVALID -j DROP
    $IPTABLES -A FORWARD -p tcp -m state --state INVALID -j DROP
    $IPTABLES -A FORWARD -p udp -m state --state INVALID -j DROP
    
    $IP6TABLES -A INPUT -p tcp -m state --state INVALID -j DROP
    $IP6TABLES -A INPUT -p udp -m state --state INVALID -j DROP
    $IP6TABLES -A INPUT -p icmpv6 -m state --state INVALID -j DROP
    $IP6TABLES -A OUTPUT -p tcp -m state --state INVALID -j DROP
    $IP6TABLES -A OUTPUT -p udp -m state --state INVALID -j DROP
    $IP6TABLES -A OUTPUT -p icmpv6 -m state --state INVALID -j DROP
    $IP6TABLES -A FORWARD -p tcp -m state --state INVALID -j DROP
    $IP6TABLES -A FORWARD -p udp -m state --state INVALID -j DROP

    # Reserved addresses. We shouldn't received any packets from them!
    $IPTABLES -A INPUT -s 10.0.0.0/8 -j DROP
    $IPTABLES -A INPUT -s 169.254.0.0/16 -j DROP
    
    ## Localhost
    $IPTABLES -A INPUT ! -i lo -s 127.0.0.0/24 -j DROP  
    $IPTABLES -A OUTPUT ! -o lo -d 127.0.0.0/24 -j DROP
    $IPTABLES -A FORWARD -s 127.0.0.0/24 -j DROP

    $IP6TABLES -A INPUT ! -i lo -s ::1/128 -j DROP
    $IP6TABLES -A OUTPUT ! -o lo -d ::1/128 -j DROP
    $IP6TABLES -A FORWARD -s ::1/128 -j DROP
    
    ## IPv6 security
    # No IPv4 -> IPv6 tunneling
    $IP6TABLES -A INPUT -s 2002::/16 -j DROP        # 6to4 tunnels
    $IP6TABLES -A FORWARD -s 2002::/16 -j DROP
    $IP6TABLES -A INPUT -s 2001:0::/32 -j DROP      # Teredo tunnels
    $IP6TABLES -A FORWARD -s 2001:0::/32 -j DROP
    
    # Block IPv6 protocol in IPv4 frames
    $IPTABLES -A INPUT -p 41 -j DROP
    $IPTABLES -A OUTPUT -p 41 -j DROP
    $IPTABLES -A FORWARD -p 41 -j DROP


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
        $IPTABLES -A INPUT -s $IP_LAN_V4 -d $IP_LAN_V4 -j ACCEPT
        $IPTABLES -A OUTPUT -s $IP_LAN_V4 -d $IP_LAN_V4 -j ACCEPT
    fi
    if [ ! -z "$IP_LAN_V6" ] 
    then
        log_progress_msg "Allow LAN communication - IP v6 - Network: $IP_LAN_V6"
        $IP6TABLES -A INPUT -s $IP_LAN_V6 -d $IP_LAN_V6 -j ACCEPT
        $IP6TABLES -A OUTPUT -s $IP_LAN_V6 -d $IP_LAN_V6 -j ACCEPT
    fi

    
    log_progress_msg "Enable common protocols: DHCP, DNS, FTP (passive/active)"
    ## DHCP client >> Broadcast IP request 
    $IPTABLES -A OUTPUT -p udp -d 255.255.255.255 --sport 68 --dport 67 -j ACCEPT
    $IPTABLES -A INPUT -p udp -s 255.255.255.255 --sport 67 --dport 68 -j ACCEPT
    $IPTABLES -A OUTPUT -p udp --dport 67 -j ACCEPT 
    $IPTABLES -A OUTPUT -p udp --dport 68 -j ACCEPT 
     
    # DNS (udp)
    $IPTABLES -A OUTPUT -p udp --sport 53 -j ACCEPT
    $IPTABLES -A OUTPUT -p udp --dport 53 -j ACCEPT
    $IPTABLES -A INPUT -p udp --sport 53 -j ACCEPT
    $IPTABLES -A INPUT -p udp --dport 53 -j ACCEPT
    $IP6TABLES -A OUTPUT -p udp --dport 53 -j ACCEPT
    $IP6TABLES -A OUTPUT -p udp --sport 53 -j ACCEPT
    $IP6TABLES -A INPUT -p udp --dport 53 -j ACCEPT
    $IP6TABLES -A INPUT -p udp --sport 53 -j ACCEPT
    # DNS sec (tcp)
    $IPTABLES -A OUTPUT -p tcp --sport 53 -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 53 -j ACCEPT
    $IP6TABLES -A OUTPUT -p tcp --dport 53 -j ACCEPT
    $IP6TABLES -A OUTPUT -p tcp --sport 53 -j ACCEPT
    
    # FTP requests  
    # FTP data transfer
    $IPTABLES -A OUTPUT -p tcp --dport 20 -j ACCEPT
    $IP6TABLES -A OUTPUT -p tcp --dport 20 -j ACCEPT  
    # FTP control (command)
    $IPTABLES -A OUTPUT -p tcp --dport 21 -j ACCEPT
    $IP6TABLES -A OUTPUT -p tcp --dport 21 -j ACCEPT  
}




# Security rules
# Networking protocols enforcement
function protocolEnforcement {
    log_progress_msg " Security protection"
    # ICMP packets should not be fragmented
    $IPTABLES -A INPUT --fragment -p icmp -j DROP    
    # Limit ICMP Flood
    $IPTABLES -A INPUT -p icmp -m limit --limit 1/s --limit-burst 1 -j ACCEPT
    #$IPTABLES -A OUTPUT -p icmp -m limit --limit 1/s --limit-burst 1 -j ACCEPT
    $IPTABLES -A OUTPUT -p icmp --icmp-type 0 -j ACCEPT
    $IPTABLES -A OUTPUT -p icmp --icmp-type 3 -j ACCEPT
    $IPTABLES -A OUTPUT -p icmp --icmp-type 8 -j ACCEPT    
    # Avoid common attacks ... but blocks ping
    #$IPTABLES -A OUTPUT -p icmp --icmp-type 3 -j DROP

    
    log_progress_msg " ... Layer 2: ICMP v6 "
    # Feedback for problems
    $IP6TABLES -A INPUT -p icmpv6 --icmpv6-type 1 -j ACCEPT
    $IP6TABLES -A INPUT -p icmpv6 --icmpv6-type 2 -j ACCEPT
    $IP6TABLES -A INPUT -p icmpv6 --icmpv6-type 3 -j ACCEPT
    $IP6TABLES -A INPUT -p icmpv6 --icmpv6-type 4 -j ACCEPT
    
    # Router and neighbor discovery 
    $IP6TABLES -A INPUT -p icmpv6 --icmpv6-type 133 -j ACCEPT
    $IP6TABLES -A INPUT -p icmpv6 --icmpv6-type 134 -j ACCEPT
    $IP6TABLES -A INPUT -p icmpv6 --icmpv6-type 135 -j ACCEPT
    $IP6TABLES -A INPUT -p icmpv6 --icmpv6-type 136 -j ACCEPT
    
    $IP6TABLES -A OUTPUT -p icmpv6 --icmpv6-type 133 -j ACCEPT
    $IP6TABLES -A OUTPUT -p icmpv6 --icmpv6-type 134 -j ACCEPT
    $IP6TABLES -A OUTPUT -p icmpv6 --icmpv6-type 135 -j ACCEPT
    $IP6TABLES -A OUTPUT -p icmpv6 --icmpv6-type 136 -j ACCEPT
    
    # Ping requests
    $IP6TABLES -A INPUT -p icmpv6 --icmpv6-type 128 -j ACCEPT
    $IP6TABLES -A OUTPUT -p icmpv6 --icmpv6-type 128 -j ACCEPT
    
    
    log_progress_msg " ... Layer 4: TCP # check packets conformity"
    # INCOMING packets check
    # All new incoming TCP should be SYN first
    $IPTABLES -A INPUT -p tcp ! --syn -m state --state NEW -j DROP
    # Avoid SYN Flood (max 3 SYN packets / second. Then Drop all requests !!)
    $IPTABLES -A INPUT -p tcp --syn -m limit --limit 1/s --limit-burst 3 -j ACCEPT
    # Avoid fragment packets
    $IPTABLES -A INPUT -f -j DROP
    # Check TCP flags -- flag 64, 128 = bogues
    $IPTABLES -A INPUT -p tcp --tcp-option 64 -j DROP
    $IPTABLES -A INPUT -p tcp --tcp-option 128 -j DROP


    log_progress_msg " ... Layer 4: TCP # Avoid NMAP Scans"
    # XMAS-NULL
    $IPTABLES -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
    # XMAS-TREE
    $IPTABLES -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
    # SYN/RST Scan
    $IPTABLES -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
    # SYN/FIN Scan
    $IPTABLES -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP
    # SYN/ACK Scan
    #$IPTABLES -A INPUT -p tcp --tcp-flags ALL ACK -j DROP
    $IPTABLES -A INPUT -p tcp --tcp-flags SYN,ACK SYN,ACK -j DROP
    # FIN/RST Scan
    $IPTABLES -A INPUT -p tcp --tcp-flags FIN,RST FIN,RST -j DROP
    # FIN/ACK Scan
    $IPTABLES -A INPUT -p tcp -m tcp --tcp-flags FIN,ACK FIN -j DROP
    # ACK/URG Scan
    $IPTABLES -A INPUT -p tcp --tcp-flags ACK,URG URG -j DROP
    # FIN/URG/PSH Scan
    $IPTABLES -A INPUT -p tcp --tcp-flags FIN,URG,PSH FIN,URG,PSH -j DROP
    # Stealth XMAS Scan
    $IPTABLES -A INPUT -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP
    # XMAS-PSH Scan
    $IPTABLES -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP
    # End TCP connection
    $IPTABLES -A INPUT -p tcp --tcp-flags ALL FIN -j DROP
    # Ports scans
    $IPTABLES -A INPUT -p tcp --tcp-flags FIN,SYN,RST,ACK SYN -j DROP
    $IPTABLES -A INPUT -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP
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
    $IPTABLES -A INPUT -p tcp -m limit --limit 3/min --limit-burst 3 --dport 22 -j ACCEPT 
    $IP6TABLES -A INPUT -p tcp -m limit --limit 3/min --limit-burst 3 --dport 22 -j ACCEPT

    # Remote desktop 
    #$IPTABLES -A INPUT -p tcp --dport 4000 -j ACCEPT        # NoMachine LAN server
    #$IPTABLES -A INPUT -p tcp --dport 4080 -j ACCEPT        # NoMachine HTTP server
    #$IPTABLES -A INPUT -p tcp --dport 4443 -j ACCEPT        # NoMachine HTTPS server
    #$IPTABLES -A INPUT -p udp --dport 4011:4999 -j ACCEPT   # NoMachine UDP real-time feed
    
    #################
    # WEB
    #################
    # HTTP, HTTPS  
    #$IPTABLES -A INPUT -p tcp --dport 80 -j ACCEPT      # Access restrictions managed by Apache2 VHost
    #$IPTABLES -A INPUT -p tcp --dport 443 -j ACCEPT     # Access restrictions managed by Apache2 VHost

    # Web server (HTTP alt)
    #$IPTABLES -A INPUT -p tcp --dport 8080 -j ACCEPT
    #$IPTABLES -A INPUT -p tcp --dport 8443 -j ACCEPT

    # JEE server      
    #$IPTABLES -A INPUT -p tcp --dport 4848 -j ACCEPT   # Glassfish admin
    #$IPTABLES -A INPUT -p tcp --dport 1527 -j ACCEPT   # Glassfish4 security manager
    #echo -e " ... Opening Jboss Wildfly"   
    #$IPTABLES -A INPUT -p tcp --dport 9990 -j ACCEPT   # Jboss Widlfy admin

    # Software quality
    #$IPTABLES -A INPUT -p tcp --dport 9000 -j ACCEPT    # Sonar
    #soureIpFiltering 9000

    #################
    # Database
    #################
    # MySQL db
    #$IPTABLES -A INPUT -p tcp --dport 3306 -j ACCEPT
    #soureIpFiltering 3306

    #################
    # IT
    #################
    # File-share
    #$IPTABLES -A INPUT -p udp --dport 137 -j ACCEPT    # Access restrictions managed by Samba
    #$IPTABLES -A INPUT -p udp --dport 138 -j ACCEPT
    #$IPTABLES -A INPUT -p tcp --dport 139 -j ACCEPT
    #$IPTABLES -A INPUT -p tcp --dport 445 -j ACCEPT

    # LDAP
    #$IPTABLES -A INPUT -p tcp -m state --state NEW --dport 389 -j ACCEPT # LDAP
    #$IPTABLES -A INPUT -p tcp -m state --state NEW --dport 636 -j ACCEPT # LDAPS

    # IT tools
    #$IPTABLES -A INPUT -p tcp --dport 10000 -j ACCEPT  # Webmin services
    #$IPTABLES -A INPUT -p tcp --dport 20000 -j ACCEPT  # Webmin users management

    #$IPTABLES -A INPUT -p tcp --dport 10051 -j ACCEPT  # Zabbix server

    # ElasticSearch, Logstash, Kibana
    #$IPTABLES -A INPUT -p tcp --dport 9200 -j ACCEPT   # HTTP
    #$IPTABLES -A INPUT -p tcp --dport 9300 -j ACCEPT   # Transport
    #$IPTABLES -A INPUT -p tcp --dport 54328 -j ACCEPT  # Multicasting
    #$IPTABLES -A INPUT -p udp --dport 54328 -j ACCEPT  # Multicasting

    #################
    # Java
    #################
    #$IPTABLES -A INPUT -p tcp --dport 1099 -j ACCEPT   # JMX

    #################
    # Messaging
    #################
    # Open MQ (bundled with Glassfish)
    #$IPTABLES -A INPUT -p tcp --dport 7676 -j ACCEPT    # JMS broker
    
    # ActiveMQ server
    #$IPTABLES -A INPUT -p tcp --dport 8161 -j ACCEPT    # HTTP console
    #$IPTABLES -A INPUT -p tcp --dport 8162 -j ACCEPT    # HTTPS console
    #$IPTABLES -A INPUT -p tcp --dport 11099 -j ACCEPT   # JMX management
    #$IPTABLES -A INPUT -p tcp --dport 61616 -j ACCEPT   # JMS queues

    # Rabbit MQ
    #$IPTABLES -A INPUT -p tcp --dport 15672 -j ACCEPT   # HTTP console
    #$IPTABLES -A INPUT -p tcp --dport 5672 -j ACCEPT    # AMPQ protocol
       
    ## TODO example of IP @ filtering       
    #soureIpFiltering 8088    

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
    $IPTABLES -A OUTPUT -p tcp --dport 22 -j ACCEPT     # SSH (default port)
    $IPTABLES -A OUTPUT -p tcp --dport 23 -j ACCEPT     # Telnet
    # Web
    $IPTABLES -A OUTPUT -p tcp --dport 80 -j ACCEPT     # HTTP
    $IPTABLES -A OUTPUT -p tcp --dport 443 -j ACCEPT    # HTTPS
    $IPTABLES -A OUTPUT -p tcp --dport 8080 -j ACCEPT   # TomCat (Java Web Server)
    # Core Linux services
    $IPTABLES -A OUTPUT -p udp --dport 123 -j ACCEPT    # Time NTP UDP
    $IPTABLES -A OUTPUT -p tcp --dport 135 -j ACCEPT    # Remote Procedure Call

    ##############
    # Remote control
    ##############
    $IPTABLES -A OUTPUT -p tcp --dport 3389 -j ACCEPT          # Windows Remote Desktop (terminal Server)
    $IPTABLES -A OUTPUT -p tcp --dport 5900 -j ACCEPT          # VNC and Apple Remote Desktop

    $IPTABLES -A OUTPUT -p tcp --dport 4000 -j ACCEPT          # NoMachine LAN access
    $IPTABLES -A OUTPUT -p tcp --dport 4080 -j ACCEPT          # NoMachine HTTP access
    $IPTABLES -A OUTPUT -p tcp --dport 4443 -j ACCEPT          # NoMachine HTTPS access
    $IPTABLES -A OUTPUT -p udp --dport 4011:4999 -j ACCEPT     # NoMachine UDP transmission

    ##############
    # VMware products
    ##############
    $IPTABLES -A OUTPUT -p tcp --dport 9443 -j ACCEPT   # VMware vsphere web client 
                                                        # https://myServer:9443/vsphere-client
    
    ##############
    # Communication
    ##############
    # Email
    $IPTABLES -A OUTPUT -p tcp --dport 25 -j ACCEPT     # SMTP
    $IPTABLES -A OUTPUT -p tcp --dport 110 -j ACCEPT    # POP3
    $IPTABLES -A OUTPUT -p tcp --dport 143 -j ACCEPT    # IMAP
    $IPTABLES -A OUTPUT -p tcp --dport 993 -j ACCEPT    # IMAP over SSL
    $IPTABLES -A OUTPUT -p tcp --dport 995 -j ACCEPT    # POP over SSL
    $IPTABLES -A OUTPUT -p tcp --dport 587 -j ACCEPT    # SMTP SSL (gmail)
    $IPTABLES -A OUTPUT -p tcp --dport 465 -j ACCEPT    # SMTP SSL (gmail)
    
    $IPTABLES -A OUTPUT -p tcp --dport 1863 -j ACCEPT   # MSN
    $IPTABLES -A OUTPUT -p tcp --dport 5060 -j ACCEPT   # SIP -VoIP-
    $IPTABLES -A OUTPUT -p udp --dport 5060 -j ACCEPT   # SIP -VoIP-
    $IPTABLES -A OUTPUT -p tcp --dport 5061 -j ACCEPT   # MS Lync
    $IPTABLES -A OUTPUT -p tcp --dport 5222 -j ACCEPT   # Google talk

    ##############
    # I.T
    ##############
    # Domain
    $IPTABLES -A OUTPUT -p tcp --dport 113 -j ACCEPT    # Kerberos
    $IPTABLES -A OUTPUT -p tcp --dport 389 -j ACCEPT    # LDAP 
    $IPTABLES -A OUTPUT -p tcp --dport 636 -j ACCEPT    # LDAP over SSL 
    # Network Services
    $IPTABLES -A OUTPUT -p tcp --dport 43 -j ACCEPT     # WhoIs
    $IPTABLES -A OUTPUT -p tcp --dport 427 -j ACCEPT    # Service Location Protocol
    $IPTABLES -A OUTPUT -p udp --dport 1900 -j ACCEPT   # UPnP - Peripheriques reseau
    # Webmin 
    $IPTABLES -A OUTPUT -p tcp --dport 10000 -j ACCEPT  # Services and configuration
    $IPTABLES -A OUTPUT -p tcp --dport 20000 -j ACCEPT  # Users management
    # Zabbix
    $IPTABLES -A OUTPUT -p tcp --dport 10051 -j ACCEPT
    # ELK (ElasticSearch, Logstash, Kibana)
    $IPTABLES -A OUTPUT -p tcp --dport 9200 -j ACCEPT   # HTTP
    $IPTABLES -A OUTPUT -p tcp --dport 9300 -j ACCEPT   # Transport
    $IPTABLES -A OUTPUT -p tcp --dport 54328 -j ACCEPT  # Multicasting
    $IPTABLES -A OUTPUT -p udp --dport 54328 -j ACCEPT  # Multicasting

    ##############
    # File share
    ##############
    $IPTABLES -A OUTPUT -p udp --dport 137 -j ACCEPT    # NetBios Name Service
    $IPTABLES -A OUTPUT -p udp --dport 138 -j ACCEPT    # NetBios Data Exchange
    $IPTABLES -A OUTPUT -p tcp --dport 139 -j ACCEPT    # NetBios Session + Samba
    $IPTABLES -A OUTPUT -p tcp --dport 445 -j ACCEPT    # CIFS - Partage Win2K and more

    ##############
    # Development
    ##############    
    # Java
    $IPTABLES -A OUTPUT -p tcp --dport 1099 -j ACCEPT   # JMX default port
    # Version control
    $IPTABLES -A OUTPUT -p tcp --dport 3690 -j ACCEPT   # SVN
    $IPTABLES -A OUTPUT -p tcp --dport 9418 -j ACCEPT   # GIT
    # Database 
    $IPTABLES -A OUTPUT -p tcp --dport 3306 -j ACCEPT   # MySQL
    $IPTABLES -A OUTPUT -p tcp --dport 1433 -j ACCEPT   # Microsoft SQL server
    $IPTABLES -A OUTPUT -p udp --dport 1433 -j ACCEPT   # Microsoft SQL server
    $IPTABLES -A OUTPUT -p tcp --dport 1434 -j ACCEPT   # Microsoft SQL server 2005
    $IPTABLES -A OUTPUT -p udp --dport 1434 -j ACCEPT   # Microsoft SQL server 2005
    # JEE server    
    $IPTABLES -A OUTPUT -p tcp --dport 4848 -j ACCEPT   # Glassfish admin
    $IPTABLES -A OUTPUT -p tcp --dport 1527 -j ACCEPT   # Glassfish4 security manager
    $IPTABLES -A OUTPUT -p tcp --dport 9990 -j ACCEPT   # Jboss Widlfy admin
    # Open MQ (bundled with Glassfish)
    $IPTABLES -A OUTPUT -p tcp --dport 7676 -j ACCEPT    # JMS broker
    # ActiveMQ server
    $IPTABLES -A OUTPUT -p tcp --dport 8161 -j ACCEPT    # HTTP console
    $IPTABLES -A OUTPUT -p tcp --dport 8162 -j ACCEPT    # HTTPS console
    $IPTABLES -A OUTPUT -p tcp --dport 11099 -j ACCEPT   # JMX management
    $IPTABLES -A OUTPUT -p tcp --dport 61616 -j ACCEPT   # JMS queues
    # Rabbit MQ
    $IPTABLES -A OUTPUT -p tcp --dport 15672 -j ACCEPT   # HTTP console
    $IPTABLES -A OUTPUT -p tcp --dport 5672 -j ACCEPT    # AMPQ protocol
    # Software quality
    $IPTABLES -A OUTPUT -p tcp --dport 9000 -j ACCEPT    # Sonar

    ################################
    # Blizzard Diablo 3
    ################################
    # Battle.net Desktop Application
    $IPTABLES -A OUTPUT -p tcp --dport 1119 -j ACCEPT
    $IPTABLES -A OUTPUT -p udp --dport 1119 -j ACCEPT
    # Blizzard Downloader
    $IPTABLES -A OUTPUT -p tcp --dport 1120 -j ACCEPT
    $IPTABLES -A OUTPUT -p udp --dport 1120 -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 3724 -j ACCEPT
    $IPTABLES -A OUTPUT -p udp --dport 3724 -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 4000 -j ACCEPT
    $IPTABLES -A OUTPUT -p udp --dport 4000 -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 6112:6114 -j ACCEPT
    $IPTABLES -A OUTPUT -p udp --dport 6112:6114 -j ACCEPT
    # Diablo 3
    $IPTABLES -A OUTPUT -p udp --dport 6115:6120 -j ACCEPT
    $IPTABLES -A OUTPUT -p tcp --dport 6115:6120 -j ACCEPT

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
        $IPTABLES -A INPUT -p $VPN_PROTOCOL --dport $VPN_PORT -j ACCEPT
        $IPTABLES -A OUTPUT -p $VPN_PROTOCOL --dport $VPN_PORT -j ACCEPT
        $IPTABLES -A OUTPUT -p $VPN_PROTOCOL --sport $VPN_PORT -j ACCEPT

        # Allow VPN packets type INPUT,OUTPUT,FORWARD
        $IPTABLES -A INPUT -i $INT_VPN -m state ! --state INVALID -j ACCEPT
        $IPTABLES -A OUTPUT -o $INT_VPN -m state ! --state INVALID -j ACCEPT
        $IPTABLES -A FORWARD -o $INT_VPN -m state ! --state INVALID -j ACCEPT

        # Allow forwarding
        if [ ! -z "$INT_ETH" ] ; then
            $IPTABLES -A FORWARD -i $INT_VPN -o $INT_ETH -j ACCEPT
            $IPTABLES -A FORWARD -i $INT_ETH -o $INT_VPN -j ACCEPT
        fi
        if [ ! -z "$INT_WLAN" ] ; then
            $IPTABLES -A FORWARD -i $INT_VPN -o $INT_WLAN -j ACCEPT
            $IPTABLES -A FORWARD -i $INT_WLAN -o $INT_VPN -j ACCEPT
        fi

        log_end_msg 0


        if [ ! -z "$IP_LAN_VPN_PRV" ]
        then
            log_daemon_msg "VPN to $IP_LAN_VPN_PRV"
            # Allow packets to be send from|to the VPN network
            $IPTABLES -A FORWARD -s $IP_LAN_VPN_PRV -j ACCEPT
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
            $IPTABLES -A FORWARD -s $IP_LAN_VPN_PRO -j ACCEPT
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
        #route add -net 192.168.12.0/24 gw 192.168.1.45
    fi
}



# ------------------------------------------------------------------------------
# LOGGING
# ------------------------------------------------------------------------------
function logDropped {
    log_daemon_msg "Firewall log dropped packets"
    $IPTABLES -N LOGGING
    $IPTABLES -A INPUT -j LOGGING
    $IPTABLES -A OUTPUT -j LOGGING
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
log_daemon_msg "Firewall init"
enableModules
defaultPolicy
protocolEnforcement
log_end_msg 0


###### Port filtering (input | output | forwarding)
incomingPortFiltering
outgoingPortFiltering
#forward

###### VPN
vpn

###### Log dropped packets
logDropped

echo " "
echo " "
