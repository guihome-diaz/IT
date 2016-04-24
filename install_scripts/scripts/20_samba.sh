#!/bin/bash
#
# To setup Samba file-share 
#
RED="\\033[0;31m"
RED_BOLD="\\033[1;31m"
BLUE="\\033[1;34m"
GREEN="\\033[0;32m"
WHITE="\\033[0;37m"
YELLOW="\\033[1;33m"


function setupSambaFileShare() {
	ASSETS_PATH="./../assets"
	if [ $# -eq 1 ]; then
	    ASSETS_PATH="$1/assets"
	fi
	export DEBIAN_FRONTEND=dialog

	echo -e "$BLUE "
	echo -e "####################################"
	echo -e "         Samba file-share" 
	echo -e "#################################### $WHITE"
	echo " "
	echo " "
	
	echo -e "\n\n $YELLOW Creating Samba user (user that will access the share) $WHITE \n\n"
	smbUsername="smbuser"
	smbPassword="xiongmaos"
	egrep "^$smbUsername" /etc/passwd >/dev/null
	if [ $? -eq 0 ]; then
		echo "Samba user already exits!" 
	else
                ## Create a new system user 'smbUser' and add it to the list of SAMBA users
                # 1. New system user
		echo -e "  Add new samba user" 
		echo -e "     | "  
		echo -e "     |- Login:    $smbUsername" 
		echo -e " "
		useradd -c "Samba user" -s /sbin/nologin -m $smbUsername
		if [ $? -eq 0 ]; then
                        passwd $smbUsername      
                        # 2. Add system user to 'users'
			useradd -G users $smbUsername
			echo -e "  $smbUsername has been added to system" 
                        # 3. Add account to SAMBA                  
                        smbpasswd -a $smbUsername
                        # 4. Grant SAMBA access to account
                        smbpasswd -e $smbUsername
			echo -e "  $smbUsername has been added to SAMBA and granted access" 
		else
			echo -e "  Failed to add a $smbUsername ! :(" 
		fi
	fi

	# Package
	echo -e "\n\n $YELLOW Installing Samba client & server $WHITE \n\n"
	apt-get install -y samba samba-common libkrb5-3 winbind smbclient
	apt-get install -y cifs-utils
	apt-get install -y libcups2 cups cups-pdf

	# Setup default configuration
	cp /etc/samba/smb.conf /etc/samba/smb.conf.backup
	cp $ASSETS_PATH/samba/* /etc/samba/
	cp /etc/samba/smb_guest.conf /etc/samba/smb.conf


	# Ask user for LAN(s) information
	myNetworks=""
	tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/testSamba$$
	trap "rm -f $tempfile" 0 1 2 5 15
	dialog --title "Local network" --clear \
	        --inputbox "Type your local network(s) \n
	        			- All networks will be allowed \n
	        			- You can type many LAN, separated by ' ' \n
						ex: 192.168.1.0/24 172.16.128.0/16" 16 75 2> $tempfile
	retval=$?
	case $retval in
	  0)
		myNetworks=`cat $tempfile`
	    echo -e "\n\n Input string is $myNetworks"
	    ;;
	  1)
	    echo -e "\n\n Cancel pressed." ;;
	  255)
	      echo -e "\n\n ESC pressed." ;;
	esac
	rm $tempfile

	# Set hostname
	localHostname=`hostname`
	sed -i "s/myHostname/$localHostname/g" /etc/samba/smb.conf
	sed -i "s#myLocalNetwork#$myNetworks#g" /etc/samba/smb.conf

	# Restart samba service
	echo -e "\n\n $YELLOW Starting file-share server $WHITE \n\n"
	service samba restart


	echo -e "\n\n $GREEN ... File-share server OK ! $WHITE"
	echo -e "    >> Share: smb://$localHostname/Logs      ==    \\\\$localHostname\\Logs"
	echo -e "    >> Share: smb://$localHostname/Public    ==    \\\\$localHostname\\Public"
	echo -e " "
}



###### To test the script, just uncomment the following lines
#source ./check_root_rights.sh
#checkRootRights
#setupSambaFileShare
