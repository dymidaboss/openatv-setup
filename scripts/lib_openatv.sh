#!/bin/sh
# lib_openatv.sh — @dymidaboss
set -eu
OWNER="${GITHUB_OWNER:-dymidaboss}"
REPO="${GITHUB_REPO:-openatv-setup}"
BRANCH="${GITHUB_BRANCH:-main}"
[ -f /etc/openatv-setup/github_token ] && GITHUB_TOKEN="$(cat /etc/openatv-setup/github_token 2>/dev/null || true)" || GITHUB_TOKEN=""

if [ "${OSD_SILENT:-0}" = "1" ]; then
  osd(){ :; }
else
  osd(){ MSG="$1"; TYPE="${2:-1}"; TO="${3:-8}"; QMSG="$(printf '%s' "$MSG" | sed 's/ /%20/g; s/&/%26/g')"; wget -qO- "http://127.0.0.1/api/message?text=$QMSG&type=$TYPE&timeout=$TO" >/dev/null 2>&1 || true; }
fi

gh_fetch(){
  REMOTE="$1"; DEST="$2"
  if [ -n "${GITHUB_TOKEN:-}" ]; then
    JSON="$(curl -fsS -H "Authorization: token $GITHUB_TOKEN" "https://api.github.com/repos/$OWNER/$REPO/contents/$REMOTE?ref=$BRANCH" 2>/dev/null || true)"
    CNT="$(printf "%s" "$JSON" | tr -d '\n' | sed -n 's/.*"content":"\([^"]*\)".*/\1/p')"
    if [ -n "$CNT" ]; then
      (command -v base64 >/dev/null && printf "%s" "$CNT" | base64 -d > "$DEST") || (printf "%s" "$CNT" | openssl base64 -d > "$DEST")
      return 0
    fi
  fi
  curl -fsSL "https://raw.githubusercontent.com/$OWNER/$REPO/$BRANCH/$REMOTE" -o "$DEST"
}
