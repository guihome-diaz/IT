!#/bin/bash

############################################################################
# Backup / restore features for Wordpress blog, NextGen Gallery plugin
############################################################################
# Script history:
# 2024/02: creation @Gdiaz
#
############################################################################

# To check if the given image file should be processed or not.
# A file is considered valid if does not belongs to *backup* or *thumbs* folder.
#
# @param $1: image complete filename
# @return 0 (true) if you should process the file ; 1 (false) otherwise
function isImageFileToProcess() {
  if [ $# -eq 0 ]; then
    # no arguments provided
    return 1
  fi

  # Extract file paths
  img_filename=$(basename "${1}")
  img_path=$(dirname "${1}")

  # Skip backup and thumbs files
  if [[ "${img_path}" =~ .*"backup"*. ]]; then
    return 1
  fi
  if [[ "${img_path}" =~ .*"thumbs"*. ]]; then
    return 1
  fi

  # All good!
  return 0
}


# To initialize the file/backup and file/thumbs directories if they do not already exist.
#
# @param $1: image complete filename
function initBackupAndThumbsDirectories() {
  img_path=$(dirname "${1}")
	mkdir -p "${img_path}/backup"
	mkdir -p "${img_path}/thumbs"
}


# To restore a previous backup file.
# This apply to a SINGLE FILE.
# Supported backup files:
#    - filename_backup
#    - ./backup/filename
#
# @param $1: image complete filename
# @return 0 (true) if a backup has been restored. 1 (false) in case no backup is available.
function restoreBackupFile() {
  img_filename=$(basename "${1}")
  img_path=$(dirname "${1}")

  # Restore from *_backup file
	if [[ -f "${img_path}/${img_filename}_backup" ]]; then
		echo -e "   .. restore original image from backup file: ${img_path}/${img_filename}_backup"
		rm "${1}"
		cp "${img_path}/${img_filename}_backup" "${1}"
		rm "${img_path}/${img_filename}_backup"
		return 0
	fi

	# restore from /backup/ folder
	if [[ -f "${img_path}/backup/${img_filename}" ]]; then
		echo -e "   .. restore original image from backup folder: ${img_path}/backup/${img_filename}"
		rm "${1}"
		cp "${img_path}/backup/${img_filename}" "${1}"
		return 0
	fi

  # No backup available
  return 1
}


# To restore a previous backups. This apply to a FOLDER AND ITS SUB-FOLDERS.
#
# @param $1: folder path. This folder will be scan and all images underneath will be restored.
# @return 0 (true) if process is ok ; 1 (false) in case of errors
function restoreAllImages() {
  if [ $# -eq 0 ]; then
    echo -e "Cannot restore backups! You must provide a root folder path."
    echo -e "  ex: /opt/blog/wp-content/gallery/2016"
    return 1
  fi

  image_folder=$1
  total_images=0
  restored_images=0
  for file in $(find ${image_folder} -type f -iname *.jpg); do
    # Skip backups or thumbs folders
    if isImageFileToProcess "${file}" ; then
      echo -e " >> skip backup or thumbs file: ${file}"
      continue
    fi
    total_images=$(( $total_images + 1 ))
    # Init directories
    initBackupAndThumbsDirectories "${file}"
    # Restore original image from backup
    if restoreBackupFile "${file}" ; then
      restored_images=$(( $restored_images + 1 ))
    fi
  done

  echo -e "${restored_images} restored images over ${total_images} images available."
  # all good
  return 0
}


# To backup an image into the ./backup/ folder
#
# @param $1: image complete filename
# @return 0 (true) if backup has been done ; 1 (false) in case of no backup
function backupImage() {
  # Extract file paths
  img_filename=$(basename "${1}")
  img_path=$(dirname "${1}")

	if [ ! -f "${img_path}/backup/${img_filename}" ]; then
		echo -e "   .. backup original image to ${img_path}/backup/${img_filename}"
		cp "${1}" "${img_path}/backup/${img_filename}"
	  return 0
	else
	  return 1
	fi
}


# To resize an image and create a thumbnail of it in ./thumbs/
#
# @param $1: image to process
# @param $2: size in px for resizing (this apply to the biggest side only)
# @return 0 (true) if backup has been done ; 1 (false) in case of no backup
function resizeImage() {
  if [ $# -eq 0 ]; then
    echo -e "Nothing to resize: no image provided"
    return 1
  fi

  # Extract file paths
  img_filename=$(basename "${1}")
  img_path=$(dirname "${1}")
  # Read image size
  img_width=$(/usr/bin/identify -format "%w" "${1}")> /dev/null
  img_height=$(/usr/bin/identify -format "%h" "${1}")> /dev/null
  echo -e "   .. Original dimensions: ${img_width} x ${img_height}"

  # --- 0. backup image before anything else ---
  backupImage "${1}"

	# --- 1. compute algo arguments ---
	# Apply the "x" param on the side you'd like
	# x | left => height is fixed
	# x | right => width is fixed
	resize_description="height"
	resize_param="x${resize_size}";
	thumbs_param="x${thumbs_size}";
	# Resize parameter. 0 => resize must apply. 1 => resize does not apply
	should_resize=1
  if [ "${img_width}" -gt "${img_height}" ]; then
    # Width management
    resize_description="width"
    resize_param="${resize_size}x";
    thumbs_param="${thumbs_size}x";
		if [ "${img_width}" -gt "${resize_size}" ]; then
		  should_resize=0
		fi
	elif [ "${img_height}" -gt "${resize_size}" ]; then
    # Height management
    should_resize=0
  fi

  # --- 2. Do resizing if required ---
  # This only occurs if original image side is bigger than resize_size (comparison in px)
  # remove base file and replace it with a resized one.
  if [ ${should_resize} -eq 0 ]; then
    echo -e "   .. resize ${resize_description} to ${resize_size}px"
    rm "${1}"
    /usr/bin/convert "${img_path}/backup/${img_filename}" -resize "${resize_param}" "${1}"
  fi

	# --- 3. Create thumb ---
	# remove previous thumb if present
  if [ -f "${img_path}/thumbs/thumbs_${img_filename}" ]; then
    rm "${img_path}/thumbs/thumbs_${img_filename}"
  fi
  # generate thumb
  echo -e "   .. create thumbnail"
  /usr/bin/convert "${file}" -resize "${thumbs_param}" "${img_path}/thumbs/thumbs_${img_filename}"
}