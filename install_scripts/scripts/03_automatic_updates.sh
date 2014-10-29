#!/bin/bash
#
# To enable automatic updates
#
RED="\\033[0;31m"
RED_BOLD="\\033[1;31m"
BLUE="\\033[1;34m"
GREEN="\\033[0;32m"
WHITE="\\033[0;37m"
YELLOW="\\033[1;33m"


function setupAutomaticUpdates() {
	ASSETS_PATH="./../assets"
	if [ $# -eq 1 ]; then
	    ASSETS_PATH="$1/assets"
	fi
	export DEBIAN_FRONTEND=dialog

	echo -e "$BLUE "
	echo -e "####################################"
	echo -e "          Automatic updates" 
	echo -e "#################################### $WHITE"
	echo " "
	echo " "

	UPDATE_SCRIPT="/etc/apt/apt.conf.d/50unattended-upgrades"


	echo -e "\n\n $YELLOW >> Installing required package $WHITE"
	apt-get install -y unattended-upgrades

	echo -e "\n\n $YELLOW >> Enable 'updates' and 'proposed' packages $WHITE"
	sed -i 's#//      "${distro_id}:${distro_codename}-updates";#        "${distro_id}:${distro_codename}-updates";#g' $UPDATE_SCRIPT
	sed -i 's#//      "${distro_id}:${distro_codename}-proposed";#        "${distro_id}:${distro_codename}-proposed";#g' $UPDATE_SCRIPT


	echo -e "\n\n $YELLOW >> Enable dist-upgrade and auto-clean + set update frequency $WHITE"
	cp $ASSETS_PATH/apt/10periodic /etc/apt/apt.conf.d/10periodic


	echo -e "\n\n $GREEN ... Automatic updates OK ! $WHITE"
	echo -e " "
	
}


###### To test the script, just uncomment the following lines
#source ./check_root_rights.sh
#checkRootRights
#setupAutomaticUpdates
