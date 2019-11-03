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
#   version 1.6 - April 2015
#                  >> Simple version for ELO
#####
# Authors: Guillaume Diaz (all versions) + Julien Rialland (contributor to v1.4 & 1.6)
#


# -------------------------------- #
#   LOCATION OF LINUX SOFTWARES    #
# -------------------------------- #
MODPROBE=`which modprobe`
IPTABLES=`which iptables`
IP6TABLES=`which ip6tables`

# --------------------- #
#   COMMON VARIABLES    #ip6tnl0
# --------------------- #
# network configuration (only taking ETH... into account)
INT_ETH="eth0"
IP_LAN_ETH_V4=`/sbin/ifconfig $INT_ETH | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`
IP_LAN_ETH_V6=`/sbin/ifconfig $INT_ETH | grep 'inet6 addr:' | cut -d: -f2- | awk '{ print $1 }'`



function logDropped {
	echo " "
	echo "---------------------------------"
	echo " Dropped packets will be logged"
	echo "---------------------------------"

	$IPTABLES -N LOGGING
	$IPTABLES -A INPUT -j LOGGING
	#$IPTABLES -A OUTPUT -j LOGGING
	$IPTABLES -A LOGGING -m limit --limit 2/min -j LOG --log-prefix "iptables - dropped: " --log-level 4
	$IPTABLES -A LOGGING -j DROP
}


# To enable networking modules in the current OS
function enableModules {
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
}

# To flush old rules and setup the default policy
function defaultPolicy {
	echo -e " "		
	echo -e "------------------------"
	echo -e " Flush existing rules "
	echo -e "------------------------"

	$IP6TABLES -F	
	$IP6TABLES -X
	$IPTABLES -F
	$IPTABLES -X

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

	echo -e " "		
	echo -e "------------------------"
	echo -e " Default policy"
	echo -e "------------------------"
	echo -e "              || --> OUTGOING    reject all"
	echo -e "          --> ||     INCOMING    reject all"
	echo -e "          --> || --> FORWARDING  reject all"
	$IPTABLES -P INPUT DROP
	$IP6TABLES -P INPUT DROP
	$IPTABLES -P FORWARD DROP
	$IP6TABLES -P FORWARD DROP
	$IPTABLES -P OUTPUT DROP
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
	$IPTABLES -A INPUT -s 10.0.0.0/8 -j DROP
	$IPTABLES -A INPUT -s 169.254.0.0/16 -j DROP
	$IPTABLES -A INPUT -s 172.16.0.0/16 -j DROP
	
	echo -e " ... Allow localhost"
    $IPTABLES -A INPUT ! -i lo -s 127.0.0.0/24 -j DROP	
	$IPTABLES -A OUTPUT ! -o lo -d 127.0.0.0/24 -j DROP
    $IPTABLES -A FORWARD -s 127.0.0.0/24 -j DROP

    $IP6TABLES -A INPUT ! -i lo -s ::1/128 -j DROP
    $IP6TABLES -A OUTPUT ! -o lo -d ::1/128 -j DROP
    $IP6TABLES -A FORWARD -s ::1/128 -j DROP

	echo " ... Block IPv6 protocol in IPv4 frames"
	$IPTABLES -A INPUT -p 41 -j DROP
	$IPTABLES -A OUTPUT -p 41 -j DROP
	$IPTABLES -A FORWARD -p 41 -j DROP
	
	echo -e " ... Keep ESTABLISHED and RELATED connections "
	$IPTABLES -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
	$IPTABLES -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
	$IPTABLES -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

	$IP6TABLES -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
	$IP6TABLES -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
	$IP6TABLES -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
	
	## No DHCP ==> Static IP!

	## DNS
	echo -e " ... Allow DNS requests"
	$IPTABLES -A OUTPUT -p udp --dport 53 -j ACCEPT
	$IPTABLES -A INPUT -p udp --dport 53 -j ACCEPT
	$IPTABLES -A OUTPUT -p tcp --dport 53 -j ACCEPT
	$IPTABLES -A INPUT -p tcp --dport 53 -j ACCEPT
	
	$IP6TABLES -A OUTPUT -p udp --dport 53 -j ACCEPT
	$IP6TABLES -A INPUT -p udp --dport 53 -j ACCEPT
	$IP6TABLES -A OUTPUT -p tcp --dport 53 -j ACCEPT
	$IP6TABLES -A INPUT -p tcp --dport 53 -j ACCEPT
}




# Security rules
# Networking protocols enforcement
function protocolEnforcement {
	echo -e " "		
	echo -e "------------------------"
	echo -e " Security protection"
	echo -e "------------------------"
	echo -e " ... Layer 2: ICMP v4  -- no fragment and avoid ICMP flood"
	# ICMP packets should not be fragmented
	$IPTABLES -A INPUT --fragment -p icmp -j DROP
	$IPTABLES -A INPUT -p icmp -m limit --limit 1/s --limit-burst 1 -j ACCEPT

	$IPTABLES -A OUTPUT -p icmp --icmp-type 0 -j ACCEPT
	$IPTABLES -A OUTPUT -p icmp --icmp-type 3 -j ACCEPT
	$IPTABLES -A OUTPUT -p icmp --icmp-type 8 -j ACCEPT
		
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

function soureIpFiltering() {
	SOURCE_PORT=$1
	echo "     ... Applying source IP @ filter on TCP $SOURCE_PORT"
	
	# Swedish remote IP @
	$IPTABLES -A INPUT -p tcp --dport $SOURCE_PORT -s 193.12.118.194 -j ACCEPT        # codriver.veho.com
	$IPTABLES -A INPUT -p tcp --dport $SOURCE_PORT -s 193.12.118.195 -j ACCEPT        # smartcards.veho.com
	$IPTABLES -A INPUT -p tcp --dport $SOURCE_PORT -s 193.12.118.196 -j ACCEPT        # code.vehco.com
	$IPTABLES -A INPUT -p tcp --dport $SOURCE_PORT -s 192.168.1.0/24 -j ACCEPT        # Swedish LAN
	$IPTABLES -A INPUT -p tcp --dport $SOURCE_PORT -s 192.168.12.0/24 -j ACCEPT       # Swedish VPN
	
	# French office
	$IPTABLES -A INPUT -p tcp --dport $SOURCE_PORT -s 90.83.80.91 -j ACCEPT
	$IPTABLES -A INPUT -p tcp --dport $SOURCE_PORT -s 195.101.122.32/27 -j ACCEPT
	$IPTABLES -A INPUT -p tcp --dport $SOURCE_PORT -s 195.101.122.64/27 -j ACCEPT
	
	# Danish office
	$IPTABLES -A INPUT -p tcp --dport $SOURCE_PORT -s 94.189.38.254/24 -j ACCEPT      #### December 2014 IP

	# Drop all the rest
	$IPTABLES -A INPUT -p tcp --dport $SOURCE_PORT -s 0.0.0.0/0 -j DROP
}


# Firewall INCOMING rules
# -------------------------
# You have to allow:
#    * Local services (the ones that are running on this computer)
#    * All redirections ports
#
function incomingPortFiltering {

	echo -e " "		
	echo -e "------------------------"
	echo -e " INCOMING port filters"
	echo -e "------------------------"

	# SSH
	echo -e " ... Opening SSH"	
	$IPTABLES -A INPUT -p tcp -m limit --limit 3/min --limit-burst 3 --dport 22 -j ACCEPT 
	$IP6TABLES -A INPUT -p tcp -m limit --limit 3/min --limit-burst 3 --dport 22 -j ACCEPT 

	# HTTP, HTTPS
	echo -e " ... Opening HTTP"	
	$IPTABLES -A INPUT -p tcp --dport 80 -j ACCEPT
	$IP6TABLES -A INPUT -p tcp --dport 80 -j ACCEPT
	$IPTABLES -A INPUT -p tcp --dport 443 -j ACCEPT
	$IP6TABLES -A INPUT -p tcp --dport 443 -j ACCEPT

	# MySQL db
	echo -e " ... Opening MySQL database (IP @ filtering)"
	soureIpFiltering 3306


	# Web server (HTTP alt)
	# ------------------------- 
	# Tomcat is NOT reachable directly! You must go through the Apache2 proxy!
	#$IPTABLES -A INPUT -p tcp --dport 8080 -j ACCEPT

	# Rabbit MQ
	# ------------------------- 
	# This server should use the Swedish RabbitMQ server
	#$IPTABLES -A INPUT -p tcp --dport 15672 -j ACCEPT 	 # HTTP console
	#$IPTABLES -A INPUT -p tcp --dport 5672 -j ACCEPT    # AMPQ protocol
	

	#################
	# VEHCO
	#################
	echo -e " ... VEHCO RTD ELO"
	$IPTABLES -A INPUT -p udp --dport 7789 -j ACCEPT	# ELO OBC tracking (legacy)
	$IPTABLES -A INPUT -p udp --dport 7792 -j ACCEPT	# ELO OBC tracking
	$IPTABLES -A INPUT -p udp --dport 7795 -j ACCEPT	# ELO RTD OBC authentication
	$IPTABLES -A INPUT -p tcp --dport 7796 -j ACCEPT	# ELO smartcards server <> RTD server
	$IPTABLES -A INPUT -p udp --dport 7793 -j ACCEPT	# ELO RTD OBC dump
	
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
	$IPTABLES -A OUTPUT -p tcp --dport 22 -j ACCEPT     # SSH
	$IP6TABLES -A OUTPUT -p tcp --dport 22 -j ACCEPT
	$IPTABLES -A OUTPUT -p tcp --dport 23 -j ACCEPT     # Telnet

	# Web
	$IPTABLES -A OUTPUT -p tcp --dport 80 -j ACCEPT     # HTTP
	$IPTABLES -A OUTPUT -p tcp --dport 443 -j ACCEPT    # HTTPS
	$IP6TABLES -A OUTPUT -p tcp --dport 443 -j ACCEPT
	$IPTABLES -A OUTPUT -p tcp --dport 8080 -j ACCEPT   # TomCat (Java Web Server)

	# Core Linux services
	$IPTABLES -A OUTPUT -p udp --dport 123 -j ACCEPT    # Time NTP UDP
	$IP6TABLES -A OUTPUT -p udp --dport 123 -j ACCEPT
	$IPTABLES -A OUTPUT -p tcp --dport 135 -j ACCEPT    # Remote Procedure Call

		
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
	

	##############
	# I.T
	##############
	
	echo -e " ... I.T ports"
	echo -e "        LDAP, Printing, WhoIs, UPnP, Webmin, Zabbix, ELK ..."	
	# Domain
	$IPTABLES -A OUTPUT -p tcp --dport 113 -j ACCEPT    # Kerberos
	$IPTABLES -A OUTPUT -p tcp --dport 389 -j ACCEPT    # LDAP 
	$IP6TABLES -A OUTPUT -p tcp --dport 389 -j ACCEPT    # LDAP 
	$IPTABLES -A OUTPUT -p tcp --dport 636 -j ACCEPT    # LDAP over SSL 
	$IP6TABLES -A OUTPUT -p tcp --dport 636 -j ACCEPT    # LDAP over SSL 
	
	# Network Services
	$IPTABLES -A OUTPUT -p tcp --dport 43 -j ACCEPT     # WhoIs
	$IPTABLES -A OUTPUT -p tcp --dport 427 -j ACCEPT    # Service Location Protocol

	##############
	# Development
	##############
	
	echo -e " ... Development ports"
	echo -e "        Java*, version control, DB*, *MQ"
	
	# Version control
	$IPTABLES -A OUTPUT -p tcp --dport 3690 -j ACCEPT   # SVN
	$IPTABLES -A OUTPUT -p tcp --dport 9418 -j ACCEPT   # GIT
			
	# ActiveMQ server
	$IPTABLES -A OUTPUT -p tcp --dport 61616 -j ACCEPT   # JMS queues

	# Rabbit MQ
	$IPTABLES -A OUTPUT -p tcp --dport 5672 -j ACCEPT    # AMPQ protocol


	#################
	# VEHCO
	#################
	#echo -e " ... VEHCO RTD ELO"
	#$IPTABLES -A OUTPUT -p udp --dport 7789 -j ACCEPT	# ELO OBC tracking (legacy)
	#$IPTABLES -A OUTPUT -p udp --dport 7792 -j ACCEPT	# ELO OBC tracking
	#$IPTABLES -A OUTPUT -p udp --dport 7795 -j ACCEPT	# ELO RTD OBC authentication
	#$IPTABLES -A OUTPUT -p tcp --dport 7796 -j ACCEPT	# ELO smartcards server <> RTD server
	#$IPTABLES -A OUTPUT -p udp --dport 7793 -j ACCEPT	# ELO RTD OBC dump
}



# Note that the order in which rules are appended is very important. 
# For example, if your first rule is to deny everything... then no matter what you specifically, it will be denied. 

echo " "
echo " "
echo " "
echo -e "# --------------------- #"
echo -e "#    FW START script    #"
echo -e "# --------------------- #"
echo " "
echo " "
echo -e "# Network interface      : $INT_ETH"
echo -e "#    IP @ v4             : $IP_LAN_ETH_V4"
echo -e "#    IP @ v6 link-local  : $IP_LAN_ETH_V6"
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

# Log dropped packets
#---------------------
logDropped


echo " " 
echo " firewall started !"
echo " "
echo " "

