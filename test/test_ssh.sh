#!/usr/bin/env bash
# Tests that the SSH client is installed.
set -Eeuo pipefail

ssh -V
command -v ssh-keyscan
echo "SSH OK"
