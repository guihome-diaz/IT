#!/bin/bash

# Script to turn videos



RED="\\033[0;31m"
RED_BOLD="\\033[1;31m"
BLUE="\\033[1;34m"
GREEN="\\033[0;32m"
WHITE="\\033[0;37m"
YELLOW="\\033[1;33m"



#####################
FFMPEG=`which ffmpeg`
FFPROBE=`which ffprobe`


# To detect the video orientation: landscape / portrait
# Usage: getVideoOrientation <String: videoPath>
#
# @param $1 String, path of the video to analyse
# @return boolean. TRUE (0) for PORTRAIT orientation ; FALSE(1) for LANDSCAPE orientation
function isPortraitOrientation() {
    VIDEO_TO_ANALYSE=$1

    VIDEO_METADATAS=`$FFPROBE $VIDEO_TO_ANALYSE 2>&1 | egrep 'Stream #0:0'`;
#    echo "Metadatas: $VIDEO_METADATAS"

    # get field: 640×360 [PAR 1:1 DAR 16:9]
    IFS=',' read -r -a PROPS <<< "$VIDEO_METADATAS"
    for PROP in "${PROPS[@]}"; 
    do
	if [[ $PROP == *"1920x1080"* ]] || [[ $PROP == *"[SAR"* ]]; then
    	   RESOLUTION_FIELD=$PROP
#           echo "Resolution line: $RESOLUTION_FIELD"
	fi
    done

    # get resolution parts: 640×360
    IFS=' ' read -r -a ITEMS <<< "$RESOLUTION_FIELD"
    RESOLUTION_ITEM=${ITEMS[0]}
#    echo "Resolution item: $RESOLUTION_ITEM"
	    
    # get X,Y values
    IFS='x' read -r -a DIMENSIONS <<< "$RESOLUTION_ITEM"
    RES_X=${DIMENSIONS[0]};
    RES_Y=${DIMENSIONS[1]};
#    echo "Resolution values: $RES_X:$RES_Y"
    
    # Compute orientation
    if [ "$RES_X" -gt "$RES_Y" ]
    then
        ORIENTATION="Landscape: $RES_X x $RES_Y"
    	# 1 = false
    	IS_PORTRAIT=1
    else
        ORIENTATION="Portrait: $RES_X x $RES_Y"
    	# 0 = true
    	IS_PORTRAIT=0
    fi
#    echo "Orientation: $ORIENTATION"
    return $IS_PORTRAIT
}


# To list the videos files that are inside the current directory
# @return list of videos files (array)
function listFiles() {
	echo -e "$BLUE... looking for videos files in the folder (.mov, .mp4, .m4v)$WHITE"
	for file in *.mov *.mp4 *.m4v; do
		VIDEOS_FILES=("${VIDEOS_FILES[@]}" $file)
	done
	echo -e "    ${#VIDEOS_FILES[@]} videos files have been found"

	#printf 'List of videos files:\n'
	#printf '  * %s\n' "${VIDEOS_FILES[@]}"
}


# To ask the user to choose how to rotate each file, if required. 
# @param list of videos files (array)
# @return user's actions
function askForActions() {
	echo -e " "
	echo -e " "
	echo -e "$BLUE... Definition of the actions$WHITE"
	for file in "${VIDEOS_FILES[@]}"; do
		echo -e " "
	    echo -e "Analysing$YELLOW $file $WHITE"
		PS3='What do you want to do?'

		## Choose how to turn the file
	    options=("no_turn" "turn_left" "turn_right" "Quit")
	    select opt in "${options[@]}"
	    do
	        case "$opt,$REPLY" in
	            no_turn,*|*,no_turn)
	                echo -e "   |You choose: No turn"
					VIDEOS_ACTIONS=("${VIDEOS_ACTIONS[@]}" "no_turn")
	                break
	                ;;
	            turn_left,*|*,turn_left)
	                echo -e "   |You choose: Left turn"
					VIDEOS_ACTIONS=("${VIDEOS_ACTIONS[@]}" "left_turn")
	                break
	                ;;
	            turn_right,*|*,turn_right)
	                echo -e "   |You choose: Right turn"
					VIDEOS_ACTIONS=("${VIDEOS_ACTIONS[@]}" "right_turn")
	                break
	                ;;
	            quit,*|*,quit)
	                exit 2
	                ;;
	            *) 
	                echo "invalid option, try something else!"
	                ;;
	        esac
	    done
	done


	# SUMMARY
	echo -e " "
	echo -e " "
	echo -e "$BLUE... Summary$WHITE"
	printf "    %30s | Action\n-----------------------------------------------\n" "File"
	for i in "${!VIDEOS_FILES[@]}"; do 
	  printf "    %30s | %s\n" "${VIDEOS_FILES[$i]}" "${VIDEOS_ACTIONS[$i]}"
	done
}

function legacyProcessing() {
	for file in *.mov *.mp4 *.m4v; do
	    echo -e " "
	    echo -e " "
	    echo -e " "
	    echo -e "--------------------------------------------------"
	    echo -e "$BLUE You're about to process a new video file$WHITE"
	    echo -e "   * File: $YELLOW$file$WHITE"
	    if isPortraitOrientation $file
	        then
	            echo -e "   * Orientation: Portrait"
	        else
	            echo -e "   * Orientation: Landscape"
	    fi
	    echo -e "--------------------------------------------------"
	    PS3='What whould you like to do?'
	    options=("no_turn" "turn_left" "turn_right" "skip" "Quit")
	    select opt in "${options[@]}"
	    do
	        case "$opt,$REPLY" in
	            no_turn,*|*,no_turn)
	                echo -e "|$GREEN  No turn  $WHITE| >> Adjusting resolution, no turn  ... please wait, processing is ongoing ..."
	                ffmpeg -i $file -vcodec libx264 processResults/$file >/dev/null 2>&1
	                break
	                ;;
	            turn_left,*|*,turn_left)
	                echo -e "|$GREEN Left turn $WHITE| >> Adjusting resolution, left turn (counter-clockwise)   ... please wait, processing is ongoing ..."
	                ffmpeg -i $file -vf "transpose=cclock" -vcodec libx264 processResults/$file >/dev/null 2>&1
	                break
	                ;;
	            turn_right,*|*,turn_right)
	                echo -e "|$GREEN Right turn$WHITE| >> Adjusting resolution, right turn (clockwise)   ... please wait, processing is ongoing ..."
	                ffmpeg -i $file -vf "transpose=clock" -vcodec libx264 processResults/$file >/dev/null 2>&1
	                break
	                ;;
	            skip,*|*,skip)
	                echo -e "Skipping item"
	                break
	                ;;
	            quit,*|*,quit)
	                exit 2
	                break
	                ;;
	            *) 
	                echo "invalid option, try something else!"
	                ;;
	        esac
	    done
	done
}


###############

# looping through files

shopt -s nullglob # Sets nullglob

#--------------------------
# Variables declaration
#--------------------------
declare -a VIDEOS_FILES
declare -a VIDEOS_ACTIONS

# List all videos files
listFiles

# Ask user for actions
askForActions

# Process videos
echo -e " "
echo -e " "
echo -e "$BLUE... Processing$WHITE"
mkdir -p processResults
for i in "${!VIDEOS_FILES[@]}"; do 
	printf "    Processing$YELLOW %30s $WHITE >> $BLUE %s $WHITE\n" "${VIDEOS_FILES[$i]}" "${VIDEOS_ACTIONS[$i]}"
	case "${VIDEOS_ACTIONS[$i]}" in
		no_turn)
			ffmpeg -i ${VIDEOS_FILES[$i]} -vcodec libx264 processResults/${VIDEOS_FILES[$i]} >/dev/null 2>&1
			;;
		left_turn)
			ffmpeg -i ${VIDEOS_FILES[$i]} -vf "transpose=cclock" -vcodec libx264 processResults/${VIDEOS_FILES[$i]} >/dev/null 2>&1
			;;
		right_turn)
			ffmpeg -i ${VIDEOS_FILES[$i]} -vf "transpose=clock" -vcodec libx264 processResults/${VIDEOS_FILES[$i]} >/dev/null 2>&1
			;;
		*) 
			echo "invalid option, try something else!"
			;;
	esac
done



echo -e " "
echo -e " "
echo -e "$GREEN Process complete !!!$WHITE"
echo -e " "
echo -e " "
echo -e " "




shopt -u nullglob # Unsets nullglob

