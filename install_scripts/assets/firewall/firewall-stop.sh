#!/bin/bash
# Firewall -- Packet level filtering
#   --> IPTABLES Rules 
#   version 1.0 - Septembre 2008
#           1.1 - Novembre 2009 
#                  >> Network security (Chalmers) + english translation
#   version 1.2 - January 2010
#				   >> Add some protections against flooding
#   version 1.2.1 - March 2011 
#		   >> Configuration for the extranet
#
#   Guillaume Diaz

RED="\\033[0;31m"
BLUE="\\033[0;34m"
GREEN="\\033[0;32m"
#BLACK="\\033[0;30m"
BLACK="\\033[0;37m"

echo " "
echo " "
echo " "
echo -e "$RED # -------------------- # $BLACK"
echo -e "$RED #    FW STOP script    # $BLACK"
echo -e "$RED # -------------------- # $BLACK"
echo " "

# -------------------------------- #
#   LOCATION OF LINUX SOFTWARES    #
# -------------------------------- #
MODPROBE=`which modprobe`
IPTABLES=`which iptables`
IP6TABLES=`which ip6tables`

# ------------- #
#  Flush rules  #
# ------------- #
echo -e " ...$RED Flush existing rules $BLACK"
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

# ---------------- #
#  Default policy  #
# ---------------- #
# INCOMING = DROP = avoid intrusions
# OUTGOING = ACCEPT = risk of disclosure (sensitive / private data)
echo -e " ...Set default policy"
echo -e "              || --> OUTGOING    $GREEN accept all $BLACK"
echo -e "          --> ||     INCOMING    $GREEN accept only SSH $BLACK"
#echo -e "          --> ||     INCOMING   $RED accept all !! careful !! $BLACK"
echo -e "          --> || --> FORWARDING  $GREEN reject all $BLACK"
$IPTABLES -A INPUT -j ACCEPT
$IPTABLES -A FORWARD -j DROP
$IPTABLES -A OUTPUT -j ACCEPT

$IP6TABLES -A INPUT -j ACCEPT
$IP6TABLES -A FORWARD -j DROP
$IP6TABLES -A OUTPUT -j ACCEPT

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

echo -e "          keep ESTABLISHED,RELATED"
# Keep established connections
$IPTABLES -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPTABLES -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

$IP6TABLES -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
$IP6TABLES -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

## Localhost
echo -e " ... Allow localhost"
$IPTABLES -A INPUT ! -i lo -s 127.0.0.0/24 -j DROP	
$IPTABLES -A OUTPUT ! -o lo -d 127.0.0.0/24 -j DROP
$IPTABLES -A FORWARD -s 127.0.0.0/24 -j DROP

$IP6TABLES -A INPUT ! -i lo -s ::1/128 -j DROP
$IP6TABLES -A OUTPUT ! -o lo -d ::1/128 -j DROP
$IP6TABLES -A FORWARD -s ::1/128 -j DROP


# SSH
echo -e " ... Allow$GREEN SSH$BLACK access "
$IPTABLES -A INPUT -p tcp -m limit --limit 3/min --limit-burst 3 --dport 22 -j ACCEPT
$IP6TABLES -A INPUT -p tcp -m limit --limit 3/min --limit-burst 3 --dport 22 -j ACCEPT


echo -e " ... Broadcast and multicast rules for$GREEN DHCP$BLACK"
# DHCP client >> Broadcast IP request 
$IPTABLES -A OUTPUT -p udp -d 255.255.255.255 --sport 68 --dport 67 -j ACCEPT
# DHCP server >> send / reply to IPs requests
$IPTABLES -A INPUT -p udp -s 255.255.255.255 --sport 67 --dport 68 -j ACCEPT

echo "Firewall has been reset!"
echo " "
