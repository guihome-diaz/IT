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
	apt-get install -y xfonts-intl-european xfonts-intl-phonetic
	apt-get install -y mathematica-fonts
	apt-get install -y ttf-mscorefonts-installer
    # Printing fonts
	apt-get install -y fontypython ttf-opensymbol


	echo -e "\n\n $YELLOW   >> Installing Chinese fonts $WHITE \n"
	apt-get install -y xfonts-intl-asian xfonts-intl-chinese xfonts-intl-chinese-big
    apt-get install -y pinyin-database sunpinyin-utils libpinyin-utils
	apt-get install -y fonts-arphic-ukai fonts-arphic-uming
    apt-get install -y fonts-arphic-*
    # See https://en.wikipedia.org/wiki/WenQuanYi
    apt-get install -y fonts-wqy-zenhei fonts-wqy-microhei xfonts-wqy


	echo -e "\n\n $YELLOW   >> Installing Android fonts $WHITE \n"
    apt-get install -y fonts-droid-fallback fonts-roboto fonts-roboto-hinted


	# Install alternate Input ? UI only !
	dialog --title "Install alternate keyboard?" \
		   --yesno "Do you want to install alternate keyboards (requires User Interface) ?" 7 60
	keyboardAnswer=$?
	case $keyboardAnswer in
	   0)	## [yes] button 							
			#echo -e "\n\n $BLUE Setting-up IBUS and Chinese keyboard (ubuntu <16) $WHITE"
			#apt-get install -y ibus
			#apt-get install -y ibus-pinyin
            #apt-get install -y ibus-sunpinyin
            #apt-get install -y ibus-googlepinyin
                        
			echo -e "\n\n $BLUE Setting-up FCITX and Chinese keyboard (ubuntu 16+) $WHITE"
            apt-get install -y fcitx
            apt-get install -y fcitx-libs fcitx-table-emoji fcitx-table-easy-big
            # Frontend keyboard selection
            #apt-get install -y fcitx-frontend-qt4 qt4-qtconfig

            # Pinyin = chinese chars. encoded in standard GB
            # SunPinYin = OpenSource project, official pinyin support for Linux
            # Google PinYin = Same PinYin as Android 
            # CheWing = MS Windows PinYin
            #apt-get install -y fcitx-pinyin fcitx-sunpinyin fcitx-googlepinyin fcitx-chewing
            apt-get install -y fcitx-pinyin fcitx-googlepinyin
            apt-get install -y fcitx-table-wbpy
            # Japanese input
            apt-get install -y fcitx-anthy 
            # Display pinyin input menu (list of characters) 
            ##### XCFE #####
            ## (i) qimpanel does NOT work well on XCFE. Better remove it and switch to the 'classic' UI
            #apt-get remove -y --purge fcitx-ui-qimpanel
            #apt-get install -y fcitx-ui-classic fcitx-ui-light
            
            # Keyboard support for Mozilla Firefox and other applications
            apt-get install -y fcitx-mozc

			echo -e "\n\n $BLUE Setup language selector $WHITE"
            apt-get install -y language-selector-gnome
            apt-get install -y im-config

			#echo -e "\n\n $BLUE Reload FCITX $WHITE"
            #fcitx -r
			;;
	   1)   # [no] button
			echo -e "\n\n No additional keyboards, [NO] button" 
			;;
	   255) 
			echo -e "\n\n Skipping Keyboard settings, [ESC] key pressed." 
			;;
	esac

	echo -e "\n\n $YELLOW   >> Add support to display EN(US), FR(FR), DE(DE), SV(SE), ZH(CN) $WHITE \n"
    apt-get install -y locales
    echo "en_US.UTF-8 UTF-8" >> /var/lib/locales/supported.d/local
    echo "fr_FR.UTF-8 UTF-8" >> /var/lib/locales/supported.d/local
    echo "de_DE.UTF-8 UTF-8" >> /var/lib/locales/supported.d/local
    echo "sv_SE.UTF-8 UTF-8" >> /var/lib/locales/supported.d/local
    echo "zh_CN.UTF-8 UTF-8" >> /var/lib/locales/supported.d/local
    dpkg-reconfigure locales

	echo -e "\n\n $GREEN ... language installation complete! $WHITE"
	echo -e " "
}


###### To test the script, just uncomment the following lines
#source ./check_root_rights.sh
#checkRootRights
#setupAdditionalLanguages
