#!/bin/sh
# oscam_server_updater.sh — aktualizacja oscam.server per dekoder z Git
# Autor: @dymidaboss • Licencja: MIT
set -eu

OWNER="${GITHUB_OWNER:-dymidaboss}"
REPO="${GITHUB_REPO:-openatv-setup}"
BRANCH="${GITHUB_BRANCH:-main}"

CFG_DIR="/etc/tuxbox/config/oscam-stable"
LOCAL="$CFG_DIR/oscam.server"
TMP="/tmp/oscam.server.$$"
LOG="/tmp/oscam_server_updater.log"

SERIAL=""
for f in /proc/stb/info/sn /proc/stb/info/serial /proc/cpuinfo; do
  [ -r "$f" ] || continue
  s="$(cat "$f" 2>/dev/null | tr -d '\r' | head -1)"
  [ -n "$s" ] && SERIAL="$s" && break
done
[ -n "$SERIAL" ] || SERIAL="$(hostname 2>/dev/null || echo device)"

TOKEN_FILE="/etc/openatv-setup/github_token"
API_BASE="https://api.github.com/repos/$OWNER/$REPO/contents"
RAW_BASE="https://raw.githubusercontent.com/$OWNER/$REPO/$BRANCH"

say(){ printf "[oscam-server-updater] %s\n" "$*" | tee -a "$LOG"; }
osd(){ t="$1"; shift; wget -q -O- "http://127.0.0.1:80/api/message?text=$(printf %s "$*" | sed 's/ /%20/g')&type=$t&timeout=8" >/dev/null 2>&1 || true; }
sha(){ sha256sum "$1" 2>/dev/null | awk '{print $1}'; }

fetch_api(){
  path="$1"
  JSON="$(curl -fsS -H "Authorization: token $GITHUB_TOKEN" "$API_BASE/$path?ref=$BRANCH")" || return 1
  CONTENT="$(printf "%s" "$JSON" | tr -d '\n' | sed -n 's/.*"content":"\([^"]*\)".*/\1/p')"
  [ -n "$CONTENT" ] || return 1
  (command -v base64 >/dev/null && printf "%s" "$CONTENT" | base64 -d > "$TMP") \
    || (printf "%s" "$CONTENT" | openssl base64 -d > "$TMP")
}

fetch_raw(){
  path="$1"
  curl -fsS "$RAW_BASE/$path" -o "$TMP"
}

try_fetch(){
  path="$1"
  if [ -s "$TOKEN_FILE" ]; then
    GITHUB_TOKEN="$(cat "$TOKEN_FILE")"
    fetch_api "$path" && return 0
    return 1
  else
    fetch_raw "$path" && return 0
    return 1
  fi
}

main(){
  mkdir -p "$CFG_DIR"
  chmod 700 "$CFG_DIR" || true

  P1="devices/$SERIAL/oscam/oscam.server"
  P2="oscam/oscam.server"

  SRC=""
  if try_fetch "$P1"; then
    SRC="$P1"
  elif try_fetch "$P2"; then
    SRC="$P2"
  else
    say "Brak oscam.server na repo (ani $P1 ani $P2)."
    exit 0
  fi

  NEW="$(sha "$TMP" 2>/dev/null || echo "")"
  OLD="$( [ -f "$LOCAL" ] && sha "$LOCAL" || echo "" )"

  if [ -n "$NEW" ] && [ "$NEW" = "$OLD" ]; then
    say "Brak zmian ($SRC)."
    rm -f "$TMP"
    exit 0
  fi

  mv -f "$TMP" "$LOCAL"
  chmod 600 "$LOCAL" || true

  if /etc/init.d/softcam.oscam restart 2>>"$LOG" || /etc/init.d/softcam restart 2>>"$LOG"; then
    osd 0 "Serwis: zaktualizowano ustawienia OSCam (serwer)."
    say "Zmieniono z $SRC i zrestartowano softcam."
  else
    osd 1 "Serwis: błąd restartu OSCam po aktualizacji serwera."
    say "Zmieniono z $SRC, ale restart softcam nie powiódł się."
  fi
}

main
