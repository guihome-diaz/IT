#!/bin/bash
#
# To setup database server
#
RED="\\033[0;31m"
RED_BOLD="\\033[1;31m"
BLUE="\\033[1;34m"
GREEN="\\033[0;32m"
WHITE="\\033[0;37m"
YELLOW="\\033[1;33m"


function setupMySQLserver() {
	export DEBIAN_FRONTEND=dialog

	echo -e "$BLUE "
	echo -e "####################################"
	echo -e "           MySQL database" 
	echo -e "#################################### $WHITE"
	echo " "
	echo " "

	echo -e "\n\n $YELLOW Installation MySQL server $WHITE \n\n" 
	apt-get install -y mysql-server mysql-client

	dialog --title "MySQL installation" \
		   --yesno "Enable remote access?" 7 60
	mysqlAnswer=$?
	case $mysqlAnswer in
	   0)	# [yes] button
			
			# We need to know the MySQL root password
			# Ask user for the root password (in ClearText)
			rootPassword=""
			tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/testRootPassword$$
			trap "rm -f $tempfile" 0 1 2 5 15
			dialog --title "MySQL installation" --clear \
			        --inputbox "Type your MySQL root password" 16 75 2> $tempfile
			retval=$?
			case $retval in
			  0)
				rootPassword=`cat $tempfile`
			    ;;
			  1)
			    echo -e "\n\n Cancel pressed." ;;
			  255)
			      echo -e "\n\n ESC pressed." ;;
			esac
			rm $tempfile

			localHostname=`hostname`


			# Performing actions
			echo -e "\n\n $YELLOW Listening on all interfaces $WHITE"
			sed -i "s/bind-address           = 127.0.0.1/#bind-address           = 127.0.0.1/g" /etc/mysql/my.cnf

			echo -e "\n\n $YELLOW Allow root access from all locations $WHITE"
			mysql -uroot -p$rootPassword mysql -e "update user set host='%' where user='root' and host='$localHostname'; flush privileges;";
			;;
	   1)   # [no] button
			echo -e "\n\n Skipping remote access, [NO] button" ;;
	   255) 
			echo -e "\n\n Skipping remote access, [ESC] key pressed." ;;
	esac

	echo -e "\n\n $YELLOW Restarting MySQL server $WHITE \n\n" 
	service mysql restart


	echo -e "\n\n $GREEN ... MySQL server OK ! $WHITE"
	echo -e " "
}



###### To test the script, just uncomment the following lines
#source ./check_root_rights.sh
#checkRootRights
#setupMySQLserver
