#!/bin/bash
#
# To setup Apache2 web server
#
RED="\\033[0;31m"
RED_BOLD="\\033[1;31m"
BLUE="\\033[1;34m"
GREEN="\\033[0;32m"
WHITE="\\033[0;37m"
YELLOW="\\033[1;33m"


function setupApacheWebServer() {
	ASSETS_PATH="./../assets"
	if [ $# -eq 1 ]; then
	    ASSETS_PATH="$1/assets"
	fi
	export DEBIAN_FRONTEND=dialog

	echo -e "$BLUE "
	echo -e "####################################"
	echo -e "         Apache 2 web server" 
	echo -e "#################################### $WHITE"
	echo -e "\n\n $YELLOW Installing Apache2 web-server $WHITE \n\n"

	apt install -y apache2 apache2-utils ssl-cert
	apt install -y libapache2-mod-fcgid libruby
	apt install -y apache2-doc
	apt install -y libapache2-mod-perl2 libapache2-mod-perl2-doc
	#apt install -y libapache2-mod-ldap-userdir
	#apt install -y libapache2-mod-svn

	##### Apache2 modules 
	# Ask user
	tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/testApache2$$
	trap "rm -f $tempfile" 0 1 2 5 15

	dialog --title "Apache2 modules" \
	    --checklist "Which Apache2 modules would you like to enable?" 20 61 5 \
	        "proxy"     "Proxy (http, ajp, html)" on \
	        "rewrite"   "Redirection and rewrite" on \
	        "ssl"       "SSL" on \
	        "deflate"   "Deflate" Off 2> $tempfile
	        #"dav_svn"   "SVN HTTP proxy" Off \
	        #"ldap"      "LDAP authentication" off 2> $tempfile
	retval=$?
	apache2modulesChoices=`cat $tempfile`
	case $retval in
	  0)
    	echo -e "\n\n You select: $apache2modulesChoices";;
	  1)
	    echo -e "\n\n Cancel pressed.";;
	  255)
	    echo -e "\n\n ESC pressed.";;
	  *)
	    echo -e "\n\n Unexpected return code: $retval (ok would be $DIALOG_OK)";;
	esac

	# Process user choices
	IFS=', ' read -a apache2modulesChoicesArray <<< "$apache2modulesChoices"
	for moduleChoice in "${apache2modulesChoicesArray[@]}"
	do
		case "$moduleChoice" in
			"proxy") 
				echo -e "\n\n $YELLOW >> Enabling proxy module $WHITE"
				a2enmod proxy proxy_http proxy_ajp proxy_html xml2enc
				;;
			"rewrite")
				echo -e "\n\n $YELLOW  >> Enabling rewrite module $WHITE"
				a2enmod rewrite
				;;
			"ssl") 
				echo -e "\n\n $YELLOW  >> Enabling ssl module $WHITE"
				a2enmod ssl
				;;
			"deflate") 
				echo -e "\n\n $YELLOW  >> Enabling deflate module $WHITE"
				a2enmod deflate
				;;
			"ldap") 
				echo -e "\n\n $YELLOW  >> Enabling ldap module $WHITE"
				a2enmod ldap authnz_ldap ldap_userdir
				;;
			"dav_svn")
				echo -e "\n\n $YELLOW  >> Enabling DAV SVN module $WHITE"
				a2enmod dav_svn
				;;
			*)
				echo -e "\n\n $RED_BOLD Unknown module: $moduleChoice $WHITE"
				;;
		esac
	done


	# PHP 
	dialog --title "PHP installation" \
		   --yesno "Do you want to install PHP?" 7 60
	phpAnswer=$?
	case $phpAnswer in
	   0)	# [yes] button						
			echo -e "\n\n $YELLOW Installing PHP support for Apache2 web-support $WHITE" 
			# PHP engine
			apt install -y libapache2-mod-php php php-common

			######################################
			# PHP standalone deamon, it will have its own thread (not managed by Apache2)			
			apt install -y php-fpm
			# Add Apache2 module to communicate with PHP standalone
			a2enmod proxy_fcgi
			# Apply Apache2 changes
			systemctl restart apache2
			# Tell Apache2 to forward all PHP request to standalone engine
			a2enconf php7.4-fpm
			systemctl restart apache2
			######################################

			# script execution
			apt install -y php-cli php-cgi
			# Support encoding and streams
			apt install -y php-mbstring
			# php utilities
			apt install -y php-dev 
			apt install -y php-pear 
			# XML rpc (required for wordpress)
			apt install -y php-xmlrpc php-xsl
			# SOAP web services support
			apt install -y php-soap
			# URLs
			apt install -y php-curl
			# databases
			apt install -y php-mysql
			apt install -y php-odbc
			# PDO: abstraction layer for object mapping (ORM)
			apt install -y php-pdo
			# Memory and performances
			apt install -y php-memcache
			# Emails
			apt install -y php-imap
			# Monitoring
			apt install -y php-snmp
			# Images
			apt install -y php-gd php-imagick imagemagick
			# Zip file handling
			apt install -y php-zip
			# Crypto
			apt install -y mcrypt

			echo -e "\n\n $YELLOW create phpinfo page $WHITE "
			echo "<?php phpinfo(); ?>" > /var/www/html/phpinfo.php
			chown www-data:www-data /var/www/html/phpinfo.php

			echo -e "\n\n $YELLOW Enabling Apache PHP module $WHITE"
			a2enmod php7*

			echo -e "\n\n $YELLOW Enabling PHP 7.4 extensions $WHITE"
			cp /etc/php/7.4/apache2/php.ini /etc/php/7.4/apache2/php.ini.backup
			# increase POST and uplooad size
			sed -i "s/post_max_size = 8M/post_max_size = 32M/g" /etc/php/7.4/apache2/php.ini
			sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 64M/g" /etc/php/7.4/apache2/php.ini
			# URLs
			sed -i "s/;extension=curl/extension=curl/g" /etc/php/7.4/apache2/php.ini
			# FTP
			sed -i "s/;extension=ftp/extension=ftp/g" /etc/php/7.4/apache2/php.ini
			# File access
			sed -i "s/;extension=fileinfo/extension=fileinfo/g" /etc/php/7.4/apache2/php.ini
			# Graphics
			sed -i "s/;extension=gd2/extension=gd2/g" /etc/php/7.4/apache2/php.ini
			# international
			sed -i "s/;extension=intl/extension=intl/g" /etc/php/7.4/apache2/php.ini
			sed -i "s/;extension=mbstring/extension=mbstring/g" /etc/php/7.4/apache2/php.ini
			# MySQL and MariaDB
			sed -i "s/;extension=mysqli/extension=mysqli/g" /etc/php/7.4/apache2/php.ini
			sed -i "s/;extension=pdo_mysql/extension=pdo_mysql/g" /etc/php/7.4/apache2/php.ini
			# Security
			sed -i "s/;extension=openssl/extension=openssl/g" /etc/php/7.4/apache2/php.ini

			echo -e "\n\n $YELLOW Setup phpmyadmin $WHITE"
			apt install -y phpmyadmin

			;;
	   1)   # [no] button
			echo -e "\n\n Skipping PHP installation, [NO] button" 
			;;
	   255) 
			echo -e "\n\n Skipping PHP installation, [ESC] key pressed." 
			;;
	esac


	# Copy VEHCO samples
	echo -e "\n\n $YELLOW Copying VEHCO v-hosts samples $WHITE \n\n"
	mkdir -p /etc/apache2/vehco-samples
	cp $ASSETS_PATH/apache2/conf/* /etc/apache2/vehco-samples/

	echo -e "\n\n $YELLOW Copying VEHCO websites samples $WHITE \n\n"
	mkdir -p /var/www/vehco-samples
	cp $ASSETS_PATH/apache2/www/* /var/www/vehco-samples/
	chown -R www-data:www-data /var/www/vehco-samples
	chmod -R 755 /var/www/vehco-samples
	

	# Take on changes		
	echo -e "\n\n $YELLOW Restarting Apache2 web-server and applying changes $WHITE \n\n"
	service apache2 restart

	echo -e "\n\n $GREEN ... Apache2 web-server installation complete! $WHITE"
	echo -e " "
}



###### To test the script, just uncomment the following lines
#source ./check_root_rights.sh
#checkRootRights
#setupApacheWebServer
