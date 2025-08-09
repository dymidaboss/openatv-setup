#!/bin/sh
set -eu
. /usr/script/lib_openatv.sh
. /usr/script/osd_messages.sh

CFG_DIR="/etc/tuxbox/config/oscam-stable"

check_net(){ ping -c1 -W1 1.1.1.1 >/dev/null 2>&1; }
check_e2(){ wget -qO- http://127.0.0.1 >/dev/null 2>&1; }
check_osc(){ ps | grep -i '[o]scam' >/dev/null 2>&1 || /etc/init.d/softcam.oscam-stable status >/dev/null 2>&1; }

if ! check_net; then osd_err "Brak internetu. Sprawdź Wi‑Fi/kabel i router."; exit 0; fi
if ! check_e2; then osd_warn "Usługa dekodera nie odpowiada — przywracam."; init 4; sleep 2; init 3; fi
if ! check_osc; then
  osd_warn "OSCam zatrzymany — uruchamiam…"
  /etc/init.d/softcam.oscam-stable restart >/dev/null 2>&1 || /etc/init.d/softcam restart >/dev/null 2>&1 || true
  sleep 3
  if ! check_osc; then
    if [ -s "$CFG_DIR/oscam.server" ]; then osd_err "OSCam nadal nie działa (możliwa przerwa u dostawcy)."
    else osd_err "Brak konfiguracji serwera OSCam."; fi
  else osd_ok "OSCam działa."; fi
fi
