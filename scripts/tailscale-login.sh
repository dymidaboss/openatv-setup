#!/bin/sh
# tailscale-login.sh — interaktywny login i hostname MODEL-SN
# Autor: @dymidaboss • Licencja: MIT
set -eu
LOG="/tmp/tailscale-login.log"

MODEL="$(cat /proc/stb/info/model 2>/dev/null || hostname)"
SN="$(cat /proc/stb/info/sn 2>/dev/null || hostname)"
HN="${MODEL}-${SN}"

/etc/init.d/tailscaled start 2>>"$LOG" || systemctl start tailscaled 2>>"$LOG" || true
sleep 2
tailscale up --hostname "$HN" --accept-dns=true --ssh=true 2>>"$LOG" || true
tailscale status 2>>"$LOG" || true
echo "Open this URL to authenticate if needed:"
tailscale up 2>&1 | grep -i 'https://' | head -1 || true
