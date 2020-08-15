
#!/bin/bash
#
# To setup wordpress website
#
RED="\\033[0;31m"
RED_BOLD="\\033[1;31m"
BLUE="\\033[1;34m"
GREEN="\\033[0;32m"
WHITE="\\033[0;37m"
YELLOW="\\033[1;33m"


function setupWordpressWebsite() {
	ASSETS_PATH="./../assets"
	if [ $# -eq 1 ]; then
	    ASSETS_PATH="$1/assets"
	fi
	export DEBIAN_FRONTEND=dialog


	CURRENT_IP_ADDRESS=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'`

	echo -e ""
	echo -e "####################################"
	echo -e "$BLUE         Wordpress website setup$WHITE" 
	echo -e " " 
	echo -e " Files:    Wordpress will be available in$YELLOW /var/www/blog"$WHITE
	echo -e " URL:      You can access it at$YELLOW http://localhost/blog$WHITE"
	echo -e " Database: A new MariaDB user will be created for worpress"
	echo -e "             * schema:$YELLOW wordpress$WHITE"
	echo -e "             * user:$YELLOW wordpress$WHITE"
	echo -e "             * pwd:$YELLOW  wordpress$WHITE"
	echo -e "             * access:$YELLOW localhost + remote $WHITE"
	echo -e " WP client accessible with$YELLOW wp$WHITE command"
	echo -e " "
	echo -e "To access the blog$YELLOW http://localhost/blog$WHITE"
	echo -e "             * user:$YELLOW admin$WHITE"
	echo -e "             * password:$YELLOW admin$WHITE"

	echo -e "#################################### $WHITE"

	
	###########################################
	# Database
	###########################################
	echo -e "\n\n $YELLOW Create new schema and DB user 'wordpress' $WHITE \n\n"
	# Create database
	mysql -u root -e "create database wordpress";
	# Create user
        mysql -u root -e "create user 'wordpress' identified by 'wordpress'";
	# Allow localhost connection
        mysql -u root -e "GRANT USAGE ON *.* TO 'wordpress'@localhost IDENTIFIED BY 'wordpress'";
	# Allow remote connection
	mysql -u root -e "GRANT USAGE ON *.* TO 'wordpress'@'%' IDENTIFIED BY 'wordpress'";
	# Grant rights
        mysql -u root -e "GRANT ALL privileges ON wordpress.* TO 'wordpress'@localhost";
        mysql -u root -e "GRANT ALL privileges ON wordpress.* TO 'wordpress'@'%'";
	# Apply changes
        mysql -u root -e "FLUSH PRIVILEGES";
	# Show configuration
	echo -e "\n\n $YELLOW    >>> new user 'wordpress' database rights$WHITE, expect 2 times 2 results in 2 tables\n\n"
	mysql -u root -e "SHOW GRANTS FOR 'wordpress'@localhost";
	mysql -u root -e "SHOW GRANTS FOR 'wordpress'@'%'";

	
        ###############################################
        # Wordpress startup
        ###############################################	
	echo -e "\n\n $YELLOW Get latest version of wordpress $WHITE \n\n"
	# Setup folders
	sudo mkdir -p /var/www/blog
	cd /var/www/blog
	# Get worpdress
	sudo wget http://wordpress.org/latest.tar.gz
	sudo tar xzvf latest.tar.gz
	sudo rm latest.tar.gz
	sudo mv worpress/* .
	sudo rm -r wordpress/
	# Set privileges
	sudo chown -R www-data:www-data /var/www/blog
	
	echo -e "\n\n $YELLOW Setup Wordpress command line client$WHITE (in /opt/wp-client/ ; command shortcut: wp)\n\n"
	echo -e "See https://wp-cli.org/ "
	# Download WP client
	sudo mkdir -p /opt/wp-client
	sudo cd /opt/wp-client
        sudo curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
	# Grant execution right and list current configuration
	sudo chmod +x wp-cli.phar
	php wp-cli.phar --info
	# create symlink
	sudo ln -s /opt/wp-client/wp-cli.phar /usr/bin/wp-cli
	# Create working folder
	sudo mkdir -p /var/www/.wp-cli/cache/
        sudo chown -R www-data:www-data /var/www/.wp-cli/cache/

	echo -e "\n\n $YELLOW Wordpress boot$WHITE\n\n"
	cd /var/www/blog
	# Create configuration
	sudo -u www-data wp core config --dbname=wordpress --dbuser=wordpress --dbpass=wordpress --dbhost=localhost
	# Initialize tables + admin user 
	sudo -u www-data wp core install --url=http://$CURRENT_IP_ADDRESS/blog --title=Daxiongmao_blog --admin_user=admin --admin_password=admin --admin_email=postmaster@daxiongmao.eu --skip-email


	########################################
	# Apache 2 config
	# this replace the .htaccess file
	########################################
	echo -e "\n\n $YELLOW Apache2 configuration$WHITE \n\n"
	# Create configuration
        echo "# Wordpress Apache configuration" > /etc/apache2/conf-available/blog.conf
        echo "Alias /blog /var/www/blog" >> /etc/apache2/conf-available/blog.conf
        echo " " >> /etc/apache2/conf-available/blog.conf
        echo "RewriteEngine On" >> /etc/apache2/conf-available/blog.conf
        echo "<Directory /var/www/blog>" >> /etc/apache2/conf-available/blog.conf
        echo "    Options Indexes FollowSymLinks" >> /etc/apache2/conf-available/blog.conf
        echo "    #Options Indexes SymLinksIfOwnerMatch" >> /etc/apache2/conf-available/blog.conf
        echo "    AllowOverride All" >> /etc/apache2/conf-available/blog.conf
        echo "    Require all granted" >> /etc/apache2/conf-available/blog.conf
        echo "    DirectoryIndex index.php" >> /etc/apache2/conf-available/blog.conf
        echo "</Directory>" >> /etc/apache2/conf-available/blog.conf
        echo " " >> /etc/apache2/conf-available/blog.conf
	# Enable configuration
	a2enconf blog
	systemctl reload apache2


	### new blog is accessible at http://serverIP@/blog/

	########################################
	# Configure nice URLs
	########################################
	echo -e "\n\n $YELLOW Wordpress configuration$WHITE\n\n"
	sudo -u www-data wp option update permalink_structure /%postname%/
	sudo -u www-data wp option update time_format H:i
	sudo -u www-data wp option update date_format Y-m-d
	
	########################################
	# Install plugins (public ones)
	########################################
	echo -e "\n\n $YELLOW Wordpress plugins$WHITE\n\n"

	echo -e "        * akismet anti-spam (akismet)"
	sudo -u www-data wp plugin install akismet
	sudo -u www-data wp option add wordpress_api_key ce78662c899c
	sudo -u www-data wp plugin activate akismet

	echo -e "        * Better Notifications for WP (bnfw)"
	sudo -u www-data wp plugin install bnfw
	sudo -u www-data wp plugin activate bnfw

	echo -e "        * Old text editor (before Gutenberg project)"
	sudo -u www-data wp plugin install classic-editor
	sudo -u www-data wp plugin activate classic-editor


	########################################
	# Content
	########################################
	sudo -u www-data wp option update blogdescription 'Every day is a wonder'


	#Remove default themes

	rm -rf /var/www/blog/wp-content/twentyseventeen/
	rm -rf /var/www/blog/wp-content/twentyeighteen/
	rm -rf /var/www/blog/wp-content/twentynineteen/
	#rm -rf /var/www/blog/wp-content/twentytwenty/




