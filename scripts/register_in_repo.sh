#!/bin/sh
# Upload logu instalacji do repo install-logs/<SN>/...
set -Eeuo pipefail
OWNER="${OWNER_SETUP:-dymidaboss}"
REPO="${REPO_SETUP:-openatv-setup}"
BRANCH="${BRANCH_SETUP:-main}"

BASE="/etc/openatv-setup"
TOKEN="$(cat "$BASE/github_token" 2>/dev/null || true)"
[ -n "$TOKEN" ] || exit 0

SN(){
  for f in /proc/stb/info/sn /proc/stb/info/serial /proc/stb/info/board_serial; do
    [ -r "$f" ] && { cat "$f"; return; }
  done
  ip link 2>/dev/null | awk '/ether/ {print $2; exit}' | tr -d ':'
}

LOG="$1"
[ -f "$LOG" ] || exit 0

P="install-logs/$(SN)/$(basename "$LOG")"
CONTENT="$(base64 -w0 "$LOG")"
MSG="upload install log $(date -Iseconds)"
curl -fsSL -X PUT -H "Authorization: Bearer $TOKEN" \
  -d "{\"message\":\"$MSG\",\"content\":\"$CONTENT\",\"branch\":\"$BRANCH\"}" \
  "https://api.github.com/repos/$OWNER/$REPO/contents/$P" >/dev/null 2>&1 || true
exit 0
