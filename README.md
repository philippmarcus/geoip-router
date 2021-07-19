# Traffic Split Router for a Raspberry Pi 4b based on GeoIP, IPsec, and Docker

This collection of scripts builds and starts a Docker conttainer on a Raspberry Pi 4b in macvlan mode, that acts as a VPN internet \
router for other PCs in the home network based on the location of the destination. he Raspberry Pi coexists as a router in the same \
subnet as the WAN internet router and can be used as a router by individual devices if required. This allows in the best case to consume both, \
domestic and international streaming/media content all without geolocation restrictions. Roughly, the solution works as follows:

- A Docker container starts with macvlan mode on the Raspberry Pi 4b
- The geoip kernel module of the host sysem is loaded in the namespace of the docker conainer
- Iptables rules are setup to mark all packages to international destinations with the marker 2
- A policy routing table is setup that per default prohibits all packages with marker 2 unless an ipsec connection is established
- The updown script of the ipsec connection adds default routes to the policy route table for international packages
- The traffic selector of the ipsec security association is defined to tunnel packets from the inside ip of thee tunnel (`leftsourceip`) that have the `mark_out=2`
- Accordingly the `updown` script of the ipsec connection installs a SNAT rule for all routable packets that have a marker 2 towards the inside ip of the tunnel 
- All unmarked packets are forwarded by the container to the default gateway of the home network instead of the tunnel

The solution is tailored for NordVPN but can be adjusted to any other VPN vendor that is ueses IPsec / strongswan. The charm of the solution is that the existing WLAN \
can continue to be used unchanged. Additionally, the Docker container on the Raspberry Pi is available as an alternative router for individual devices that require the VPN traffic split functionality. \
Also, the host system of the Raspberry Pi is not modified except for the kernel module that has to be installed (but not loaded on the host). \
Drawbacks are potential DNS leaks if a domestic DNS server is used, or geolocation blocks imposed on domestic websites if an international DNS server is used (to be added in future releases).

## Contents

```
├── docker_build_run.sh
├── docker_build.sh
├── docker_run.sh
├── geoip-router.conf
├── LICENSE
├── README.md
└── scripts
    ├── Dockerfile
    ├── entrypoint.sh
    ├── ipsec.conf
    ├── ipsec.script.sh
    └── update-geodb.sh
```

## Requirements

The requirements of this setup are as follows:

- A Raspberry Pi 4b
- Installation of the package `xtables-addons-common` on the Raspberry Pi 4b host
- A license key from (https://www.maxmind.com/en/geolite2/signup) for updating the geoip database
= A Docker installation on the Rasspberry Pi 4b
- An account from NordVPN

Most likely the setup also works on other systems, but was only tested on the Raspberry Pi 4b.

## Installation

- Insert your configuration parameters in the file `geoip-router.conf`
- Execute `bocker_build.sh` to build the Docker image, incl. download of the geoip
- Execute `docker_run.sh` to start the container as a router, check the connection status with `ipsec status`
- Configure your client computers to use the container's IP as Gateway/Router

Even if the setup was tested, here some advices for debugging:

- If debugging is required, enable in `/etc/sysctl.conf` the option `net.netfilter.nf_log_all_netns=1` and uncomment the iptables logging lines in `scripts/entrypoint.sh`. See log output on the host with `journalctl -f | grep FORWARD`
- Debugging within the Docker container can be done with `iptables -L -nv -t mangle` to show the packets that matched the marker
- Also recommended is `tcpdump -i eth0`
