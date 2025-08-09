#!/bin/sh
# auto_update.sh — aktualizacje systemu (cicho) + czytelne OSD
# Autor: @dymidaboss • Licencja: MIT
set -eu

LOG="/tmp/auto_update.log"

osd(){ t="$1"; shift; wget -q -O- "http://127.0.0.1:80/api/message?text=$(printf %s "$*" | sed 's/ /%20/g')&type=$t&timeout=8" >/dev/null 2>&1 || true; }

osd 0 "Serwis: trwa aktualizacja systemu…"
if opkg update >/dev/null 2>&1 && opkg upgrade >/dev/null 2>&1; then
  osd 0 "Serwis: aktualizacja systemu zakończona."
else
  osd 1 "Serwis: problem podczas aktualizacji systemu."
fi

# (opcjonalnie) jeśli wymagany restart — można dodać znacznik i osobny harmonogram
exit 0
