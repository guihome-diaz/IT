#!/bin/bash
# To setup RabbitMQ
#
RED="\\033[0;31m"
RED_BOLD="\\033[1;31m"
BLUE="\\033[1;34m"
GREEN="\\033[0;32m"
WHITE="\\033[0;37m"
YELLOW="\\033[1;33m"

function setupRabbitMQ() {
	ASSETS_PATH="./../assets"
	if [ $# -eq 1 ]; then
	    ASSETS_PATH="$1/assets"
	fi
	export DEBIAN_FRONTEND=dialog

	echo -e "$BLUE "
	echo -e "####################################"
	echo -e "      RabbitMQ installation " 
	echo -e "#################################### $WHITE \n"
	echo -e " "

	# RabbitMQ repository
	rabbitRepo=$(grep ^ /etc/apt/sources.list /etc/apt/sources.list.d/* | grep rabbitmq | cut -d ':' -f 2- | grep "deb ")
	if [[ -z "$rabbitRepo" ]]; then
		echo -e "\n\n $YELLOW Installation of RabbitMQ repository $WHITE"
		echo -e " " >> /etc/apt/sources.list
		echo -e "# RabbitMQ repository" >> /etc/apt/sources.list
		echo -e "deb http://www.rabbitmq.com/debian/ testing main" >> /etc/apt/sources.list

		wget http://www.rabbitmq.com/rabbitmq-signing-key-public.asc
		apt-key add rabbitmq-signing-key-public.asc
		apt update > /dev/null
	fi

	echo -e "\n\n $YELLOW   >> Installing RabbitMQ $WHITE \n"
	apt install rabbitmq-server amqp-tools



	# Ask for administrative user
	adminLogin=""
	tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/testRabbitMQadminLogin$$
	trap "rm -f $tempfile" 0 1 2 5 15
	dialog --title "RabbitMQ" --clear \
	        --inputbox "Type your administrator login \n" 16 75 2> $tempfile
	retval=$?
	case $retval in
	  0)
		adminLogin=`cat $tempfile`
	    ;;
	  1)
	    echo -e "\n\n Cancel pressed. Aborting process"
	    ;;
	  255)
	    echo -e "\n\n ESC pressed. Aborting process"
	    ;;
	esac
	rm $tempfile

	if [ -z "$adminLogin" ]; then
	    echo -e "$RED You must set an administrator login $WHITE"
	    echo -e " "
	    exit 1
	fi

	adminPassword=""
	tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/testRabbitMQadminPasswd$$
	trap "rm -f $tempfile" 0 1 2 5 15
	dialog --title "RabbitMQ" --clear \
	        --inputbox "Type your administrator password \n" 16 75 2> $tempfile
	retval=$?
	case $retval in
	  0)
		adminPassword=`cat $tempfile`
	    ;;
	  1)
	    echo -e "\n\n Cancel pressed. Aborting process"
	    ;;
	  255)
	    echo -e "\n\n ESC pressed. Aborting process"
	    ;;
	esac
	rm $tempfile

	if [ -z "$adminPassword" ]; then
	    echo -e "$RED You must set an administrator password $WHITE"
	    echo -e " "
	    exit 1
	fi

	echo -e "\n\n $YELLOW   >> Enabling RabbitMQ plugins $WHITE \n"
	rabbitmq-plugins enable amqp_client
	rabbitmq-plugins enable rabbitmq_management
	service rabbitmq-server restart


	echo -e "\n\n $YELLOW   >> Register admin user $WHITE \n"
	rabbitmqctl add_user $adminLogin $adminPassword
	rabbitmqctl set_user_tags $adminLogin administrator
	rabbitmqctl set_permissions -p / $adminLogin ".*" ".*" ".*"

	echo -e "\n\n $YELLOW   >> Delete guest user $WHITE \n"
	rabbitmqctl delete_user guest
	


	# Automatic start 
	dialog --title "RabbitMQ" \
		   --yesno "Do you want to start RabbitMQ on boot?" 7 60
	mqAnswer=$?
	case $mqAnswer in
	   0)	# [yes] button						
			echo -e "\n\n $YELLOW Registring RabbitMQ to start on boot $WHITE" 
			localDirectory=`pwd`
			cd /etc/init.d/
			update-rc.d rabbitmq-server defaults
			cd $localDirectory
			;;
	   1)   # [no] button
			echo -e "\n\n Skipping boot registration, [NO] button" 
			;;
	   255) 
			echo -e "\n\n Skipping boot registration, [ESC] key pressed." 
			;;
	esac

	echo -e "\n\n $YELLOW   >> Apply changes $WHITE \n"
	service rabbitmq-server restart


	echo -e "\n\n $GREEN ... RabbitMQ installation complete! $WHITE"
	echo -e " "
}


###### To test the script, just uncomment the following lines
#source ./check_root_rights.sh
#checkRootRights
#setupRabbitMQ


