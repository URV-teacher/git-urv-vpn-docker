#!/usr/bin/env bash
# Tests that openfortivpn is installed, with the helpers of the BMDE, and that the health check tells that the VPN does
# not work when it is not connected, as any user (it needs no root).
set -Eeuo pipefail

openfortivpn --version
command -v connect_vpn.sh vpn_healthcheck.sh
# Also for sudo and the HEALTHCHECK of Docker, which do not load the PATH of /etc/profile.d
test -x /usr/local/bin/connect_vpn.sh
test -x /usr/local/bin/vpn_healthcheck.sh

if vpn_healthcheck.sh -v; then
  echo "vpn_healthcheck.sh says that the VPN works, but it is not connected" >&2
  exit 1
fi
echo "openfortivpn OK"
