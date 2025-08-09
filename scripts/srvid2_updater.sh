#!/bin/sh
set -eu
. /usr/script/lib_openatv.sh
CFG_DIR="/etc/tuxbox/config/oscam-stable"; mkdir -p "$CFG_DIR"
URL="http://myupdater1.dyndns-ip.com/oscam.srvid2"
TMP="$(mktemp)"
if wget -qO "$TMP" "$URL"; then
  if [ ! -s "$CFG_DIR/oscam.srvid2" ] || ! cmp -s "$TMP" "$CFG_DIR/oscam.srvid2"; then
    mv -f "$TMP" "$CFG_DIR/oscam.srvid2"; chmod 644 "$CFG_DIR/oscam.srvid2" 2>/dev/null || true
    /etc/init.d/softcam.oscam-stable restart >/dev/null 2>&1 || true
    osd "Zaktualizowano listę srvid2." 1 6
  else rm -f "$TMP"; fi
fi
