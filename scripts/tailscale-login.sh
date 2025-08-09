#!/bin/sh
set -Eeuo pipefail
BASE="/etc/openatv-setup"
mkdir -p "$BASE"
if ! pgrep -f '[t]ailscaled' >/dev/null 2>&1; then
  /etc/init.d/tailscaled start 2>/dev/null || true
fi
URL="$(tailscale up --ssh --accept-routes=false --accept-dns=true --reset --authkey= 2>&1 | sed -n 's/.*visit //p' | head -1)"
[ -n "$URL" ] && printf "%s" "$URL" > "$BASE/tailscale_login_url" || true
exit 0
