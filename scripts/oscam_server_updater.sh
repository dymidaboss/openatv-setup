#!/bin/sh
# oscam_server_updater.sh — @dymidaboss
set -eu
. /usr/script/lib_openatv.sh 2>/dev/null || true
SN="$(cat /proc/stb/info/sn 2>/dev/null || echo unknown)"
CFG="/etc/tuxbox/config/oscam-stable/oscam.server"
CAND1="oscam-config/force/$SN/oscam.server"
CAND2="oscam/oscam.server"
TMP="$(mktemp)"
if gh_fetch "$CAND1" "$TMP" 2>/dev/null || gh_fetch "$CAND2" "$TMP" 2>/dev/null; then
  if [ ! -f "$CFG" ] || ! cmp -s "$TMP" "$CFG"; then
    mv -f "$TMP" "$CFG"; chmod 600 "$CFG" 2>/dev/null || true
    /etc/init.d/softcam.oscam-stable restart >/dev/null 2>&1 || /etc/init.d/softcam restart >/dev/null 2>&1 || true
    osd "Zaktualizowano serwer OSCam. Uruchomiono ponownie." 1 6
  else
    rm -f "$TMP"
  fi
else
  rm -f "$TMP"
fi
