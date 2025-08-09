#!/bin/sh
set -eu
. /usr/script/lib_openatv.sh
. /usr/script/osd_messages.sh

opkg update >/dev/null 2>&1 || true
UPG="$(opkg list-upgradable || true)"
[ -z "$UPG" ] && exit 0

osd_warn "Aktualizacja systemu — proszę nie wyłączać."
if opkg upgrade >/dev/null 2>&1; then
  if echo "$UPG" | egrep -qi 'enigma2|kernel|glibc|drivers|softcam|busybox'; then
    osd_warn "Aktualizacja zakończona. Restart dekodera za 30 s." 30
    (sleep 30; reboot) &
  else
    osd_ok "Aktualizacja zakończona."
  fi
else
  osd_err "Aktualizacja systemu nie powiodła się."
fi
