#!/bin/bash
#
#################################
# Script to keep only the FULL quality pictures (*_backup)
# all smaller pictures will be removed
#
# version 1.0 - 2021/11 - @Guillaume Diaz
# version 2.0 - 2024/02 - @Guillaume Diaz 
#    work on all subfolders
##################################

base_directory="."

# Do insensitive case search
shopt -s nocaseglob
# Enable use of recursive globs (**)
shopt -s globstar

nb_backup_file=$(find ${base_directory} -type f -name *_backup | wc -l)
if [ $nb_backup_file -eq 0 ];then
        ### No backup files
        echo -e "Nb of pictures (no _backup files available)"
        find ${base_directory} -type f -iname *.jpg | wc -l
else
        ## There are some backup files.
        echo -e "Nb of full size pictures"
        find ${base_directory} -type f -iname *_backup | wc -l

        echo -e "Nb of pictures to remove"
        find ${base_directory} -type f -iname *.jpg | wc -l

        ### Business code
        echo -e "Delete resized pictures"
        find ${base_directory} -type f -iname *.jpg -delete

        echo -e "Rename full size pictures"
        for file in $(find ${base_directory} -type f -iname *_backup); do
			renamed_file=`echo ${file//"_backup"/}`
			echo -e "Rename file: ${file}  >> to >> ${renamed_file}"
			mv ${file} ${renamed_file}
        done
fi

echo -e "Remove thumbs, dynamic, cache folders"
find ${base_directory} -type d -name thumbs -exec rm -rf {} \; > /dev/null 2>&1
find ${base_directory} -type d -name dynamic -exec rm -rf {} \; > /dev/null 2>&1
find ${base_directory} -type d -name cache -exec rm -rf {} \; > /dev/null 2>&1

