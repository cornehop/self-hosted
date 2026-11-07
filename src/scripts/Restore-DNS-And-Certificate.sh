#!/bin/bash
# Restore-DNS-And-Certificate.sh
# Re-applies SteamOS-wiped config after an update:
#   1. /etc/hosts entry for home.huizehop -> 192.168.68.66
#   2. Caddy root CA trust
#
# Usage: run after every SteamOS update:
#   ./Restore-DNS-And-Certificate.sh
#
# Place this script somewhere in /home/deck (e.g. ~/scripts/) --
# the home partition is never touched by SteamOS updates.

set -euo pipefail

HOSTNAME_ENTRY="home.huizehop"
HOST_IP="192.168.68.66"
CA_SOURCE="$HOME/Certificates/caddy-ca.crt"
CA_ANCHOR="/etc/ca-certificates/trust-source/anchors/caddy-ca.crt"

hosts_done=false
ca_done=false

# --- 1. /etc/hosts entry ---
if grep -qE "^[[:space:]]*${HOST_IP}[[:space:]]+.*${HOSTNAME_ENTRY}([[:space:]]|\$)" /etc/hosts; then
    echo "[hosts] Entry for ${HOSTNAME_ENTRY} already present, skipping."
else
    echo "[hosts] Adding ${HOST_IP} ${HOSTNAME_ENTRY} to /etc/hosts..."
    echo "${HOST_IP} ${HOSTNAME_ENTRY}" | sudo tee -a /etc/hosts >/dev/null
    hosts_done=true
fi

# --- 2. Caddy root CA trust ---
if [[ ! -f "$CA_SOURCE" ]]; then
    echo "[ca] WARNING: ${CA_SOURCE} not found!"
    echo "[ca] Put the Caddy root certificate there first:"
    echo "[ca]   (on the server) docker cp caddy:/data/caddy/pki/authorities/local/root.crt ~/Downloads/caddy-ca.crt"
elif [[ -f "$CA_ANCHOR" ]] && cmp -s "$CA_SOURCE" "$CA_ANCHOR"; then
    echo "[ca] CA already installed and identical, skipping."
else
    echo "[ca] Installing Caddy root CA..."
    sudo cp "$CA_SOURCE" "$CA_ANCHOR"
    sudo update-ca-trust
    ca_done=true
fi

# --- 3. Verify ---
echo ""
echo "--- Verification ---"
getent hosts "$HOSTNAME_ENTRY" >/dev/null && \
    echo "[ok] ${HOSTNAME_ENTRY} resolves to $(getent hosts "$HOSTNAME_ENTRY" | awk '{print $1}')" || \
    echo "[FAIL] ${HOSTNAME_ENTRY} does not resolve"

if curl -sfIo /dev/null --max-time 5 "https://${HOSTNAME_ENTRY}"; then
    echo "[ok] https://${HOSTNAME_ENTRY} is reachable and certificate trusted"
else
    echo "[note] Could not reach https://${HOSTNAME_ENTRY} via curl"
    echo "[note] (Server offline, Caddy down, or CA not yet trusted)"
fi

echo ""
echo "Done. Remember to re-run this script after the next SteamOS update."
