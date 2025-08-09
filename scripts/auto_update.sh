#!/bin/sh
# auto_update.sh — @dymidaboss
set -eu
. /usr/script/lib_openatv.sh 2>/dev/null || true
opkg update >/dev/null 2>&1 || exit 0
UP=$(opkg list-upgradable | wc -l)
[ "$UP" -gt 0 ] || exit 0
osd "Trwa aktualizacja systemu. Proszę nie wyłączać." 2 10
opkg upgrade -d root >/dev/null 2>&1 || true
osd "Aktualizacja zakończona. Restart za 30 s." 1 8
sleep 30
reboot
