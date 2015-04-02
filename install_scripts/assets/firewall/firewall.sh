#!/bin/sh
### BEGIN INIT INFO
# Provides:             firewall
# Required-Start:       $all
# Required-Stop:
# Default-Start:        2 3 4 5
# Default-Stop:         0 1 6
# Short-Description:    Firewall personnel
### END INIT INFO

# FIREWALL start/stop script
# Copyright (C) 2015 Guillaume Diaz [guillaume @ qin-diaz.com]
##################################
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
##################################

start() {
    /etc/firewall/firewall-start.sh
}

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

