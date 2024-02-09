#!/bin/bash

source ./functions/backup_restore_functions.sh

function usage() {
  echo -e " "
  echo -e "Script to restore backup images"
  echo -e " "
  echo -e "Objectives"
  echo -e "-------------------------------"
  echo -e "This script will resize all images based on given sizes"
  echo -e "  original images are saved in <img>/backup folder"
  echo -e "  it will generate thumbnails as well"
  echo -e "Please note that all resized images have a watermark."
  echo -e
  echo -e " "
  echo -e "recommendations"
  echo -e "--------------------------------"
  echo -e "Set 1280px for the image size"
  echo -e "Set 300px for thumbnails size"
  echo -e " "
  echo -e "Usage"
  echo -e "--------------------------------"
  echo -e "resize_all_images.sh <pathToProcess> <imageSizeInPx> <thumbnailSizeInPx>"
  echo -e "resize_all_images.sh ~/www/family/wp-content/gallery/2016 1280 300"
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

# Resize all images
resizeAllImages "${imageFolder}" "${imageSizeInPx}" "${thumbnailSizeInPx}"

exit 0