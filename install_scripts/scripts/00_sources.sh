#!/bin/bash
#
# To setup the list of repositories and upgrade the current distribution
#
RED="\\033[0;31m"
RED_BOLD="\\033[1;31m"
BLUE="\\033[1;34m"
GREEN="\\033[0;32m"
WHITE="\\033[0;37m"
YELLOW="\\033[1;33m"


function setupSourcesList() {
	ASSETS_PATH="./../assets"
	if [ $# -eq 1 ]; then
	    ASSETS_PATH="$1/assets"
	fi

	export DEBIAN_FRONTEND=dialog

	echo -e "$BLUE "
	echo -e "####################################"
	echo -e "     Updating repositories list" 
	echo -e "#################################### $WHITE"
	echo -e " " 
	echo -e "\n\n $YELLOW Attempt to update /etc/apt/sources.list $WHITE" 
	if [ ! -f /etc/apt/sources.list.backup ]; then
	    echo -e "\n\n $YELLOW ... Updating repositories list $WHITE"
	    # Backup
	    cp /etc/apt/sources.list /etc/apt/sources.list.backup
	    # Put new sources
	    cp $ASSETS_PATH/apt/sources.list /etc/apt/sources.list
            echo -e "\n\n $YELLOW Please wait... Repositories update in progress $WHITE"
	    apt update > /dev/null
	else 
		echo -e "\n\n $YELLOW ... Repositories list already seems to be up-to-date, nothing to do $WHITE" 
	fi

	# Java repository
	# 2018-10: Not required anymore because JDK 11 from Oracle is not free
	echo -e "\n\n $YELLOW  ... Setup OpenJRE and OpenJDK $WHITE"
	# Java 8 - For legacy compatibility
	apt install openjdk-8-jdk
  # Install JDK 11 LTS - for legacy reasons
	apt install -y openjdk-11-doc openjdk-11-jdk openjdk-11-jre
	# Latest JDK
	apt install -y default-jre default-jdk default-jdk-doc

	# Install all updates? 
	dialog --title "Perform upgrade?" \
		   --yesno "Do you want upgrade your computer [dist-upgrade] ?" 7 60
	upgradeAnswer=$?
	case $upgradeAnswer in
	   0)	# [yes] button 							
			echo -e "\n\n $BLUE Performing distribution upgrade $WHITE"
			echo -e " "
			echo -e "\n $YELLOW ... Fixing bugs, if any $WHITE"
			apt install -f
			echo -e "\n $YELLOW ... Updating list of repositories $WHITE"
			apt update 
			echo -e "\n\n $YELLOW ... Performing distribution upgrade $WHITE"
			apt dist-upgrade
			echo -e "\n\n $YELLOW ... Removing old packages $WHITE"
			apt autoremove
			echo -e "\n\n $YELLOW ... Cleaning repositories list $WHITE"
			apt autoclean && apt clean 
			echo -e "\n\n $GREEN ... distribution upgrade complete! $WHITE"
			;;
	   1)   # [no] button
			echo -e "\n\n Skipping distribution upgrade, [NO] button" 
			;;
	   255) 
			echo -e "\n\n Skipping distribution upgrade, [ESC] key pressed." 
			;;
	esac

	echo -e "\n\n $GREEN ... repositories list is now OK! $WHITE"
	echo -e " "
}


###### To test the script, just uncomment the following lines
#source ./check_root_rights.sh
#checkRootRights
#setupSourcesList

