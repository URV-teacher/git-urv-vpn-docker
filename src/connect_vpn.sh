#!/bin/bash

set -e

# Path to secrets
USER_SECRET_PATH="/run/secrets/urv_user"
PASS_SECRET_PATH="/run/secrets/urv_pass"
REALM_SECRET_PATH="/run/secrets/vpn_realm"
GATEWAY_SECRET_PATH="/run/secrets/vpn_gateway"
PORT_SECRET_PATH="/run/secrets/vpn_port"
TRUSTED_CERT_SECRET_PATH="/run/secrets/vpn_trusted_cert"

# Validate secrets
if [[ ! -f "$USER_SECRET_PATH" ]]; then
    echo "❌ VPN user secret not found at $USER_SECRET_PATH"
    exit 1
fi

if [[ ! -f "$PASS_SECRET_PATH" ]]; then
    echo "❌ VPN password secret not found at $PASS_SECRET_PATH"
    exit 1
fi

if [[ ! -f "$REALM_SECRET_PATH" ]]; then
    echo "❌ VPN realm secret not found at $REALM_SECRET_PATH"
    exit 1
fi

if [[ ! -f "$GATEWAY_SECRET_PATH" ]]; then
    echo "❌ VPN gateway secret not found at $GATEWAY_SECRET_PATH"
    exit 1
fi

if [[ ! -f "$PORT_SECRET_PATH" ]]; then
    echo "❌ VPN port secret not found at $PORT_SECRET_PATH"
    exit 1
fi

if [[ ! -f "$TRUSTED_CERT_SECRET_PATH" ]]; then
    echo "❌ VPN port secret not found at $TRUSTED_CERT_SECRET_PATH"
    exit 1
fi

VPN_USER="$(< "$USER_SECRET_PATH")"
VPN_PASS="$(< "$PASS_SECRET_PATH")"
VPN_REALM="$(< "$REALM_SECRET_PATH")"
VPN_GATEWAY="$(< "$GATEWAY_SECRET_PATH")"
VPN_PORT="$(< "$PORT_SECRET_PATH")"
VPN_TRUSTED_CERT="$(< "$TRUSTED_CERT_SECRET_PATH")"

if [[ -z "$VPN_USER" ]]; then
    echo "❌ VPN user secret is empty"
    exit 1
fi

if [[ -z "$VPN_PASS" ]]; then
    echo "❌ VPN password secret is empty"
    exit 1
fi

if [[ -z "$VPN_REALM" ]]; then
    echo "❌ VPN realm secret is empty"
    exit 1
fi

if [[ -z "$VPN_GATEWAY" ]]; then
    echo "❌ VPN gateway secret is empty"
    exit 1
fi

if [[ -z "$VPN_PORT" ]]; then
    echo "❌ VPN port secret is empty"
    exit 1
fi

if [[ -z "$VPN_TRUSTED_CERT" ]]; then
    echo "❌ VPN trusted cert secret is empty"
    exit 1
fi

# Configure openfortiVPN
tee /etc/openfortivpn/config > /dev/null <<EOF
host = $VPN_GATEWAY
port = $VPN_PORT
username = $VPN_USER
password = $VPN_PASS
realm = $VPN_REALM
trusted-cert = $VPN_TRUSTED_CERT
set-routes = 1
set-dns = 1
EOF

echo "🔐 Connecting to VPN"
openfortivpn -vv >/var/log/vpn.log 2>&1 &

# Espera a que la VPN esté activa
echo "Waiting for the VPN to stablish..."
TRIES=0
while ! grep -q "Remote gateway has allocated a VPN" /var/log/vpn.log; do
    sleep 1
    TRIES=$((TRIES+1))
    if [ $TRIES -gt 20 ]; then
        echo "VPN did not connect after 20 seconds. Aborting."
        cat /var/log/vpn.log
        exit 1
    fi
done

echo "VPN active. Testing"
echo "IP solvable? (wait, this usually takes approximately 2 minutes and 10 seconds)"
if wget 10.117.30.11 -O /var/log/ip.html > /var/log/ip.log 2>&1; then
  echo "Yes"
else
  echo "No. Aborting"
  exit 1
fi
echo "DNS solvable?"
if wget https://intranet.deim.urv.cat/ -O /var/log/dns.html > /var/log/dns.log 2>&1; then
  echo "Yes"
else
  echo "No. Aborting"
  exit 2
fi
echo "VPN validated. Continuing"
