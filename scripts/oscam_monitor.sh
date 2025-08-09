#!/bin/sh
# oscam_monitor.sh — @dymidaboss
set -eu
. /usr/script/lib_openatv.sh 2>/dev/null || true
if ! ping -c1 -W2 8.8.8.8 >/dev/null 2>&1; then osd "Brak internetu. Sprawdź Wi‑Fi/kabel." 3 8; exit 0; fi
if ! pidof oscam >/dev/null 2>&1; then
  /etc/init.d/softcam.oscam-stable start >/dev/null 2>&1 || /etc/init.d/softcam start >/dev/null 2>&1 || true
  sleep 2
  if ! pidof oscam >/dev/null 2>&1; then osd "OSCam nie działa. Próba uruchomienia nieudana." 3 8; exit 0; fi
fi
if ! grep -Eq '^[ \t]*(C:|cs357x|newcamd)' /etc/tuxbox/config/oscam-stable/oscam.server 2>/dev/null; then
  osd "Brak konfiguracji serwera w OSCam. Zaczekaj na synchronizację." 2 8
fi
