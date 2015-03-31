#!/bin/sh
### BEGIN INIT INFO
# Provides:             firewall
# Required-Start:       $all
# Required-Stop:
# Default-Start:        2 3 4 5
# Default-Stop:         0 1 6
# Short-Description:    Firewall personnel
### END INIT INFO

RED="\\033[0;31m"
BLUE="\\033[0;32m"
GREEN="\\033[0;32m"
#BLACK="\\033[0;30m"
BLACK="\\033[0;37m"

#Launch the firewall
start() {
    /etc/firewall/firewall-start.sh
}

#Stop the firewall
stop() {
    /etc/firewall/firewall-stop.sh
}

# Execution on demand
case $1 in
    "start")
        start
        ;;
    "stop")
        stop
        ;;
    "restart")
        stop
	echo " "
	echo "-----------------------------------------------------------"
	echo " "
        start
        ;;
    "status")
        echo " "
        echo "-----------------------------------------------------------"
        echo " IPv4 rules"
        echo "-----------------------------------------------------------"
        echo " "
        /sbin/iptables -L -v -n
        echo " "
        echo "-----------------------------------------------------------"
        echo " IPv4 NAT rules"
        echo "-----------------------------------------------------------"
        echo " "
        /sbin/iptables -t nat -L -v -n
        echo " "
        echo "-----------------------------------------------------------"
        echo " IPv6 rules"
        echo "-----------------------------------------------------------"
        echo " "
        /sbin/ip6tables -L -v -n
        ;;
    *)
        echo "Usage: firewall {start|stop|restart|status}"
    esac
exit

