#!/usr/bin/env bash
# Tests that git is installed, with the helpers of the BMDE.
set -Eeuo pipefail

git --version
command -v git.exp git_clone.exp clone_repos.sh expect jq
