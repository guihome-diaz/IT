#!/bin/sh
# /etc/init.d/tomcat8 -- startup script for the Tomcat 8 servlet engine
# 
# [April 2015, Guillaume Diaz] Modified version of an existing tomcat8 script (see below)
# this script refers to the Tomcat installation setup described on my wiki:
# 
#
#
# Source: http://satishchilukuri.com/blog/entry/installing-java-8-and-tomcat-8-on-debian-wheezy 
# Modified version of the tomcat7 script pulled from Debian Wheezy Tomcat 7 package
#
# Modifications are:
#   * Remove authbind.
#   * Remove JVM_TMP. We will use CATALINA_BASE/temp
#   * Explicitly set JAVA_HOME. No need to figure out where it is.
#   * Remove SECURITY. We are not using the Java security manager.
#   * Remove references to DEFAULT. We have no defaults to use.
#   * Explicitly provide values for variables that are supposed to be set
#     while installing the tomcat package.
#   * Remove references to POLICY_CACHE.
#

### BEGIN INIT INFO
# Provides:          tomcat
# Required-Start:    $local_fs $remote_fs $network $syslog
# Required-Stop:     $local_fs $remote_fs $network $syslog
# Should-Start:      $named
# Should-Stop:       $named
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Tomcat
# Description:       Tomcat servlet container
### END INIT INFO


#-----------------------------------------------------------------------------
# CONFIGURATION 
# ... Adjust these settings to match your configuration
#-----------------------------------------------------------------------------
#Process name
NAME="tomcat8"

# Target user/group
USER="tomcat"
GROUP="tomcat"

# Directory where the Tomcat 8 binary distribution resides
CATALINA_HOME=/opt/tomcat-home

# Directory for per-instance configuration files and webapps
CATALINA_BASE=/opt/tomcat-base

# JVM to use if JAVA_HOME is NOT already set
TOMCAT_JAVA_HOME="/usr/lib/jvm/java-8-oracle"

#-----------------------------------------------------------------------------
# Other settings, do not change them
#-----------------------------------------------------------------------------
# Server generic
CATALINA_SH="$CATALINA_HOME/bin/catalina.sh"
# Instance specifics
CATALINA_PID="$CATALINA_BASE/tomcat.pid"
CATALINA_TMPDIR="$CATALINA_BASE/temp"



# This enable the system logger and related functions
. /lib/lsb/init-functions
if [ -r /etc/default/rcS ]; then
  . /etc/default/rcS
fi



echo " "
echo "# ------------------------- #"
echo "# Tomcat start/stop manager #"
echo "# ------------------------- #"
echo " "


#-----------------------------------------------------------------------------
# Ensure you have right to execute that script
if [ `id -u` -ne 0 ]; then
  log_failure_msg "!! You need root privileges to run this script !!"
  exit 1
fi

# checking user/group
id "$USER" > /dev/null 2>&1
if [ "$?" -ne "0" ]; then
	log_failure_msg "Error: user '$USER' does not exist !"
	exit 1
fi
id -g "$GROUP" > /dev/null 2>&1
if [ "$?" -ne "0" ]; then
  log_failure_msg "Error: group '$GROUP' does not exist !"
  exit 1
fi

# checking environment settings
if [ -z "$JAVA_HOME" ]; then
  JAVA_HOME="$TOMCAT_JAVA_HOME"
  export JAVA_HOME
fi 
if [ -z "$JAVA_HOME" ]; then
  log_failure_msg "no JDK found - please set \$JAVA_HOME or \$TOMCAT_JAVA_HOME to a valid path"
  exit 1
fi
if [ ! -d "$CATALINA_HOME" ]; then
  log_failure_msg "invalid $NAME installation folder \$CATALINA_HOME: $CATALINA_HOME"
  exit 1
fi
if [ ! -f "$CATALINA_HOME/bin/bootstrap.jar" ]; then
  log_failure_msg "Error, $NAME installation seems corrupt... bootstrap.jar is not installed"
  exit 1
fi
if [ ! -d "$CATALINA_BASE/conf" ]; then
  log_failure_msg "invalid configuration folder \$CATALINA_BASE: $CATALINA_BASE"
  exit 1
fi

# Make sure tomcat is started with system locale
if [ -r /etc/default/locale ]; then
  . /etc/default/locale
  export LANG
fi

# Look for Java Secure Sockets Extension (JSSE) JARs
if [ -z "${JSSE_HOME}" -a -r "${JAVA_HOME}/jre/lib/jsse.jar" ]; then
    JSSE_HOME="${JAVA_HOME}/jre/"
fi

# Default Java options: no local screen, prefer IPv4 when possible
if [ -z "$JAVA_OPTS" ]; then
  JAVA_OPTS="-Djava.awt.headless=true -Djava.net.preferIPv4Stack=true"
else
  JAVA_OPTS="${JAVA_OPTS} -Djava.awt.headless=true -Djava.net.preferIPv4Stack=true"
fi
#-----------------------------------------------------------------------------


function run_catalina() {
  ##### Escape any double quotes in the value of JAVA_OPTS
  JAVA_OPTS="$(echo $JAVA_OPTS | sed 's/\"/\\\"/g')"

  ##### Define Tomcat context + command to execute
  # set -a tells sh to export assigned variables to spawned shells.
  TOMCAT_SH="set -a; JAVA_HOME=\"$JAVA_HOME\"; \
    CATALINA_HOME=\"$CATALINA_HOME\"; \
    CATALINA_BASE=\"$CATALINA_BASE\"; \
    JAVA_OPTS=\"$JAVA_OPTS\"; \
    CATALINA_PID=\"$CATALINA_PID\"; \
    CATALINA_TMPDIR\"$CATALINA_TMPDIR\"; \
    LANG=\"$LANG\"; JSSE_HOME=\"$JSSE_HOME\"; \
    cd \"$CATALINA_BASE\"; \
    \"$CATALINA_SH\" $@"

  
  set +e

  ##### Manual log rotation
  if [ -f "$CATALINA_BASE/logs/catalina.out" ]; then
      # move old log
      CURRENT_DATETIME=`date +"%Y-%m-%d_%H:%M"`
      mv $CATALINA_BASE/logs/catalina.out $CATALINA_BASE/logs/catalina_$CURRENT_DATETIME.out
  fi
  # Create new empty log  
  touch $CATALINA_BASE/logs/catalina.out
  chown $USER:$GROUP "$CATALINA_BASE"/logs/catalina.out      


  ##### Create PID
  touch "$CATALINA_PID"
  chown $USER "$CATALINA_PID"

  ##### Call catalina.sh
  start-stop-daemon --start --background --quiet \
                    --user "$USER" --group "$GROUP" \
                    --chuid "$USER" \
                    --chdir "$CATALINA_TMPDIR" \
                    --pidfile "$CATALINA_PID" \
                    --exec /bin/bash \
                    --name "$NAME" -- -c "$TOMCAT_SH"
  status="$?"
  set +a -e
  return $status
}

function start() {
  log_daemon_msg "Starting $NAME"
  if start-stop-daemon --test --start \
                       --pidfile "$CATALINA_PID" \
                       --user $USER \
                       --exec "$JAVA_HOME/bin/java" \
                       >/dev/null; then

      # Clean tomcat base temp directory
      rm -rf "$CATALINA_TMPDIR"
      mkdir -p "$CATALINA_TMPDIR" || {
        log_failure_msg "could not create JVM temporary directory"
        exit 1
      }
      chown -R $USER $CATALINA_TMPDIR
      chgrp -R $GROUP $CATALINA_TMPDIR      


      # Start Tomcat
      run_catalina start

      # Wait and ensure server has been started
      sleep 5
      if start-stop-daemon --test --start \
                           --pidfile "$CATALINA_PID" \
                           --user $USER \
                           --exec "$JAVA_HOME/bin/java" \
                           >/dev/null; then

        # server is not running
        if [ -f "$CATALINA_PID" ]; then
          rm -f "$CATALINA_PID"
        fi
        log_end_msg 1
      else
        log_end_msg 0
      fi
  else
    log_progress_msg "$NAME server is already started"
    log_end_msg 0
  fi
} 


function stop() {
  log_daemon_msg "Stopping $NAME"

  set +e
  if [ -f "$CATALINA_PID" ]; then
    start-stop-daemon --stop --pidfile "$CATALINA_PID" \
                      --user $USER \
                      --retry=TERM/20/KILL/5 >/dev/null
    if [ $? -eq 1 ]; then
        log_progress_msg "$NAME is not running but pid file exists, cleaning up"
    elif [ $? -eq 3 ]; then
        PID="`cat $CATALINA_PID`"
        log_failure_msg "Failed to stop $NAME (pid $PID)"
        exit 1
    fi
    rm -f "$CATALINA_PID"
  else
    log_progress_msg "$NAME server is not running"
  fi
  log_end_msg 0
  set -e
} 


function status() {
  set +e
  start-stop-daemon --test --start --pidfile "$CATALINA_PID" \
                    --user $USER \
                    --exec "$JAVA_HOME/bin/java" \
                    >/dev/null 2>&1
  if [ "$?" = "0" ]; then
  
    if [ -f "$CATALINA_PID" ]; then
        log_success_msg "$NAME is not running, but pid file exists. You can remove $CATALINA_PID"
        exit 1
      else
        log_success_msg "$NAME is not running."
        exit 3
      fi
    else
      log_success_msg "$NAME is running with pid `cat $CATALINA_PID`"
    fi
    set -e
}

case "$1" in
  start)
    start 	
  	;;
  stop)
    stop
    ;;
  restart)
    stop
    start
	 ;;
  status)
  	status
    ;;
  *)
	  echo "Usage: $0 {start|stop|restart|status}"
	  exit 1
	;;
esac

exit 0
