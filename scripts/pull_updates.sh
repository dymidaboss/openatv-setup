#!/bin/sh
# pull_updates.sh — pobieranie z repo: skrypty, bootlogo, satellites, configi OSCam (bez oscam.server)
# Autor: @dymidaboss • Licencja: MIT
set -eu

OWNER="${GITHUB_OWNER:-dymidaboss}"
REPO="${GITHUB_REPO:-openatv-setup}"
BRANCH="${GITHUB_BRANCH:-main}"

BASE="/etc/openatv-setup"
TOKEN_FILE="$BASE/github_token"
RAW_BASE="https://raw.githubusercontent.com/$OWNER/$REPO/$BRANCH"
API_BASE="https://api.github.com/repos/$OWNER/$REPO/contents"

LOG="/tmp/pull_updates.log"

say(){ printf "[pull-updates] %s\n" "$*" | tee -a "$LOG"; }
sha(){ sha256sum "$1" 2>/dev/null | awk '{print $1}'; }
dl_raw(){ curl -fsS "$RAW_BASE/$1" -o "$2"; }
dl_api(){
  JSON="$(curl -fsS -H "Authorization: token $GITHUB_TOKEN" "$API_BASE/$1?ref=$BRANCH")" || return 1
  CONTENT="$(printf "%s" "$JSON" | tr -d '\n' | sed -n 's/.*"content":"\([^"]*\)".*/\1/p')"
  [ -n "$CONTENT" ] || return 1
  (command -v base64 >/dev/null && printf "%s" "$CONTENT" | base64 -d > "$2") \
    || (printf "%s" "$CONTENT" | openssl base64 -d > "$2")
}

smart_get(){
  # $1 path on repo, $2 local path; returns 1 if updated, else 0
  TMP="/tmp/.pull.$$.tmp"
  if [ -s "$TOKEN_FILE" ]; then
    GITHUB_TOKEN="$(cat "$TOKEN_FILE")"
    dl_api "$1" "$TMP" || return 0
  else
    dl_raw "$1" "$TMP" || return 0
  fi
  if [ -s "$2" ] && [ "$(sha "$2")" = "$(sha "$TMP")" ]; then
    rm -f "$TMP"
    return 0
  fi
  mkdir -p "$(dirname "$2")"
  mv -f "$TMP" "$2"
  return 1
}

# 1) skrypty
upd=0
for f in auto_update.sh git_command_runner.sh oscam_monitor.sh oscam_server_updater.sh srvid2_updater.sh tailscale-login.sh; do
  if smart_get "scripts/$f" "/usr/script/$f"; then :; else upd=1; fi
  chmod +x "/usr/script/$f" 2>/dev/null || true
done
[ "$upd" = "1" ] && say "Zaktualizowano skrypty."

# 2) bootlogo
if smart_get "bootlogo/bootlogo.mvi" "/usr/share/bootlogo.mvi"; then
  say "Zaktualizowano bootlogo (wymaga restartu Enigma2)."
  # Nie restartujemy od razu dekodera; zrobisz to w oknie serwisowym
fi

# 3) satellites.xml
if smart_get "satellites/satellites.xml" "/etc/tuxbox/satellites.xml"; then
  say "Zaktualizowano listę satelitów (wymaga restartu Enigma2)."
fi

# 4) OSCam configi (bez oscam.server — tym zarządza osobny updater)
OSD_REFRESH=0
for f in oscam.conf oscam.user oscam.dvbapi; do
  if smart_get "oscam/$f" "/etc/tuxbox/config/oscam-stable/$f"; then
    OSD_REFRESH=1
  fi
done
if [ "$OSD_REFRESH" = "1" ]; then
  /etc/init.d/softcam.oscam restart 2>>"$LOG" || /etc/init.d/softcam restart 2>>"$LOG" || true
  wget -q -O- "http://127.0.0.1:80/api/message?text=Serwis:%20zaktualizowano%20ustawienia%20OSCam.&type=0&timeout=8" >/dev/null 2>&1 || true
fi

exit 0
