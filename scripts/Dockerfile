FROM debian

##############################################
# PART 1: Install strongswan, configs, certs #
##############################################

# Install strongswan ipsec and basic packages
RUN apt-get update && apt-get upgrade && apt-get -y install iptables strongswan libcharon-extra-plugins wget kmod ipcalc rsyslog

# Install NordVPN certificate
RUN wget https://downloads.nord-help.com/certificates/root.der -O /etc/ipsec.d/cacerts/NordVPN.der && \
    openssl x509 -inform der -in /etc/ipsec.d/cacerts/NordVPN.der -out /etc/ipsec.d/cacerts/NordVPN.pem

# Copy the ipsec configuration as published by NordVPN but add "mark_out=2" for international
# packets.
COPY ipsec.conf /etc/ipsec.conf
RUN chmod 750 /etc/ipsec.conf

# Custom updown script for installing manual VTI device
COPY ipsec.script.sh /ipsec.script.sh
RUN chmod 750 /ipsec.script.sh

##########################################
# PART 2: Install geoip related material #
##########################################

# Install the geoip database
RUN apt-get -y install libgeoip2-perl libmaxminddb0 libnet-cidr-lite-perl libtext-csv-xs-perl unzip traceroute systemd tcpdump

# Manually install the xtables-addons-commons at it is not available in the standard repo
RUN wget http://ftp.jp.debian.org/debian/pool/main/x/xtables-addons/xtables-addons-common_3.13-1_armhf.deb && \
    dpkg -i xtables-addons-common_3.13-1_armhf.deb && \
    rm xtables-addons-common_3.13-1_armhf.deb

# Get updated geoip data
COPY update-geodb.sh /update-geodb.sh
RUN chmod 750 /update-geodb.sh
RUN --mount=type=secret,id=maxmind,dst=/maxmind /update-geodb.sh

# Remove all packages that were needed to update the geodb
RUN apt -y remove libgeoip2-perl libmaxminddb0 libnet-cidr-lite-perl libtext-csv-xs-perl unzip wget && \
    apt -y autoremove && \
    rm /update-geodb.sh

###################################
# PART 3: Entry point script ######
###################################   

# Setup script
COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

# Execute setup script
ENTRYPOINT ["/entrypoint.sh"]
