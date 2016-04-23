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
#   version 1.8 - March 2016 
#                  >> Validation on Ubuntu 16.04
#####
# Authors: Guillaume Diaz (all versions) + Julien Rialland (contributor to v1.4)
#

#### Load other scripts
source /etc/firewall/firewall-lib.sh


# --------------------- #
#   COMMON VARIABLES    #
# --------------------- #
# Set to 0 to disable IPv4 and|or IPv6 firewall
export DO_IPV4="1"
export DO_IPV6="1"

##### Advanced settings
# Source IP filtering
declare -a sourcesIpAllowed=("5.39.81.23" "172.16.100.0/26")
declare -a sourcesIp6Allowed=("")



function firewallSetup {
    log_daemon_msg "Firewall initialization"
        # ----------------------------------------------------
        # Core features
        # ----------------------------------------------------
        clearPolicies
        setDefaultPolicies
        basicProtection
        protocolsEnforcement
        keepEstablishedRelatedConnections
        allowBaseCommunications
        blockIp4Ip6Tunnels


        # ----------------------------------------------------
        # IPv4
        # ----------------------------------------------------
        #filterNetworksIpv4
        allowIpv4LAN "172.16.100.0/26"


        # ----------------------------------------------------
        # IPv6
        # ----------------------------------------------------
        allowIpv6LAN "2a02:678:421:8400::0/64"
        blockRoutingHeaderIpv6

    log_end_msg 0
}



# ----------------------------------------------------
# Forwarding
# ----------------------------------------------------
function forwardConfiguration {
    log_daemon_msg "Forward rules"

        ### IPv4
        declare -a forwardIpAllowed=("5.39.81.23" "172.16.100.0/26")
        # Allow forward for specific sources
        for forwardIP in "${forwardIpAllowed[@]}"
        do
            allowForwardingFromIpv4 $forwardIP "$forwardIP"
        done
        # Forward rules
        DAXIONGMAO_SERVER=90.83.80.91
        forwardPortIpv4 8090 udp $DAXIONGMAO_SERVER 8080 "Tomcat dev. server"

    log_end_msg 0
}


# ------------------------------------------------------------------------------
# INCOMING rules
# ------------------------------------------------------------------------------
function incomingPortFiltering {
    log_daemon_msg "Firewall INPUT filtering"

    ### SSH
    inputFiltering tcp 22 "SSH" true

    ### Remote desktop 
    #inputFiltering tcp 4000 "NoMachine LAN server"
    #inputFiltering tcp 4080 "NoMachine HTTP server"
    #inputFiltering tcp 4443 "NoMachine HTTPS server"
    #inputFiltering udp 4011:4999 "NoMachine UDP data feed"
    
    ### HTTP, HTTPS  
    #inputFiltering tcp 80 "HTTP"
    #inputFiltering tcp 443 "HTTPS"

    ### Web server (HTTP alt)
    #inputFiltering tcp 8080 "HTTP alt."
    #inputFiltering tcp 8443 "HTTPS alt."

    ### JEE server      
    #inputFiltering tcp 4848 "Glassfish admin"
    #inputFiltering tcp 1527 "Glassfish security manager"
    #inputFiltering tcp 9990 "JBoss admin"

    ### Software quality
    #inputFiltering tcp 9000 "Sonarqube"
    #sourceIpFilteringIpv4 9000 tcp $sourcesIpAllowed

    #################
    # Database
    #################
    #inputFiltering tcp 3306 "MySQL"
    #inputFiltering tcp 5432 "PostgreSQL"
    #sourceIpFilteringIpv4 3306 tcp $$sourcesIpAllowed

    #################
    # IT
    #################
    # File-share
    inputFiltering tcp 135 "Samba - DCE endpoint resolution"
    inputFiltering tcp 137 "Samba - NetBIOS Name Service"
    inputFiltering tcp 138 "Samba - NetBIOS Datagram"
    inputFiltering tcp 139 "Samba - NetBIOS Session"
    inputFiltering tcp 445 "Samba - over TCP"

    #sourceIpFilteringIpv4 135 udp $$sourcesIpAllowed
    #sourceIpFilteringIpv4 137 udp $$sourcesIpAllowed
    #sourceIpFilteringIpv4 138 udp $$sourcesIpAllowed
    #sourceIpFilteringIpv4 139 tcp $$sourcesIpAllowed
    #sourceIpFilteringIpv4 445 tcp $$sourcesIpAllowed

    ### LDAP
    #inputFiltering tcp 389 "LDAP + LDAP startTLS"
    #inputFiltering tcp 636 "LDAPS"

    ### IT tools
    #inputFiltering tcp 10000 "Webmin services"
    #inputFiltering tcp 20000 "Webmin users"

    #inputFiltering tcp 10050 "Zabbix agent"
    #inputFiltering tcp 10051 "Zabbix server"
    #inputFiltering tcp 3030 "Dashboard (zabbix)"

    ### ElasticSearch, Logstash, Kibana
    #inputFiltering tcp 9200 "ElasticSearch HTTP"
    #inputFiltering tcp 9300 "ElasticSearch Transport"
    #inputFiltering tcp 54328 "ElasticSearch Multicasting"
    #inputFiltering tcp 54328 "ElasticSearch Multicasting"

    #################
    # Java
    #################
    #inputFiltering tcp 1099 "JMX"

    #################
    # Messaging
    #################
    ### Open MQ (bundled with Glassfish)
    #inputFiltering tcp 7676 "OpenMQ"
    
    ### ActiveMQ server
    #inputFiltering tcp 8161 "ActiveMQ HTTP console"
    #inputFiltering tcp 8162 "ActiveMQ HTTPS console"
    #inputFiltering tcp 11099 "ActiveMQ JMX"
    #inputFiltering tcp 61616 "ActiveMQ JMS Queues"

    ### Rabbit MQ
    #inputFiltering tcp 15672 "RabbitMQ HTTP console"
    #inputFiltering tcp 5672 "RabbitMQ data"

    ####################################
    # STEAM 
    ####################################
    #inputFiltering udp 4380 "Steam game client"
    #inputFiltering udp 27000:27015 "Steam game client traffic"
    #inputFiltering udp 27016:27030 "Steam game matchmaking and HLTV"
    #inputFiltering udp 27031:27036 "Steam in-home streaming"

    #inputFiltering tcp 27015 "Steam SRCDS Rcon port"
    #inputFiltering tcp 27036:27037 "Steam in-home streaming"

    #inputFiltering tcp 6000:6063 "X11 streaming"

    ##########################
    # Common input to reject
    ##########################
    ipt46 -A INPUT -p tcp --dport 631 -m comment --comment "Internet printing (IPP)" -j DROP
    ipt46 -A INPUT -p udp --sport 57621 --dport 57621 -m comment --comment "Spotify network scan" -j DROP
    ipt46 -A INPUT -p udp --sport 17500 --dport 17500 -m comment --comment "Dropbox network scan" -j DROP

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
    outputFiltering tcp 22 "SSH"
    outputFiltering tcp 23 "Telnet"
    # Web
    outputFiltering tcp 80 "HTTP"
    outputFiltering tcp 443 "HTTPS"
    outputFiltering tcp 8080 "HTTP alt."
    # Core Linux services
    outputFiltering tcp 135 "RPC (Remote Procedure Call)"

    ##############
    # Remote control
    ##############
    outputFiltering tcp 3389 "Microsoft RDP"
    outputFiltering tcp 5900 "VNC"

    outputFiltering tcp 4000 "NoMachine LAN"
    outputFiltering tcp 4080 "NoMachine HTTP"
    outputFiltering tcp 4443 "NoMachine HTTPS"
    outputFiltering udp 4011:4999 "NoMachine data feed"

    ##############
    # VMware products
    ##############
    # https://myServer:9443/vsphere-client
    outputFiltering tcp 9443 "VMware vsphere web client"
    
    ##############
    # Communication
    ##############
    # Email
    outputFiltering tcp 25 "SMTP"
    outputFiltering tcp 110 "POP3"
    outputFiltering tcp 143 "IMAP"
    outputFiltering tcp 993 "IMAP over SSL"
    outputFiltering tcp 995 "POP over SSL"
    outputFiltering tcp 587 "SMTP SSL (gmail)"
    outputFiltering tcp 465 "SMTP SSL (gmail)"
    
    outputFiltering tcp 1863 "MSN"
    outputFiltering tcp 5060 "SIP -VoIP-"
    outputFiltering udp 5060 "SIP -VoIP-"
    outputFiltering tcp 5061 "MS Lync"
    outputFiltering tcp 5222 "Google talk"

    ##############
    # I.T
    ##############
    # Domain
    outputFiltering tcp 113 "Kerberos"
    outputFiltering tcp 389 "LDAP"
    outputFiltering tcp 636 "LDAP over SSL"
    # Network Services
    outputFiltering tcp 43 "WhoIs"
    outputFiltering tcp 427 "Service Location Protocol"
    outputFiltering udp 1900 "UPnP - Peripheriques reseau"
    # Webmin 
    outputFiltering tcp 10000 "Services and configuration"
    outputFiltering tcp 20000 "Users management"
    # Zabbix
    outputFiltering tcp 10050 "Zabbix agent"
    outputFiltering tcp 10051 "Zabbix server"
    outputFiltering tcp 3030 "Dashboard (zabbix)"
    # ELK (ElasticSearch, Logstash, Kibana)
    outputFiltering tcp 9200 "ElasticSearch HTTP console"
    outputFiltering tcp 9300 "ElasticSearch Transport"
    outputFiltering tcp 54328 "ElasticSearch Multicasting"
    outputFiltering udp 54328 "ElasticSearch Multicasting"

    ##############
    # File share
    ##############
    outputFiltering udp 137 "NetBios Name Service"
    outputFiltering udp 138 "NetBios Data Exchange"
    outputFiltering tcp 139 "NetBios Session + Samba"
    outputFiltering tcp 445 "CIFS - Partage Win2K and more"
    outputFiltering tcp 548 "Apple file sharing"

    ##############
    # Development
    ##############    
    # Java
    outputFiltering tcp 1099 "JMX"
    # Version control
    outputFiltering tcp 3690 "SVN"
    outputFiltering tcp 9418 "GIT"
    # Database 
    outputFiltering tcp 3306 "MySQL"
    outputFiltering tcp 5432 "Postgresql"
    outputFiltering tcp 1433 "Microsoft SQL server"
    outputFiltering udp 1433 "Microsoft SQL server"
    outputFiltering tcp 1434 "Microsoft SQL server 2005"
    outputFiltering udp 1434 "Microsoft SQL server 2005"
    # JEE server    
    outputFiltering tcp 4848 "Glassfish admin"
    outputFiltering tcp 1527 "Glassfish4 security manager"
    outputFiltering tcp 9990 "Jboss admin"
    # Open MQ (bundled with Glassfish)
    outputFiltering tcp 7676 "OpenMQ"
    # ActiveMQ server
    outputFiltering tcp 8161 "ActiveMQ HTTP console"
    outputFiltering tcp 8162 "ActiveMQ HTTPS console"
    outputFiltering tcp 11099 "ActiveMQ JMX"
    outputFiltering tcp 61616 "ActiveMQ JMS queues"
    # Rabbit MQ
    outputFiltering tcp 15672 "RabbitMQ HTTP console"
    outputFiltering tcp 5672 "RabbitMQ data"
    # Software quality
    outputFiltering tcp 9000 "Sonarqube"
    # JetBrains Hub
    outputFiltering tcp 8081 "JetBrains hub"
  
    ################################
    # Communication
    ################################
    # Viber
    outputFiltering tcp 4244 "Viber"
    outputFiltering tcp 5242 "Viber"
    outputFiltering udp 5243 "Viber"
    outputFiltering udp 9785 "Viber"


    ####################################
    # STEAM 
    ####################################
    outputFiltering udp 4380 "Steam game client"
    outputFiltering udp 27000:27015 "Steam game client traffic"
    outputFiltering udp 27016:27030 "Steam game matchmaking and HLTV"
    outputFiltering udp 27031:27036 "Steam in-home streaming"

    outputFiltering tcp 27015 "Steam SRCDS Rcon port"
    outputFiltering tcp 27036:27037 "Steam in-home streaming"


    outputFiltering tcp 6000:6063 "X11 streaming"


    ################################
    # Blizzard Diablo 3
    ################################
    # Battle.net Desktop Application
    outputFiltering tcp 1119 "Battle.net Desktop Application" 
    outputFiltering udp 1119 "Battle.net Desktop Application"
    # Blizzard Downloader
    outputFiltering tcp 1120 "Blizzard Downloader"
    outputFiltering udp 1120 "Blizzard Downloader"
    outputFiltering tcp 3724 "Blizzard Downloader"
    outputFiltering udp 3724 "Blizzard Downloader"
    outputFiltering tcp 4000 "Blizzard Downloader"
    outputFiltering udp 4000 "Blizzard Downloader"
    outputFiltering tcp 6112:6114 "Blizzard Downloader"
    outputFiltering udp 6112:6114 "Blizzard Downloader"
    # Diablo 3
    outputFiltering udp 6115:6120 "Diablo 3"
    outputFiltering tcp 6115:6120 "Diablo 3"


    ##########################
    # Spotify
    ##########################
    outputFiltering tcp 1935 "Spotify web client"


    ##########################
    # Custom ports
    ##########################
    outputFiltering tcp 2200 "Custom SSH"


    ##########################
    # Common input to reject
    ##########################
    ipt46 -A OUTPUT -p tcp --dport 631 -m comment --comment "Internet printing (IPP)" -j DROP
    ipt46 -A OUTPUT -p udp --sport 57621 --dport 57621 -m comment --comment "Spotify network scan" -j DROP
    ipt46 -A OUTPUT -p udp --sport 17500 --dport 17500 -m comment --comment "Dropbox network scan" -j DROP


    log_end_msg 0
}



echo " "
echo " "
echo "# --------------------- #"
echo "#    FW START script    #"
echo "# --------------------- #"

###### Mandatory
firewallSetup

###### Port filtering (input | output | forwarding)
incomingPortFiltering
outgoingPortFiltering

###### Forward
#forwardConfiguration

###### VPN 
vpn "tun0" 8080 udp "eth0" "192.168.15.0/24" "2001:41d0:8:9318::/64"



###### Log and drop the rest!
log_daemon_msg "Log and DROP packets"
    logDroppedIpv4
    logDroppedIpv6
log_end_msg 0

echo " "
echo " "

