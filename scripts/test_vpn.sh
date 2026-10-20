#!/usr/bin/env bash
# Tests that openfortivpn is installed, with the helper of the BMDE.
set -Eeuo pipefail

openfortivpn --version
command -v connect_vpn.sh
