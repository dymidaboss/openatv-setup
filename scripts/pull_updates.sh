#!/bin/sh
# pull_updates.sh — @dymidaboss
set -eu
. /usr/script/lib_openatv.sh 2>/dev/null || true
changed=0
update_if_changed(){
  REM="$1"; DEST="$2"; TMP="$(mktemp)"
  if gh_fetch "$REM" "$TMP" 2>/dev/null; then
    if [ ! -f "$DEST" ] || ! cmp -s "$TMP" "$DEST"; then mv -f "$TMP" "$DEST"; changed=1; else rm -f "$TMP"; fi
  else rm -f "$TMP"; fi
}
update_if_changed assets/bootlogo.mvi /usr/share/bootlogo.mvi
update_if_changed assets/satellites.xml /etc/tuxbox/satellites.xml
update_if_changed oscam/oscam.conf /etc/tuxbox/config/oscam-stable/oscam.conf
update_if_changed oscam/oscam.user /etc/tuxbox/config/oscam-stable/oscam.user
update_if_changed oscam/oscam.dvbapi /etc/tuxbox/config/oscam-stable/oscam.dvbapi
if [ "$changed" -eq 1 ]; then
  /etc/init.d/softcam.oscam-stable restart >/dev/null 2>&1 || /etc/init.d/softcam restart >/dev/null 2>&1 || true
  osd "Zastosowano aktualizacje z repo." 1 6
fi
