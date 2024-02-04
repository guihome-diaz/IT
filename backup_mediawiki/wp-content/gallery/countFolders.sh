#!/bin/bash

# To count the number of folders per year

echo -e " "
echo -e "#######################"
echo -e "# How many galleries? #"
echo -e "#######################"
echo -e " "
for year in {2016..2024}; do
    for month in {01..12}; do
        nb_galleries=$(ls ${year} | grep -E "${year}_${month}|${year}-${month}" | wc -l)
        #echo "     ls ${year} | grep -E \"${year}_${month}|${year}-${month}\" | wc -l"
        echo "  ${year}/${month}: ${nb_galleries}"
    done
    echo -e " "
done

echo -e " "
echo -e "Done!"
echo -e " "
echo -e " "
