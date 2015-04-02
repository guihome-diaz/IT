#!/bin/bash
# FIREWALL stop script
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
#   version 1.2.1 - March 2011 
#                  >> Configuration for the extranet
#   version 1.3 - April 2015
#                  >> IPv6 support  
#                  >> Improving log using 'log_' functions

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


log_daemon_msg "Firewall stop (DROP input but SSH, ALLOW all output)"

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


# SSH
log_progress_msg "Enable SSH"
$IPTABLES -A INPUT -p tcp -m limit --limit 3/min --limit-burst 3 --dport 22 -j ACCEPT 
$IP6TABLES -A INPUT -p tcp -m limit --limit 3/min --limit-burst 3 --dport 22 -j ACCEPT

log_end_msg 0
