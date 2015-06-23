#!/bin/bash

# Backup script 
# This will save the server configuration and settings.
#
# Version 1.0 - June 2015 - Guillaume Diaz
#

BACKUP_DIRECTORY=""

### System values. Please do not change these variables
NOW=$(date +"%Y-%m-%d")
BACKUP_TMP_DIRECTORY="/tmp/backup_script_$NOW"
logFile="/var/log/backup_script_$NOW.log"

### Ensure user has root rights
if [ $(id -u) -ne 0 ]; then
	echo -e "" 
	echo -e "!! Security alert !!" 
	echo -e "You need to be root or have root privileges to run this script!\n\n"
	echo -e "" 
	exit 1
fi

### Create execution log file
touch $logFile > /dev/null
echo "" > $logFile

### Create temp backup directory
mkdir -p $BACKUP_TMP_DIRECTORY


# Sources
mkdir -p $BACKUP_TMP_DIRECTORY/etc/apt/
cp /etc/apt/sources.list $BACKUP_TMP_DIRECTORY/etc/apt/sources.list
cp -r /etc/apt/sources.list.d $BACKUP_TMP_DIRECTORY/etc/apt/

# vim
mkdir -p $BACKUP_TMP_DIRECTORY/etc/vim/
cp /etc/vim/vimrc $BACKUP_TMP_DIRECTORY/etc/vim/vimrc

# Bash
mkdir -p $BACKUP_TMP_DIRECTORY/etc/
cp /etc/bash.bashrc $BACKUP_TMP_DIRECTORY/etc/bash.bashrc
mkdir -p $BACKUP_TMP_DIRECTORY/root/
cp /root/.bashrc $BACKUP_TMP_DIRECTORY/root/.bashrc

# Firewall scripts
if [ -d "/etc/firewall" ]; then
	mkdir -p $BACKUP_TMP_DIRECTORY/etc/firewall/
	mkdir -p $BACKUP_TMP_DIRECTORY/etc/init.d/
	mkdir -p $BACKUP_TMP_DIRECTORY/usr/bin/
	cp -r /etc/firewall/* $BACKUP_TMP_DIRECTORY/etc/firewall/
	# symlinks
	cp -d /etc/init.d/firewall $BACKUP_TMP_DIRECTORY/etc/init.d/firewall
	cp -d /usr/bin/firewall $BACKUP_TMP_DIRECTORY/usr/bin/firewall
fi

# hosts and hostname
mkdir -p $BACKUP_TMP_DIRECTORY/etc/
cp /etc/hosts $BACKUP_TMP_DIRECTORY/etc/hosts
cp /etc/hostname $BACKUP_TMP_DIRECTORY/etc/hostname

# Interface settings
mkdir -p $BACKUP_TMP_DIRECTORY/etc/network/
cp /etc/network/interfaces $BACKUP_TMP_DIRECTORY/etc/network/interfaces

# SSL local infrastructure
if [ -d "/srv/ssl" ]; then
	mkdir -p $BACKUP_TMP_DIRECTORY/srv/ssl/
	cp -r /srv/ssl/* $BACKUP_TMP_DIRECTORY/srv/ssl
fi

# Apache2
if [ -d "/etc/apache2" ]; then
	mkdir -p $BACKUP_TMP_DIRECTORY/etc/apache2/sites-available/
	cp -r /etc/apache2/sites-available/* $BACKUP_TMP_DIRECTORY/etc/apache2/sites-available/
	# Security
	cp /etc/apache2/*.key $BACKUP_TMP_DIRECTORY/etc/apache2/
	cp /etc/apache2/*.pem $BACKUP_TMP_DIRECTORY/etc/apache2/
	cp /etc/apache2/*.p12 $BACKUP_TMP_DIRECTORY/etc/apache2/
	cp /etc/apache2/*.crt $BACKUP_TMP_DIRECTORY/etc/apache2/
	# symlinks
	cp -d /etc/apache2/webServer.key $BACKUP_TMP_DIRECTORY/etc/apache2/webServer.key
	cp -d /etc/apache2/webServer.pem $BACKUP_TMP_DIRECTORY/etc/apache2/webServer.pem
fi

# VPN
if [ -d "/etc/openvpn" ]; then
	mkdir -p $BACKUP_TMP_DIRECTORY/etc/openvpn
	# core files
	cp -r /etc/openvpn/easy-rsa $BACKUP_TMP_DIRECTORY/etc/openvpn/
	cp /etc/openvpn/server.conf $BACKUP_TMP_DIRECTORY/etc/openvpn/
	cp /etc/openvpn/ipp.txt $BACKUP_TMP_DIRECTORY/etc/openvpn/
	# security settings
	cp -d /etc/openvpn/ca.crt $BACKUP_TMP_DIRECTORY/etc/openvpn/ca.crt
	cp -d /etc/openvpn/ca.key $BACKUP_TMP_DIRECTORY/etc/openvpn/ca.key
	cp -d /etc/openvpn/dh2048.pem $BACKUP_TMP_DIRECTORY/etc/openvpn/dh2048.pem
	cp -d /etc/openvpn/smartcards-gw.crt $BACKUP_TMP_DIRECTORY/etc/openvpn/smartcards-gw.crt
	cp -d /etc/openvpn/smartcards-gw.key $BACKUP_TMP_DIRECTORY/etc/openvpn/smartcards-gw.key
	# Logs
	cp -d /etc/openvpn/openvpn.log $BACKUP_TMP_DIRECTORY/etc/openvpn/openvpn.log
	cp -d /etc/openvpn/openvpn-status.log $BACKUP_TMP_DIRECTORY/etc/openvpn/openvpn-status.log
	cp -d /etc/openvpn/openvpn-status.log $BACKUP_TMP_DIRECTORY/etc/openvpn/openvpn-status.log
fi

# Samba
if [ -d "/etc/samba" ]; then
	mkdir -p $BACKUP_TMP_DIRECTORY/etc/samba/
	cp /etc/samba/smb.conf $BACKUP_TMP_DIRECTORY/etc/samba/smb.conf
	# symlinks
	cp -d /etc/init.d/firewall $BACKUP_TMP_DIRECTORY/etc/init.d/firewall
	cp -d /usr/bin/firewall $BACKUP_TMP_DIRECTORY/usr/bin/firewall
fi


# DNS server
if [ -d "/etc/bind" ]; then
	mkdir -p $BACKUP_TMP_DIRECTORY/etc/bind/
	cp /etc/bind/* $BACKUP_TMP_DIRECTORY/etc/bind/

	mkdir -p $BACKUP_TMP_DIRECTORY/etc/default/
	cp /etc/default/bind9 $BACKUP_TMP_DIRECTORY/etc/default/bind9
fi


# DHCP server
if [ -f "/etc/dhcp/dhcpd.conf" ]; then
	mkdir -p $BACKUP_TMP_DIRECTORY/etc/dhcp/
	cp /etc/dhcp/dhcpd.conf $BACKUP_TMP_DIRECTORY/etc/dhcp/dhcpd.conf
	cp /etc/webmin/miniserv.conf $BACKUP_TMP_DIRECTORY/etc/webmin/miniserv.conf
fi

# TFTP server
if [ -d "/tftpboot" ]; then
	# TFTP config
	mkdir -p $BACKUP_TMP_DIRECTORY/etc/default
	cp /etc/default/tftpd-hpa $BACKUP_TMP_DIRECTORY/tftpd-hpa
	# TFTP files, bootloard and menu
	mkdir -p $BACKUP_TMP_DIRECTORY/tftpboot
	cd /tftpboot
	zip -r tftpboot.zip *
	mv /tftpboot/tftpboot.zip $BACKUP_TMP_DIRECTORY/tftpboot/
fi

# NFS server 
# !! this is NOT the netboot image content, just the NFS server configuration !!
if [ -f "/etc/exports" ]; then
	mkdir -p $BACKUP_TMP_DIRECTORY/etc/
	cp /etc/exports $BACKUP_TMP_DIRECTORY/etc/exports
fi


# Zabbix
if [ -d "/etc/zabbix" ]; then
	mkdir -p $BACKUP_TMP_DIRECTORY/etc/zabbix/
	# Zabbix agent
	cp /etc/zabbix/zabbix_agentd.conf $BACKUP_TMP_DIRECTORY/etc/zabbix/zabbix_agentd.conf
fi

# Webmin
if [ -d "/etc/openvpn" ]; then
	mkdir -p $BACKUP_TMP_DIRECTORY/etc/webmin/
	cp /etc/webmin/config $BACKUP_TMP_DIRECTORY/etc/webmin/config
	cp /etc/webmin/miniserv.conf $BACKUP_TMP_DIRECTORY/etc/webmin/miniserv.conf
fi



###### Restore
chown -R root:root /etc/firewall
chmod 755 /etc/firewall/*.sh
ln -s /etc/firewall/firewall.sh /etc/init.d/firewall
ln -s /etc/firewall/firewall.sh /usr/bin/firewall



