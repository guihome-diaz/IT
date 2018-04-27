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

	apt install -y apache2 apache2-mpm-prefork apache2-utils ssl-cert
	apt install -y libapache2-mod-fcgid libruby
	apt install -y apache2-doc
	apt install -y libapache2-mod-perl2 libapache2-mod-perl2-doc
	apt install -y libapache2-mod-ldap-userdir
	apt install -y libapache2-mod-svn

	##### Apache2 modules 
	# Ask user
	tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/testApache2$$
	trap "rm -f $tempfile" 0 1 2 5 15

	dialog --title "Apache2 modules" \
	    --checklist "Which Apache2 modules would you like to enable?" 20 61 5 \
	        "proxy"     "Proxy (http, ajp, html)" on \
	        "rewrite"   "Redirection and rewrite" on \
	        "ssl"       "SSL" on \
	        "deflate"   "Deflate" Off \
	        "dav_svn"   "SVN HTTP proxy" Off \
	        "ldap"      "LDAP authentication" off 2> $tempfile
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
			echo -e "\n\n $YELLOW Installing PHP 5 support for Apache2 web-support $WHITE" 
			apt install -y libapache2-mod-php5 php5 php5-common
			apt install -y php5-cli php5-cgi
			apt install -y php5-curl php5-xmlrpc php5-xsl php5-dev php-pear 
			apt install -y php5-mysql
			apt install -y php5-memcache php5-xcache
			apt install -y php5-mhash php-auth php5-mcrypt mcrypt
			apt install -y php5-imap
			apt install -y php5-snmp
			apt install -y php5-gd php5-imagick imagemagick

			echo -e "\n\n $YELLOW Installing PHP 7 support for Apache2 web-support $WHITE" 
			apt install -y libapache2-mod-php7.0 php7.0 php7.0-common
			apt install -y php7.0-cli php7.0-cgi
			apt install -y php7.0-curl php7.0-xsl php7.0-dev 
			apt install -y php7.0-mysql
			apt install -y php7.0-mcrypt
			apt install -y php7.0-imap
			apt install -y php7.0-snmp
			apt install -y php7.0-gd

			echo -e "\n\n $YELLOW Enabling PHP module $WHITE"
			a2enmod php5
			a2enmod php7
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
