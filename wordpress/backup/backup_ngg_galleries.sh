#!/bin/bash
#########################################################
# Script to retrieve all NextGen Gallery and backup original photos for full re-import later on.
# @version 1.0 (2020-09)
# @author Guillaume Diaz
# @since 2020-09
#########################################################
#
# This script must be executed at the root of the wordpress blog
#
#########################################################

##### Global variables (they are populated by the functions)
declare -a galleries
# Get current IP @, do not change that line
WORDPRESS_ROOT=$(pwd)

#####
# Get galleries names
# Arguments: None
# Outputs:   array population 'galleries'
########################################
function getGalleries() {
  echo -e " "
  echo -e "List existing galleries..."

  for gallery_name in ${WORDPRESS_ROOT}/wp-content/gallery/*; do
    if [ -d "${gallery_name}" ]; then
      galleries+=(${gallery_name})
    fi
  done

  echo -e "    ${YELLOW}${#galleries[@]} galleries found${WHITE}"
  echo -e " "
}

#####
# To register photos files to save
# Arguments: 1. gallery path
# Outputs:   array population 'photos_files'
########################################
function getPhotosFiles() {
  echo -e " "
  echo -e "List photos..."

  # bash v4.4+
  #mapfile -d $'\0' photos_files < <(find ${WORDPRESS_ROOT}/wp-content/gallery/ -name "*.*_backup" -print0)

  # old bash (OVH server is v4.14 in 2020/09)
#  readarray -t photos_files < <(find ${WORDPRESS_ROOT}/wp-content/gallery/ -name "*.*_backup")
set +m
shopt -s lastpipe
photos_files=()
search_pattern="*.*_backup"
find . -name "${search_pattern}" -print0 | while IFS=  read -r -d $'\0'; do photos_files+=("$REPLY"); done; declare -p photos_files


  echo -e "    ${YELLOW}${#photos_files[@]} photos found${WHITE}"
  echo -e " "
}

# List galleries
getGalleries
echo -e "    Galleries:"
for gallery in "${galleries[@]}"; do
  echo -e " * ${gallery}"
done
echo -e " "
echo -e " "

# List files
getPhotosFiles
echo -e "    Files:"
for gallery in "${photos_files[@]}"; do
  echo -e "   * ${photos_files}"
done
echo -e " "
echo -e " "

echo -e " "
echo -e "Scan complete!"
echo -e " "
