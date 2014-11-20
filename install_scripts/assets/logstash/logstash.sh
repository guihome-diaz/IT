#!/bin/sh
### BEGIN INIT INFO
# Provides: logstash
# Required-Start: $remote_fs $syslog
# Required-Stop: $remote_fs $syslog
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Start daemon at boot time
# Description: Enable service provided by daemon.
### END INIT INFO

. /lib/lsb/init-functions

if [ $(id -u) -ne 0 ]; then
	echo -e " " 
	echo -e "!!!!!!!!!!!!!!!!!!!!" 
	echo -e "!! Security alert !!" 
	echo -e "!!!!!!!!!!!!!!!!!!!!" 
	echo -e "You need to be root or have root privileges to run this script!\n\n"
	echo -e " " 
	exit 1
fi

# Where logstash keeps track of each log file
export SINCEDB_DIR="/etc/logstash/db"

# Logstash params
name="logstash"
logstash_bin="/opt/logstash/bin/logstash"
logstash_conf="/etc/logstash/conf.d/"
logstash_log="/var/log/logstash.log"
pid_file="/var/run/$name.pid"

start () {
	commandOpts="agent -f $logstash_conf --log ${logstash_log} --verbose"
	log_daemon_msg "Starting $name" "$name"
	if start-stop-daemon --start --quiet --oknodo --pidfile "$pid_file" -b -m --exec $logstash_bin -- $commandOpts; then
		log_end_msg 0
	else
		log_end_msg 1
	fi
}
testConfig () {
	echo "#############################"
	echo " Logstash configuration test"
	echo "#############################"
	command="${logstash_bin} -f $logstash_conf --verbose -t"
	$command
}
stop () {
	log_daemon_msg "Stopping $name" "$name"
	start-stop-daemon --stop --quiet --oknodo --pidfile "$pid_file"
}
status () {
	status_of_proc -p $pid_file "" "$name"
}

case $1 in
	start)
		if status; then exit 0; fi
		start
		;;
	stop)
		stop
		;;
	reload)
		stop
		start
		;;
	restart)
		stop
		start
		;;
	status)
		status && exit 0 || exit $?
		;;
	testConfig)
		testConfig
		;;
	*)
		echo "Usage: $0 {start|stop|restart|reload|status|testConfig}"
		exit 1
		;;
esac
exit 0 
