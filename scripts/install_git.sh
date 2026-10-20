#!/usr/bin/env bash
# Installs git (and gitk), and the helpers of the BMDE to run git commands (git.exp, git_clone.exp, clone_repos.sh) into
# /URV/bmde/git-urv-vpn/bin, and its environment (PATH) into /etc/profile.d/bmde-git-urv-vpn.sh. Standalone: can be run
# in an Ubuntu / Debian host, and is also used by the BMDE Docker images. Set BMDE_ROOT to install into another
# directory.
set -Eeuo pipefail

BMDE_ROOT="${BMDE_ROOT:-/URV/bmde}"
SUDO=""; if [ "$(id -u)" -ne 0 ]; then SUDO=sudo; fi
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_URL="https://raw.githubusercontent.com/URV-teacher/git-urv-vpn-docker/master"
BIN_DIR="${BMDE_ROOT}/git-urv-vpn/bin"

${SUDO} apt-get update
${SUDO} apt-get install -y --no-install-recommends ca-certificates wget git gitk expect jq

${SUDO} mkdir -p "${BIN_DIR}"
for helper in git.exp git_clone.exp clone_repos.sh; do
  # Use the file of the repository if the script is run from it, or download it otherwise
  if [ -f "${SCRIPT_DIR}/../src/${helper}" ]; then
    ${SUDO} install -m 755 "${SCRIPT_DIR}/../src/${helper}" "${BIN_DIR}/${helper}"
  else
    wget -q "${REPO_URL}/src/${helper}" -O "/tmp/${helper}"
    ${SUDO} install -m 755 "/tmp/${helper}" "${BIN_DIR}/${helper}"
    rm -f "/tmp/${helper}"
  fi
done

${SUDO} tee /etc/profile.d/bmde-git-urv-vpn.sh > /dev/null <<PROFILE
case ":\${PATH}:" in
  *":${BIN_DIR}:"*) ;;
  *) export PATH="${BIN_DIR}:\${PATH}" ;;
esac
PROFILE

echo "git installed, with the helpers of the BMDE in ${BIN_DIR}"
