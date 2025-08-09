#!/bin/sh
set -eu
. /usr/script/lib_openatv.sh
. /usr/script/osd_messages.sh

changed=0; touched_oscam=0
mkdir -p /usr/script

sync_file(){
  REL="$1"; DEST="$2"; MODE="${3:-644}"; RESTART_OSCAM="${4:-0}"
  TMP="$(mktemp)"
  if gh_fetch "$REL" "$TMP"; then
    if [ ! -s "$DEST" ] || ! cmp -s "$TMP" "$DEST"; then
      mv -f "$TMP" "$DEST"; chmod "$MODE" "$DEST" 2>/dev/null || true
      changed=1
      [ "$RESTART_OSCAM" -eq 1 ] && touched_oscam=1
    else rm -f "$TMP"; fi
  fi
}

# skrypty
for s in lib_openatv.sh osd_messages.sh oscam_monitor.sh oscam_server_updater.sh pull_updates.sh srvid2_updater.sh auto_update.sh git_command_runner.sh tailscale-login.sh register_in_repo.sh; do
  sync_file "scripts/${s}" "/usr/script/${s}" 755 0
done

# assets
sync_file "assets/bootlogo.mvi" "/usr/share/bootlogo.mvi" 644 0 && (command -v showiframe >/dev/null && showiframe /usr/share/bootlogo.mvi || true)
sync_file "assets/satellites.xml" "/etc/tuxbox/satellites.xml" 644 0

# oscam (bez serwera)
CFG="/etc/tuxbox/config/oscam-stable"; mkdir -p "$CFG"
sync_file "oscam/oscam.conf"  "$CFG/oscam.conf"  600 1
sync_file "oscam/oscam.user"  "$CFG/oscam.user"  600 1
sync_file "oscam/oscam.dvbapi" "$CFG/oscam.dvbapi" 600 1

# restart OSCam, jeśli config dotknięty
[ "$touched_oscam" -eq 1 ] && { /etc/init.d/softcam.oscam-stable restart >/dev/null 2>&1 || true; }

[ "$changed" -eq 1 ] && osd_ok "Zastosowano aktualizacje z repo."
