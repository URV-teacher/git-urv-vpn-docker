#!/bin/bash
set -euo pipefail

# Use read secret function
SSH_HOST="$(cat /run/secrets/ssh_host)"

echo "adding key server to known hosts"
mkdir -p /root/.ssh
ssh-keyscan -H $SSH_HOST >> /etc/ssh/ssh_known_hosts
echo "end adding key"

GIT_EMAIL="$(cat /run/secrets/git_email)"
GIT_NAME="$(cat /run/secrets/git_name)"
echo "Configuring email"
git config --global user.email "${GIT_EMAIL}"
echo "Configuring username"
git config --global user.email "${GIT_NAME}"

cd /repos
/git.exp $@