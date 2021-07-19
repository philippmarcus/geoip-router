#!/bin/sh
set -e

# Activate the syslog daemon
service rsyslog start

# Create the correct ipsec config for vpn connection
sed -i "s/USERNAME/$1/g" /etc/ipsec.conf
sed -i "s/SERVER_IP/$3/g" /etc/ipsec.conf
sed -i "s/SERVER_HOSTNAME/$4/g" /etc/ipsec.conf

# Config ipsec to auto-reconnect
sed -i "s/dpdaction=clear/dpdaction=restart/g" /etc/ipsec.conf
sed -i "$ a\	closeaction=restart" /etc/ipsec.conf
sed -i "$ a\	keyingtries=%forever" /etc/ipsec.conf

# Config ipsec for marker 2 and custom updown script
sed -i "$ a\	leftupdown=/ipsec.script.sh" /etc/ipsec.conf
sed -i "$ a\	mark_out=2" /etc/ipsec.conf

# Store the credentials for ipsec
echo $1 : EAP \"$2\" >> /etc/ipsec.secrets

# Change load config
sed -i "s/load = yes/load = no/g" /etc/strongswan.d/charon/constraints.conf

# Disable automatic creation of virtual IP address (as we are creating our own VTI device)
sed -i 's/# install_routes = yes/install_routes = no/g' /etc/strongswan.d/charon.conf

# Strongswan logging
logger="# two defined file loggers\n\
filelog {\n\
    charon {\n\
        # path to the log file, specify this as section name in versions prior to 5.7.0\n\
        path = /var/log/charon.log\n\
        # add a timestamp prefix\n\
        time_format = %b %e %T\n\
        # prepend connection name, simplifies grepping\n\
        ike_name = yes\n\
        # overwrite existing files\n\
        append = no\n\
        # increase default loglevel for all daemon subsystems\n\
        default = 2\n\
        # flush each line to disk\n\
        flush_line = yes\n\
    }\n\
    stderr {\n\
        # more detailed loglevel for a specific subsystem, overriding the\n\
        # default loglevel.\n\
        ike = 2\n\
        knl = 3\n\
    }\n\
}\n\
# and two loggers using syslog\n\
syslog {\n\
    # prefix for each log message\n\
    identifier = charon-custom\n\
    # use default settings to log to the LOG_DAEMON facility\n\
    daemon {\n\
    }\n\
    # very minimalistic IKE auditing logs to LOG_AUTHPRIV\n\
    auth {\n\
        default = -1\n\
        ike = 0\n\
    }\n\
}\n"

sed -i "/charon {/ a 	$logger" /etc/strongswan.conf

# Start ipsec daemon
ipsec start

# Wait for daemon
while [ $(ipsec status) != ""]; do
    echo "Waiting for ipsec daemon"
    sleep 1
done
echo "ipsec daemon started"

# Load the kernel module
modprobe xt_geoip
echo "xt_geoip loaded"

# CONFIG parameters
router_ip=$5
export DEV=$6
export HOME_COUNTRY_CODE=$7

# Derive the subnet for eth0
dev_subnet_cidr=$(ipcalc $(ip -o -f inet addr show $dev | awk '/scope global/ {print $4}') | awk '/Network:/ {print $2}')

###################################
# Part 1: Define the routing tables
###################################

# routing table for IP packets towards international destinations
ip rule add fwmark 2 table 2 prio 200

#############################
# Part 2: Marking in IPTables
#############################

# mark outgoing packages to international destinations (outside of Germany) with marker 2
# set the mark_out according to the ipsec conf for international packages
iptables -A PREROUTING -t mangle -m geoip ! --dst-cc $HOME_COUNTRY_CODE -i $DEV -s $dev_subnet_cidr -j MARK --set-mark 2

###################################
# Part 3: Routing Commands
###################################

# Prohibit packets towards international destinations (overriden by up.sh)
ip route add prohibit default table 2

# DEBUGGING RULES for netfilter logging to host machinee
#iptables -A PREROUTING -t mangle  -j LOG --log-prefix "PREROUTING mangle :" -m mark --mark 2
#iptables -A INPUT -t filter  -j LOG --log-prefix "INPUT filter :" -m mark --mark 2
#iptables -A OUTPUT -t filter  -j LOG --log-prefix "OUTPUT filter :" -m mark --mark 2
#iptables -A OUTPUT -t raw  -j LOG --log-prefix "OUTPUT raw :" -m mark --mark 2
#iptables -A POSTROUTING -t mangle  -j LOG --log-prefix "POSTROUTING mangle :" -m mark --mark 2
#iptables -A FORWARD -t filter  -j LOG --log-prefix "FORWARD filter :" -m mark --mark 2
#iptables -A FORWARD -t mangle  -j LOG --log-prefix "FORWARD mangle :" -m mark --mark 2

# Start tunnel
ipsec up NordVPN

# sleep forever until container terminates
while true; do sleep 3600; done
