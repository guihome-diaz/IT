#!/bin/bash
# To setup anti-virus program.
#
RED="\\033[0;31m"
RED_BOLD="\\033[1;31m"
BLUE="\\033[1;34m"
GREEN="\\033[0;32m"
WHITE="\\033[0;37m"
YELLOW="\\033[1;33m"

function setupAntivirus() {
	ASSETS_PATH="./../assets"
	if [ $# -eq 1 ]; then
	    ASSETS_PATH="$1/assets"
	fi
	export DEBIAN_FRONTEND=dialog

	echo -e "$BLUE "
	echo -e "####################################"
	echo -e "      Anti-virus installation " 
	echo -e "#################################### $WHITE \n"
	echo -e " "

	echo -e "\n\n $YELLOW   >> Installing package $WHITE \n"
	apt-get install -y clamav clamav-freshclam clamav-docs
	# Daemon (auto-run and service management)
	apt-get install -y clamav-daemon python3-clamav-daemon 
	# Utilities (additional scans)
	apt-get install -y libclamunrar7 clamassassin
	# Frontend (optional)
	apt-get install -y clamtk
	echo -e "\n\n $YELLOW   >> Updating anti-virus definitions $WHITE \n"
	freshclam

	echo -e "\n\n $YELLOW   >> Add daily scan at 02:30 $WHITE \n"
	cp $ASSETS_PATH/clamAVantiVirusScan /etc/cron.daily/
	chmod 755 /etc/cron.daily/clamAVantiVirusScan

	echo -e "\n\n $GREEN ... anti-virus installation complete! $WHITE"
	echo -e " "
}


###### To test the script, just uncomment the following lines
#source ./check_root_rights.sh
#checkRootRights
#setupAntivirus


