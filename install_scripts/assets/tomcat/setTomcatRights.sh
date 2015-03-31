#!/bin/sh
# Script based upon http://satishchilukuri.com/blog/entry/installing-java-8-and-tomcat-8-on-debian-wheezy
# Last modification: April 2015, Guillaume Diaz. 
#                    I arranged it so the binaries VS instance operations are easier to grasp
#

CATALINA_HOME=/opt/tomcat-home        # Tomcat binaries
CATALINA_BASE=/opt/tomcat-base        # Tomcat instance (dedicated configuration + runtime)

TOMCAT_INSTANCE_USER=tomcat8
TOMCAT_GROUP=tomcat


################################
# Tomcat binaries
################################
# Ownership
chgrp -R $TOMCAT_GROUP $CATALINA_HOME $CATALINA_HOME/*

# Read only rights
chown -Rh root:$TOMCAT_GROUP $CATALINA_HOME/conf $CATALINA_HOME/lib $CATALINA_HOME/bin

# Ensure configuration files are group readable
chmod go+r $CATALINA_HOME/conf/*

# Change permissions on tomcat-users.xml so that others can’t change it (but tomcat):
chmod 640 $CATALINA_HOME/conf/tomcat-users.xml

# Allow execution of general scripts
chmod 755 $CATALINA_HOME/**/*.sh



################################
# Tomcat instance
################################
# Ownership
chown -R $TOMCAT_INSTANCE_USER /opt/tomcat-base
chgrp -R $TOMCAT_GROUP /opt/tomcat-base

# Read only
chown -Rh root:$TOMCAT_GROUP $CATALINA_BASE/conf $CATALINA_BASE/lib $CATALINA_BASE/bin

# Ensure configuration files are group readable
chmod go+r $CATALINA_BASE/conf/*

# Change permissions on tomcat-users.xml so that others can’t change it (but tomcat):
chmod 640 $CATALINA_BASE/conf/tomcat-users.xml
