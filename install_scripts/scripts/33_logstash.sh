#!/bin/bash
#
# Logstash setup
#

RED="\\033[0;31m"
RED_BOLD="\\033[1;31m"
BLUE="\\033[1;34m"
GREEN="\\033[0;32m"
WHITE="\\033[0;37m"
YELLOW="\\033[1;33m"

function setupLogstash() {
	CURRENT_DIRECTORY=`pwd`
	ASSETS_PATH="./../assets"
	if [ $# -eq 1 ]; then
	    ASSETS_PATH="$1/assets"
	fi
	cd $ASSETS_PATH
	echo "ASSET PATH: `pwd`"
	
	export DEBIAN_FRONTEND=dialog


	echo -e "$BLUE "
	echo -e "####################################"
	echo -e "            Logstash" 
	echo -e "#################################### $WHITE"
	echo " "
	echo " "

	LOGSTASH_VERSION="1.4.2"

	echo -e "\n\n $YELLOW   >> Setup directories and files $WHITE \n"
	# Configuration folders
	mkdir -p /etc/logstash/conf.d
	mkdir /etc/logstash/grok
	mkdir /etc/logstash/db

	# Logs
	touch /var/log/logstash.log
	chmod -R 777 /var/log/logstash.log

	# Startup script
	cp logstash/logstash.sh /etc/init.d
	chmod -R 755 /etc/init.d/logstash.sh

	# Copy grok patterns
	cp logstash/*.grok /etc/logstash/grok/

	# Copy configuration with default files
	cp logstash/*.conf /etc/logstash/conf.d/	

	# Set rights
	chmod -R 777 /etc/logstash
	
	# Get and install logstash
	echo -e "\n\n $YELLOW   >> Download and installation of Logstash binaries\n | Logstash version: $LOGSTASH_VERSION $WHITE \n"
	wget https://download.elasticsearch.org/logstash/logstash/logstash-$LOGSTASH_VERSION.tar.gz
	tar xzvf "logstash-$LOGSTASH_VERSION.tar.gz"
	rm logstash-$LOGSTASH_VERSION.tar.gz
	mv logstash-$LOGSTASH_VERSION/ /opt/
	cd /opt
	ln -s /opt/logstash-$LOGSTASH_VERSION /opt/logstash

	# Register logstash as application	
	echo -e "\n\n $YELLOW   >> Register logstash as an applicaiton $WHITE \n"
	ln -s /etc/init.d/logstash.sh /usr/bin/logstash

	# add logstash to boot sequence
	echo -e "\n\n $YELLOW   >> Start logstash on boot $WHITE \n"
	cd /etc/init.d/
	update-rc.d logstash.sh defaults

	echo -e "\n\n $GREEN ... Logstash installation complete! $WHITE"
	echo -e " "

	echo -e " You need to adjust your configuration in /etc/logstash/conf.d/"
	echo -e " "
}


###### To test the script, just uncomment the following lines
#source ./check_root_rights.sh
#setupLogstash
