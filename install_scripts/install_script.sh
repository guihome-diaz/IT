#!/bin/bash
#### Script to automat the installation of a Linux workstation

RED="\\033[0;31m"
RED_BOLD="\\033[1;31m"
BLUE="\\033[1;34m"
GREEN="\\033[0;32m"
WHITE="\\033[0;37m"
YELLOW="\\033[1;33m"

# Required variables
export DEBIAN_FRONTEND=dialog



## Get current path and ensure that assets folder is available
EXECUTION_PATH=`pwd`
if [ ! -d "$EXECUTION_PATH/assets" ]; then
	echo -e "$RED_BOLD " 
	echo -e "!!!!!!!!!!!!!!!!!!!!!!!" 
	echo -e "!! Resources missing !!" 
	echo -e "!!!!!!!!!!!!!!!!!!!!!!! $RED" 
	echo -e "Resources are missing ! :( \n The '$EXECUTION_PATH/assets' folder does not exists ! \n\n"
	echo -e "$WHITE " 
	exit 1
fi

if [ ! -d "$EXECUTION_PATH/install_scripts" ]; then
	echo -e "$RED_BOLD " 
	echo -e "!!!!!!!!!!!!!!!!!!!!!!!" 
	echo -e "!! Resources missing !!" 
	echo -e "!!!!!!!!!!!!!!!!!!!!!!! $RED" 
	echo -e "Installations scripts are not available ! :O \n The '$EXECUTION_PATH/install_scripts' folder does not exists ! \n\n"
	echo -e "$WHITE " 
	exit 1
fi


#### Load other scripts
source ./scripts/check_root_rights.sh
source ./scripts/00_sources.sh
source ./scripts/01_core_packages.sh
source ./scripts/01_ui_packages.sh
source ./scripts/01_languages.sh
source ./scripts/01_vim_config.sh
source ./scripts/02_firewall.sh
source ./scripts/03_automatic_updates.sh
source ./scripts/10_mysql_db.sh
source ./scripts/11_apache2_web_server.sh
source ./scripts/20_samba.sh
source ./scripts/30_antivirus.sh
source ./scripts/31_rabbitmq.sh


# Enable log file writing as /dev/fd/3
# see http://stackoverflow.com/questions/18460186/writing-outputs-to-log-file-and-console
checkRootRights




### Create execution log file
logFile="/tmp/installScriptLog.txt"
touch $logFile > /dev/null
echo "" > $logFile




## Check if dialog is available or not
if [[ -n $(which dialog) ]]; then
    echo "Everything is ready !"
else
	# Install dialog if not already there !
    echo "... installation of required application, please wait"
	apt-get install -y dialog >> /bin/null
fi
DIALOG_OK=0
DIALOG_CANCEL=1
DIALOG_ESC=255




######################################
# Ask user about features to install #
######################################


tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/test$$
trap "rm -f $tempfile" 0 1 2 5 15

dialog --backtitle "VEHCO" \
	--title "Feature list" \
    --checklist "Hi, what features do you want to install?" 20 75 5 \
        "Sources"      "Ubuntu 14.04 LTS repositories" on \
        "CorePackages" "Linux core packages" on \
        "UIPackages"   "Ubuntu UI application and tools" off \
        "Languages"    "Additional fonts + Chinese support" off \
        "Firewall"     "IpTables Firewall" on \
        "Updates"      "Automatic updates, upgrades and dist-upgrades ; from all repositories" on \
        "Database"     "MySQL database" off \
        "Web-server"   "Apache2 web server" off \
        "File-share"   "Samba file-share" off \
        "AntiVirus"    "ClamAV antiVirus + daily scan" off \
        "RabbitMQ"    "RabbitMQ messaging server" off 2> $tempfile
retval=$?
choices=`cat $tempfile`
case $retval in
  $DIALOG_OK)
    echo "You select: $choices";;
  $DIALOG_CANCEL)
    echo "Cancel pressed.";;
  $DIALOG_ESC)
    echo "ESC pressed.";;
  *)
    echo "Unexpected return code: $retval (ok would be $DIALOG_OK)";;
esac


#########################
# Process user response #
#########################
# Cast String result into array
# Process each array value using {switch,case}

clear
IFS=', ' read -a choicesArray <<< "$choices"
for choice in "${choicesArray[@]}"
do
	case "$choice" in

		"Sources")		
			setupSourcesList $EXECUTION_PATH
			echo " " >> $logFile
			echo "#######" >> $logFile
			echo "# APT #" >> $logFile
			echo "#######" >> $logFile
			echo "List of repositories available in /etc/apt/sources.list" >> $logFile
			echo " " >> $logFile
			;;

		"CorePackages") 
			setupCorePackages $EXECUTION_PATH
			setupVim $EXECUTION_PATH
			;;

		"UIPackages")
			setupUIPackages $EXECUTION_PATH
			;;

		"Languages")
			setupAdditionalLanguages $EXECUTION_PATH
			;;

		"Firewall")
			setupFirewall $EXECUTION_PATH
			echo " " >> $logFile
			echo "############" >> $logFile
			echo "# Firewall #" >> $logFile
			echo "############" >> $logFile
			echo "Firewall script in /etc/firewall/firewall.sh" >> $logFile
			echo "... The FW will start automatically on boot" >> $logFile
			echo " " >> $logFile
			;;

		"Updates")
			setupAutomaticUpdates $EXECUTION_PATH
			;;

		"Database")
			setupMySQLserver $EXECUTION_PATH
			;;

		"Web-server")
			setupApacheWebServer $EXECUTION_PATH
			echo " " >> $logFile
			echo "###########" >> $logFile
			echo "# Apache2 #" >> $logFile
			echo "###########" >> $logFile
			echo "Apache2 configuration in /etc/apache2/" >> $logFile
			echo "... No VHOST enable, you have to create | adjust your configuration" >> $logFile
			echo "... Some configuration examples are available in /etc/apache2/vehco-samples" >> $logFile
			echo "... Some websites examples are available in /var/www/vehco-samples" >> $logFile
			echo " " >> $logFile
			;;

		"File-share")
			setupSambaFileShare $EXECUTION_PATH
			echo " " >> $logFile
			echo "##############" >> $logFile
			echo "# File-share #" >> $logFile
			echo "##############" >> $logFile
			echo "Adjust your shares in /etc/samba/smb.conf" >> $logFile
			echo " " >> $logFile
			;;

		"AntiVirus")
			setupAntivirus $EXECUTION_PATH
			;;

		"Subversion") 
			echo "Installing SVN client" 
			apt-get install subversion subversion-tools

			echo "Installing SVN server" 
			apt-get install subversion subversion-tools >> $logFile

			;;

		"RabbitMQ")
			setupRabbitMQ $EXECUTION_PATH
			;;
		*)
			echo "Something else: $choice"
			;;
	esac
done



echo -e "\n\n $GREEN ... Installation is complete ! $WHITE \n\n"
echo -e " "
cat $logFile
echo -e " "
echo -e " "

exit 0
