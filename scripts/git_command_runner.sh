#!/bin/sh
# Wykonywanie zdalnych komend: commands/global.sh i commands/<SN>.sh
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

run_once(){
  F="$1"
  TMP="/tmp/.cmd_runner_$(basename "$F").sh"
  HASHFILE="/etc/openatv-setup/.hash_$(basename "$F")"
  gh_fetch "$OWNER" "$REPO" "$BRANCH" "$F" > "$TMP" 2>/dev/null || return 0
  [ -s "$TMP" ] || { rm -f "$TMP"; return 0; }
  NEWHASH="$(md5sum "$TMP" | awk '{print $1}')"
  OLDHASH="$(cat "$HASHFILE" 2>/dev/null || true)"
  if [ "$NEWHASH" != "$OLDHASH" ]; then
    chmod +x "$TMP"
    sh "$TMP" || true
    echo "$NEWHASH" > "$HASHFILE"
  fi
  rm -f "$TMP"
}

run_once "commands/global.sh"
run_once "commands/$(SN).sh"
