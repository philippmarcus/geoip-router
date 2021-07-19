#!/bin/bash

set -eE -o functrace
echo "Execution of updown script initiated" 

case "${PLUTO_VERB}" in
    up-client)
	# Longest prefix matching. Has priority over the prohibit that is
	# installed in table 2. Default route for marked traffic.
	ip route add 0.0.0.0/1 dev eth0 src "${PLUTO_MY_SOURCEIP}" table 2
	ip route add 128.0.0.0/1 dev eth0 src "${PLUTO_MY_SOURCEIP}" table 2

        # Source NAT of marked packages to the inside IP of the tunnel in order to match
	# the traffic selector of the Security Association.
	iptables -t nat -A POSTROUTING -j SNAT --to-source "${PLUTO_MY_SOURCEIP}" -m mark --mark 2
	;;
    down-client)
	# Remove SNAT for packages routed via the tunnel
	iptables -t nat -D POSTROUTING -j SNAT --to-source "${PLUTO_MY_SOURCEIP}" -m mark --mark 2
	
	# Remove default routes and 
	ip route del 0.0.0.0/1 dev $DEV src "${PLUTO_MY_SOURCEIP}" table 2
	ip route del 128.0.0.0/1 dev $DEV src "${PLUTO_MY_SOURCEIP}" table 2
        ;;
esac

echo "Executed updown script.""
