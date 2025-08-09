#!/bin/sh
# srvid2_updater.sh — aktualizacja oscam.srvid2 z zewnętrznego URL
# Autor: @dymidaboss • Licencja: MIT
set -eu

URL="${SRVID2_URL:-http://myupdater1.dyndns-ip.com/oscam.srvid2}"
DST="/etc/tuxbox/config/oscam-stable/oscam.srvid2"
TMP="/tmp/oscam.srvid2.$$"
LOG="/tmp/srvid2_updater.log"

sha(){ sha256sum "$1" 2>/dev/null | awk '{print $1}'; }

if curl -fsS "$URL" -o "$TMP"; then
  NEW="$(sha "$TMP" 2>/dev/null || echo "")"
  OLD="$( [ -f "$DST" ] && sha "$DST" || echo "" )"
  if [ -n "$NEW" ] && [ "$NEW" = "$OLD" ]; then
    rm -f "$TMP"; exit 0
  fi
  mv -f "$TMP" "$DST"
  chmod 644 "$DST" || true
  /etc/init.d/softcam.oscam restart 2>>"$LOG" || /etc/init.d/softcam restart 2>>"$LOG" || true
  wget -q -O- "http://127.0.0.1:80/api/message?text=Serwis:%20zaktualizowano%20oscam.srvid2.&type=0&timeout=8" >/dev/null 2>&1 || true
fi
exit 0
