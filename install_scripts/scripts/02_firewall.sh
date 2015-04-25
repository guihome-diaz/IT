#!/bin/bash
#
# To setup firewall
#
RED="\\033[0;31m"
RED_BOLD="\\033[1;31m"
BLUE="\\033[1;34m"
GREEN="\\033[0;32m"
WHITE="\\033[0;37m"
YELLOW="\\033[1;33m"


function setupFirewall() {
	CURRENT_DIRECTORY=`pwd`
	ASSETS_PATH="./../assets"
	if [ $# -eq 1 ]; then
	    ASSETS_PATH="$1/assets"
	fi
	cd $ASSETS_PATH
	echo "ASSET PATH: `pwd`"
	export DEBIAN_FRONTEND=dialog

	echo -e "$BLUE "
	echo -e "####################################"
	echo -e "            Firewall" 
	echo -e "#################################### $WHITE"
	echo " "
	echo " "

	FIREWALL_SCRIPT="/etc/firewall/firewall.sh"
	FIREWALL_START_SCRIPT="/etc/firewall/firewall-start.sh"

	#### Copy log file and restart rsyslog
	touch /var/log/iptables.log
	chmod 777 /var/log/iptables.log
	cp firewall/10-iptables.conf /etc/rsyslog.d
	service rsyslog restart
	
	#### Firewall to copy, link and start
	cp -r firewall /etc
	chmod -R 755 /etc/firewall/*.sh
	ln -s $FIREWALL_SCRIPT /etc/init.d/firewall
	ln -s $FIREWALL_SCRIPT /usr/bin/firewall
	cd /etc/init.d/
	update-rc.d firewall defaults

	#### Ask user to choose the INPUT ports to open
	tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/testFW1$$
	trap "rm -f $tempfile" 0 1 2 5 15

	dialog --title "Firewall" \
	    --checklist "Which INPUT ports would you like to open?" 20 61 5 \
	        "Web"          "HTTP and HTTPS ports (80, 443)" on \
	        "HTTP_alt"     "HTTP and HTTPS alt. ports (8080, 8443)" off \
	        "MySQL"        "MySQL database (3306)" off \
	        "Postgresql"   "Postgresql database (5432)" off \
	        "File-share"   "Samba file-share " off \
	        "Java_JMX"     "Java JMX (1099)" off \
	        "Sonar"        "SonarQube (9000)" off \
	        "Glassfish"    "Glassfish application server (4848, 1527)" off \
	        "Jboss"        "Jboss Wildfly application server (9990)" off \
	        "RabbitMQ"     "RabbitMQ messaging (5672, 15672)" off \
	        "ActiveMQ"     "OpenMQ JMS messaging (8161, 8162, 11099, 61616)" off \
	        "SVN"          "Subversion server (3690)" off \
	        "LDAP"         "LDAP server (389, 636)" off \
	        "Zabbix"       "Zabbix monitoring server (10051)" off \
	        "ELK"          "ELK logs monitoring (9200, 9300, 54328)" off \
	        "Webmin"       "Webmin administrative tool (10000, 20000)" off 2> $tempfile
	retval=$?
	choices=`cat $tempfile`
	case $retval in
		0)
			echo -e "\n\n You select: $choices";;
		1)
			echo -e "\n\n Cancel pressed.";;
		255)
	    	echo -e "\n\n ESC pressed.";;
	  *)
			echo -e "\n\n Unexpected return code: $retval (ok would be 0)";;
	esac


	clear
	IFS=', ' read -a portArray <<< "$choices"
	for currentPort in "${portArray[@]}"
	do
		case "$currentPort" in
			"Web")		
				echo -e "\n\n $YELLOW >> Opening web ports (HTTP tcp 80, HTTPS tcp 443) $WHITE"
				sed -i 's/#$IPTABLES -A INPUT -p tcp --dport 80 -j ACCEPT/$IPTABLES -A INPUT -p tcp --dport 80 -j ACCEPT/g' $FIREWALL_START_SCRIPT
				sed -i 's/#$IPTABLES -A INPUT -p tcp --dport 443 -j ACCEPT/$IPTABLES -A INPUT -p tcp --dport 443 -j ACCEPT/g' $FIREWALL_START_SCRIPT
				;;
			"HTTP_alt")
				echo -e "\n\n $YELLOW >> Opening alternate web ports (tcp 8080, tcp 8443) $WHITE"
				sed -i 's/#$IPTABLES -A INPUT -p tcp --dport 8080 -j ACCEPT/$IPTABLES -A INPUT -p tcp --dport 8080 -j ACCEPT/g' $FIREWALL_START_SCRIPT
				sed -i 's/#$IPTABLES -A INPUT -p tcp --dport 8443 -j ACCEPT/$IPTABLES -A INPUT -p tcp --dport 8443 -j ACCEPT/g' $FIREWALL_START_SCRIPT
				;;
			"MySQL") 
				echo -e "\n\n $YELLOW >> Opening MySQL port (tcp 3306) $WHITE"
				sed -i 's/#$IPTABLES -A INPUT -p tcp --dport 3306 -j ACCEPT/$IPTABLES -A INPUT -p tcp --dport 3306 -j ACCEPT/g' $FIREWALL_START_SCRIPT
				;;
			"Postgresql")
				echo -e "\n\n $YELLOW >> Opening Postgresql port (tcp 5432) $WHITE"
				sed -i 's/#$IPTABLES -A INPUT -p tcp --dport 5432 -j ACCEPT/$IPTABLES -A INPUT -p tcp --dport 5432 -j ACCEPT/g' $FIREWALL_START_SCRIPT
				;;
				;;
			"File-share")
				echo -e "\n\n $YELLOW >> Opening file-share port (udp 137,138 | tcp 139,445) $WHITE"
				sed -i 's/#$IPTABLES -A INPUT -p udp --dport 137 -j ACCEPT/$IPTABLES -A INPUT -p udp --dport 137 -j ACCEPT/g' $FIREWALL_START_SCRIPT
				sed -i 's/#$IPTABLES -A INPUT -p udp --dport 138 -j ACCEPT/$IPTABLES -A INPUT -p udp --dport 138 -j ACCEPT/g' $FIREWALL_START_SCRIPT
				sed -i 's/#$IPTABLES -A INPUT -p tcp --dport 139 -j ACCEPT/$IPTABLES -A INPUT -p tcp --dport 139 -j ACCEPT/g' $FIREWALL_START_SCRIPT
				sed -i 's/#$IPTABLES -A INPUT -p tcp --dport 445 -j ACCEPT/$IPTABLES -A INPUT -p tcp --dport 445 -j ACCEPT/g' $FIREWALL_START_SCRIPT
				;;
			"Java_JMX")
				echo -e "\n\n $YELLOW >> Opening Java JMX (tcp 1099) $WHITE"
				sed -i 's/#$IPTABLES -A INPUT -p tcp --dport 1099 -j ACCEPT/$IPTABLES -A INPUT -p tcp --dport 1099 -j ACCEPT/g' $FIREWALL_START_SCRIPT
				;;	
			"Sonar")
				echo -e "\n\n $YELLOW >> Opening SonarQube (tcp 9000) $WHITE"
				sed -i 's/#$IPTABLES -A INPUT -p tcp --dport 9000 -j ACCEPT/$IPTABLES -A INPUT -p tcp --dport 9000 -j ACCEPT/g' $FIREWALL_START_SCRIPT
				;;
			"Glassfish")
				echo -e "\n\n $YELLOW >> Opening Glassfish Application Server (tcp 1527, 4848) $WHITE"
				sed -i 's/#$IPTABLES -A INPUT -p tcp --dport 4848 -j ACCEPT/$IPTABLES -A INPUT -p tcp --dport 4848 -j ACCEPT/g' $FIREWALL_START_SCRIPT
				sed -i 's/#$IPTABLES -A INPUT -p tcp --dport 1527 -j ACCEPT/$IPTABLES -A INPUT -p tcp --dport 1527 -j ACCEPT/g' $FIREWALL_START_SCRIPT
				;;
			"Jboss")
				echo -e "\n\n $YELLOW >> Opening Jboss Wildfly (tcp 9990) $WHITE"
				sed -i 's/#$IPTABLES -A INPUT -p tcp --dport 9990 -j ACCEPT/$IPTABLES -A INPUT -p tcp --dport 9990 -j ACCEPT/g' $FIREWALL_START_SCRIPT
				;;
			"RabbitMQ")
				echo -e "\n\n $YELLOW >> Opening RabbitMQ (tcp 5672, 15672) $WHITE"
				sed -i 's/#$IPTABLES -A INPUT -p tcp --dport 5672 -j ACCEPT/$IPTABLES -A INPUT -p tcp --dport 5672 -j ACCEPT/g' $FIREWALL_START_SCRIPT
				sed -i 's/#$IPTABLES -A INPUT -p tcp --dport 15672 -j ACCEPT/$IPTABLES -A INPUT -p tcp --dport 15672 -j ACCEPT/g' $FIREWALL_START_SCRIPT
				;;
			"ActiveMQ")
				echo -e "\n\n $YELLOW >> Opening ActiveMQ (tcp 8161, 8162, 11099, 61616) $WHITE"
				sed -i 's/#$IPTABLES -A INPUT -p tcp --dport 8161 -j ACCEPT/$IPTABLES -A INPUT -p tcp --dport 8161 -j ACCEPT/g' $FIREWALL_START_SCRIPT
				sed -i 's/#$IPTABLES -A INPUT -p tcp --dport 8162 -j ACCEPT/$IPTABLES -A INPUT -p tcp --dport 8162 -j ACCEPT/g' $FIREWALL_START_SCRIPT
				sed -i 's/#$IPTABLES -A INPUT -p tcp --dport 11099 -j ACCEPT/$IPTABLES -A INPUT -p tcp --dport 11099 -j ACCEPT/g' $FIREWALL_START_SCRIPT
				sed -i 's/#$IPTABLES -A INPUT -p tcp --dport 61616 -j ACCEPT/$IPTABLES -A INPUT -p tcp --dport 61616 -j ACCEPT/g' $FIREWALL_START_SCRIPT
				;;
			"SVN")
				echo -e "\n\n $YELLOW >> Opening Subversion server (tcp 3690). $RED You should use a HTTP proxy instead! $WHITE"
				sed -i 's/#$IPTABLES -A INPUT -p tcp --dport 3690 -j ACCEPT/$IPTABLES -A INPUT -p tcp --dport 3690 -j ACCEPT/g' $FIREWALL_START_SCRIPT
				;;
			"LDAP")
				echo -e "\n\n $YELLOW >> Opening LDAP server (tcp 389, 636) $WHITE"
				sed -i 's/#$IPTABLES -A INPUT -p tcp --dport 389 -j ACCEPT/$IPTABLES -A INPUT -p tcp --dport 389 -j ACCEPT/g' $FIREWALL_START_SCRIPT
				sed -i 's/#$IPTABLES -A INPUT -p tcp --dport 636 -j ACCEPT/$IPTABLES -A INPUT -p tcp --dport 636 -j ACCEPT/g' $FIREWALL_START_SCRIPT
				;;
			"Zabbix")
				echo -e "\n\n $YELLOW >> Opening Zabbix monitoring server (tcp 10051) $WHITE"
				sed -i 's/#$IPTABLES -A INPUT -p tcp --dport 10051 -j ACCEPT/$IPTABLES -A INPUT -p tcp --dport 10051 -j ACCEPT/g' $FIREWALL_START_SCRIPT
				;;
			"ELK")
				echo -e "\n\n $YELLOW >> Opening ELK (ElasticSearch, Logstash, Kibana) $WHITE"
				sed -i 's/#$IPTABLES -A INPUT -p tcp --dport 9200 -j ACCEPT/$IPTABLES -A INPUT -p tcp --dport 9200 -j ACCEPT/g' $FIREWALL_START_SCRIPT
				sed -i 's/#$IPTABLES -A INPUT -p tcp --dport 9300 -j ACCEPT/$IPTABLES -A INPUT -p tcp --dport 9300 -j ACCEPT/g' $FIREWALL_START_SCRIPT
				sed -i 's/#$IPTABLES -A INPUT -p tcp --dport 54328 -j ACCEPT/$IPTABLES -A INPUT -p tcp --dport 54328 -j ACCEPT/g' $FIREWALL_START_SCRIPT
				sed -i 's/#$IPTABLES -A INPUT -p udp --dport 54328 -j ACCEPT/$IPTABLES -A INPUT -p udp --dport 54328 -j ACCEPT/g' $FIREWALL_START_SCRIPT
				;;
	        "Webmin")
				echo -e "\n\n $YELLOW >> Opening Webmin administrative tool (tcp 10000, 20000) $WHITE"
				sed -i 's/#$IPTABLES -A INPUT -p tcp --dport 10000 -j ACCEPT/$IPTABLES -A INPUT -p tcp --dport 10000 -j ACCEPT/g' $FIREWALL_START_SCRIPT
				sed -i 's/#$IPTABLES -A INPUT -p tcp --dport 20000 -j ACCEPT/$IPTABLES -A INPUT -p tcp --dport 20000 -j ACCEPT/g' $FIREWALL_START_SCRIPT
				;;
			*)
				echo "Something else: $choice"
				;;
		esac
	done

	###### Allow all output ? - Ask the user
	dialog --title "Firewall installation" \
		   --yesno "Do you want to allow all OUTPUT?" 7 60
	fwOutputAnswer=$?
	case $fwOutputAnswer in
	   0)	# [yes] button
			sed -i 's/$IPTABLES -P OUTPUT DROP/$IPTABLES -P OUTPUT ACCEPT/g' $FIREWALL_START_SCRIPT
			sed -i 's/$IP6TABLES -P OUTPUT DROP/$IP6TABLES -P OUTPUT ACCEPT/g' $FIREWALL_START_SCRIPT
			# need to be done in 2 times to avoid commented function!
			sed -i 's/outgoingPortFiltering/#outgoingPortFiltering/g' $FIREWALL_START_SCRIPT
			sed -i 's/function #outgoingPortFiltering/function outgoingPortFiltering/g' $FIREWALL_START_SCRIPT			
			# do not drop output packets
			sed -i 's/$IPTABLES -A OUTPUT -j LOGGING/#$IPTABLES -A OUTPUT -j LOGGING/g' $FIREWALL_START_SCRIPT
			;;
	   1)   # [no] button
			echo -e "\n\n Skipping Output configuration. Default is output RESTRICTED" 
			;;
	   255) 
			echo -e "\n\n Skipping Output configuration. Default is output RESTRICTED" 
			;;
	esac


	###### Should we enable full LAN access (not recommanded) - Ask the user
	dialog --title "Firewall installation" \
		   --yesno "Do you want to allow all LAN communications?" 7 60
	fwLanAnswer=$?
	case $fwLanAnswer in
	   0)	# [yes] button						
			###### Ask user for LAN(s) information
			myNetworks=""
			tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/testFW2$$
			trap "rm -f $tempfile" 0 1 2 5 15
			dialog --title "Local network" --clear \
			        --inputbox "Type the LAN to allow \n
			        			- You can type only 1 LAN \n
								ex: 192.168.1.0/24" 16 75 2> $tempfile
			retval=$?
			case $retval in
			  0)
				myNetworks=`cat $tempfile`
				sed -i "s#myLocalNetwork#$myNetworks#g" $FIREWALL_START_SCRIPT
			    ;;
			  1)
				sed -i "s/myLocalNetwork//g" $FIREWALL_START_SCRIPT
			    echo -e "\n\n Cancel pressed." ;;
			  255)
				sed -i "s/myLocalNetwork//g" $FIREWALL_START_SCRIPT
			    echo -e "\n\n ESC pressed." ;;
			esac
			rm $tempfile
			;;
	   1)   # [no] button
			sed -i "s/myLocalNetwork//g" $FIREWALL_START_SCRIPT
			echo -e "\n\n Skipping LAN communication, [NO] button" 
			;;
	   255) 
			sed -i "s/myLocalNetwork//g" $FIREWALL_START_SCRIPT
			echo -e "\n\n Skipping LAN communication, [ESC] key pressed." 
			;;
	esac


	echo -e "\n\n $GREEN ... Firewall OK ! $WHITE"
	echo -e " "
	

	cd $CURRENT_DIRECTORY
}


###### To test the script, just uncomment the following lines
#source ./check_root_rights.sh
#checkRootRights
#setupFirewall
