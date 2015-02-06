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
	apt-get install -y rsyslog
	echo -e "\n\n $YELLOW   >> Installing Linux Editors $WHITE \n"
	apt-get install -y vim vim-nox vim-scripts nano

	echo -e "\n\n $YELLOW   >> Installing Security applications $WHITE \n" 
	apt-get install -y openssl
	apt-get install -y openssh-server openssh-client
	apt-get install -y fail2ban

	echo -e "\n\n $YELLOW   >> Installing Archive managers $WHITE \n"
	apt-get install -y flex libarchive-zip-perl libio-compress-perl m4 perl perl-modules unzip zip
	apt-get install -y zoo bzip2 arj nomarch lzop cabextract
	apt-get install -y lzip ncompress rzip sharutils unace unalz unrar p7zip-rar

	echo -e "\n\n $YELLOW   >> Installing Linux compilation tools $WHITE \n"
	apt-get install -y make autoconf automake cpp gcc
	apt-get install -y build-essential

	echo -e "\n\n $YELLOW   >> Installing Core libraries extensions $WHITE \n"
	apt-get install -y libnet-ldap-perl libauthen-sasl-perl daemon libio-string-perl libio-socket-ssl-perl
	apt-get install -y libnet-ident-perl libnet-dns-perl

	echo -e "\n\n $YELLOW   >> Installing Python $WHITE \n"
	apt-get install -y python3 python3-doc
	apt-get install -y python-pip
	apt-get install -y pkg-config
	
	echo -e "\n\n $YELLOW   >> Installing Advanced APT manager $WHITE \n"
	apt-get install -y software-properties-common python-software-properties

	echo -e "\n\n $YELLOW   >> Installing Processes manager $WHITE \n"
	apt-get install -y htop

	echo -e "\n\n $YELLOW   >> Installing Startup manager $WHITE \n"
	apt-get install -y sysv-rc-conf

	echo -e "\n\n $YELLOW   >> Installing time sync $WHITE \n"
	apt-get install -y ntp ntpdate

	echo -e "\n\n $YELLOW   >> Installing Dos2unix converter and vice-versa $WHITE \n"
	apt-get install -y dos2unix tofrodos

	echo -e "\n\n $YELLOW   >> Installing midnight commander $WHITE \n" 
	apt-get install -y mc

	echo -e "\n\n $YELLOW   >> Installing Network utilities $WHITE \n"
	apt-get install -y curl

	echo -e "\n\n $YELLOW   >> Network clients (NFS, Samba) $WHITE \n"
	apt-get install -y nfs-common smbclient

	echo -e "\n\n $GREEN ... core packages installation complete! $WHITE"
	echo -e " "
}


###### To test the script, just uncomment the following lines
#source ./check_root_rights.sh
#checkRootRights
#setupCorePackages
