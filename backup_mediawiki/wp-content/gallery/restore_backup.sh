#!/bin/bash

source ./backup_restore_functions.sh

function usage() {
  echo -e " "
  echo -e "Script to restore backup images"
  echo -e " "
  echo -e "Objectives"
  echo -e "-------------------------------"
  echo -e "This script will:"
  echo -e "   1. remove ./thumbs and ./cache folders"
  echo -e "   2. restore original image from ./backup/\$img or ./\$img_backup [if available]"
  echo -e "   3. compute new images and thumbnails based on given sizes"
  echo -e " "
  echo -e "recommendations"
  echo -e "--------------------------------"
  echo -e "Set 1280px for the image size"
  echo -e "Set 300px for thumbnails size"
  echo -e " "
  echo -e "Usage"
  echo -e "--------------------------------"
  echo -e "restore_backup.sh <pathToProcess> <imageSizeInPx> <thumbnailSizeInPx>"
  echo -e "restore_backup.sh ~/www/family/wp-content/gallery/2016 1280 300"
  echo -e " "
}

# Arg check
if [ ! $# -eq 3 ]; then
  echo -e "ERROR: You must provide all arguments."
  echo -e " "
  usage
  echo -e " "
  exit 1
fi

imageFolder=${1}
imageSizeInPx=${2}
thumbnailSizeInPx=${3}

# Clear previous cache and thumbs
removeFolders "${imageFolder}"
# Restore all original images
restoreAllImages "${imageFolder}"
# Resize all images
resizeAllImages "${imageFolder}" "${imageSizeInPx}" "${thumbnailSizeInPx}"

exit 0