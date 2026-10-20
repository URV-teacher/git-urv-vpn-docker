#!/usr/bin/env bash
# Installs openfortivpn, the client of the VPN of the URV, and the helper of the BMDE to connect to it
# (connect_vpn.sh) into /URV/bmde/git-urv-vpn/bin, and its environment (PATH) into
# /etc/profile.d/bmde-git-urv-vpn.sh. Standalone: can be run in an Ubuntu / Debian host, and is also used by the BMDE
# Docker images. Set BMDE_ROOT to install into another directory.
set -Eeuo pipefail

BMDE_ROOT="${BMDE_ROOT:-/URV/bmde}"
SUDO=""; if [ "$(id -u)" -ne 0 ]; then SUDO=sudo; fi
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_URL="https://raw.githubusercontent.com/URV-teacher/git-urv-vpn-docker/master"
BIN_DIR="${BMDE_ROOT}/git-urv-vpn/bin"

${SUDO} apt-get update
${SUDO} apt-get install -y --no-install-recommends ca-certificates wget openfortivpn

${SUDO} mkdir -p "${BIN_DIR}"
# Use the file of the repository if the script is run from it, or download it otherwise
if [ -f "${SCRIPT_DIR}/../src/connect_vpn.sh" ]; then
  ${SUDO} install -m 755 "${SCRIPT_DIR}/../src/connect_vpn.sh" "${BIN_DIR}/connect_vpn.sh"
else
  wget -q "${REPO_URL}/src/connect_vpn.sh" -O /tmp/connect_vpn.sh
  ${SUDO} install -m 755 /tmp/connect_vpn.sh "${BIN_DIR}/connect_vpn.sh"
  rm -f /tmp/connect_vpn.sh
fi

${SUDO} tee /etc/profile.d/bmde-git-urv-vpn.sh > /dev/null <<PROFILE
case ":\${PATH}:" in
  *":${BIN_DIR}:"*) ;;
  *) export PATH="${BIN_DIR}:\${PATH}" ;;
esac
PROFILE

echo "openfortivpn installed, with the helper of the BMDE in ${BIN_DIR}"
