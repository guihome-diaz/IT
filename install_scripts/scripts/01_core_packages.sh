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

function setupCorePackages() {

	export DEBIAN_FRONTEND=dialog

	echo -e "$BLUE "
	echo -e "####################################"
	echo -e "  Installation of key applications" 
	echo -e "#################################### $WHITE"
	echo -e "... this might take some time, please wait"
	echo -e " "

	echo -e "\n\n $YELLOW   >> Installing RsysLog $WHITE \n" 
	apt install -y rsyslog
	echo -e "\n\n $YELLOW   >> Installing Linux Editors $WHITE \n"
	apt install -y vim vim-nox vim-scripts nano

	echo -e "\n\n $YELLOW   >> Installing Security applications $WHITE \n" 
	apt install -y openssl
	apt install -y openssh-server openssh-client
	apt install -y fail2ban

	echo -e "\n\n $YELLOW   >> Installing Network tools (including ifconfig)$WHITE \n"
	apt install -y net-tools

	echo -e "\n\n $YELLOW   >> Installing PERL $WHITE \n"
	apt install -y perl perl-modules
	apt install -y libarchive-zip-perl libio-compress-perl
	echo -e "\n\n $YELLOW   >> Installing PERL libraries $WHITE \n"
	apt install -y libnet-ldap-perl libauthen-sasl-perl daemon libio-string-perl libio-socket-ssl-perl libnet-ident-perl libnet-dns-perl
	
	echo -e "\n\n $YELLOW   >> Installing Archive managers $WHITE \n"
	apt install -y unzip zip
	apt install -y bzip2 arj unrar unace
	#apt install -y nomarch lzop cabextract
	#apt install -y lzip ncompress rzip sharutils unalz p7zip-rar

	echo -e "\n\n $YELLOW   >> Installing Linux compilation tools $WHITE \n"
	apt install -y make autoconf automake cpp gcc g++
	apt install -y build-essential

	echo -e "\n\n $YELLOW   >> Installing SVN client$WHITE \n"
	apt install -y subversion
	
	echo -e "\n\n $YELLOW   >> Installing GIT client$WHITE \n"
	apt install git

	echo -e "\n\n $YELLOW   >> Installing Python $WHITE \n"
	apt install -y python3 python3-doc
	apt install -y python-pip
	apt install -y pkg-config
	
	echo -e "\n\n $YELLOW   >> Installing Advanced APT manager $WHITE \n"
	apt install -y software-properties-common

	echo -e "\n\n $YELLOW   >> Installing Processes manager $WHITE \n"
	apt install -y htop

	echo -e "\n\n $YELLOW   >> Installing Startup manager $WHITE \n"
	apt install -y sysv-rc-conf

	echo -e "\n\n $YELLOW   >> Installing time sync $WHITE \n"
	apt install -y ntp ntpdate

	echo -e "\n\n $YELLOW   >> Installing Dos2unix converter and vice-versa $WHITE \n"
	apt install -y dos2unix tofrodos

	#echo -e "\n\n $YELLOW   >> Installing midnight commander $WHITE \n"
	#apt install -y mc

	echo -e "\n\n $YELLOW   >> Installing Network utilities $WHITE \n"
	apt install -y curl

	echo -e "\n\n $YELLOW   >> Network clients (NFS, Samba) $WHITE \n"
	apt install -y nfs-common smbclient

	echo -e "\n\n $YELLOW   >> Installing manual pages $WHITE \n"
	apt install -y manpages
	
	echo -e "\n\n $YELLOW   >> Installing Android USB driver $WHITE \n"
	apt install -y android-tools-adb

	echo -e "\n\n $YELLOW   >> Auto-completion ignore case $WHITE \n"
	echo "set completion-ignore-case On" >> ~/.inputrc

	echo -e "\n\n $GREEN ... core packages installation complete! $WHITE"
	echo -e " "
}


###### To test the script, just uncomment the following lines
#source ./check_root_rights.sh
#checkRootRights
#setupCorePackages
