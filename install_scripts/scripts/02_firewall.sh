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

	echo -e "\n\n $GREEN ... Firewall OK ! $WHITE"
	echo -e " "

	cd $CURRENT_DIRECTORY
}


###### To test the script, just uncomment the following lines
#source ./check_root_rights.sh
#checkRootRights
#setupFirewall
