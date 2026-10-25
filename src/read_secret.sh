# shellcheck shell=bash
# Library of the VPN helpers (connect_vpn.sh, vpn_healthcheck.sh). Source it.
#
# read_secret NAME prints the value of the secret NAME (lowercase, e.g. vpn_password), from the first of:
#   1) /run/secrets/NAME, where Docker mounts its secrets (and bmde passes its credentials)
#   2) the file in $NAME_FILE (e.g. VPN_PASSWORD_FILE)
#   3) $NAME (e.g. VPN_PASSWORD)
# or nothing if it is in none of them.
read_secret() {
  local name="$1" upper
  upper="$(printf '%s' "${name}" | tr '[:lower:]' '[:upper:]')"
  local file_var="${upper}_FILE"

  if [ -f "/run/secrets/${name}" ]; then
    printf '%s' "$(< "/run/secrets/${name}")"
  elif [ -n "${!file_var:-}" ] && [ -f "${!file_var}" ]; then
    printf '%s' "$(< "${!file_var}")"
  else
    printf '%s' "${!upper:-}"
  fi
}
