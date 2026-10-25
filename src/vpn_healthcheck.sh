#!/usr/bin/env bash
# Exits 0 if the VPN of the URV works, 1 otherwise, from the state of openfortivpn instead of a file that the connection
# creates: openfortivpn is running, its PPP interface exists and, if they are configured, the internal network answers
# through it (vpn_test_ip and vpn_test_dns, see read_secret.sh). It only reads, so it needs no root and works in a host
# as well as the HEALTHCHECK of the image (where the network is the one of the container).
#
#   vpn_healthcheck.sh [-v]    (-v prints the reason when the VPN does not work)
#
# VPN_CHECK_TIMEOUT: seconds that each request to the internal network can take (3 by default)
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
# shellcheck source-path=SCRIPTDIR source=read_secret.sh
source "${SCRIPT_DIR}/read_secret.sh"

VERBOSE=0
if [ "${1:-}" = -v ]; then
  VERBOSE=1
fi

unhealthy() {
  if [ "${VERBOSE}" -eq 1 ]; then
    echo "VPN not working: $*" >&2
  fi
  exit 1
}

# The name of every process is in /proc, readable by every user, also for the processes of root
openfortivpn_running() {
  local comm name
  for comm in /proc/[0-9]*/comm; do
    if read -r name 2> /dev/null < "${comm}" && [ "${name}" = openfortivpn ]; then
      return 0
    fi
  done
  return 1
}

# openfortivpn creates a pppN interface when the gateway allocates the tunnel, and pppd removes it when it ends
ppp_interface_up() {
  local interface
  for interface in /sys/class/net/ppp*; do
    if [ -e "${interface}" ]; then
      return 0
    fi
  done
  return 1
}

answers() {
  wget -q -t 1 -T "${VPN_CHECK_TIMEOUT:-3}" -O /dev/null "$1"
}

openfortivpn_running || unhealthy "openfortivpn is not running"
ppp_interface_up || unhealthy "there is no PPP interface: the tunnel is not established"

test_ip="$(read_secret vpn_test_ip)"
if [ -n "${test_ip}" ]; then
  answers "${test_ip}" || unhealthy "${test_ip} does not answer: the routes of the VPN are not ready"
fi
test_dns="$(read_secret vpn_test_dns)"
if [ -n "${test_dns}" ]; then
  answers "${test_dns}" || unhealthy "${test_dns} does not answer: the DNS of the VPN is not ready"
fi
