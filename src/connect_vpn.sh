#!/usr/bin/env bash
# Connects to the VPN of the URV with openfortivpn, waits until it works (vpn_healthcheck.sh) and stays connected until
# openfortivpn ends (Ctrl+C disconnects). The same in a host and in a container: run it as your user, without sudo.
# Only openfortivpn needs root (to create the PPP interface), so it is run with sudo when the user is not root.
#
# Credentials (see read_secret.sh): vpn_username, vpn_password, vpn_host, vpn_port, vpn_realm and vpn_cert, and
# vpn_test_ip and vpn_test_dns, which tell that the internal network works (optional). The configuration of openfortivpn,
# with the password, and its log are written to VPN_STATE_DIR, only readable by the user, never to /etc or /var/log;
# the configuration is removed as soon as openfortivpn has read it.
#
#   VPN_STATE_DIR  where the configuration and the log go ($XDG_RUNTIME_DIR/bmde-vpn, or /tmp/bmde-vpn-UID)
#   VPN_TIMEOUT    seconds to wait for the VPN to work before giving up (300)
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
# shellcheck source-path=SCRIPTDIR source=read_secret.sh
source "${SCRIPT_DIR}/read_secret.sh"

SUDO=()
if [ "$(id -u)" -ne 0 ]; then
  SUDO=(sudo)
fi
if [ -n "${XDG_RUNTIME_DIR:-}" ] && [ -d "${XDG_RUNTIME_DIR}" ]; then
  STATE_DIR="${VPN_STATE_DIR:-${XDG_RUNTIME_DIR}/bmde-vpn}"
else
  STATE_DIR="${VPN_STATE_DIR:-/tmp/bmde-vpn-$(id -u)}"
fi
CONFIG="${STATE_DIR}/config"
LOG="${STATE_DIR}/vpn.log"
TIMEOUT="${VPN_TIMEOUT:-300}"

install -d -m 700 "${STATE_DIR}"
(
  umask 077
  cat > "${CONFIG}" <<EOF
host = $(read_secret vpn_host)
port = $(read_secret vpn_port)
username = $(read_secret vpn_username)
password = $(read_secret vpn_password)
realm = $(read_secret vpn_realm)
trusted-cert = $(read_secret vpn_cert)
set-routes = 1
set-dns = 1
EOF
)
: > "${LOG}"

# VPN_PID is the one of sudo when the user is not root: a process of root, which only root can signal (sudo relays the
# signal to openfortivpn), so it is killed with sudo and checked through /proc instead of with kill -0
VPN_PID=""
vpn_running() {
  [ -n "${VPN_PID}" ] && [ -d "/proc/${VPN_PID}" ]
}
cleanup() {
  rm -f "${CONFIG}"
  if vpn_running; then
    "${SUDO[@]}" kill "${VPN_PID}" 2> /dev/null || true
  fi
}
trap cleanup EXIT

# Asks for the password of sudo now, in the foreground: openfortivpn runs in the background
if [ ${#SUDO[@]} -gt 0 ]; then
  sudo -v
fi

echo "🔐 Connecting to the VPN (log: ${LOG})"
"${SUDO[@]}" openfortivpn -c "${CONFIG}" -v > >(tee -a "${LOG}") 2>&1 &
VPN_PID=$!

echo "Waiting for the VPN to work (this usually takes about 2 minutes)..."
SECONDS=0
until "${SCRIPT_DIR}/vpn_healthcheck.sh"; do
  if ! vpn_running; then
    echo "openfortivpn ended before the VPN worked. Aborting." >&2
    exit 1
  fi
  if [ "${SECONDS}" -ge "${TIMEOUT}" ]; then
    echo "The VPN did not work after ${TIMEOUT} seconds. Aborting." >&2
    "${SCRIPT_DIR}/vpn_healthcheck.sh" -v || true
    exit 1
  fi
  # openfortivpn reads its configuration when it starts, so the password does not stay on disk once it is connecting
  if [ -f "${CONFIG}" ] && grep -q "Remote gateway has allocated a VPN" "${LOG}"; then
    rm -f "${CONFIG}"
  fi
  sleep 2
done
rm -f "${CONFIG}"

echo "VPN validated. Waiting for the termination of the VPN process (check it with vpn_healthcheck.sh)"
wait "${VPN_PID}"
