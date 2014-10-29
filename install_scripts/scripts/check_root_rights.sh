#!/bin/bash
#
# To ensure that the user has root privileges
#

function checkRootRights() {
	if [ $(id -u) -ne 0 ]; then
		echo -e "$RED_BOLD " 
		echo -e "!!!!!!!!!!!!!!!!!!!!" 
		echo -e "!! Security alert !!" 
		echo -e "!!!!!!!!!!!!!!!!!!!! $RED" 
		echo -e "You need to be root or have root privileges to run this script!\n\n"
		echo -e "$WHITE " 
		exit 1
	fi
}
