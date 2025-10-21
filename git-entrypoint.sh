#!/bin/bash
set -e

GIT_SERVER="$(cat /run/secrets/git_server)"
echo "adding key server to known hosts"
mkdir -p /root/.ssh
ssh-keyscan -H $GIT_SERVER >> /etc/ssh/ssh_known_hosts
echo "end adding key"

cd /repos
/git.exp $@