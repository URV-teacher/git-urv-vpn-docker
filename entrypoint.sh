#!/bin/bash

set -e

# Path to secrets
USER_SECRET_PATH="/run/secrets/vpn_user"
PASS_SECRET_PATH="/run/secrets/vpn_pass"
PROFILE_SECRET_PATH="/run/secrets/vpn_profile"
GATEWAY_SECRET_PATH="/run/secrets/vpn_gateway"

# Validate secrets
if [[ ! -f "$USER_SECRET_PATH" ]]; then
    echo "❌ VPN user secret not found at $USER_SECRET_PATH"
    exit 1
fi

if [[ ! -f "$PASS_SECRET_PATH" ]]; then
    echo "❌ VPN password secret not found at $PASS_SECRET_PATH"
    exit 1
fi

if [[ ! -f "$PROFILE_SECRET_PATH" ]]; then
    echo "❌ VPN profile secret not found at $PROFILE_SECRET_PATH"
    exit 1
fi

if [[ ! -f "$GATEWAY_SECRET_PATH" ]]; then
    echo "❌ VPN gateway secret not found at $GATEWAY_SECRET_PATH"
    exit 1
fi

VPN_USER="$(< "$USER_SECRET_PATH")"
VPN_PASS="$(< "$PASS_SECRET_PATH")"
VPN_PROFILE="$(< "$PROFILE_SECRET_PATH")"
VPN_GATEWAY="$(< "$GATEWAY_SECRET_PATH")"

if [[ -z "$VPN_USER" ]]; then
    echo "❌ VPN user secret is empty"
    exit 1
fi

if [[ -z "$VPN_PASS" ]]; then
    echo "❌ VPN password secret is empty"
    exit 1
fi

if [[ -z "$VPN_PROFILE" ]]; then
    echo "❌ VPN profile secret is empty"
    exit 1
fi

if [[ -z "$VPN_GATEWAY" ]]; then
    echo "❌ VPN gateway secret is empty"
    exit 1
fi

# Configure VPN profile if not already existing
if ! forticlient vpn | grep -q "$VPN_PROFILE"; then
    echo "⚙️  Configuring VPN profile: $VPN_PROFILE"
    /usr/local/bin/configure_fortivpn.exp "$VPN_PROFILE" "$VPN_HOST" "$VPN_USER"
fi

# Connect to VPN
echo "🔐 Connecting to VPN profile: $VPN_PROFILE as user $VPN_USER"
/usr/local/bin/connect_fortivpn.exp $(cat ./secrets/VPN_PROFILE) $(cat ./secrets/VPN_PASSWORD)
