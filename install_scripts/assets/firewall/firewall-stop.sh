#!/bin/bash
# FIREWALL stop script
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
#
#   version 1.0 - September 2008
#           1.1 - November 2009 
#                  >> Network security (Chalmers) + english translation
#   version 1.2 - January 2010
#                  >> Add some protections against flooding
#   version 1.2.1 - March 2011 
#                  >> Configuration for the extranet
#   version 1.3 - April 2015
#                  >> IPv6 support  
#                  >> Improving log using 'log_' functions

#### Load other scripts
source /etc/firewall/firewall-lib.sh

export DO_IPV4="1"
export DO_IPV6="1"

log_daemon_msg "Firewall reset"
	clearPolicies
	setDefaultPolicies
	basicProtection
	protocolsEnforcement
	keepEstablishedRelatedConnections
log_end_msg 0

