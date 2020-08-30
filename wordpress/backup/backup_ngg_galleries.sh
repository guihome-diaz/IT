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
declare -a photos_files
photos_index=0

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

  # This is for bash v4.3 and earlier
  # The OVH server is still running bash v4.14 (2020-08)
  while IFS=  read -r -d $'\0'; do
    photos_files+=("${REPLY}")
  done < <(find "${WORDPRESS_ROOT}/wp-content/gallery/" -name "*.*_backup" -type f -print0)

  #find_photos=$(find "${WORDPRESS_ROOT}/wp-content/gallery/" -name "*.*_backup" -type f)
  #for photo_file in ${find_photos}; do
  #  photos_files[${photos_index}]="${photo_file}"
  #  photos_index=$(( photos_index + 1 ))
  #  echo -e "   * ${photo_file}"
  #done

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
for photo_file in "${photos_files[@]}"; do
  echo -e "   * ${photo_file}"
done
echo -e " "
echo -e " "

echo -e " "
echo -e "Scan complete!"
echo -e " "
