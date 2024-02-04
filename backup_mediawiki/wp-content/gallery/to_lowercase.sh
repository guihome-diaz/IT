#!/bin/bash
#
#################################
# Script to rename all files (only files) in lowercase.
# This script must be accompanied by a SQL request to set all files to lowercase.
#
#-- SQL requests to rename all galleries and pictures to lowercase
#-- Set all images files extension to lowercase
#UPDATE `family_blog_ngg_gallery` SET path = LOWER(path)
#UPDATE `family_blog_ngg_pictures` SET filename = LOWER(filename)
#
#
# version 1.0 - 2024/02 - @Guillaume Diaz
##################################

base_directory="."

# Do insensitive case search
shopt -s nocaseglob
# Enable use of recursive globs (**)
shopt -s globstar

for file in $(find ${base_directory} -type f); do
  renamed_file=`echo ${file,,}`
  echo -e "Rename file: ${file}  >> to >> ${renamed_file}"
  mv ${file} ${renamed_file}
done
