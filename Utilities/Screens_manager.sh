#/bin/sh
######################## 
# Script to automatically configure screens on DELL Latitude E6430
# Version 1.1, May 2014
# Author: Guillaume Diaz
########################

LAPTOP_OUTPUT="LVDS-0"
VGA_OUTPUT="VGA-0"
DVI_OUTPUT_1="DP-0"
DVI_OUTPUT_2="DP-1"
DVI_RESOLUTION="1920x1080"


echo " "
echo "Screen configuration"
echo " "

####################################
# DVI outputs
####################################
# Check for DVI 1
xrandr | grep $DVI_OUTPUT_1 | grep " connected "
if [ $? -eq 0 ]; then
	xrandr --output $VGA_OUTPUT --off
	echo " ... DVI 0 detected"

	# Check for DVI 2. If enable, then the laptop screen will be off
	xrandr | grep $DVI_OUTPUT_2 | grep " connected "
	if [ $? -eq 0 ]; then
		# both DVI 1 and DVI 2
		echo "  ... DVI 1 detected. Using DVI0 + DVI1"
		xrandr --output $LAPTOP_OUTPUT --off 
		xrandr --output $DVI_OUTPUT_1 --auto
		xrandr --output $DVI_OUTPUT_1 --mode $DVI_RESOLUTION
		xrandr --output $DVI_OUTPUT_2 --mode $DVI_RESOLUTION --right-of $DVI_OUTPUT_1
	else 
		# DVI 1 + laptop
		echo "  ... Using DVI0 + laptop"
		xrandr --output $LAPTOP_OUTPUT --auto
		xrandr --output $DVI_OUTPUT_1 --mode $DVI_RESOLUTION --right-of $LAPTOP_OUTPUT
		xrandr --output $DVI_OUTPUT_2 --off
	fi

	echo " "
	echo "DVI configuration is complete."
	echo " "
	exit
else
	# No DVI
	echo " ... No DVI output"
	xrandr --output $DVI_OUTPUT_1 --off
	xrandr --output $DVI_OUTPUT_2 --off
fi

####################################
# VGA
####################################
xrandr |grep $VGA_OUTPUT | grep " connected "
if [ $? -eq 0 ]; then	
	# VGA + laptop
	echo " ... VGA detected. Using VGA + laptop"
	xrandr --output $LAPTOP_OUTPUT --auto 
	xrandr --output $VGA_OUTPUT --right-of $LAPTOP_OUTPUT
	
	echo " "
	echo "VGA configuration is complete."
	echo " "
	exit
else
	# No VGA
	echo " ... No VGA output"
	xrandr --output $VGA_OUTPUT --off
fi


####################################
# Laptop only
####################################
xrandr --output $LAPTOP_OUTPUT --auto 
echo " "
echo "Laptop configuration is complete."
echo " "
exit

