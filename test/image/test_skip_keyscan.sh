#!/usr/bin/env bash
# Tests --skip-keyscan of the entrypoint of the git image: with it, git runs without reaching the git server to trust
# its key (here, without any network at all), while by default the entrypoint still trusts it first. Runs the image
# from the host (unlike the tests of test/, which run inside the image), so it needs Docker.
#
#   test/image/test_skip_keyscan.sh [IMAGE]    (aleixmt/git-sshpass:latest by default)
set -Eeuo pipefail

IMAGE="${1:-aleixmt/git-sshpass:latest}"

status=0

# A local repository, as tot checks out a commit of a clone: no network needed
work_dir="$(mktemp -d)"
git -C "${work_dir}" init -q
git -C "${work_dir}" -c user.name=test -c user.email=test@test commit -q --allow-empty -m first
commit="$(git -C "${work_dir}" rev-parse HEAD)"
git -C "${work_dir}" -c user.name=test -c user.email=test@test commit -q --allow-empty -m second

if ! output="$(docker run --rm --network none --user "$(id -u):$(id -g)" -v "${work_dir}:/repos/repo" \
  -w /repos/repo "${IMAGE}" --skip-keyscan checkout -q "${commit}" 2>&1)"; then
  echo "git didn't run with --skip-keyscan:" >&2
  echo "${output}" >&2
  status=1
elif [ "$(git -C "${work_dir}" rev-parse HEAD)" != "${commit}" ]; then
  echo "git didn't check out ${commit} with --skip-keyscan" >&2
  status=1
elif grep -q "Adding server key" <<< "${output}"; then
  echo "--skip-keyscan still added the server key" >&2
  status=1
fi
rm -rf "${work_dir}"

# By default the key is still trusted first, which can't work without the network
if output="$(docker run --rm --network none "${IMAGE}" --version 2>&1)"; then
  echo "git ran without trusting the server key first" >&2
  status=1
elif ! grep -q "Adding server key" <<< "${output}"; then
  echo "the server key wasn't added by default:" >&2
  echo "${output}" >&2
  status=1
fi

[ "${status}" -eq 0 ]
echo "--skip-keyscan OK"
