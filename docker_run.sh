#!/bin/bash

# Source  parameters
source geoip-router.conf

# Create a network
docker network create -d macvlan \
  --subnet=$NETWORK_SUBNET \
  --gateway=$NETWORK_GATEWAY \
  --ip-range=$NETWORK_CONTAINER_IP \
  -o parent=$DEV \
  homenet

# Start the container
docker run -dit --rm --network=homenet \
		--log-driver=journald \
		--name demo \
		--privileged --cap-add=ALL \
		-v /dev:/dev -v /lib/modules:/lib/modules \
		geovpn \
		$VPN_USERNAME \
		$VPN_PASSWORD \
		$VPN_SERVER_IP \
		$VPN_SERVER_NAME \
		$NETWORK_GATEWAY \
		$DEV \
		$HOME_COUNTRY

# Bash in the container
docker exec -it demo bash

# Stop container
docker container stop demo

# Delete network
docker network rm homenet
