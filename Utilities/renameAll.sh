#!/bin/bash
# Convert filenames to lowercase
# and replace characters recursively
#####################################

# Source: StackOverflow

clear

# Check arguments
if [ -z $1 ] 
	then 
	echo " "
	echo "!!!!!!!!!!!!!!! ERROR !!!!!!!!!!!!!!!!!!!"
	echo "You must provide a directory to process"
	echo " "
	echo "Usage: "
	echo "./renameAll /home/guillaume/myFolder"
	echo " "
	exit 1
fi

# Go over the source directory recursively
find "$1" -depth -name '*' | while read file ; do
        directory=$(dirname "$file")
        oldfilename=$(basename "$file")
        newfilename=$(echo "$oldfilename" | tr 'A-Z' 'a-z' | tr ' ' '_' | sed 's/_-_/-/g')
        if [ "$oldfilename" != "$newfilename" ]; then
                mv -i "$directory/$oldfilename" "$directory/$newfilename"
                echo ""$directory/$oldfilename" ---> "$directory/$newfilename""
        fi
        done
exit 0

