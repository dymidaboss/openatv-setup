#!/bin/sh
# register_in_repo.sh — @dymidaboss
set -eu
. /usr/script/lib_openatv.sh 2>/dev/null || true
LOGFILE="${1:-}"; [ -n "$LOGFILE" ] || exit 0
SN="$(cat /proc/stb/info/sn 2>/dev/null || echo unknown)"
[ -n "${GITHUB_TOKEN:-}" ] || exit 0
B64=$(base64 -w0 "$LOGFILE" 2>/dev/null || openssl base64 -A -in "$LOGFILE")
PATH_API="install-logs/$SN/$(basename "$LOGFILE")"
JSON="{\"message\":\"log: $(basename "$LOGFILE")\",\"content\":\"$B64\"}"
curl -fsS -X PUT -H "Authorization: token $GITHUB_TOKEN" -H "Content-Type: application/json" \
  -d "$JSON" "https://api.github.com/repos/$OWNER/$REPO/contents/$PATH_API?ref=$BRANCH" >/dev/null 2>&1 || true
