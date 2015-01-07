#!/bin/bash
# Resize photos in HD resolution, ready to be send over Internet
#
# Author: Guillaume Diaz
# Version: 1.0 - January 2015
##################################################################

RED="\\033[1;31m"
GREEN="\\033[0;32m"
WHITE="\\033[0;37m"
YELLOW="\\033[1;33m"

clear

# Check arguments
if [ $# -ne 2 ] 
	then 
	echo -e "$RED_BOLD "
	echo "!!!!!!!!!!!!!!! ERROR !!!!!!!!!!!!!!!!!!!"
	echo "You must provide 2 arguments:"
	echo "   $1 == source directory to process"
	echo "   $2 == output directory to save files"
	echo " "
	echo "Usage: "
	echo "./resizeImages sourceDirectory  outputDirectory"
	echo -e "$WHITE "
	exit 1
fi

# Temp folder that will handle transformations...
echo " "
echo -e "$YELLOW... Processing files, please wait...$WHITE"
echo "In case of error please check /tmp/photos"
echo " "
TEMP_DIR="/tmp/photos"
mkdir -p $TEMP_DIR/HD1080
mkdir -p $TEMP_DIR/HD720

# Go over the source directory recursively
find "$1" -depth -type f -name '*' | while read file
	do
		# File properties
        directory=$(dirname "$file")
        fullname=$(basename "$file")
        extension="${fullname##*.}"
		name="${fullname%.*}"

		# Create temp targets
		mkdir -p $TEMP_DIR/HD1080/$directory
		mkdir -p $TEMP_DIR/HD720/$directory

		# Get image size
		file_width=`identify -ping -format "%w" $directory/$fullname`
		file_height=`identify -ping -format "%h" $directory/$fullname`


		##### Transformation details #####
		# Filter spline produces better graphics and keep lights
		# Only resize if original is bigger than the target size (operator -resize \>)
		# Unsharp settings are a bit of taste... 
		#  GIMP value:                -unsharp 0x0.75+0.75+0.008
		#  IM recommendations:        -unsharp 1.5x1+0.7+0.02
		###################################

		# Ensure file is an image
		if [[ ! -z $file_width ]]
		then
			if [ $file_width -ge $file_height ]
			then
				echo "processing horizon. file: $directory/$fullname"
				convert -filter spline -resize 1920x1080\> -unsharp 1.5x1+0.7+0.02 $directory/$fullname $TEMP_DIR/HD1080/$directory/$name-HD1080.$extension
				convert -filter spline -resize 1280x720\> -unsharp 1.5x1+0.7+0.02 $directory/$fullname $TEMP_DIR/HD720/$directory/$name-HD720.$extension
			else
				echo "processing vertical file: $directory/$fullname"
				convert -filter spline -resize 1080x1920\> -unsharp 1.5x1+0.7+0.02 $directory/$fullname $TEMP_DIR/HD1080/$directory/$name-HD1080.$extension
				convert -filter spline -resize 720x1280\> -unsharp 1.5x1+0.7+0.02 $directory/$fullname $TEMP_DIR/HD720/$directory/$name-HD720.$extension
			fi
		fi

    done


# Move back the resize photos
mv $TEMP_DIR $2/resize_photos
echo -e "$GREEN "
echo ":) OPERATION COMPLETE !"
echo -e "$WHITE "
echo "Files are now available in $2resize_photos"
echo " "

exit 0

