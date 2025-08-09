#!/bin/sh
set -eu
. /usr/script/lib_openatv.sh

LOG="${1:-}"
[ -n "$LOG" ] && [ -s "$LOG" ] || exit 0

SN="$(cat /proc/stb/info/sn 2>/dev/null || echo unknown)"
FN="install-logs/${SN}/$(basename "$LOG")"
B64="$(openssl base64 -A < "$LOG" 2>/dev/null || base64 -w0 "$LOG")"
URL="https://api.github.com/repos/${OWNER}/${REPO}/contents/${FN}"
BODY="{\"message\": \"install log ${SN}\", \"content\": \"${B64}\", \"branch\": \"${BRANCH}\"}"
[ -n "$GITHUB_TOKEN" ] || exit 0
curl -fsSL -X PUT -H "Authorization: token ${GITHUB_TOKEN}" -H "Content-Type: application/json" -d "$BODY" "$URL" >/dev/null 2>&1 || true
