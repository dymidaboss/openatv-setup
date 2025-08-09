#!/bin/sh
# srvid2_updater.sh — @dymidaboss
set -eu
URL="http://myupdater1.dyndns-ip.com/oscam.srvid2"
DST="/etc/tuxbox/config/oscam-stable/oscam.srvid2"
TMP="$(mktemp)"
if wget -qO "$TMP" "$URL" || curl -fsSL "$URL" -o "$TMP"; then
  if [ ! -f "$DST" ] || ! cmp -s "$TMP" "$DST"; then
    mv -f "$TMP" "$DST"; chmod 644 "$DST" 2>/dev/null || true
    /etc/init.d/softcam.oscam-stable restart >/dev/null 2>&1 || /etc/init.d/softcam restart >/dev/null 2>&1 || true
    . /usr/script/lib_openatv.sh 2>/dev/null || true; osd "Zaktualizowano listę usług (srvid2)." 1 6
  else rm -f "$TMP"; fi
else rm -f "$TMP"; fi
