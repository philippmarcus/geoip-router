#!/bin/bash

# end script immediately if any command fails
set -euo pipefail

geotmpdir=$(mktemp -d)
csv_files="GeoLite2-Country-Blocks-IPv4.csv GeoLite2-Country-Blocks-IPv6.csv"
OLDPWD="${PWD}"
cd "${geotmpdir}"
/usr/libexec/xtables-addons/xt_geoip_dl_maxmind /maxmind
cd GeoLite2-Country-CSV_*
mkdir -p /usr/share/xt_geoip
/usr/libexec/xtables-addons/xt_geoip_build_maxmind -D /usr/share/xt_geoip ${csv_files}
cd "${OLDPWD}"
rm -r "${geotmpdir}"
exit 0
