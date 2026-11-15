#!/bin/bash
# Restore-DNS-And-Certificate.sh
# Re-applies SteamOS-wiped config after an update:
#   1. /etc/hosts entries for home.huizehop and actual.huizehop -> 192.168.68.66
#   2. Caddy root CA trust
#
# Usage: run after every SteamOS update:
#   ./Restore-DNS-And-Certificate.sh
#
# Place this script somewhere in /home/deck (e.g. ~/scripts/) --
# the home partition is never touched by SteamOS updates.

set -euo pipefail

HOSTNAMES=("home.huizehop" "actual.huizehop")
HOST_IP="192.168.68.66"
CA_SOURCE="$HOME/Certificates/caddy-ca.crt"
CA_ANCHOR="/etc/ca-certificates/trust-source/anchors/caddy-ca.crt"

hosts_done=false
ca_done=false

# --- 1. /etc/hosts entries ---
for HOSTNAME in "${HOSTNAMES[@]}"; do
    if grep -qE "^[[:space:]]*${HOST_IP}[[:space:]]+.*${HOSTNAME}([[:space:]]|\$)" /etc/hosts; then
        echo "[hosts] Entry for ${HOSTNAME} already present, skipping."
    else
        echo "[hosts] Adding ${HOST_IP} ${HOSTNAME} to /etc/hosts..."
        echo "${HOST_IP} ${HOSTNAME}" | sudo tee -a /etc/hosts >/dev/null
        hosts_done=true
    fi
done

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
for HOSTNAME in "${HOSTNAMES[@]}"; do
    getent hosts "$HOSTNAME" >/dev/null && \
        echo "[ok] ${HOSTNAME} resolves to $(getent hosts "$HOSTNAME" | awk '{print $1}')" || \
        echo "[FAIL] ${HOSTNAME} does not resolve"

    if curl -sfIo /dev/null --max-time 5 "https://${HOSTNAME}"; then
        echo "[ok] https://${HOSTNAME} is reachable and certificate trusted"
    else
        echo "[note] Could not reach https://${HOSTNAME} via curl"
        echo "[note] (Server offline, Caddy down, or CA not yet trusted)"
    fi
done

echo ""
echo "Done. Remember to re-run this script after the next SteamOS update."
