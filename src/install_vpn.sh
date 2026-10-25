#!/usr/bin/env bash
# Installs openfortivpn, the client of the VPN of the URV, and the helpers of the BMDE to connect to it (connect_vpn.sh)
# and to check that it works (vpn_healthcheck.sh) into /URV/bmde/git-urv-vpn/bin, and its environment (PATH) into
# /etc/profile.d/bmde-git-urv-vpn.sh. Can be run in an Ubuntu / Debian host from a checkout of the repository, and is
# also used by the BMDE Docker images. Set BMDE_ROOT to install into another directory.
set -Eeuo pipefail

BMDE_ROOT="${BMDE_ROOT:-/URV/bmde}"
SUDO=""; if [ "$(id -u)" -ne 0 ]; then SUDO=sudo; fi
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
BIN_DIR="${BMDE_ROOT}/git-urv-vpn/bin"

${SUDO} apt-get update
${SUDO} apt-get install -y --no-install-recommends ca-certificates wget openfortivpn

${SUDO} mkdir -p "${BIN_DIR}"
${SUDO} install -m 755 "${SCRIPT_DIR}/connect_vpn.sh" "${BIN_DIR}/connect_vpn.sh"
${SUDO} install -m 755 "${SCRIPT_DIR}/vpn_healthcheck.sh" "${BIN_DIR}/vpn_healthcheck.sh"
${SUDO} install -m 644 "${SCRIPT_DIR}/read_secret.sh" "${BIN_DIR}/read_secret.sh"
# Also in /usr/local/bin, for the shells that do not load /etc/profile.d: the HEALTHCHECK of Docker, and sudo, whose
# secure_path replaces the PATH. The helpers find the files next to them through the links
for helper in connect_vpn.sh vpn_healthcheck.sh; do
  ${SUDO} ln -sf "${BIN_DIR}/${helper}" "/usr/local/bin/${helper}"
done

${SUDO} tee /etc/profile.d/bmde-git-urv-vpn.sh > /dev/null <<PROFILE
case ":\${PATH}:" in
  *":${BIN_DIR}:"*) ;;
  *) export PATH="${BIN_DIR}:\${PATH}" ;;
esac
PROFILE

echo "openfortivpn installed, with the helper of the BMDE in ${BIN_DIR}"
