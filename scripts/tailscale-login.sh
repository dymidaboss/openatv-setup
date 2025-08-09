#!/bin/sh
# tailscale-login.sh — @dymidaboss
set -eu
LOG="/var/log/tailscale-login.log"
URLFILE="/etc/openatv-setup/tailscale_login_url"
mkdir -p /etc/openatv-setup
: > "$LOG"
/etc/init.d/tailscaled enable >/dev/null 2>&1 || true
/etc/init.d/tailscaled start  >/dev/null 2>&1 || true
( tailscale up --reset --accept-dns=true --accept-routes=true > /tmp/ts.out 2>&1 || true ) &
sleep 2
URL="$(sed -n 's|.*\(https://login.tailscale.com/a/[A-Za-z0-9_-]*\).*|\1|p' /tmp/ts.out | head -1)"
[ -n "$URL" ] && echo "$URL" > "$URLFILE" || true
