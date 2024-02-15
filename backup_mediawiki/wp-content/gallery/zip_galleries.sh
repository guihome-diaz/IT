#!/bin/bash

############################
# Simple script to zip all galleries by month
# @author Guillaume Diaz
# @version 1.0 2024/02
#########################

function usage() {
  echo -e " "
  echo -e "Script to compress all galeries by month"
  echo -e " "
  echo -e "Objectives"
  echo -e "-------------------------------"
  echo -e "This script will:"
  echo -e "   Zip all galeries from images_folder/<year>_01 to images_folder/<year>_01.zip"
  echo -e " "
  echo -e "Usage"
  echo -e "--------------------------------"
  echo -e "zip_all.sh <path> <year> <start_month>"
  echo -e "zip_all.sh \$(pwd) 2016 1      - start from January"
  echo -e "zip_all.sh ~/www/family/wp-content/gallery/2018 2018 5      - start from May"
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

imageFolder=${1}
year=${2}
startMonth=${3}




echo -e " "
echo -e " "
echo -e "---------------------------------------"
echo -e "Archiving process"
echo -e "---------------------------------------"
echo -e " "
echo -e " "

for monthIndex in $(seq ${startMonth} 12);
do
  if [[ ${monthIndex} -lt 10 ]]; then
    echo -e " "
    echo -e " "
    echo -e ">>>> Zip folders: ${imageFolder}/${year}_0${monthIndex}*   to  ${imageFolder}/${year}_0${monthIndex}.zip"
    echo -e " "
    echo -e " "
    zip -r "${imageFolder}/${year}_0${monthIndex}.zip" ${imageFolder}/${year}_0${monthIndex}_*
  else
    echo -e " "
    echo -e " "
    echo -e ">>>> Zip folders: ${imageFolder}/${year}_${monthIndex}*   to  ${imageFolder}/${year}_${monthIndex}.zip"
    echo -e " "
    echo -e " "
    zip -r "${imageFolder}/${year}_${monthIndex}.zip" ${imageFolder}/${year}_${monthIndex}_*
  fi
done

echo -e " "
echo -e " "
echo -e "---------------------------------------"
echo -e "All archives have been created."
echo -e "Everything is available under ${imageFolder}"
echo -e "---------------------------------------"
echo -e " "
echo -e " "