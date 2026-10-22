#!/usr/bin/env bash
# Installs git (and gitk, when there is one for that git), and the helpers of the BMDE to run git commands (git.exp,
# git_clone.exp, clone_repos.sh) into /URV/bmde/git-urv-vpn/bin, and its environment (PATH) into
# /etc/profile.d/bmde-git-urv-vpn.sh. Can be run in an Ubuntu / Debian host from a checkout of the repository, and is
# also used by the BMDE Docker images. Set BMDE_ROOT to install into another directory.
set -Eeuo pipefail

BMDE_ROOT="${BMDE_ROOT:-/URV/bmde}"
SUDO=""; if [ "$(id -u)" -ne 0 ]; then SUDO=sudo; fi
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
BIN_DIR="${BMDE_ROOT}/git-urv-vpn/bin"

${SUDO} apt-get update
packages=(ca-certificates wget git expect jq)
# gitk is only a history viewer, so it is skipped when the distribution has no gitk for the git installed: e.g. a git
# from the git-core PPA (like in the GitHub runners), newer than the one the gitk of Ubuntu depends on
if apt-get install -s -y --no-install-recommends git gitk > /dev/null 2>&1; then
  packages+=(gitk)
else
  echo "WARNING: gitk is not installed, because there is no version of it for the installed git" >&2
fi
${SUDO} apt-get install -y --no-install-recommends "${packages[@]}"

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
