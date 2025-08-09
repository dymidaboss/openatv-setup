#!/bin/sh
set -Eeuo pipefail
URL="http://myupdater1.dyndns-ip.com/oscam.srvid2"
DST="/etc/tuxbox/config/oscam-stable/oscam.srvid2"
TMP="/tmp/.srvid2"

if wget -qO "$TMP" "$URL"; then
  if ! cmp -s "$TMP" "$DST" 2>/dev/null; then
    mv "$TMP" "$DST" && chmod 644 "$DST"
    /etc/init.d/softcam.oscam-stable restart 2>/dev/null || /etc/init.d/softcam restart 2>/dev/null || true
  else
    rm -f "$TMP"
  fi
fi
