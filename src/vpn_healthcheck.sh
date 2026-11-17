#!/usr/bin/env bash
# Exits 0 if the VPN of the URV works, 1 otherwise, from the state of openfortivpn instead of a file that the connection
# creates: openfortivpn is running, its PPP interface exists and the git server answers through it: a TCP connection to
# vpn_test_host (see read_secret.sh), git.deim.urv.cat:22 by default, the SSH port that git clones through. Its name is
# resolved with the DNS of the VPN, so that is checked too. It only reads, so it needs no root and works in a host as well
# as the HEALTHCHECK of the image (where the network is the one of the container).
#
# vpn_test_ip and vpn_test_dns, which it requested by HTTP before, are not used anymore: the URV stopped routing the test
# IP through the VPN, and the internal network answering a web page does not tell that the git server answers.
#
#   vpn_healthcheck.sh [-v]    (-v prints the reason when the VPN does not work)
#
# VPN_CHECK_TIMEOUT: seconds that the connection to the git server can take (3 by default)
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
# shellcheck source-path=SCRIPTDIR source=read_secret.sh
source "${SCRIPT_DIR}/read_secret.sh"

# The SSH port of the git server of the DEIM, which is only reachable through the VPN
DEFAULT_TEST_HOST="git.deim.urv.cat:22"

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

# Whether a TCP connection to HOST:PORT succeeds within VPN_CHECK_TIMEOUT seconds (bash opens it through /dev/tcp)
answers() {
  local host="${1%:*}" port="${1##*:}"
  # shellcheck disable=SC2016 # the host and the port are the arguments of the inner bash
  timeout "${VPN_CHECK_TIMEOUT:-3}" bash -c ': < "/dev/tcp/$1/$2"' _ "${host}" "${port}" 2> /dev/null
}

openfortivpn_running || unhealthy "openfortivpn is not running"
ppp_interface_up || unhealthy "there is no PPP interface: the tunnel is not established"

test_host="$(read_secret vpn_test_host)"
test_host="${test_host:-${DEFAULT_TEST_HOST}}"
case "${test_host}" in
  *:*) ;;
  *) test_host="${test_host}:22" ;;
esac
answers "${test_host}" || unhealthy "${test_host} does not answer: the routes or the DNS of the VPN are not ready"
