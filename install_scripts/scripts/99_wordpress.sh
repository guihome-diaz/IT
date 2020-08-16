#!/usr/bin/env bash
set -e

###############################################################################
# Utility script to setup a wordpress website and its database in minutes
#
# I created that script to backup and restore my own blog and to be able to experiment new extensions/configuration without damaging production database.
# Also this helps to create standalone installation and give it to family members for offline use.
#
################################################################################
# Configuration
# -------------
#
# Before using it 'as is' please review and adjust the configuration section
# at the beginning of the script. Set your own settings to apply
#
################################################################################
# Technical notes
# ---------------
# /!\ This script uses DEVELOPER SETTINGS as default
# For production you might need to review it and comment some lines such as remote DB access
#
# Requirements:
#   * Current server uses Apache2 (the script creates a ".conf" + it reloads Apache2)
#   * Current server has PHP 7.4 or later installed
#   * Current server has a MariaDB with a "root" user
#   * Internet connection is available to download wordpress, wp-cli, plugins and themes
#
# Principle:
#   * Create Wordpress database: new schema and user, according to configuration.
#     We allow remote connection for maintenance purposes.
#   * Create a new web-folder and download wordpress
#     Folder is owned by 'www-data'
#   * Download and install Wordpress command line client: "WP-CLI"
#   * Create Apache2 configuration and apply changes
#   * Setup wordpress:
#      * Create database
#      * Create users
#      * Setup core configuration
#      * Download key plugins + apply corresponding configuration
#      * Download theme
#
# Thanks to 'set -e' the script will exit if a command fails (exit code different from 0)
#
# Last but not least, use https://www.shellcheck.net/ to verify the ShellScript syntax + 'bash -n script.sh'
###############################################################################
# Author:   Guillaume Diaz
# Version:  1.0 - 2020/08 - script creation
#
# Thanks to Greg Parker for its excellent article (https://medium.com/@beBrllnt/from-30-minutes-to-10-seconds-automating-wordpress-setup-5ff7526942c0)
# Thanks to WP-CLI team for writing such a convenient and efficient tool (https://wp-cli.org/)
#
###############################################################################

RED="\\033[0;31m"
RED_BOLD="\\033[1;31m"
BLUE="\\033[1;34m"
GREEN="\\033[0;32m"
WHITE="\\033[0;37m"
YELLOW="\\033[1;33m"
# Get current IP @, do not change that line
CURRENT_IP_ADDRESS=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')

# ********************************************* #
# ***              CONFIGURATION            *** #
# ********************************************* #
# Slug: wordpress short name to use in URL and for installation folder
WP_INSTALLATION_SLUG="blog"

# Installation folder (this folder will be created)
WEBSITE_ROOT="/var/www/${WP_INSTALLATION_SLUG}"

# Wordpress website URL (feel free to set your own DNS name)
WEBSITE_URL="http://$CURRENT_IP_ADDRESS/${WP_INSTALLATION_SLUG}"

# Database (Maria DB) settings
WP_DB_SCHEMA="wordpress"
WP_DB_USER="wordpress"
WP_DB_PASSWORD="wordpress"

# Wordpress configuration (admin user)
WP_ADMIN_USER="admin"
WP_ADMIN_PASSWORD="admin"
WP_ADMIN_EMAIL="guillaume@qin-diaz.com"

# Wordpress content
WP_TITLE="MiniXiongMao"
WP_DESCRIPTION="Every day is a wonder"

# ********************************************* #
# ***              /CONFIGURATION            *** #
# ********************************************* #


#***************************************************************************#
#***************************************************************************#
#****************              INSTALLATION                 ****************#
#***************************************************************************#
#***************************************************************************#

#######################################
# Create wordpress database in Maria DB
# Arguments: None
# Outputs:   None
#######################################
function createWordpressDatabase() {
  echo -e "Create new DB schema and new DB user"
  # Create database
  mysql -u root -e "create database ${WP_DB_SCHEMA}"
  # Create user
  mysql -u root -e "create user '${WP_DB_USER}' identified by '${WP_DB_PASSWORD}'"
  # Allow localhost connection
  mysql -u root -e "GRANT USAGE ON *.* TO '${WP_DB_USER}'@localhost IDENTIFIED BY '${WP_DB_PASSWORD}'"
  # Allow remote connection
  mysql -u root -e "GRANT USAGE ON *.* TO '${WP_DB_USER}'@'%' IDENTIFIED BY '${WP_DB_PASSWORD}'"
  # Grant rights
  mysql -u root -e "GRANT ALL privileges ON ${WP_DB_SCHEMA}.* TO '${WP_DB_USER}'@localhost"
  mysql -u root -e "GRANT ALL privileges ON ${WP_DB_SCHEMA}.* TO '${WP_DB_USER}'@'%'"
  # Apply changes
  mysql -u root -e "FLUSH PRIVILEGES"

  # Show configuration
  echo -e "    >>> DB checks: new user '${WP_DB_USER}' rights will appear (expect 2 times 2 results in 2 tables)"
  mysql -u root -e "SHOW GRANTS FOR '${WP_DB_USER}'@localhost"
  mysql -u root -e "SHOW GRANTS FOR '${WP_DB_USER}'@'%'"

  # Summary
  echo -e "${BLUE}************************************${WHITE}"
  echo -e "Wordpress database settings"
  echo -e "  * schema:${YELLOW}   ${WP_DB_SCHEMA}${WHITE}"
  echo -e "  * user:${YELLOW}     ${WP_DB_USER}${WHITE}"
  echo -e "  * password:${YELLOW} ${WP_DB_PASSWORD}${WHITE}"
  echo -e "  * access:${YELLOW}   localhost + remote ${WHITE}"
  echo -e "${BLUE}************************************${WHITE}"
}

#######################################
# To download latest version of Wordpress
# Arguments: None
# Outputs:   None
#######################################
function downloadWordpress() {
  # Setup folders
  echo -e "Create wordpress folder"
  sudo mkdir -p ${WEBSITE_ROOT}
  cd ${WEBSITE_ROOT}

  # Get worpdress
  echo -e "Get latest version of wordpress and save it to: ${WEBSITE_ROOT}"
  sudo wget https://wordpress.org/latest.tar.gz
  echo -e "Unpack archive and set rights"
  sudo tar xzvf ${WEBSITE_ROOT}/latest.tar.gz
  sudo rm ${WEBSITE_ROOT}/latest.tar.gz
  sudo mv ${WEBSITE_ROOT}/wordpress/* ${WEBSITE_ROOT}/
  sudo rm --recursive --force ${WEBSITE_ROOT}/wordpress/
  # Set privileges
  sudo chown -R www-data:www-data ${WEBSITE_ROOT}

  # Summary
  echo -e "${BLUE}************************************${WHITE}"
  echo -e "Wordpress files are available at:${YELLOW} ${WEBSITE_ROOT}${WHITE}"
  echo -e "${BLUE}************************************${WHITE}"
}

########################################
# Apache 2 config
# this configuration replaces the .htaccess file
# Arguments: None
# Outputs:   None
#######################################
function createWordpressApache2configuration() {
  echo -e "Apache2 configuration"
  # Create configuration
  echo "# Wordpress Apache configuration" >/etc/apache2/conf-available/${WP_INSTALLATION_SLUG}.conf
  echo "Alias /${WP_INSTALLATION_SLUG} ${WEBSITE_ROOT}" >>/etc/apache2/conf-available/${WP_INSTALLATION_SLUG}.conf
  echo " " >>/etc/apache2/conf-available/${WP_INSTALLATION_SLUG}.conf
  echo "RewriteEngine On" >>/etc/apache2/conf-available/${WP_INSTALLATION_SLUG}.conf
  echo "<Directory ${WEBSITE_ROOT}>" >>/etc/apache2/conf-available/${WP_INSTALLATION_SLUG}.conf
  echo "    Options Indexes FollowSymLinks" >>/etc/apache2/conf-available/${WP_INSTALLATION_SLUG}.conf
  echo "    #Options Indexes SymLinksIfOwnerMatch" >>/etc/apache2/conf-available/${WP_INSTALLATION_SLUG}.conf
  echo "    AllowOverride All" >>/etc/apache2/conf-available/${WP_INSTALLATION_SLUG}.conf
  echo "    Require all granted" >>/etc/apache2/conf-available/${WP_INSTALLATION_SLUG}.conf
  echo "    DirectoryIndex index.php" >>/etc/apache2/conf-available/${WP_INSTALLATION_SLUG}.conf
  echo "</Directory>" >>/etc/apache2/conf-available/${WP_INSTALLATION_SLUG}.conf
  echo " " >>/etc/apache2/conf-available/${WP_INSTALLATION_SLUG}.conf
  # Enable configuration
  a2enconf ${WP_INSTALLATION_SLUG}
  systemctl reload apache2

  # Summary
  echo -e "${BLUE}************************************${WHITE}"
  echo -e "Wordpress is accessible at${YELLOW} ${WEBSITE_URL}${WHITE}"
  echo -e "${BLUE}************************************${WHITE}"
}

#######################################
# To download and setup WP-CLI (wordpress command line utility)
# see https://wp-cli.org/
# Arguments: None
# Outputs:   None
#######################################
function installWpCli() {
  echo -e "Setup Wordpress command line client"
  # Download WP client
  sudo mkdir -p /opt/wp-client
  cd /opt/wp-client
  sudo curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar

  echo -e "Dry run"
  # Grant execution right and list current configuration
  sudo chmod +x wp-cli.phar
  php wp-cli.phar --info

  echo -e "Create symlink 'wp'"
  # create symlink
  sudo ln -s /opt/wp-client/wp-cli.phar /usr/bin/wp-cli
  # Create working folder
  sudo mkdir -p /var/www/.wp-cli/cache/
  sudo chown -R www-data:www-data /var/www/.wp-cli/cache/

  # Summary
  echo -e "${BLUE}************************************${WHITE}"
  echo -e "WP-CLI is available.Use${YELLOW} wp${WHITE} command to use it"
  echo -e "${BLUE}************************************${WHITE}"
}

#######################################
# To start wordpress: this will populate database and initialize the main settings
# Arguments: None
# Outputs:   None
#######################################
function startWordpress() {
  echo -e "Starting up wordpress for the first time..."
  cd ${WEBSITE_ROOT}
  # Create configuration
  sudo -u www-data wp core config --dbname=${WP_DB_SCHEMA} --dbuser=${WP_DB_USER} --dbpass=${WP_DB_PASSWORD} --dbhost=localhost
  # Initialize tables + admin user
  sudo -u www-data wp core install --url="${WEBSITE_URL}" --title="${WP_TITLE}" --admin_user=${WP_ADMIN_USER} --admin_password=${WP_ADMIN_PASSWORD} --admin_email=${WP_ADMIN_EMAIL} --skip-email
}

#######################################
# To configure wordpress
# Arguments: None
# Outputs:   None
#######################################
function wordpressConfiguration() {
  echo -e "Applying wordpress core configuration + URL format"
  # Configure nice URLs
  sudo -u www-data wp option update permalink_structure /%postname%/
  # Date time
  sudo -u www-data wp option update time_format H:i
  sudo -u www-data wp option update date_format Y-m-d
  # Titles
  sudo -u www-data wp option update blogdescription "${WP_DESCRIPTION}"
}

########################################
# Install plugins (public ones)
# Arguments: None
# Outputs:   None
########################################
function wordpressPlugins() {
  echo -e "Adding Wordpress plugins"

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
}

########################################
# Install themes (public ones)
# Arguments: None
# Outputs:   None
########################################
function wordpressThemes() {
  echo -e "Managing Wordpress themes"

  echo -e "   * remove old themes"
  rm -rf ${WEBSITE_ROOT}/wp-content/twentyseventeen/
  rm -rf ${WEBSITE_ROOT}/wp-content/twentyeighteen/
  rm -rf ${WEBSITE_ROOT}/wp-content/twentynineteen/
  #rm -rf ${WEBSITE_ROOT}/wp-content/twentytwenty/

  echo -e "   * add new theme"
}


########################################
# Installation workflow
# >>>> METHOD TO EXECUTE <<<<
# Arguments: None
# Outputs:   None
########################################
function doWordpressInstallation() {
  ASSETS_PATH="./../assets"
  if [ $# -eq 1 ]; then
    ASSETS_PATH="$1/assets"
  fi
  export DEBIAN_FRONTEND=dialog

  createWordpressDatabase
  downloadWordpress
  createWordpressApache2configuration
  startWordpress
  wordpressConfiguration
  wordpressPlugins
  wordpressThemes
}



#***************************************************************************#
#***************************************************************************#
#****************                ROLLBACK                   ****************#
#***************************************************************************#
#***************************************************************************#

#######################################
# To delete wordpress user and database
# Arguments: None
# Outputs:   None
#######################################
function rollbackDatabase() {
  echo -e "Remove wordpress user and database"
  # Revoke rights
  mysql -u root -e "REVOKE ALL PRIVILEGES, GRANT OPTION FROM '${WP_DB_USER}'@'localhost'"
  mysql -u root -e "REVOKE ALL PRIVILEGES, GRANT OPTION FROM '${WP_DB_USER}'@'%'"
  # Remove user
  mysql -u root -e "DROP USER IF EXISTS '${WP_DB_USER}'"
  # Remove database
  mysql -u root -e "DROP database ${WP_DB_SCHEMA}"
  # Apply changes
  mysql -u root -e "FLUSH PRIVILEGES"
}

#######################################
# To delete wordpress Apache2 configuration
# Arguments: None
# Outputs:   None
#######################################
function rollbackApache2Configuration() {
  echo -e "Remove Apache2 configuration"
  # Disable configuration
  a2disconf ${WP_INSTALLATION_SLUG}
  systemctl reload apache2
  # Delete configuration
  rm /etc/apache2/conf-available/${WP_INSTALLATION_SLUG}.conf
}

#######################################
# To remove wordpress files
# Arguments: None
# Outputs:   None
#######################################
function rollbackInstallation() {
  echo -e "Remove wordpress files"
  rm --recursive --force ${WEBSITE_ROOT}
}

#######################################
# To perform rollback
# Arguments: None
# Outputs:   None
#######################################
function doRollback() {
  rollbackInstallation
  rollbackDatabase
  rollbackApache2Configuration
}



###### To test the script, just uncomment the following lines
source ./check_root_rights.sh
checkRootRights
doWordpressInstallation
#doRollback
