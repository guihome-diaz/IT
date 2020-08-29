#!/bin/bash
#
# Wordpress configuration
#*********************************
# Edit values to match your own configuration
#*********************************
#
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
WP_ADMIN_ADDRESS_STREET="82 route d'Arlon"
WP_ADMIN_ADDRESS_POSTCODE="1150"
WP_ADMIN_ADDRESS_CITY="Luxembourg"
WP_ADMIN_ADDRESS_COUNTRY="LU"

# Anti-spam Akismet
WP_AKISMET_KEY="ce78662c899c"

# Wordpress content
WP_TITLE="MiniXiongMao"
WP_DESCRIPTION="Every day is a wonder"

# Hide my site
WP_HIDE_MY_SITE_PAGE_TITLE="Private website"
WP_HIDE_MY_SITE_BANNER="This site is a private site. You must enter the access password"
WP_HIDE_MY_SITE_DURATION="360"
WP_HIDE_MY_SITE_BACKGROUND_IMAGE="https://www.qin-diaz.com/family/wp-content/uploads/2017/08/Teddy-bear-family-HD-wallpaper.jpg"
WP_HIDE_MY_SITE_PASSWORD="password"
WP_HIDE_MY_SITE_PASSWORD_HINT="Like us, but smaller"
WP_HIDE_MY_SITE_THEME="hmsbinder"

# NextGen Gallery
## Thumbnails
WP_NGG_THUMB_WIDTH="480"
WP_NGG_THUMB_HEIGHT="320"
WP_NGG_THUMB_QUALITY="100"
## Images
## Alternative setting: (in production up to 2020-09) width=1024, height=768)
WP_NGG_IMG_SIZE_WIDTH="1800"
WP_NGG_IMG_SIZE_HEIGHT="1200"
WP_NGG_IMG_QUALITY="100"
WP_NGG_IMG_BACKUP_ORIGINAL="1"
WP_NGG_IMG_AUTO_RESIZE="1"
# Ordering photos in gallery
WP_NGG_GALLERY_SORT_BY="imagedate"
WP_NGG_GALLERY_SORT_DIRECTION="ASC"
## Watermark
WP_NGG_WATERMARK_POS="botRight"
WP_NGG_WATERMARK_XPOS="5"
WP_NGG_WATERMARK_YPOS="5"
WP_NGG_WATERMARK_TYPE="text"
WP_NGG_WATERMARK_SIZE="10"
WP_NGG_WATERMARK_TEXT="© Daxiongmao.eu | 秦-diaz"
WP_NGG_WATERMARK_COLOR="ffffff"
WP_NGG_WATERMARK_OPAQUE="100"
WP_NGG_WATERMARK_AT_UPLOAD="1"
## Protection
## (i) Global protection will remove right click
WP_NGG_PROTECT_IMAGES="1"
WP_NGG_PROTECT_IMAGES_GLOBALLY="0"
# Pro settings
WP_NGG_STUDIO_NAME="Qin Diaz"
WP_NGG_THUMB_EFFECT="photocrati-nextgen_pro_lightbox"
