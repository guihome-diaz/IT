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

	echo -e "\n\n $YELLOW   >> Installing Sublime Text editor $WHITE \n"
  # 2018-04 No need of a repository anymore!! Use SNAP :)
  #snap install sublime-text --classic

	#echo -e "\n\n $YELLOW   >> Installing Notepad++ $WHITE \n"
	#snap install notepad-plus-plus

	echo -e "\n\n $YELLOW   >> Installing hexadecimal editor (BLESS) $WHITE \n"
	apt install -y bless

	echo -e "\n\n $YELLOW   >> Installing Web-Browser FIREFOX $WHITE \n"
	apt install -y firefox

	echo -e "\n\n $YELLOW   >> Installing xclip (paperclip) $WHITE \n"
	apt install -y xclip

	echo -e "\n\n $YELLOW   >> Installing Guake $WHITE \n"
	apt install -y guake

	echo -e "\n\n $YELLOW   >> Hardware detection $WHITE \n"
	apt install -y sysinfo
	apt install -y hardinfo

	echo -e "\n\n $YELLOW   >> Power management (to disable the screen saver) $WHITE \n"
	apt install -y caffeine

	echo -e "\n\n $YELLOW   >> Installing gparted to manage disks $WHITE \n"
	apt install -y gparted

	echo -e "\n\n $YELLOW   >> Installing scanner tools $WHITE \n"
	apt install -y simple-scan xsane

	echo -e "\n\n $YELLOW   >> Installing GNOME tweak $WHITE \n"
	apt install -y gnome-tweak-tool

	echo -e "\n\n $YELLOW   >> Installing ADOBE flash player $WHITE \n"
	apt install -y adobe-flashplugin

	echo -e "\n\n $YELLOW   >> Installing OPENVPN support $WHITE \n"
	apt install -y network-manager-openvpn-gnome openvpn-systemd-resolved

	echo -e "\n\n $YELLOW   >> Installing Samba client $WHITE \n"
	apt install -y system-config-samba

	tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/testUIpackages$$
	trap "rm -f $tempfile" 0 1 2 5 15

	dialog --backtitle "Xiongmaos" \
		--title "UI applications" \
	    --checklist "Hi, what features do you want to install?" 20 75 5 \
	        "Communication"  "Communication tools (Skype)" on \
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
				apt install -y tshark wireshark wireshark-doc
				apt install -y nmap zenmap
				echo -e "\n\n $YELLOW   >> Installing Filezilla $WHITE \n"
				apt install -y filezilla
				echo -e "\n\n $YELLOW   >> Installing RDP utility (Remmina rdesktop) $WHITE \n"
				apt install -y rdesktop
				apt install -y remmina remmina-plugin-vnc remmina-plugin-rdp
				echo -e "\n\n $YELLOW   >> Installing OpenVPN client + UI tool $WHITE \n"
				apt install -y openvpn
				apt install -y network-manager-openvpn
				echo -e "\n\n $YELLOW   >> Installing Deluge (Torrent client, very good!) $WHITE \n"
                ## Deluge repository
                ## not required for UBUNTU 17.10 ARTFUL !
                #delugeRepo=$(grep ^ /etc/apt/sources.list /etc/apt/sources.list.d/* | grep deluge-team | cut -d ':' -f 2- | grep "deb ")
                #if [[ -z "$delugeRepo" ]]; then
                #    echo -e "\n\n $YELLOW Installation of DELUGE repository $WHITE"
                #    add-apt-repository ppa:deluge-team/ppa
                #    apt update > /dev/null
                #fi
                apt install -y deluge
				;;

			"Multimedia") 
				echo -e "\n\n $YELLOW   >> Multimedia features (video) $WHITE \n"
				apt install -y ubuntu-restricted-extras
				apt install -y vlc
				apt install -y libquicktime2
				echo -e "\n\n $YELLOW   >> Multimedia features (audio) $WHITE \n"
				apt install -y rhythmbox

				# KODI (media center)
        ## Trick 2016-04-24 until KODI ppa is stable:
        ##  - install KODI version packaged with ubuntu repository (it is stable);
        ##  - add team-xbmc repo and wait for stable upgrade.
        apt install -y kodi
				#echo -e "\n\n $YELLOW   >> Multimedia features (media center) $WHITE \n"
				# Requirements
				apt install -y python-software-properties pkg-config
				apt install -y software-properties-common

        # 2018-04: no need of dedicated repository for Spotify! Use SNAP :)
        #snap install spotify

		#echo -e "\n\n $YELLOW   >> Musixmatch alternative: DeepIN Music (songs lyrics) $WHITE \n"
		## Chinese alternative: deepin-music
		#sudo snap install deepin-music
		
		### Musixmatch
		echo -e "\n\n $YELLOW   >> Musixmatch $WHITE \n"
		wget -O musixmatch.deb https://adv.musixmatch.com/r/
		dpkg -i musixmatch.deb
		apt install -y -f

		echo -e "\n\n $YELLOW   >> Handbrake video (crop and convert) $WHITE \n"
    ## Handbrake repository
    ## not required for UBUNTU 17.10 ARTFUL !
    #handbreakRepo=$(grep ^ /etc/apt/sources.list /etc/apt/sources.list.d/* | grep stebbins | cut -d ':' -f 2- | grep "deb ")
    #if [[ -z "$handbreakRepo" ]]; then
    #    echo -e "\n\n $YELLOW Installation of Hand-Brake repository $WHITE"
		#	add-apt-repository ppa:stebbins/handbrake-releases
    #	apt update > /dev/null
    #fi
		apt install -y handbrake-gtk handbrake-cli

		echo -e "\n\n $YELLOW   >> FFMPEG (command line video tool) $WHITE \n"
    ## FFMEPG
    apt install -y ffmpeg
		apt install -y frei0r-plugins
		;;

			"Dock") 
				echo -e "\n\n $YELLOW   >> Installing CAIRO dock $WHITE \n"
				apt install -y cairo-dock cairo-dock-plug-ins cairo-dock-plug-ins-integration
				;;
			"Office")
				echo -e "\n\n $YELLOW   >> Installing Libre Office and related dictionnaries + menu [EN, FR, SV, ZH] $WHITE \n"
				apt install -y libreoffice libreoffice-calc libreoffice-draw  libreoffice-impress libreoffice-writer libreoffice-templates libreoffice-pdfimport
				apt install -y hunspell-en-us hyphen-en-us mythes-en-us
				apt install -y hunspell-fr hyphen-fr mythes-fr
                                apt install -y libreoffice-grammarcheck-fr
				apt install -y hunspell-sv-se
                                apt install -y hunspell-dictionary-sv
				apt install -y libreoffice-l10n-fr libreoffice-help-fr
				apt install -y libreoffice-l10n-sv libreoffice-help-sv

				echo -e "\n\n $YELLOW   >> Installing eBooks library (Calibre) $WHITE \n"
				apt install -y calibre

				echo -e "\n\n $YELLOW   >> Installing diagram tool (DIA) $WHITE \n"
				apt install -y dia

				echo -e "\n\n $YELLOW   >> Installing Mind Mapping (FreeMind) $WHITE \n"
				apt install -y freeplane

				echo -e "\n\n $YELLOW   >> Installing scanner drivers (SANE) $WHITE \n"
				apt install -y sane
				;;

			"Photo")
				echo -e "\n\n $YELLOW   >> Installing GIMP (Advanced image editor) $WHITE \n"
				#2018-04 don't use snap yet: it doesn't install all features
				#snap install gimp
                                apt install -y gimp gimp-help-common
				apt install -y gimp-data-extras gimp-gmic gimp-ufraw gnome-xcf-thumbnailer
				echo -e "\n\n $YELLOW   >> Installing GThumb images gallery + easy editor $WHITE \n"
				apt install -y gthumb
				;;

			"Wine")
				echo -e "\n\n $YELLOW   >> Installing Windows Emulator and Windows libraries (WINE) $WHITE \n"
				# 2018-04: we can rely on the version inside the 18.04 LTS repository
                apt install -y --install-recommends winehq-devel
				apt install -y winetricks 
				apt install -y wine-mono
				apt install -y q4wine

				# Use "Play on linux" to create VM-like for each windows application
				apt install -y playonlinux
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
			"Communication")
                                # 2018-04 No need of repository anymore!! Use snap :)
				echo -e "\n\n $YELLOW   >> Installing SKYPE $WHITE \n"
                snap install skype --classic

				#echo -e "\n\n $YELLOW   >> Installing VIBER DESKTOP $WHITE \n"
				#wget -O viber.deb http://download.cdn.viber.com/cdn/desktop/Linux/viber.deb
				#dpkg -i viber.deb
				;;
			*)
				echo "Something else: $choice"
				;;
		esac
	done


	echo -e "\n\n $GREEN ... UI packages installation complete! $WHITE"
	echo -e " "
	echo -e "Other applications:"
	echo -e "  * SoGou PinYin: http://www.ubuntukylin.com/application/show.php?lang=en&id=292"
	echo -e "  * FoxItPDF:     https://www.foxitsoftware.com/pdf-reader/"
	echo -e "  * Teamviewer:   https://www.teamviewer.com/en/download/linux/"
	echo -e "  * Hubic:        http://mir7.ovh.net/ovh-applications/hubic/hubiC-Linux/"
	echo -e " "
}


###### To test the script, just uncomment the following lines
#source ./check_root_rights.sh
#checkRootRights
#setupUIPackages
