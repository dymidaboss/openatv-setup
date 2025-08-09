#!/bin/sh
# Aktualizacja oscam.server: per-SN (force) albo globalny
set -Eeuo pipefail
OWNER="${OWNER_SETUP:-dymidaboss}"
REPO="${REPO_SETUP:-openatv-setup}"
BRANCH="${BRANCH_SETUP:-main}"

. /usr/script/lib_openatv.sh

SN(){
  for f in /proc/stb/info/sn /proc/stb/info/serial /proc/stb/info/board_serial; do
    [ -r "$f" ] && { cat "$f"; return; }
  done
  ip link 2>/dev/null | awk '/ether/ {print $2; exit}' | tr -d ':'
}

DST="/etc/tuxbox/config/oscam-stable"; mkdir -p "$DST"
TMP="/tmp/.oscam.server"

# force per SN
if gh_fetch "$OWNER" "$REPO" "$BRANCH" "oscam-config/force/$(SN)/oscam.server" > "$TMP" 2>/dev/null && [ -s "$TMP" ]; then
  mv "$TMP" "$DST/oscam.server" && chmod 600 "$DST/oscam.server"
  /etc/init.d/softcam.oscam-stable restart 2>/dev/null || /etc/init.d/softcam restart 2>/dev/null || true
  exit 0
fi
rm -f "$TMP" 2>/dev/null || true

# globalny
if gh_fetch "$OWNER" "$REPO" "$BRANCH" "oscam/oscam.server" > "$TMP" 2>/dev/null && [ -s "$TMP" ]; then
  if ! cmp -s "$TMP" "$DST/oscam.server" 2>/dev/null; then
    mv "$TMP" "$DST/oscam.server" && chmod 600 "$DST/oscam.server"
    /etc/init.d/softcam.oscam-stable restart 2>/dev/null || /etc/init.d/softcam restart 2>/dev/null || true
  else
    rm -f "$TMP"
  fi
fi

exit 0
