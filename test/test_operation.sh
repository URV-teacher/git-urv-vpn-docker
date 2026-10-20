#!/usr/bin/env bash
# Tests the git operation: clones a repository of the course through SSH. Manual test: replace USER_ID with your user
# (it asks for your password), and connect to the VPN of the URV first if you are outside its network.
set -Eeuo pipefail

git clone USER_ID@git.deim.urv.cat:comp_25 .
