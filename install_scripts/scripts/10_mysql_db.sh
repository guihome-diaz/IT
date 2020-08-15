#!/bin/bash
#
# To setup database server
#
RED="\\033[0;31m"
RED_BOLD="\\033[1;31m"
BLUE="\\033[1;34m"
GREEN="\\033[0;32m"
WHITE="\\033[0;37m"
YELLOW="\\033[1;33m"


function setupMySQLserver() {
	export DEBIAN_FRONTEND=dialog

	echo -e "$BLUE "
	echo -e "####################################"
	echo -e "           MariaDB database" 
	echo -e "            (MySQL fork)"
	echo -e "#################################### $WHITE"
	echo " "
	echo " "

	echo -e "\n\n $YELLOW add repo MariaDB $WHITE \n\n"
	sudo apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc'
        sudo add-apt-repository 'deb [arch=amd64] http://mariadb.mirror.globo.tech/repo/10.5/ubuntu focal main'
	sudo apt update

	echo -e "\n\n $YELLOW Installation MariaDB server $WHITE \n\n" 
	apt install -y mariadb-server mariadb-client

	echo -e "\n\n $YELLOW secure server setup $WHITE "
	echo -e "answers - 2020-08: "
	echo -e " $WHITE     Switch to unix_socket authentication [Y/n] $YELLOW n $WHITE "
	echo -e " $WHITE     Change the root password? [Y/n]  $YELLOW Y $WHITE "
	echo -e " $WHITE     New password: $YELLOW toor $WHITE "
	echo -e " $WHITE     Re-enter new password: $YELLOW toor $WHITE "
	echo -e " $WHITE     Remove anonymous users? [Y/n] $YELLOW n $WHITE "
	echo -e " $WHITE     Disallow root login remotely? [Y/n] $YELLOW n $WHITE "
	echo -e " $WHITE     Remove test database and access to it? [Y/n]  $YELLOW n $WHITE "
	echo -e " $WHITE     Reload privilege tables now? [Y/n] $YELLOW Y $WHITE "
	echo -e "---------------------------------------- \n\n\n "
	mysql_secure_installation


	localHostname=`hostname`
	echo -e "\n\n $YELLOW Listening on all interfaces $WHITE"
	cp /etc/mysql/mariadb.conf.d/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf.backup
	sed -i "s/bind-address            = 127.0.0.1/#bind-address            = 127.0.0.1/g" /etc/mysql/mariadb.conf.d/50-server.cnf

	#echo -e "\n\n $YELLOW Allow root access from all locations $WHITE"
	#mysql -uroot -p$rootPassword mysql -e "update user set host='%' where user='root' and host='$localHostname'; flush privileges;";

	echo -e "\n\n $YELLOW Restarting MariaDB server $WHITE \n\n" 
	service mariadb restart

	echo -e "\n\n $GREEN ... MariaDB server OK ! $WHITE"
	echo -e " "
}



###### To test the script, just uncomment the following lines
#source ./check_root_rights.sh
#checkRootRights
#setupMySQLserver
