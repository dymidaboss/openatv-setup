#!/bin/sh
set -eu
. /usr/script/lib_openatv.sh
. /usr/script/osd_messages.sh

CFG_DIR="/etc/tuxbox/config/oscam-stable"; mkdir -p "$CFG_DIR"
SN="$(cat /proc/stb/info/sn 2>/dev/null || echo unknown)"
TMP="$(mktemp)"; TARGET="$CFG_DIR/oscam.server"

# 1) per-SN
if gh_fetch "oscam-config/force/${SN}/oscam.server" "$TMP" || gh_fetch "oscam/oscam.server" "$TMP"; then
  if [ ! -s "$TARGET" ] || ! cmp -s "$TMP" "$TARGET"; then
    mv -f "$TMP" "$TARGET"; chmod 600 "$TARGET" 2>/dev/null || true
    /etc/init.d/softcam.oscam-stable restart >/dev/null 2>&1 || true
    osd_ok "Zaktualizowano serwer OSCam."
  else rm -f "$TMP"; fi
else
  echo "[oscam-server-updater] Brak oscam.server na repo (ani devices/${SN} ani oscam/oscam.server)."
fi
