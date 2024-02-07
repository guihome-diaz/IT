#!/bin/bash

############################################################################
# Backup / restore features for Wordpress blog, NextGen Gallery plugin
############################################################################
# Script history:
# 2024/02: creation @Gdiaz
#
############################################################################

# To remove a folder that has the given pattern
#
# @param $1: folder name to remove (ex: thumbs / cache)
function removeFolders() {
  if [ $# -eq 0 ]; then
      echo -e "You must provide a path to clear"
      echo -e "ex: /opt/blog/wp-content/gallery/2016"
      return 1
    fi

    search_path="${1}"
    for folder in $(find ${search_path} -type d -iname *thumbs*); do
		  echo -e "   .. remove thumbs folder: ${folder}"
      rm -rf "${folder}"
    done;
    for folder in $(find ${search_path} -type d -iname *cache*); do
		  echo -e "   .. remove cache folder: ${folder}"
      rm -rf "${folder}"
    done;
}

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

  # Skip backup, thumbs and cache folders
  if [[ "${img_path}" =~ .*"backup"*. ]]; then
    return 1
  fi
  if [[ "${img_path}" =~ .*"thumbs"*. ]]; then
    return 1
  fi
  if [[ "${img_path}" =~ .*"cache"*. ]]; then
    return 1
  fi
  if [[ "${img_path}" =~ .*"watermark"*. ]]; then
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
	mkdir -p "${img_path}/cache"
	mkdir -p "${img_path}/watermark"
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

  # Check if backup is available
  backup_file="";
	if [[ -f "${img_path}/${img_filename}_backup" ]]; then
	  backup_file="${img_path}/${img_filename}_backup"
	elif [[ -f "${img_path}/backup/${img_filename}" ]]; then
    backup_file="${img_path}/backup/${img_filename}"
  fi

  if [[ -z "${backup_file}" ]]; then
    # no backup available
		echo -e "[DEBUG]     .. ${1}     | skipped | no backup available"
    return 1
  fi

  #Ensure backup size is bigger than current one
  backup_file_size=`wc -c "${backup_file}" | cut -d' ' -f1`
  original_file_size=`wc -c "${1}" | cut -d' ' -f1`

  if [ ${backup_file_size} -gt ${original_file_size} ];then
		echo -e "[DEBUG]     .. ${1}     | restored | restored from original image: ${backup_file}"
		rm "${1}"
		cp "${backup_file}" "${1}"
		rm "${backup_file}"
		return 0
	else
	  echo -e "[DEBUG]     .. ${1}     | unchanged | backup was smaller than original file size"
		rm "${backup_file}"
		return 1
	fi
}


# To restore a previous backup. This apply to a FOLDER AND ITS SUB-FOLDERS.
#
# @param $1: folder path. This folder will be scan and all images underneath will be restored.
# @return 0 (true) if process is ok ; 1 (false) in case of errors
function restoreAllImages() {
  if [ $# -eq 0 ]; then
    echo -e "[ERROR] Cannot restore backups! You must provide a root folder path."
    echo -e "[ERROR]   ex: /opt/blog/wp-content/gallery/2016"
    return 1
  fi

  image_folder="${1}"
  echo -e "[INFO] Restore all original images from their respective backup (if available). Folder to process: ${image_folder}"

  total_images=0
  restored_images=0
  for file in $(find ${image_folder} -type f -iname *.jpg); do
    # Skip backups or thumbs folders
    if ! isImageFileToProcess ${file}; then
      echo -e "[DEBUG]     .. ${file}     | skipped | ignore backup, thumbs or cache file"
      continue
    fi
    total_images=$(( $total_images + 1 ))
    # Restore original image from backup
    if restoreBackupFile "${file}"; then
      restored_images=$(( $restored_images + 1 ))
    fi
  done

  echo -e "[INFO] ${restored_images} restored images over ${total_images} images available."
  # all good
  return 0
}

# To restore a previous backup. This apply to a FOLDER AND ITS SUB-FOLDERS.
#
# @param $1: folder path. This folder will be scan and all images underneath will be restored.
# @return 0 (true) if process is ok ; 1 (false) in case of errors
function resizeAllImages() {
  if [ $# -eq 0 ]; then
    echo -e "[WARNING] Nothing to resize: no image folder provided"
    return 1
  fi
  if [ ! $# -eq 3 ]; then
    echo -e "[WARNING] Cannot resize. You must provide the filename, expected size (in px) and thumbnail size (in px)"
    return 1
  fi

  image_folder="${1}"
  resize_size=${2}
  thumbs_size=${3}
  echo -e "[INFO] Resize all images. Folder to process: ${image_folder}"

  total_images=0
  resized_images=0
  for file in $(find ${image_folder} -type f -iname *.jpg); do
    # Skip backups or thumbs folders
    if ! isImageFileToProcess ${file}; then
      echo -e "[DEBUG]     .. ${file}     | skipped | ignore backup, thumbs or cache file"
      continue
    fi
    initBackupAndThumbsDirectories "${file}"
    total_images=$(( $total_images + 1 ))
    # Restore original image from backup
    if resizeImage "${file}" "${resize_size}" "${thumbs_size}"; then
      resized_images=$(( resized_images + 1 ))
    fi
  done

  echo -e "[INFO] ${resized_images} resized images over ${total_images} images available."
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
		echo -e "[DEBUG]     .. backup original image to ${img_path}/backup/${img_filename}"
		cp "${1}" "${img_path}/backup/${img_filename}"
	  return 0
	else
	  return 1
	fi
}


# To resize an image. This will:
# - backup the original image in ./backup/__image_name__
# - create a new image thumbnail in ./thumbs/__image_name__
#
# @param $1: image to process
# @param $2: size in px for resizing (this apply to the biggest side only). Ex:
# @param $3: size in px for thumbnail (this apply to the biggest side only)
# @return 0 (true) if backup has been done ; 1 (false) in case of no backup
function resizeImage() {
  if [ $# -eq 0 ]; then
    echo -e "[WARNING] Nothing to resize: no image file provided"
    return 1
  fi
  if [ ! $# -eq 3 ]; then
    echo -e "[WARNING] Cannot resize. You must provide the filename, expected size (in px) and thumbnail size (in px)"
    return 1
  fi
  echo -e "[INFO]   .. processing image ${1}"

  # Extract file paths
  img_filename=$(basename "${1}")
  img_path=$(dirname "${1}")
  # Extract sizes
  resize_size=${2}
  thumbs_size=${3}
  # Read image size
  img_width=$(/usr/bin/identify -format "%w" "${1}")> /dev/null
  img_height=$(/usr/bin/identify -format "%h" "${1}")> /dev/null
  echo -e "[DEBUG]     .. Original image dimensions: ${img_width} x ${img_height}"

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
    echo -e "[DEBUG]     .. resize image [${resize_description}: ${resize_size} px]"
    rm "${1}"
    ### Resize without watermark
    /usr/bin/convert "${img_path}/backup/${img_filename}" -resize "${resize_param}" "${1}"

    echo -e "[DEBUG]     .. apply watermark"
    ### Apply watermark (see https://www.imagemagick.org/Usage/annotating/#wmark_text)
    # Create new image with text that will be placed at the bottom of the image
    # -fill white -undercolor '#00000080' -gravity South -annotate +0+0 'Qin Diaz ©'
    # where 'gravity' indicates where to put the watermark (NorthWest, NorthEast, SouthWest, SouthEast)
    #
    #convert "${1}" -background transparent -fill grey -font Calibri -size 140x80 -pointsize 14 -gravity southeast -annotate +0+0 'copyright text' output.jpg
    convert "${1}" -fill white -undercolor '#00000080' -pointsize 14 -gravity South -annotate +0+0 'QIN-DIAZ.COM ©' "${img_path}/watermark/${img_filename}"
  fi

	# --- 3. Create thumb ---
	# remove previous thumb if present
  if [ -f "${img_path}/thumbs/thumbs_${img_filename}" ]; then
    echo -e "[DEBUG]     .. remove previous thumbnail"
    rm "${img_path}/thumbs/thumbs_${img_filename}"
  fi
  # generate thumb
  echo -e "[DEBUG]     .. create thumbnail [${resize_description}: ${thumbs_param} px]"
  /usr/bin/convert "${file}" -resize "${thumbs_param}" "${img_path}/thumbs/thumbs_${img_filename}"

  return 0
}