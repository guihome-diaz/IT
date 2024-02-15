
#!/bin/bash

############################
# Simple script to zip all galleries by month
# @author Guillaume Diaz
# @version 1.0 2024/02
#########################

function usage() {
  echo -e " "
  echo -e "Script to compress all uploads by month"
  echo -e " "
  echo -e "Objectives"
  echo -e "-------------------------------"
  echo -e "This script will:"
  echo -e "   Zip all files from uploads_folder/01 to images_folder/12.zip"
  echo -e " "
  echo -e "Usage"
  echo -e "--------------------------------"
  echo -e "zip_uploads.sh <path> <year> <start_month>"
  echo -e "zip_uploads.sh ~/www/family/wp-content/uploads/2016 2016 1      - start from January"
  echo -e "zip_uploads.sh ~/www/family/wp-content/uploads/2018 2018 5      - start from May"
  echo -e " "
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

uploadsFolder=${1}
year=${2}
startMonth=${3}

for monthIndex in $(seq ${startMonth} 12);
do
  if [[ ${monthIndex} -lt 10 ]]; then
    echo -e "ZIP ${uploadsFolder}/0${monthIndex}*    to    ${uploadsFolder}/${year}_0${monthIndex}.zip"
    zip -r "${uploadsFolder}/0${monthIndex}.zip" ${uploadsFolder}/${year}_0${monthIndex}*
  else
    echo -e "ZIP ${uploadsFolder}/${monthIndex}*    to    ${uploadsFolder}/${year}_${monthIndex}.zip"
    zip -r "${uploadsFolder}/${monthIndex}.zip" ${uploadsFolder}/${year}_${monthIndex}*
  fi
done
