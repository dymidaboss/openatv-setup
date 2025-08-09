#!/bin/sh
# git_command_runner.sh — @dymidaboss
set -eu
. /usr/script/lib_openatv.sh 2>/dev/null || true
SN="$(cat /proc/stb/info/sn 2>/dev/null || echo unknown)"
for C in "commands/global.sh" "commands/$SN.sh"; do
  TMP="$(mktemp)"
  if gh_fetch "$C" "$TMP" 2>/dev/null; then
    SUM="$(sha256sum "$TMP" | awk '{print $1}')"
    MARK="/etc/openatv-setup/.done_$(echo "$C"|tr '/' '_')"
    LAST=""; [ -f "$MARK" ] && LAST="$(cat "$MARK" 2>/dev/null || true)"
    if [ "$SUM" != "$LAST" ]; then
      chmod 755 "$TMP"; sh "$TMP" >/tmp/gitcmd.out 2>&1 || true
      echo "$SUM" > "$MARK"
      osd "Wykonano zdalne polecenie." 1 6
    fi
    rm -f "$TMP"
  fi
done
