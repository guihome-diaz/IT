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

DIALOG_OK=0
DIALOG_CANCEL=1
DIALOG_ESC=255


function setupUIPackages() {

	export DEBIAN_FRONTEND=dialog


	echo -e "$BLUE "
	echo -e "####################################"
	echo -e "  Installation of UI apps" 
	echo -e "#################################### $WHITE"
	echo -e " "
	echo -e "\n\n $BLUE UI Core libraries $WHITE \n"
	echo -e " "

	echo -e "\n\n $YELLOW   >> Icon status manager (missing in late UI) $WHITE \n"
	apt-get install -y libgtk2-appindicator-perl

	echo -e "\n\n $YELLOW   >> Installing Sublime Text editor $WHITE \n"
	add-apt-repository ppa:webupd8team/sublime-text-3 
	apt-get update
	apt-get install -y sublime-text-installer

	echo -e "\n\n $YELLOW   >> Installing hexadecimal editor (BLESS) $WHITE \n"
	apt-get install -y bless

	echo -e "\n\n $YELLOW   >> Installing Guake $WHITE \n"
	apt-get install -y guake

	echo -e "\n\n $YELLOW   >> Installing unetbootin to create USB install disk $WHITE \n"
	apt-get install -y unetbootin

	echo -e "\n\n $YELLOW   >> Installing Zenmap to scan the Network $WHITE \n"
	apt-get install -y zenmap

	echo -e "\n\n $YELLOW   >> Installing gparted to manage disks $WHITE \n"
	apt-get install -y gparted

	echo -e "\n\n $YELLOW   >> Installing scanner tools $WHITE \n"
	apt-get install -y simple-scan xsane

	tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/testUIpackages$$
	trap "rm -f $tempfile" 0 1 2 5 15

	dialog --backtitle "VEHCO" \
		--title "UI applications" \
	    --checklist "Hi, what features do you want to install?" 20 75 5 \
	        "Network"      "Network utilities such as Filezilla, RDP, OpenVPN client, etc." on \
	        "Multimedia"   "Multimedia libraries and players (VLC, RythmBox, etc.)" on \
	        "Office"       "Libre office + diagrams + eBook tools" on \
	        "Photo"        "Image editor (Gimp) and photo library (GThumb)" on \
	        "Wine"         "Windows emulator" off 2> $tempfile
	retval=$?
	choices=`cat $tempfile`
	case $retval in
	  $DIALOG_OK)
	    echo "You select: $choices";;
	  $DIALOG_CANCEL)
	    echo "Cancel pressed.";;
	  $DIALOG_ESC)
	    echo "ESC pressed.";;
	  *)
	    echo "Unexpected return code: $retval (ok would be $DIALOG_OK)";;
	esac


	#########################
	# Process user response #
	#########################
	# Cast String result into array
	# Process each array value using {switch,case}

	clear
	IFS=', ' read -a choicesArray <<< "$choices"
	for choice in "${choicesArray[@]}"
	do
		case "$choice" in

			"Network")		
				echo -e "\n\n $YELLOW   >> Installing Filezilla $WHITE \n"
				apt-get install -y filezilla
				echo -e "\n\n $YELLOW   >> Installing RDP utility (Remmina rdesktop) $WHITE \n"
				apt-get install -y rdesktop
				apt-get install -y remmina remmina-plugin-vnc remmina-plugin-gnome remmina-plugin-rdp
				echo -e "\n\n $YELLOW   >> Installing OpenVPN client + UI tool $WHITE \n"
				apt-get install -y openvpn
				apt-get install -y network-manager-openvpn
				;;

			"Multimedia") 
				echo -e "\n\n $YELLOW   >> Multimedia features (video) $WHITE \n"
				apt-get install -y ubuntu-restricted-extras
				apt-get install -y vlc
				apt-get install -y libquicktime2
				echo -e "\n\n $YELLOW   >> Multimedia features (audio) $WHITE \n"
				apt-get install -y rhythmbox rhythmbox-mozilla rhythmbox-doc rhythmbox-plugin-visualizer rhythmbox-radio-browser
				echo -e "\n\n $YELLOW   >> Multimedia features (media center) $WHITE \n"
				add-apt-repository ppa:team-xbmc/ppa
				apt-get update
				apt-get install -y kodi
				echo -e "\n\n $YELLOW   >> Handbrake video (crop and convert) $WHITE \n"
				add-apt-repository ppa:stebbins/handbrake-releases
				apt-get update
				apt-get install -y handbrake-gtk handbrake-cli
				;;

			"Office")
				echo -e "\n\n $YELLOW   >> Installing Libre Office and related dictionnaries + menu [EN, FR, SV] $WHITE \n"
				apt-get install -y libreoffice libreoffice-calc libreoffice-draw  libreoffice-impress libreoffice-writer libreoffice-templates libreoffice-pdfimport
				apt-get install -y hunspell-en-us hyphen-en-us mythes-en-us
				apt-get install -y hunspell-fr hyphen-fr mythes-fr
				apt-get install -y hunspell-sv-se
				apt-get install -y libreoffice-l10n-fr libreoffice-help-fr
				apt-get install -y libreoffice-l10n-sv libreoffice-help-sv

				echo -e "\n\n $YELLOW   >> Installing eBooks library (Calibre) $WHITE \n"
				apt-get install -y calibre

				echo -e "\n\n $YELLOW   >> Installing diagram tool (DIA) $WHITE \n"
				apt-get install -y dia

				echo -e "\n\n $YELLOW   >> Installing Mind Mapping (FreeMind) $WHITE \n"
				apt-get install -y freemind freemind-plugins-svg freemind-plugins-help freemind-browser
				;;

			"Photo")
				echo -e "\n\n $YELLOW   >> Installing GIMP (Advanced image editor) $WHITE \n"
				apt-get install -y gimp gimp-help-common
				apt-get install -y gimp-data-extras gimp-gmic gimp-ufraw gnome-xcf-thumbnailer
				echo -e "\n\n $YELLOW   >> Installing GThumb images gallery + easy editor $WHITE \n"
				apt-get install -y gthumb
				;;

			"Wine")
				echo -e "\n\n $YELLOW   >> Installing Windows Emulator and Windows libraries (WINE) $WHITE \n"
				apt-get install -y wine
				apt-get install -y q4wine
				apt-get install -y winetricks
				;;

			"Web-server")
				setupApacheWebServer $EXECUTION_PATH
				echo " " >> $logFile
				echo "###########" >> $logFile
				echo "# Apache2 #" >> $logFile
				echo "###########" >> $logFile
				echo "Apache2 configuration in /etc/apache2/" >> $logFile
				echo "... No VHOST enable, you have to create | adjust your configuration" >> $logFile
				echo "... Some configuration examples are available in /etc/apache2/vehco-samples" >> $logFile
				echo "... Some websites examples are available in /var/www/vehco-samples" >> $logFile
				echo " " >> $logFile
				;;
			*)
				echo "Something else: $choice"
				;;
		esac
	done


	echo -e "\n\n $GREEN ... UI packages installation complete! $WHITE"
	echo -e " "
}


###### To test the script, just uncomment the following lines
#source ./check_root_rights.sh
#checkRootRights
#setupUIPackages
