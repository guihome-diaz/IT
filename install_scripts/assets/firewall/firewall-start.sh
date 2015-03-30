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

RED="\\033[0;31m"
BLUE="\\033[0;36m"
GREEN="\\033[0;32m"
#BLACK="\\033[0;30m"
BLACK="\\033[0;37m"

# -------------------------------- #
#   LOCATION OF LINUX SOFTWARES    #
# -------------------------------- #
MODPROBE=`which modprobe`
IPTABLES=`which iptables`
IP6TABLES=`which ip6tables`

# --------------------- #
#   COMMON VARIABLES    #
# --------------------- #
# network configuration
INT_ETH=`ifconfig -a | sed -n 's/^\([^ ]\+\).*/\1/p' | grep -Fvx -e lo | grep -Fvx -e wlan0`
#INT_ETH="eth0"
IP_LAN_ETH_V4=`/sbin/ifconfig $INT_ETH | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`
IP_LAN_ETH_V6_LINK=`/sbin/ifconfig $INT_ETH | grep 'inet6 addr:' | grep 'Link' | awk '{print $3}'`
IP_LAN_ETH_V6_GLOBAL=`/sbin/ifconfig $INT_ETH | grep 'inet6 addr:' | grep 'Global' | awk '{print $3}'`


IP_LAN_V4="myLocalNetwork"
IP_LAN_V6=""
IP_LAN_VPN_PRV=""
IP_LAN_VPN_PRO=""

INT_VPN=tun0
VPN_PORT="8080"
VPN_PROTOCOL="udp"



function logDropped {
	echo " "
	echo " [!] Dropped packets will be logged"
	echo " "
	iptables -N LOGGING
	iptables -A INPUT -j LOGGING
	iptables -A OUTPUT -j LOGGING
	iptables -A LOGGING -m limit --limit 2/min -j LOG --log-prefix "iptables - dropped: " --log-level 4
	iptables -A LOGGING -j DROP
}


##### Source IP @ filter
# usage:   sourceIpFiltering <portNumber>
function soureIpFiltering() {
        SOURCE_PORT=$1
        echo "     ... Applying source IP @ filter on TCP $SOURCE_PORT"

        # LAN
        if [ ! -z "$IP_LAN_V4" ] 
		then
        	$IPTABLES -A INPUT -p tcp --dport $SOURCE_PORT -s $IP_LAN_V4 -j ACCEPT
		fi

        # VPN
        if [ ! -z "$IP_LAN_VPN_PRV" ] 
		then
        	$IPTABLES -A INPUT -p tcp --dport $SOURCE_PORT -s $IP_LAN_VPN_PRV -j ACCEPT
		fi
        if [ ! -z "$IP_LAN_VPN_PRO" ] 
		then
        	$IPTABLES -A INPUT -p tcp --dport $SOURCE_PORT -s $IP_LAN_VPN_PRO -j ACCEPT
		fi

        ##### Remote location(s)
        #$IPTABLES -A INPUT -p tcp --dport $SOURCE_PORT -s 5.39.81.23 -j ACCEPT

        # Drop all the rest
        $IPTABLES -A INPUT -p tcp --dport $SOURCE_PORT -s 0.0.0.0/0 -j DROP
}


##### Allow FORWARD to...
function forwardSources() {
        echo " "
        echo "Allow port forwarding for specific server(s)"
        echo "  => This will allow packets to be reach specific server(s)"
        echo " "

        # LAN
        if [ ! -z "$IP_LAN_V4" ] 
		then
       		$IPTABLES -A FORWARD -s $IP_LAN_V4 -j ACCEPT
		fi

        # VPN
        if [ ! -z "$IP_LAN_VPN_PRV" ] 
		then
        	$IPTABLES -A FORWARD -s $IP_LAN_VPN_PRV -j ACCEPT
		fi

        ##### Remote server(s)
        #$IPTABLES -A FORWARD -s 82.231.97.17 -j ACCEPT
}


##### setup TCP port forwarding
# usage:   forwardTcpPort <sourcePort> <targetServer> <targetPort>
function forwardTcpPort() {
        SOURCE_PORT=$1
        TARGET_SERVER=$2
        TARGET_PORT=$3
        echo "     ... forwarding TCP $SOURCE_PORT   to     $TARGET_SERVER:$TARGET_PORT"
        $IPT -A PREROUTING -t nat -p tcp --dport $SOURCE_PORT -j DNAT --to $TARGET_SERVER:$TARGET_PORT
}


# To enable networking modules in the current OS
function enableModules {
	echo -e " "		
	echo -e "-----------------------------"
	echo -e " Enable networking modules"
	echo -e "-----------------------------"
    
	# IPv4
	echo " ... IPv4"
	$MODPROBE ip_tables
	$MODPROBE iptable_filter
	$MODPROBE iptable_mangle
	# Allow to use state match
	$MODPROBE ip_conntrack

	# IPv6
	echo " ... IPv6"
	$MODPROBE ip6_tables
	$MODPROBE ip6table_filter
	$MODPROBE ip6table_mangle

	# Allow NAT
	echo " ... NAT"
	$MODPROBE iptable_nat
	
	# Allow active / passive FTP
	echo " ... FTP"
	$MODPROBE ip_conntrack_ftp
	$MODPROBE ip_nat_ftp

	# Allow log limits
	echo " ... burst limit"
	$MODPROBE ipt_limit


	echo -e " "		
	echo -e "------------------------"
	echo -e " Protocols enforcement"
	echo -e "------------------------"
	echo " ... Enable common Linux protections"
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

	## Check TCP window 
	echo 1 > /proc/sys/net/ipv4/tcp_window_scaling
	## Avoid DoS
	echo 30 > /proc/sys/net/ipv4/tcp_fin_timeout
	echo 1800 > /proc/sys/net/ipv4/tcp_keepalive_time
	## Adjust TTL value
	echo 64 > /proc/sys/net/ipv4/ip_default_ttl
	# Port forwarding in general
	echo " ... Enable forwarding"
	echo 1 > /proc/sys/net/ipv4/ip_forward
	echo 1 > /proc/sys/net/ipv6/conf/all/forwarding
}

# To flush old rules and setup the default policy
function defaultPolicy {
	echo -e " "		
	echo -e "------------------------"
	echo -e "$RED Flush existing rules $BLACK"
	echo -e "------------------------"

	$IP6TABLES -F
	
	$IPTABLES -t filter -F
	$IPTABLES -t filter -X
	
	# delete NAT rules
	$IPTABLES -t nat -F
	$IPTABLES -t nat -X

	# delete MANGLE rules (packets modifications)
	$IPTABLES -t mangle -F
	$IPTABLES -t mangle -X

	echo -e " "		
	echo -e "------------------------"
	echo -e " Default policy"
	echo -e "------------------------"
	echo -e "              || --> OUTGOING    $GREEN reject all $BLACK"
	#echo -e "              || --> OUTGOING    $RED accept all $BLACK"
	echo -e "          --> ||     INCOMING    $GREEN reject all $BLACK"
	echo -e "          --> || --> FORWARDING  $GREEN reject all$BLACK (each redirection needs manual configuration)"
	# INCOMING = avoid intrusions
	# OUTGOING = avoid disclosure of sensitive / private data
	$IPTABLES -P INPUT DROP
	$IPTABLES -P FORWARD DROP
	$IPTABLES -P OUTPUT DROP			
	
	$IP6TABLES -P INPUT DROP
	$IP6TABLES -P FORWARD DROP
	$IP6TABLES -P OUTPUT DROP

	echo -e " ... Reject invalid packets"
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
	$IP6TABLES -A INPUT -p icmp -m state --state INVALID -j DROP
	$IP6TABLES -A OUTPUT -p tcp -m state --state INVALID -j DROP
	$IP6TABLES -A OUTPUT -p udp -m state --state INVALID -j DROP
	$IP6TABLES -A OUTPUT -p icmp -m state --state INVALID -j DROP
	$IP6TABLES -A FORWARD -p tcp -m state --state INVALID -j DROP
	$IP6TABLES -A FORWARD -p udp -m state --state INVALID -j DROP

	echo " ... Avoid spoofing and local subnets"
	# Reserved addresses. We shouldn't received any packets from them!
	$IPTABLES -A INPUT -s 10.0.0.0/8 -j DROP
	$IPTABLES -A INPUT -s 169.254.0.0/16 -j DROP
	
	## Localhost
	echo -e " ... Allow localhost"
	# Allow localhost communication
	$IPTABLES -A INPUT -i lo -s 127.0.0.0/24 -d 127.0.0.0/24 -j ACCEPT
	$IPTABLES -A OUTPUT -o lo -s 127.0.0.0/24 -d 127.0.0.0/24 -j ACCEPT
	$IP6TABLES -A INPUT -i lo -j ACCEPT
	$IP6TABLES -A OUTPUT -o lo  -j ACCEPT
	
	# Only localhost on Loopback interface + no forward
	$IPTABLES -A INPUT ! -i lo -s 127.0.0.0/24 -j DROP	
	$IPTABLES -A FORWARD -s 127.0.0.0/24 -j DROP
	$IP6TABLES -A INPUT ! -i lo -s ::1/128 -j DROP
	$IP6TABLES -A FORWARD -s ::1/128 -j DROP
	
	## IPv6 security
	# No IPv4 -> IPv6 tunneling
	echo " ... Do not allow IPv4 @ tunnel in IPv6 !! Use native IPv6 instead !!"
	$IP6TABLES -A INPUT -s 2002::/16 -j DROP		# 6to4 tunnels
	$IP6TABLES -A FORWARD -s 2002::/16 -j DROP
	$IP6TABLES -A INPUT -s 2001:0::/32 -j DROP		# Teredo tunnels
	$IP6TABLES -A FORWARD -s 2001:0::/32 -j DROP
	
	# Block IPv6 protocol in IPv4 frames
	echo " ... Block IPv6 protocol in IPv4 frames"
	$IPTABLES -A INPUT -p 41 -j DROP
	$IPTABLES -A OUTPUT -p 41 -j DROP
	$IPTABLES -A FORWARD -p 41 -j DROP
	
	## Stateful connections
	echo -e " ... Keep$GREEN ESTABLISHED$BLACK connections "
	$IPTABLES -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
	$IPTABLES -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
	$IPTABLES -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
	
	$IP6TABLES -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
	$IP6TABLES -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
	$IP6TABLES -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT	


	## Allow LAN communication
	if [ ! -z "$IP_LAN_V4" ] 
	then
		echo -e " ... Allow LAN communication - IP v4 - Network: $IP_LAN_V4"
		$IPTABLES -A INPUT -s $IP_LAN_V4 -d $IP_LAN_V4 -j ACCEPT
		$IPTABLES -A OUTPUT -s $IP_LAN_V4 -d $IP_LAN_V4 -j ACCEPT
		# Allow forwarding within the LAN
		$IPTABLES -A FORWARD -s $IP_LAN_V4 -j ACCEPT
	fi
	if [ ! -z "$IP_LAN_V6" ] 
	then
		echo -e " ... Allow LAN communication - IP v6 - Network: $IP_LAN_V6"
		$IP6TABLES -A INPUT -s $IP_LAN_V6 -d $IP_LAN_V6 -j ACCEPT
		$IP6TABLES -A OUTPUT -s $IP_LAN_V6 -d $IP_LAN_V6 -j ACCEPT
		# Allow forwarding within the LAN
		$IPTABLES -A FORWARD -s $IP_LAN_V6 -j ACCEPT
	fi

	
	## DHCP client >> Broadcast IP request 
	echo -e " ... Broadcast and multicast rules for$GREEN DHCP$BLACK"	
	$IPTABLES -A OUTPUT -p udp -d 255.255.255.255 --sport 68 --dport 67 -j ACCEPT
	$IPTABLES -A INPUT -p udp -s 255.255.255.255 --sport 67 --dport 68 -j ACCEPT
	$IPTABLES -A OUTPUT -p udp --dport 67 -j ACCEPT 
	$IPTABLES -A OUTPUT -p udp --dport 68 -j ACCEPT 
	
	## DNS
	echo -e " ... Allow DNS requests"
	$IPTABLES -A OUTPUT -p udp --dport 53 -m limit --limit 100/s -j ACCEPT
	$IPTABLES -A OUTPUT -p udp --sport 53 -m limit --limit 100/s -j ACCEPT
	$IPTABLES -A INPUT -p udp --dport 53 -m limit --limit 100/s -j ACCEPT
	$IPTABLES -A INPUT -p udp --sport 53 -m limit --limit 100/s -j ACCEPT
	
	$IP6TABLES -A OUTPUT -p udp --dport 53 -m limit --limit 100/s -j ACCEPT
	$IP6TABLES -A OUTPUT -p udp --sport 53 -m limit --limit 100/s -j ACCEPT
	$IP6TABLES -A INPUT -p udp --dport 53 -m limit --limit 100/s -j ACCEPT
	$IP6TABLES -A INPUT -p udp --sport 53 -m limit --limit 100/s -j ACCEPT
	
	
	## FTP client - base rules
	echo -e " ... Allow FTP requests"
	$IPTABLES -A INPUT -p tcp --sport 21 -m state --state ESTABLISHED -j ACCEPT
	$IPTABLES -A OUTPUT -p tcp --dport 21 -m state --state NEW,ESTABLISHED -j ACCEPT 
	echo -e "      > FTP active mode"
	$IPTABLES -A INPUT -p tcp --sport 20 -m state --state ESTABLISHED,RELATED -j ACCEPT
	$IPTABLES -A OUTPUT -p tcp --dport 20 -m state --state ESTABLISHED -j ACCEPT 
	echo -e "      > FTP passive mode"
	$IPTABLES -A INPUT -p tcp --sport 1024: --dport 1024: -m state --state ESTABLISHED -j ACCEPT
	$IPTABLES -A OUTPUT -p tcp --sport 1024: --dport 1024: -m state --state ESTABLISHED,RELATED -j ACCEPT
}




# Security rules
# Networking protocols enforcement
function protocolEnforcement {
	echo -e " "		
	echo -e "------------------------"
	echo -e " Security protection"
	echo -e "------------------------"
	echo -e " ... Layer 2: ICMP v4  -- limitation to 1 packet / second"
	# ICMP packets should not be fragmented
	$IPTABLES -A INPUT --fragment -p icmp -j DROP
	
	# Limit ICMP Flood
	$IPTABLES -A INPUT -p icmp -m limit --limit 1/s --limit-burst 1 -j ACCEPT
	#$IPTABLES -A OUTPUT -p icmp -m limit --limit 1/s --limit-burst 1 -j ACCEPT
	$IPTABLES -A OUTPUT -p icmp --icmp-type 0 -j ACCEPT
	$IPTABLES -A OUTPUT -p icmp --icmp-type 3 -j ACCEPT
	$IPTABLES -A OUTPUT -p icmp --icmp-type 8 -j ACCEPT
	
	# Avoid common attacks ... but blocks ping :(
	# [Network, Host, Protocol, Port] unreacheable + [Destination Host, Destination network] prohibited
	#$IPTABLES -A OUTPUT -p icmp --icmp-type 3 -j DROP

	
	echo -e " ... Layer 2: ICMP v6 "
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
	
	
	echo " ... Layer 4: TCP # check packets conformity"
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

	echo " ... Layer 4: TCP # Avoid NMAP Scans"
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

# Firewall INCOMING rules
# -------------------------
# You have to allow:
#    * Local services (the ones that are running on this computer)
#    * All redirections ports
#
function incomingPortFiltering {

	### 
	# No source IP @ filtering since the server is not directly connected to Internet. 
	# source IP @ filter must be done to the session or application layers (OSI, levels 5 or 7)
	###

	echo -e " "		
	echo -e "------------------------"
	echo -e " INCOMING port filters"
	echo -e "------------------------"


	#################
	# Remote access
	#################
	# SSH
	echo -e " ... Opening SSH"	
	$IPTABLES -A INPUT -p tcp -m limit --limit 3/min --limit-burst 3 --dport 22 -j ACCEPT 
	$IP6TABLES -A INPUT -p tcp -m limit --limit 3/min --limit-burst 3 --dport 22 -j ACCEPT

	# Remote desktop 
	#echo -e " ... Opening NoMachine"
	#$IPTABLES -A INPUT -p tcp --dport 4000 -j ACCEPT	     # NoMachine LAN server
	#$IPTABLES -A INPUT -p tcp --dport 4080 -j ACCEPT	     # NoMachine HTTP server
	#$IPTABLES -A INPUT -p tcp --dport 4443 -j ACCEPT	     # NoMachine HTTPS server
	#$IPTABLES -A INPUT -p udp --dport 4011:4999 -j ACCEPT 	 # NoMachine UDP real-time feed
	

	#################
	# WEB
	#################
	# HTTP, HTTPS
	#echo -e " ... Opening HTTP"	
	#$IPTABLES -A INPUT -p tcp --dport 80 -j ACCEPT      # Access restrictions managed by Apache2 VHost
	#$IPTABLES -A INPUT -p tcp --dport 443 -j ACCEPT     # Access restrictions managed by Apache2 VHost

	# Web server (HTTP alt)
	#echo -e " ... Opening HTTP alt."	
	#$IPTABLES -A INPUT -p tcp --dport 8080 -j ACCEPT
	#$IPTABLES -A INPUT -p tcp --dport 8443 -j ACCEPT

	# JEE server	
	#echo -e " ... Opening Glassfish Application Server"	
	#$IPTABLES -A INPUT -p tcp --dport 4848 -j ACCEPT   # Glassfish admin
	#$IPTABLES -A INPUT -p tcp --dport 1527 -j ACCEPT   # Glassfish4 security manager
	#echo -e " ... Opening Jboss Wildfly"	
	#$IPTABLES -A INPUT -p tcp --dport 9990 -j ACCEPT   # Jboss Widlfy admin

	# Software quality
	#echo -e " ... Opening SonarQube"	
	#$IPTABLES -A INPUT -p tcp --dport 9000 -j ACCEPT    # Sonar


	#################
	# Database
	#################
	# MySQL db
	#echo -e " ... Opening MySQL database"
	#$IPTABLES -A INPUT -p tcp --dport 3306 -j ACCEPT


	#################
	# IT
	#################
	# File-share
	#echo -e " ... Opening Samba file-share"
	#$IPTABLES -A INPUT -p udp --dport 137 -j ACCEPT    # Access restrictions managed by Samba
	#$IPTABLES -A INPUT -p udp --dport 138 -j ACCEPT
	#$IPTABLES -A INPUT -p tcp --dport 139 -j ACCEPT
	#$IPTABLES -A INPUT -p tcp --dport 445 -j ACCEPT

	# LDAP
	#echo -e " ... Opening LDAP"
	#$IPTABLES -A INPUT -p tcp -m state --state NEW --dport 389 -j ACCEPT # LDAP
	#$IPTABLES -A INPUT -p tcp -m state --state NEW --dport 636 -j ACCEPT # LDAPS

	# IT tools
	#echo -e " ... Opening Webmin"
	#$IPTABLES -A INPUT -p tcp --dport 10000 -j ACCEPT	# Webmin services
	#$IPTABLES -A INPUT -p tcp --dport 20000 -j ACCEPT	# Webmin users management
	#echo -e " ... Opening Zabbix"
	#$IPTABLES -A INPUT -p tcp --dport 10051 -j ACCEPT	# Zabbix server

	#echo -e " ... Opening ELK (ElasticSearch, Logstash, Kibana)"
	#$IPTABLES -A INPUT -p tcp --dport 9200 -j ACCEPT	# HTTP
	#$IPTABLES -A INPUT -p tcp --dport 9300 -j ACCEPT	# Transport
	#$IPTABLES -A INPUT -p tcp --dport 54328 -j ACCEPT	# Multicasting
	#$IPTABLES -A INPUT -p udp --dport 54328 -j ACCEPT	# Multicasting

	#################
	# Java
	#################
	#echo -e " ... Opening Java JMX"
	#$IPTABLES -A INPUT -p tcp --dport 1099 -j ACCEPT   # JMX


	#################
	# Messaging
	#################
	# Open MQ (bundled with Glassfish)
	#$IPTABLES -A INPUT -p tcp --dport 7676 -j ACCEPT    # JMS broker
	
	# ActiveMQ server
	#echo -e " ... Opening ActiveMQ"
	#$IPTABLES -A INPUT -p tcp --dport 8161 -j ACCEPT    # HTTP console
	#$IPTABLES -A INPUT -p tcp --dport 8162 -j ACCEPT    # HTTPS console
	#$IPTABLES -A INPUT -p tcp --dport 11099 -j ACCEPT   # JMX management
	#$IPTABLES -A INPUT -p tcp --dport 61616 -j ACCEPT   # JMS queues

	# Rabbit MQ
	#echo -e " ... Opening RabbitMQ"
	#$IPTABLES -A INPUT -p tcp --dport 15672 -j ACCEPT 	 # HTTP console
	#$IPTABLES -A INPUT -p tcp --dport 5672 -j ACCEPT    # AMPQ protocol
	   
	## TODO enable IP @ filtering    	
	# IP @ filtering example -> for dev.vehco.com
	#$IPTABLES -A INPUT -p tcp --dport 8088 -s $IP_LAN_SWEDEN -j ACCEPT		# Sweden LAN
	#$IPTABLES -A INPUT -p tcp --dport 8088 -s 90.83.80.64/27 -j ACCEPT		# FR remote
	#$IPTABLES -A INPUT -p tcp --dport 8088 -s 90.83.80.123/27 -j ACCEPT		# FR remote
	#$IPTABLES -A INPUT -p tcp --dport 8088 -s 0.0.0.0/0 -j DROP			# DROP all the rest !

	
}


# Firewall OUTGOING rules
# -------------------------
# You have to allow:
#    * Local services (the ones that are running on this computer)
#    * All redirections ports
#
function outgoingPortFiltering {
	echo -e " "		
	echo -e "------------------------"
	echo -e " OUTGOING port filters"
	echo -e "------------------------"
	
	##############
	# Main ports
	##############
	
	echo -e " ... Mandatory ports "
	echo -e "       SSH, Telnet, HTTP(S), HTTP alt (8080), NTP, RPC"
	
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
	
	echo -e " ... Remote control"
	$IPTABLES -A OUTPUT -p tcp --dport 3389 -j ACCEPT   # Windows Remote Desktop (terminal Server)
	$IPTABLES -A OUTPUT -p tcp --dport 5900 -j ACCEPT   # VNC and Apple Remote Desktop

	$IPTABLES -A OUTPUT -p tcp --dport 4000 -j ACCEPT          # NoMachine LAN access
	$IPTABLES -A OUTPUT -p tcp --dport 4080 -j ACCEPT          # NoMachine HTTP access
	$IPTABLES -A OUTPUT -p tcp --dport 4443 -j ACCEPT          # NoMachine HTTPS access
	$IPTABLES -A OUTPUT -p udp --dport 4011:4999 -j ACCEPT     # NoMachine UDP transmission

	##############
	# VMware products
	##############
	
	echo -e " ... VMware"
	$IPTABLES -A OUTPUT -p tcp --dport 9443 -j ACCEPT   # VMware vsphere web client (https://myServer:9443/vsphere-client)
		
	
	##############
	# Communication
	##############
	
	echo -e " ... Communication"
		
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
	
	echo -e " ... I.T ports"
	echo -e "        LDAP, Printing, WhoIs, UPnP, Webmin, Zabbix, ELK ..."	
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
	$IPTABLES -A OUTPUT -p tcp --dport 54328 -j ACCEPT	# Multicasting
	$IPTABLES -A OUTPUT -p udp --dport 54328 -j ACCEPT	# Multicasting

	
	##############
	# File share
	##############
	
	echo -e " ... File share"
	$IPTABLES -A OUTPUT -p udp --dport 137 -j ACCEPT    # NetBios Name Service
	$IPTABLES -A OUTPUT -p udp --dport 138 -j ACCEPT    # NetBios Data Exchange
	$IPTABLES -A OUTPUT -p tcp --dport 139 -j ACCEPT    # NetBios Session + Samba
	$IPTABLES -A OUTPUT -p tcp --dport 445 -j ACCEPT    # CIFS - Partage Win2K and more

	

	##############
	# Development
	##############
	
	echo -e " ... Development ports"
	echo -e "        Java*, version control, DB*, *MQ"
	
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
	$IPTABLES -A OUTPUT -p tcp --dport 15672 -j ACCEPT 	 # HTTP console
	$IPTABLES -A OUTPUT -p tcp --dport 5672 -j ACCEPT    # AMPQ protocol

	# Software quality
	$IPTABLES -A OUTPUT -p tcp --dport 9000 -j ACCEPT    # Sonar

}

# VPN configuration
function vpn {		
if [[ ! -z "$IP_LAN_VPN_PRV" || ! -z "$IP_LAN_VPN_PRO" ]]
then
 
  echo " "		
  echo "------------------------"
  echo " VPN configuration"
  echo "------------------------"
  echo "    # VPN interface  : $INT_VPN"
  echo "    # VPN port       : $VPN_PORT"
  echo "    # VPN protocol   : $VPN_PROTOCOL"
  echo "    -------------------------------------- "
 
  echo "      ... Allow VPN connections through $INT_VPN"
  $IPTABLES -A INPUT -p $VPN_PROTOCOL --dport $VPN_PORT -j ACCEPT
  $IPTABLES -A OUTPUT -p $VPN_PROTOCOL --dport $VPN_PORT -j ACCEPT
  # Hint: if you do not accept all RELATED,ESTABLISHED connections then you must allow the source port
  $IPTABLES -A OUTPUT -p $VPN_PROTOCOL --sport $VPN_PORT -j ACCEPT
 
  echo "     ... Allow VPN packets type INPUT,OUTPUT,FORWARD"
  $IPTABLES -A INPUT -i $INT_VPN -m state ! --state INVALID -j ACCEPT
  $IPTABLES -A OUTPUT -o $INT_VPN -m state ! --state INVALID -j ACCEPT
  $IPTABLES -A FORWARD -o $INT_VPN -m state ! --state INVALID -j ACCEPT
 
  # Allow forwarding
  echo "      ... Allow packets to by forward from|to the VPN"
  $IPTABLES -A FORWARD -i $INT_VPN -o $INT_ETH -j ACCEPT
  $IPTABLES -A FORWARD -i $INT_ETH -o $INT_VPN -j ACCEPT
 
 
  echo "    -------------------------------------- "
  echo "      Open VPN LAN(s)"
  echo "    -------------------------------------- "
 
  if [ ! -z "$IP_LAN_VPN_PRV" ]
  then
      echo "      # VPN network IP @  : $IP_LAN_VPN_PRV"
 
      # Allow packets to be send from|to the VPN network
      $IPTABLES -A FORWARD -s $IP_LAN_VPN_PRV -j ACCEPT
      $IPTABLES -t nat -A POSTROUTING -s $IP_LAN_VPN_PRV -o $INT_ETH -j MASQUERADE
 
      # Allow VPN client <-> client communication
      $IPTABLES -A INPUT -s $IP_LAN_VPN_PRV -d $IP_LAN_VPN_PRV -m state ! --state INVALID -j ACCEPT
      $IPTABLES -A OUTPUT -s $IP_LAN_VPN_PRV -d $IP_LAN_VPN_PRV -m state ! --state INVALID -j ACCEPT
  fi
 
  if [ ! -z "$IP_LAN_VPN_PRO" ]
  then
      echo "      # VPN network IP @  : $IP_LAN_VPN_PRO"
      # Allow packets to be send from|to the VPN network
      $IPTABLES -A FORWARD -s $IP_LAN_VPN_PRO -j ACCEPT
      $IPTABLES -t nat -A POSTROUTING -s $IP_LAN_VPN_PRO -o $INT_ETH -j MASQUERADE
 
      # Allow VPN client <-> client communication
      $IPTABLES -A INPUT -s $IP_LAN_VPN_PRO -d $IP_LAN_VPN_PRO -m state ! --state INVALID -j ACCEPT
      $IPTABLES -A OUTPUT -s $IP_LAN_VPN_PRO -d $IP_LAN_VPN_PRO -m state ! --state INVALID -j ACCEPT
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


# Port forwarding setup
function forward {
	echo " "
	echo "---------------------------------"
	echo " Port forwarding configuration"
	echo "---------------------------------"
	
	### Allow forward to specific servers
	forwardSources

    ## Target ports
    LAMP_Server=192.168.1.50
    forwardTcpPort 10022 $LAMP_Server 22
    forwardTcpPort 10080 $LAMP_Server 80
    forwardTcpPort 13306 $LAMP_Server 3306
    forwardTcpPort 18080 $LAMP_Server 8080

	echo " "
}



# Note that the order in which rules are appended is very important. 
# For example, if your first rule is to deny everything... then no matter what you specifically, it will be denied. 

echo " "
echo " "
echo " "
echo -e "$BLUE # --------------------- # $BLACK"
echo -e "$BLUE #    FW START script    # $BLACK"
echo -e "$BLUE # --------------------- # $BLACK"
echo " "
echo " "
echo -e "# Network interface      : $INT_ETH"
echo -e "#    IP @ v4             : $IP_LAN_ETH_V4"
echo -e "#    IP @ v6 link-local  : $IP_LAN_ETH_V6_LINK"
echo -e "#    IP @ v6 global      : $IP_LAN_ETH_V6_GLOBAL"
echo -e " "		

# Required stuff
#--------------------
enableModules
defaultPolicy
protocolEnforcement

# Port filtering (input | output)
#--------------------
incomingPortFiltering
outgoingPortFiltering

#VPN
#--------------------
vpn


# Forwarding
#------------------
#forward

# Log dropped packets
#---------------------
logDropped

echo " " 
echo " firewall started !"
echo " "
echo " "

