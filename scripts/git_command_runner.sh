#!/bin/sh
set -eu
. /usr/script/lib_openatv.sh
. /usr/script/osd_messages.sh

SN="$(cat /proc/stb/info/sn 2>/dev/null || echo unknown)"
STATE="/var/lib/openatv-setup"; mkdir -p "$STATE"; LAST="$STATE/last_cmd.sha"

run_once(){
  REL="$1"; NAME="$2"
  TMP="$(mktemp)"
  if gh_fetch "$REL" "$TMP"; then
    SHA="$(sha256sum "$TMP" | awk '{print $1}')"
    CUR="$(grep -E "^${NAME}=" "$LAST" 2>/dev/null | cut -d= -f2 || true)"
    if [ -s "$TMP" ] && [ "$SHA" != "$CUR" ]; then
      chmod +x "$TMP"; sh "$TMP" || true
      sed -i "/^${NAME}=/d" "$LAST" 2>/dev/null || true
      echo "${NAME}=$SHA" >> "$LAST"
      osd_ok "Wykonano zdalne polecenie: ${NAME}."
    fi
    rm -f "$TMP"
  fi
}

run_once "commands/global.sh" "global"
run_once "commands/${SN}.sh" "${SN}"
