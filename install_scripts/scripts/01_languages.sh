#!/bin/bash
#
# List of Linux core packages to install
#

RED="\\033[0;31m"
RED_BOLD="\\033[1;31m"
BLUE="\\033[1;34m"
GREEN="\\033[0;32m"
WHITE="\\033[0;37m"
YELLOW="\\033[1;33m"

function setupAdditionalLanguages() {

	export DEBIAN_FRONTEND=dialog

	echo -e "$BLUE "
	echo -e "#########################################"
	echo -e "  Foreign languages supports and fonts" 
	echo -e "######################################### $WHITE"
	echo -e "... this might take some time, please wait"
	echo -e " "

	echo -e "\n\n $YELLOW   >> Installing alternate fonts $WHITE \n"
	apt-get install -y xfonts-intl-asian xfonts-intl-chinese xfonts-intl-european xfonts-intl-phonetic
	apt-get install -y mathematica-fonts
	apt-get install -y ttf-mscorefonts-installer
	apt-get install -y fontypython ttf-opensymbol


	echo -e "\n\n $YELLOW   >> Installing Chinese fonts $WHITE \n"
	apt-get install -y fonts-arphic-ukai fonts-arphic-uming


	# Install alternate Input ? UI only !
	dialog --title "Install alternate keyboard?" \
		   --yesno "Do you want to install alternate keyboards (requires User Interface) ?" 7 60
	keyboardAnswer=$?
	case $keyboardAnswer in
	   0)	# [yes] button 							
			echo -e "\n\n $BLUE Setting-up IBUS and Chinese keyboard $WHITE"
			apt-get install -y ibus
			apt-get install -y ibus-pinyin ibus-googlepinyin
			;;
	   1)   # [no] button
			echo -e "\n\n No additional keyboards, [NO] button" 
			;;
	   255) 
			echo -e "\n\n Skipping Keyboard settings, [ESC] key pressed." 
			;;
	esac

	echo -e "\n\n $GREEN ... language installation complete! $WHITE"
	echo -e " "
}


###### To test the script, just uncomment the following lines
#source ./check_root_rights.sh
#checkRootRights
#setupAdditionalLanguages
