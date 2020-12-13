#!/usr/bin/env bash
set -e
export DEBIAN_FRONTEND=dialog

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
# Before using it 'as is' please review and adjust the configuration file
# Set your own settings to apply
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
source ./wordpress_setup.conf

RED="\\033[0;31m"
RED_BOLD="\\033[1;31m"
BLUE="\\033[1;34m"
GREEN="\\033[0;32m"
WHITE="\\033[0;37m"
YELLOW="\\033[1;33m"
clear

# ********************************************* #
# ***              CONFIGURATION            *** #
# ********************************************* #
function listConfiguration() {
  echo -e " "
  echo -e " "
  echo -e " "
  echo -e " "
  echo -e " "
  echo -e "Wordpress website installation"
  echo -e " "
  echo -e "${BLUE}************************************${WHITE}"
  echo -e "${YELLOW}Configuration${WHITE}"
  echo -e "${BLUE}************************************${WHITE}"
  echo -e " "
  echo -e "  * slug                 : ${WP_INSTALLATION_SLUG}"
  echo -e "  * Website title        : ${WP_TITLE}"
  echo -e "  * Website short desc.  : ${WP_DESCRIPTION}"
  echo -e "  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  echo -e "  * installation path    : ${WEBSITE_ROOT}"
  echo -e "  * website URL          : ${WEBSITE_URL}"
  echo -e "  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  echo -e "  * database schema      : ${WP_DB_SCHEMA}"
  echo -e "  * database user        : ${WP_DB_USER}"
  echo -e "  * database pwd         : ${WP_DB_PASSWORD}"
  echo -e "  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  echo -e "  * wordpress admin user : ${WP_ADMIN_USER}"
  echo -e "  * wordpress admin pwd  : ${WP_ADMIN_PASSWORD}"
  echo -e "  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  echo -e "  * wordpress hide my ass password: ${WP_HIDE_MY_SITE_PASSWORD}"
  echo -e " "
  echo -e " "
}


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
# Arguments:
#   $1 = premium password
# Outputs:   /tmp/wp-plugins/  << folder with premium files
#######################################
function preparePremiumPlugins() {
  ppassword=$1

  rm -rf /tmp/wp-plugins
  # Copy zip files
  echo -e "        * Copy premium plugins"
  mkdir -p /tmp/wp-plugins
  cp ./plugins/pdf-embedder-premium.zip /tmp/wp-plugins
  cp ./plugins/pdf-thumbnails-premium.zip /tmp/wp-plugins
  cp ./plugins/nextgen-gallery-pro.zip /tmp/wp-plugins
  # Unzip
  echo -e "        * Unzip premium plugins"
  echo -e "            ... Like us_year.country ..."
  cd /tmp/wp-plugins
  unzip -P "${ppassword}" pdf-embedder-premium.zip
  unzip -P "${ppassword}" pdf-thumbnails-premium.zip
  unzip -P "${ppassword}" nextgen-gallery-pro.zip
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
# To check if WP CLI is installed or not ; install WP CLI if required ; then update
# Arguments: None
# Outputs:   None
#######################################
function checkAndInstallWpCli() {
  if ! command -v wp &>/dev/null; then
    echo "WP CLI is not installed"
    installWpCli
  fi

  echo "WP CLI update"
  sudo wp cli update

  echo -e " "
  echo -e "${WHITE}************************************"
  echo -e "${YELLOW}WP-CLI is ready${WHITE}"
  echo -e "${WHITE}************************************"
  echo -e " "
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
  sudo curl -O https://raw.githubusercontent.com/wp-cli/wp-cli/v2.4.0/utils/wp-completion.bash
  sudo chmod 755 /opt/wp-client/wp-completion.bash
  echo "source /opt/wp-client/wp-completion.bash" >>~/.bash_profile
  source ~/.bash_profile

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
  echo -e "Remove default plugin 'Hello Dolly'"
  sudo -u www-data wp plugin delete hello

  echo -e "Adding Wordpress plugins"
  echo -e "  (i) Since Wordpress 5.5 Gutenberg [block editor] + Site Health are included in the default bundle"
  echo -e " "

  ############# Security
  echo -e "        * akismet comments anti-spam"
  sudo -u www-data wp plugin install akismet
  sudo -u www-data wp option add wordpress_api_key ${WP_AKISMET_KEY}
  sudo -u www-data wp plugin activate akismet

  echo -e "        * Hide my site"
  sudo -u www-data wp plugin install hide-my-site
  sudo -u www-data wp plugin activate hide-my-site
  sudo -u www-data wp option add hide_my_site_pagetitle "${WP_HIDE_MY_SITE_PAGE_TITLE}"
  sudo -u www-data wp option add hide_my_site_custom_messaging_banner "${WP_HIDE_MY_SITE_BANNER}"
  sudo -u www-data wp option add hide_my_site_password "${WP_HIDE_MY_SITE_PASSWORD}"
  sudo -u www-data wp option add hide_my_site_password_hint "${WP_HIDE_MY_SITE_PASSWORD_HINT}"
  sudo -u www-data wp option add hide_my_site_enabled 1
  sudo -u www-data wp option add hide_my_site_mobile_friendly_check 1
  sudo -u www-data wp option add hide_my_site_bruteforce 1
  sudo -u www-data wp option add hide_my_site_allow_admin 1
  sudo -u www-data wp option add hide_my_site_duration "${WP_HIDE_MY_SITE_DURATION}"
  sudo -u www-data wp option add hide_my_site_custom_background_image_upload "${WP_HIDE_MY_SITE_BACKGROUND_IMAGE}"
  sudo -u www-data wp option add hide_my_site_current_theme "${WP_HIDE_MY_SITE_THEME}"
  sudo -u www-data wp option add hide_my_site_ihmsa "hmsia"

  ############# User communication
  echo -e "        * Better Notifications for WP [bnfw]"
  sudo -u www-data wp plugin install bnfw
  sudo -u www-data wp plugin activate bnfw

  echo -e "        * Contact Form 7"
  sudo -u www-data wp plugin install contact-form-7
  sudo -u www-data wp plugin activate contact-form-7
  # Contact form depends on *_POST.post_type = 'wpcf7_contact_form'

  ############# Content
  echo -e "        * Classic text editor (before Gutenberg project)"
  echo -e "          Default editor stays 'block' but user can choose to use the classic editor instead"
  sudo -u www-data wp plugin install classic-editor
  sudo -u www-data wp plugin activate classic-editor
  # Let user choose the editor
  sudo -u www-data wp option add classic-editor-allow-users allow
  sudo -u www-data wp option add classic-editor-replace block

  echo -e "        * TinyMC Advanced (extended features for both classic and block editors)"
  echo -e "          Use block 'classic paragraph' to enjoy TinyMCE"
  sudo -u www-data wp plugin install tinymce-advanced
  sudo -u www-data wp plugin activate tinymce-advanced

  echo -e "        * Timeline Express"
  sudo -u www-data wp plugin install timeline-express
  sudo -u www-data wp plugin activate timeline-express

  echo -e "        *  WordPress Media Library Folders (to scan folders for new medias)"
  sudo -u www-data wp plugin install media-library-plus
  sudo -u www-data wp plugin activate media-library-plus

  echo -e "        * NextGEN Gallery"
  sudo -u www-data wp plugin install nextgen-gallery
  sudo -u www-data wp plugin activate nextgen-gallery
  # Create gallery folder
  sudo -u www-data mkdir -p ${WEBSITE_ROOT}/wp-content/gallery
  # Watermark
  sudo -u www-data wp ngg settings edit watermark_automatically_at_upload "${WP_NGG_WATERMARK_AT_UPLOAD}"
  sudo -u www-data wp ngg settings edit wmPos "${WP_NGG_WATERMARK_POS}"
  sudo -u www-data wp ngg settings edit wmXpos "${WP_NGG_WATERMARK_XPOS}"
  sudo -u www-data wp ngg settings edit wmYpos "${WP_NGG_WATERMARK_YPOS}"
  sudo -u www-data wp ngg settings edit wmType "${WP_NGG_WATERMARK_TYPE}"
  sudo -u www-data wp ngg settings edit wmSize "${WP_NGG_WATERMARK_SIZE}"
  sudo -u www-data wp ngg settings edit wmText "${WP_NGG_WATERMARK_TEXT}"
  sudo -u www-data wp ngg settings edit wmColor "${WP_NGG_WATERMARK_COLOR}"
  sudo -u www-data wp ngg settings edit wmOpaque "${WP_NGG_WATERMARK_OPAQUE}"
  # Thumbnails
  sudo -u www-data wp ngg settings edit thumbwidth "${WP_NGG_THUMB_WIDTH}"
  sudo -u www-data wp ngg settings edit thumbheight "${WP_NGG_THUMB_HEIGHT}"
  sudo -u www-data wp ngg settings edit thumbquality "${WP_NGG_THUMB_QUALITY}"
  sudo -u www-data wp ngg settings edit thumbfix "0"

  # Images
  sudo -u www-data wp ngg settings edit imgWidth "${WP_NGG_IMG_SIZE_WIDTH}"
  sudo -u www-data wp ngg settings edit imgHeight "${WP_NGG_IMG_SIZE_HEIGHT}"
  sudo -u www-data wp ngg settings edit imgQuality "${WP_NGG_IMG_QUALITY}"
  sudo -u www-data wp ngg settings edit imgBackup "${WP_NGG_IMG_BACKUP_ORIGINAL}"
  sudo -u www-data wp ngg settings edit imgAutoResize "${WP_NGG_IMG_AUTO_RESIZE}"
  # Protection
  sudo -u www-data wp ngg settings edit protect_images "${WP_NGG_PROTECT_IMAGES}"
  sudo -u www-data wp ngg settings edit protect_images_globally "${WP_NGG_PROTECT_IMAGES_GLOBALLY}"

  # Gallery ordering
  sudo -u www-data wp ngg settings edit galSort "${WP_NGG_GALLERY_SORT_BY}"
  sudo -u www-data wp ngg settings edit galSortDir "${WP_NGG_GALLERY_SORT_DIRECTION}"

  echo -e "        * Simple page ordering"
  sudo -u www-data wp plugin install simple-page-ordering
  sudo -u www-data wp plugin activate simple-page-ordering

  echo -e "        * WP Add Custom CSS (to use your own CSS on a post, page or the whole website)"
  sudo -u www-data wp plugin install wp-add-custom-css
  sudo -u www-data wp plugin activate wp-add-custom-css

  ############### Performances
  echo -e "        * Disable User Gravatar"
  # Removing a call to 3rd party service makes the website more resistant + it also avoid timeouts and long waiting time (for ex. in China)
  sudo -u www-data wp plugin install disable-user-gravatar
  sudo -u www-data wp plugin activate disable-user-gravatar

  ############# Premium plugins
  #### PDF premium
  echo -e "        * PDF embedder premium"
  sudo -u www-data wp plugin install /tmp/wp-plugins/pdf-embedder-premium/pdf-embedder-premium.zip
  sudo -u www-data wp plugin activate PDFEmbedder-premium

  echo -e "        * PDF thumbnails premium"
  sudo -u www-data wp plugin install /tmp/wp-plugins/pdf-thumbnails-premium/pdf-thumbnails-premium.zip
  sudo -u www-data wp plugin activate PDFThumbnails-premium

  echo -e "        * NextGEN Gallery PRO"
  sudo -u www-data wp plugin install /tmp/wp-plugins/nextgen-gallery-pro/nextgen-gallery-pro.zip
  sudo -u www-data wp plugin activate nextgen-gallery-pro
  # Thumbnails
  sudo -u www-data wp ngg settings edit thumbEffect "${WP_NGG_THUMB_EFFECT}"
  # Ecommerce settings
  sudo -u www-data wp ngg settings edit ecommerce_studio_name "${WP_NGG_STUDIO_NAME}"
  sudo -u www-data wp ngg settings edit ecommerce_studio_email "${WP_ADMIN_EMAIL}"
  sudo -u www-data wp ngg settings edit ecommerce_email_notification_recipient "${WP_ADMIN_EMAIL}"
  sudo -u www-data wp ngg settings edit ecommerce_studio_street_address "${WP_ADMIN_ADDRESS_STREET}"
  sudo -u www-data wp ngg settings edit ecommerce_studio_city "${WP_ADMIN_ADDRESS_CITY}"
  sudo -u www-data wp ngg settings edit ecommerce_home_zip "${WP_ADMIN_ADDRESS_POSTCODE}"
  sudo -u www-data wp ngg settings edit ecommerce_home_country "${WP_ADMIN_ADDRESS_COUNTRY}"
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
# Arguments:
#   $1 = premium password
# Outputs:   None
########################################
function doWordpressInstallation() {
  echo -e " "
  echo -e "${WHITE}************************************"
  echo -e "${YELLOW}Installation start${WHITE}"
  echo -e "${WHITE}************************************"
  echo -e " "

  ppassword="$1"

  preparePremiumPlugins "${ppassword}"
  createWordpressDatabase
  downloadWordpress
  createWordpressApache2configuration
  startWordpress
  wordpressConfiguration
  wordpressPlugins
  wordpressThemes

  echo -e " "
  echo -e "${WHITE}************************************"
  echo -e "${YELLOW}Installation complete${WHITE}"
  echo -e "${WHITE}************************************"
  echo -e " "
}

#***************************************************************************#
#***************************************************************************#
#****************                ROLLBACK                   ****************#
#***************************************************************************#
#***************************************************************************#

#######################################
# To delete wordpress user and database
# (i) this will not fail in case of error(s)
# Arguments: None
# Outputs:   None
#######################################
function rollbackDatabase() {
  echo -e "Remove wordpress user and database"
  # Revoke rights
  mysql -u root -f -e "REVOKE ALL PRIVILEGES, GRANT OPTION FROM '${WP_DB_USER}'@'localhost'"
  mysql -u root -f -e "REVOKE ALL PRIVILEGES, GRANT OPTION FROM '${WP_DB_USER}'@'%'"
  # Remove user
  mysql -u root -f -e "DROP USER IF EXISTS '${WP_DB_USER}'"
  # Remove database
  mysql -u root -f -e "DROP database ${WP_DB_SCHEMA}"
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
  echo -e " "
  echo -e "${WHITE}************************************"
  echo -e "${YELLOW}Rollback start${WHITE}"
  echo -e "${WHITE}************************************"
  echo -e " "

  rollbackInstallation
  rollbackDatabase
  rollbackApache2Configuration

  echo -e " "
  echo -e "${WHITE}************************************"
  echo -e "${YELLOW}Rollback complete${WHITE}"
  echo -e "${WHITE}************************************"
  echo -e " "
}

###### To test the script, just uncomment the following lines
source ./check_root_rights.sh

# display configuration
listConfiguration

##################################
# Retrieve user input
##################################
if [ $# -eq 0 ]; then
    echo -e "${RED}**************************${WHITE}"
    echo -e "${RED}*          ERROR         *${WHITE}"
    echo -e "${RED}**************************${WHITE}"
    echo -e "You did not pass any command arguments. You must give a password"
    echo -e " "
    echo -e "usage: ${YELLOW}./wordpress_setup.sh ${BLUE}-p${WHITE} premiumPluginPasswordClearText"
    echo -e " "
    exit 1
fi

while getopts p:h: option
do
  case "${option}" in
    p)
      premiumPassword=${OPTARG}
      ;;
    *)
      echo "usage wordpress_setup.sh -p premiumPluginPasswordClearText"
      exit 1
      ;;
  esac
done

checkRootRights
checkAndInstallWpCli
doRollback
doWordpressInstallation "${premiumPassword}"
