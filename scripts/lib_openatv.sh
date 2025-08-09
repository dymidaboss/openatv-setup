#!/bin/sh
# Biblioteka pomocnicza (GitHub API/RAW, OSD)

set -Eeuo pipefail

BASE="/etc/openatv-setup"
TOKEN_FILE="$BASE/github_token"

gh_fetch(){
  # uŜycie: gh_fetch owner repo branch path > dest
  OWNER="$1"; REPO="$2"; BR="$3"; PATH="$4"
  TOKEN="$(cat "$TOKEN_FILE" 2>/dev/null || true)"
  if [ -n "${TOKEN:-}" ]; then
    curl -fsSL -H "Authorization: Bearer $TOKEN" \
      "https://api.github.com/repos/$OWNER/$REPO/contents/$PATH?ref=$BR" \
      | sed -n 's/.*"content":"\([^"]*\)".*/\1/p' | tr -d '\n' | base64 -d
  else
    curl -fsSL "https://raw.githubusercontent.com/$OWNER/$REPO/$BR/$PATH"
  fi
}

say_osd(){
  # Kolor żółty, 10 sekund, spójny styl
  MSG="$1"; SEC="${2:-10}"
  if command -v ecmd  >/dev/null 2>&1; then
    ecmd showMessage "[SERWIS] $MSG" "$SEC" "1"
  elif command -v showiframe >/dev/null 2>&1; then
    # brak ecmd — pomijamy OSD
    :
  fi
}
