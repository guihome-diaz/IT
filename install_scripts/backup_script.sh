#!/bin/bash
# Backup script 
# Author: Guillaume Diaz 
# Version 1.0 - September 2015 - Dev.daxiongmao.eu configuration
#                                 * Apache2 + web-applications
#                                 * APT
#                                 * Firewall
#                                 * Jenkins
#                                 * LDAP
#                                 * Maven
#                                 * MySQL
#                                 * Nexus
#                                 * SonarQube
#                                 * SSH
#                                 * VPN

# This enable system logger and related functions
if [ -e /etc/debian_version ]; then
    . /lib/lsb/init-functions
elif [ -e /etc/init.d/functions ] ; then
    . /etc/init.d/functions
fi
if [ -r /etc/default/rcS ]; then
  . /etc/default/rcS
fi


echo " "
echo " Server backup script "
echo " "

cd ~
rm -Rf ~/backup/


######## Core elements
log_daemon_msg "Linux core"
log_progress_msg "Linux core - networking"
mkdir -p ~/backup/etc/network
cp /etc/network/interfaces ~/backup/etc/network/
cp /etc/hosts ~/backup/etc/
cp /etc/hostname ~/backup/etc/
log_progress_msg "Linux core - bash"
mkdir -p ~/backup/etc/
cp /etc/bash.bashrc ~/backup/etc/bash.bashrc
log_progress_msg "Linux core - vim"
mkdir -p ~/backup/etc/vim
cp /etc/vim/vimrc ~/backup/etc/vim/
log_end_msg 0


######## APACHE 2
log_daemon_msg "Apache2"
log_progress_msg "Apache2 - web server configuration"
mkdir -p ~/backup/etc/apache2/sites-enabled
cp /etc/apache2/apache2.conf ~/backup/etc/apache2/
cp -r /etc/apache2/sites-available ~/backup/etc/apache2/
cp -s /etc/apache2/sites-enabled/* ~/backup/etc/apache2/sites-enabled/
chown -R www-data:www-data ~/backup/etc/apache2
log_progress_msg "Apache2 - v.host logs"
mkdir -p ~/backup/var/log/apache2/dev.daxiongmao.eu
touch ~/backup/var/log/apache2/dev.daxiongmao.eu/access.log
touch ~/backup/var/log/apache2/dev.daxiongmao.eu/error.log
touch ~/backup/var/log/apache2/dev.daxiongmao.eu/access_ssl.log
touch ~/backup/var/log/apache2/dev.daxiongmao.eu/error_ssl.log
chown -R www-data:www-data ~/backup/var/log/apache2/
log_progress_msg "Apache2 - web applications (simple)"
mkdir -p ~/backup/var/www
cp -r /var/www/errors ~/backup/var/www/
cp -r /var/www/dev.daxiongmao.eu ~/backup/var/www/
cp -r /var/www/self-service-password ~/backup/var/www/
chown -R www-data:www-data ~/backup/var/www/
log_progress_msg "Apache2 - web applications (apt-get)"
mkdir -p ~/backup/etc/phpldapadmin
cp /etc/phpldapadmin/config.php ~/backup/etc/phpldapadmin/
log_end_msg 0


######## APT repositories list
log_daemon_msg "APT"
log_progress_msg "APT - repositories"
mkdir -p ~/backup/etc/apt/apt.conf.d
cp /etc/apt/sources.list ~/backup/etc/apt/
cp -r /etc/apt/sources.list.d/ ~/backup/etc/apt/
log_progress_msg "APT - auto-updates"
cp /etc/apt/apt.conf.d/50unattended-upgrades ~/backup/etc/apt/apt.conf.d/
cp /etc/apt/apt.conf.d/10periodic ~/backup/etc/apt/apt.conf.d/
log_end_msg 0


####### Firewall
log_daemon_msg "Firewall"
mkdir -p ~/backup/etc/init.d
cp -r /etc/firewall ~/backup/etc/
cp -s /etc/init.d/firewall ~/backup/etc/init.d/
mkdir -p ~/backup/usr/bin/
cp -s /usr/bin/firewall ~/backup/usr/bin/
log_end_msg 0


####### OpenLDAP
log_daemon_msg "OpenLDAP"
log_progress_msg "OpenLDAP - configuration"
mkdir -p ~/backup/etc/default
cp /etc/default/slapd ~/backup/etc/default/
mkdir -p ~/backup/etc/ldap
cp /etc/ldap/ldap.conf ~/backup/etc/ldap/
cp /etc/ldap/memberof.ldif ~/backup/etc/ldap/
cp /etc/ldap/referential_integrity.ldif ~/backup/etc/ldap/
log_progress_msg "OpenLDAP - Database content"
slapcat > ~/backup/etc/ldap/backup_OpenLDAP_daxiongmao_data.ldif
log_end_msg 0


####### Jenkins
log_daemon_msg "Jenkins - Continuous Integration"
mkdir -p ~/backup/etc/default
cp /etc/default/jenkins ~/backup/etc/default/
mkdir -p ~/backup/home/jenkins
chown -R jenkins:jenkins ~/backup/home/jenkins/
echo " JENKINS configuration saved. Not the jobs files; see /home/jenkins/jobs"
log_end_msg 0


####### Maven
log_daemon_msg "Maven"
log_progress_msg "Maven - configuration"
mkdir -p ~/backup/opt/maven/conf
cp /opt/maven/conf/settings.xml ~/backup/opt/maven/conf/
log_progress_msg "Maven - SSL certificates"
mkdir -p ~/backup/root
mkdir -p ~/backup/home/guillaume
cp /root/.keystore ~/backup/root/
cp /home/guillaume/.keystore ~/backup/home/guillaume/
echo " MAVEN configuration saved. Not the m2repo; see /home/m2repo"
log_end_msg 0


####### MySQL
log_daemon_msg "MySQL"
mkdir -p ~/backup/etc/mysql
cp /etc/mysql/my.cnf ~/backup/etc/mysql/
echo " MySQL configuration saved. Not the tables contents !!"
log_end_msg 0


####### Nexus
log_daemon_msg "Nexus"
mkdir -p ~/backup/opt/nexus/conf
mkdir -p ~/backup/opt/nexus/bin
cp /opt/nexus/conf/nexus.properties ~/backup/opt/nexus/conf/
cp /opt/nexus/bin/nexus ~/backup/opt/nexus/bin/
chown -R nexus:nexus ~/backup/opt/nexus/
mkdir -p ~/backup/opt/sonatype-work/
chown -R nexus:nexus ~/backup/opt/sonatype-work
mkdir -p ~/backup/var/log/
cp -s /opt/nexus/logs/wrapper.log ~/backup/var/log/
mkdir -p ~/backup/home/nexus
chown -R nexus:nexus ~/backup/home/nexus/
mkdir -p ~/backup/etc/init.d
cp -s /etc/init.d/nexus ~/backup/etc/init.d/
mkdir -p ~/backup/usr/bin/
cp -s /usr/bin/nexus ~/backup/usr/bin/
echo " NEXUS configuration saved. Not the artifacts; see /home/nexus"
log_end_msg 0


####### SonarQube
log_daemon_msg "SonarQube"
mkdir -p ~/backup/opt/sonarqube/bin
cp -r /opt/sonarqube/conf/ ~/backup/opt/sonarqube/
cp /opt/sonarqube/bin/linux-x86-64/sonar.sh ~/backup/opt/sonarqube/bin/
mkdir -p ~/backup/etc/init.d
cp -s /etc/init.d/sonarqube ~/backup/etc/init.d/
mkdir -p ~/backup/usr/bin/
cp -s /usr/bin/sonarqube ~/backup/usr/bin/
log_end_msg


####### SSH
log_daemon_msg "SSH"
log_progress_msg "SSH - configuration"
mkdir -p ~/backup/etc/ssh
cp -r /etc/ssh/sshd_config ~/backup/etc/ssh/
log_progress_msg "SSH - authorized keys"
mkdir -p ~/backup/root
cp -r /root/.ssh/ ~/backup/etc/root/
mkdir -p ~/backup/home/guillaume
cp -r /home/guillaume/.ssh/ ~/backup/home/guillaume/
log_end_msg 0


####### OpenVPN
log_daemon_msg "OpenVPN"
mkdir -p ~/backup/etc/openvpn
cp -r /etc/openvpn/easy-rsa/ ~/backup/etc/openvpn/
cp /etc/openvpn/server.conf.* ~/backup/etc/openvpn/
cp /etc/openvpn/ipp.txt ~/backup/etc/openvpn/
cp -s /etc/openvpn/server.key ~/backup/etc/openvpn/
cp -s /etc/openvpn/server.crt ~/backup/etc/openvpn/
cp -s /etc/openvpn/ca.* ~/backup/etc/openvpn/
cp -s /etc/openvpn/dh* ~/backup/etc/openvpn/
cp -s /etc/openvpn/openvpn.log ~/backup/etc/openvpn/
mkdir -p ~/backup/var/log/
touch ~/backup/var/log/openvpn.log
log_end_msg 0


# Add backup script
cp ~/backup.sh backup/backup.sh


log_daemon_msg "Wrapping things up - backup archive creation..."
cd ~
zip -r backup_config_dev_daxiongmao.zip backup/ > /dev/null
log_end_msg 0

echo " "
echo " BACKUP complete ! "
echo " "