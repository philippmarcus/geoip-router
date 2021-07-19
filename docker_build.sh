#!/bin/bash

set -e

# Source config parameters
source geoip-router.conf

# Create a temporary key file
echo $MAXMIND_KEY > maxmind.key
chmod 400 maxmind.key

# Build the Docker container
DOCKER_BUILDKIT=1 docker build --env VPN_CERT_LOCATION=$VPN_CERT_LOCATION --progress=plain --secret id=maxmind,src=maxmind.key -t geovpn ./scripts

# Remove key file
rm -f maxmind.key
