#!/bin/bash
#########################################################
# Script to retrieve all NextGen Gallery and backup original photos for full re-import later on.
# @version 1.0 (2020-09)
# @author Guillaume Diaz
# @since 2020-09
#########################################################
#
# This script must be executed at the root of the wordpress blog
#
#########################################################

echo -e " "
echo -e "List of galleries"
echo -e " "

#####
# Get galleries names
####
echo -e "    1. Get galleries names"
declare -a galleries
for gallery_name in wp-content/gallery/*; do
    if [ -d "${gallery_name}" ]; then
        # New gallery detected
        #echo -e " * ${gallery_name}"
        galleries+=(${gallery_name})
    fi
done

# List galleries
echo -e "    2. Array content"
for gallery in "${galleries[@]}"; do
        echo -e " * ${gallery}"
done

echo -e " "
echo -e "Scan complete!"
echo -e " "
