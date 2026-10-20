#!/usr/bin/env bash
# Installs git (and gitk), and the helpers of the BMDE to run git commands (git.exp, git_clone.exp, clone_repos.sh) into
# /URV/bmde/git-urv-vpn/bin, and its environment (PATH) into /etc/profile.d/bmde-git-urv-vpn.sh. Can be run in an Ubuntu
# / Debian host from a checkout of the repository, and is also used by the BMDE Docker images. Set BMDE_ROOT to install
# into another directory.
set -Eeuo pipefail

BMDE_ROOT="${BMDE_ROOT:-/URV/bmde}"
SUDO=""; if [ "$(id -u)" -ne 0 ]; then SUDO=sudo; fi
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
BIN_DIR="${BMDE_ROOT}/git-urv-vpn/bin"

${SUDO} apt-get update
${SUDO} apt-get install -y --no-install-recommends ca-certificates wget git gitk expect jq

${SUDO} mkdir -p "${BIN_DIR}"
for helper in git.exp git_clone.exp clone_repos.sh; do
  ${SUDO} install -m 755 "${SCRIPT_DIR}/${helper}" "${BIN_DIR}/${helper}"
done

${SUDO} tee /etc/profile.d/bmde-git-urv-vpn.sh > /dev/null <<PROFILE
case ":\${PATH}:" in
  *":${BIN_DIR}:"*) ;;
  *) export PATH="${BIN_DIR}:\${PATH}" ;;
esac
PROFILE

echo "git installed, with the helpers of the BMDE in ${BIN_DIR}"
