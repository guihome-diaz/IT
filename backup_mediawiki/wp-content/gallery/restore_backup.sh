#!/bin/bash

source ./functions/backup_restore_functions.sh

function usage() {
  echo -e " "
  echo -e "Script to restore backup images"
  echo -e " "
  echo -e "Objectives"
  echo -e "-------------------------------"
  echo -e "This script will:"
  echo -e "   1. remove ./thumbs and ./cache folders"
  echo -e "   2. restore original image from ./backup/\$img or ./\$img_backup [if available]"
  echo -e " "
  echo -e "Usage"
  echo -e "--------------------------------"
  echo -e "restore_backup.sh <pathToProcess>"
  echo -e "restore_backup.sh ~/www/family/wp-content/gallery/2016"
  echo -e " "
}

# Arg check
if [ ! $# -eq 1 ]; then
  echo -e "ERROR: You must provide all arguments."
  echo -e " "
  usage
  echo -e " "
  exit 1
fi

imageFolder=${1}

# Clear previous cache and thumbs
removeFolders "${imageFolder}"
# Restore all original images
restoreAllImages "${imageFolder}"

exit 0