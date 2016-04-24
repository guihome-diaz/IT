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
        # Sublime repository
        sublimeRepo=$(grep ^ /etc/apt/sources.list /etc/apt/sources.list.d/* | grep webupd8team-ubuntu-sublime | cut -d ':' -f 2- | grep "deb ")
        if [[ -z "$sublimeRepo" ]]; then
                echo -e "\n\n $YELLOW Installation of SUBLIME TEXT repository $WHITE"
        	add-apt-repository ppa:webupd8team/sublime-text-3 
                apt-get update > /dev/null
        fi
	apt-get install -y sublime-text-installer

	echo -e "\n\n $YELLOW   >> Installing hexadecimal editor (BLESS) $WHITE \n"
	apt-get install -y bless

	echo -e "\n\n $YELLOW   >> Installing Web-Browser FIREFOX $WHITE \n"
	apt-get install -y firefox

	echo -e "\n\n $YELLOW   >> Installing Guake $WHITE \n"
	apt-get install -y guake

	echo -e "\n\n $YELLOW   >> Installing unetbootin to create USB install disk $WHITE \n"
	apt-get install -y unetbootin

	echo -e "\n\n $YELLOW   >> Hardware detection $WHITE \n"
	apt-get install -y sysinfo
	apt-get install -y hardinfo

	echo -e "\n\n $YELLOW   >> Power management (to disable the screen saver) $WHITE \n"
	apt-get install -y caffeine

	echo -e "\n\n $YELLOW   >> Installing gparted to manage disks $WHITE \n"
	apt-get install -y gparted

	echo -e "\n\n $YELLOW   >> Installing scanner tools $WHITE \n"
	apt-get install -y simple-scan xsane

	echo -e "\n\n $YELLOW   >> Installing Samba client $WHITE \n"
	apt-get install system-config-samba

	tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/testUIpackages$$
	trap "rm -f $tempfile" 0 1 2 5 15

	dialog --backtitle "Xiongmaos" \
		--title "UI applications" \
	    --checklist "Hi, what features do you want to install?" 20 75 5 \
	        "Network"      "Network utilities such as Filezilla, RDP, OpenVPN client, etc." on \
	        "Multimedia"   "Multimedia libraries and players (VLC, RythmBox, etc.)" on \
		"Dock"         "Dock (OS X like) on the desktop. Only for Xfe, Mint, Cinnamon" off \
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
				echo -e "\n\n $YELLOW   >> Installing Network scanners (Wireshark, tShark, Nmap, Zenmap) $WHITE \n"
				apt-get install -y tshark wireshark wireshark-doc
				apt-get install -y nmap zenmap
				echo -e "\n\n $YELLOW   >> Installing Filezilla $WHITE \n"
				apt-get install -y filezilla
				echo -e "\n\n $YELLOW   >> Installing RDP utility (Remmina rdesktop) $WHITE \n"
				apt-get install -y rdesktop
				apt-get install -y remmina remmina-plugin-vnc remmina-plugin-gnome remmina-plugin-rdp
				echo -e "\n\n $YELLOW   >> Installing OpenVPN client + UI tool $WHITE \n"
				apt-get install -y openvpn
				apt-get install -y network-manager-openvpn
				echo -e "\n\n $YELLOW   >> Installing Deluge (Torrent client, very good!) $WHITE \n"
                                # Deluge repository
                                delugeRepo=$(grep ^ /etc/apt/sources.list /etc/apt/sources.list.d/* | grep deluge-team | cut -d ':' -f 2- | grep "deb ")
                                if [[ -z "$delugeRepo" ]]; then
	                                echo -e "\n\n $YELLOW Installation of DELUGE repository $WHITE"
	                                add-apt-repository ppa:deluge-team/ppa
	                                apt-get update > /dev/null
                                fi
                                apt-get install -y deluge
				;;

			"Multimedia") 
				echo -e "\n\n $YELLOW   >> Multimedia features (video) $WHITE \n"
				apt-get install -y ubuntu-restricted-extras
				apt-get install -y vlc
				apt-get install -y libquicktime2
				echo -e "\n\n $YELLOW   >> Multimedia features (audio) $WHITE \n"
				apt-get install -y rhythmbox 
				apt-get install -y rhythmbox-mozilla rhythmbox-doc rhythmbox-plugin-visualizer

				# KODI (media center)
                                ## Trick 2016-04-24 until KODI ppa is stable:
                                ##  - install KODI version packaged with ubuntu repository (it is stable);
                                ##  - add team-xbmc repo and wait for stable upgrade.  
                                apt-get install -y kodi
				echo -e "\n\n $YELLOW   >> Multimedia features (media center) $WHITE \n"
				# Requirements
				apt-get install -y python-software-properties pkg-config
				apt-get install -y software-properties-common
				apt-get install -y unrar
                                # Kodi repository
                                kodiRepo=$(grep ^ /etc/apt/sources.list /etc/apt/sources.list.d/* | grep team-xbmc | cut -d ':' -f 2- | grep "deb ")
                                if [[ -z "$kodiRepo" ]]; then
	                                echo -e "\n\n $YELLOW Installation of KODI repository $WHITE"
	                                add-apt-repository ppa:team-xbmc/ppa
	                                apt-get update > /dev/null
                                fi
				apt-get install -y kodi

				# Spotify official install process (https://www.spotify.com/lu-de/download/linux/)
                                spotifyRepo=$(grep ^ /etc/apt/sources.list /etc/apt/sources.list.d/* | grep spotify | cut -d ':' -f 2- | grep "deb ")
                                if [[ -z "$spotifyRepo" ]]; then
	                                echo -e "\n\n $YELLOW Installation of SPOTIFY repository $WHITE"
				        # 1. Add the Spotify repository signing key to be able to verify downloaded packages
				        apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys BBEBDCB318AD50EC6865090613B00F1FD2C19886
				        # 2. Add the Spotify repository
				        echo deb http://repository.spotify.com stable non-free | sudo tee /etc/apt/sources.list.d/spotify.list
				        # 3. Update list of available packages
	                                apt-get update > /dev/null
                                fi
				# 4. Install Spotify
				apt-get install -y spotify-client

				echo -e "\n\n $YELLOW   >> Handbrake video (crop and convert) $WHITE \n"
                                handbreakRepo=$(grep ^ /etc/apt/sources.list /etc/apt/sources.list.d/* | grep stebbins | cut -d ':' -f 2- | grep "deb ")
                                if [[ -z "$handbreakRepo" ]]; then
	                                echo -e "\n\n $YELLOW Installation of Hand-Brake repository $WHITE"
               				add-apt-repository ppa:stebbins/handbrake-releases
	                                apt-get update > /dev/null
                                fi
				apt-get install -y handbrake-gtk handbrake-cli
				;;

			"Dock") 
				echo -e "\n\n $YELLOW   >> Installing CAIRO dock $WHITE \n"
				apt-get install -y cairo-dock cairo-dock-plug-ins cairo-dock-plug-ins-integration
				;;
			"Office")
				echo -e "\n\n $YELLOW   >> Installing Libre Office and related dictionnaries + menu [EN, FR, SV, ZH] $WHITE \n"
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
				apt-get install -y freeplane
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
				# wine repository offer a better version than the one in Ubuntu official repositories
                                wineRepo=$(grep ^ /etc/apt/sources.list /etc/apt/sources.list.d/* | grep ubuntu-wine | cut -d ':' -f 2- | grep "deb ")
                                if [[ -z "$wineRepo" ]]; then
	                                echo -e "\n\n $YELLOW Installation of WINE repository $WHITE"
               				add-apt-repository ppa:ubuntu-wine/ppa
	                                apt-get update > /dev/null
                                fi
				apt-get install -y wine1.8
				apt-get install -y winetricks 
				apt-get install -y wine-mono
				apt-get install -y q4wine

				# Use "Play on linux" to create VM-like for each windows application
				apt-get install -y playonlinux
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
