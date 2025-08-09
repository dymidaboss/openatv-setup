#!/bin/sh
# git_command_runner.sh — uruchamia z repo komendy globalne lub per-dekoder (jednorazowo)
# Autor: @dymidaboss • Licencja: MIT
set -eu

OWNER="${GITHUB_OWNER:-dymidaboss}"
REPO="${GITHUB_REPO:-openatv-setup}"
BRANCH="${GITHUB_BRANCH:-main}"

BASE="/etc/openatv-setup"
TOKEN_FILE="$BASE/github_token"

SERIAL=""
for f in /proc/stb/info/sn /proc/stb/info/serial /proc/cpuinfo; do
  [ -r "$f" ] || continue
  s="$(cat "$f" 2>/dev/null | tr -d '\r' | head -1)"
  [ -n "$s" ] && SERIAL="$s" && break
done
[ -n "$SERIAL" ] || SERIAL="$(hostname 2>/dev/null || echo device)"

RAW="https://raw.githubusercontent.com/$OWNER/$REPO/$BRANCH"
API="https://api.github.com/repos/$OWNER/$REPO/contents"

fetch(){
  path="$1"; out="$2"
  if [ -s "$TOKEN_FILE" ]; then
    TOKEN="$(cat "$TOKEN_FILE")"
    JSON="$(curl -fsS -H "Authorization: token $TOKEN" "$API/$path?ref=$BRANCH")" || return 1
    CONTENT="$(printf "%s" "$JSON" | tr -d '\n' | sed -n 's/.*"content":"\([^"]*\)".*/\1/p')"
    [ -n "$CONTENT" ] || return 1
    (command -v base64 >/dev/null && printf "%s" "$CONTENT" | base64 -d > "$out") \
      || (printf "%s" "$CONTENT" | openssl base64 -d > "$out")
  else
    curl -fsS "$RAW/$path" -o "$out"
  fi
}

TMP="/tmp/gitcmd.$$"
DONE_G="/etc/openatv-setup/.gitcmd_global.done"
DONE_D="/etc/openatv-setup/.gitcmd_${SERIAL}.done"

# Global (one-shot)
if [ ! -f "$DONE_G" ] && fetch "remote-commands/global.sh" "$TMP"; then
  sh "$TMP" || true
  date > "$DONE_G"
fi

# Per-device (one-shot)
if [ ! -f "$DONE_D" ] && fetch "devices/$SERIAL/remote-commands/run.sh" "$TMP"; then
  sh "$TMP" || true
  date > "$DONE_D"
fi

rm -f "$TMP" 2>/dev/null || true
exit 0
