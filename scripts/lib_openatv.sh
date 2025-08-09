#!/bin/sh
# @author: @dymidaboss (project)
# wspólne helpery: OSD + GitHub API/RAW

OWNER="${GITHUB_OWNER:-dymidaboss}"
REPO="${GITHUB_REPO:-openatv-setup}"
BRANCH="${GITHUB_BRANCH:-main}"
TOKEN_FILE="/etc/openatv-setup/github_token"
[ -s "$TOKEN_FILE" ] && GITHUB_TOKEN="$(tr -d '\r\n' < "$TOKEN_FILE")" || GITHUB_TOKEN=""
RAW_BASE="https://raw.githubusercontent.com/${OWNER}/${REPO}/${BRANCH}"
API_BASE="https://api.github.com/repos/${OWNER}/${REPO}/contents"

# prosty OSD (OpenWebif)
osd() {
  TEXT="$1"; TYPE="${2:-1}"; TO="${3:-8}"
  MSG="$(printf '%s' "$TEXT" | sed 's/ /%20/g; s/&/%26/g')"
  wget -qO- "http://127.0.0.1/api/message?text=${MSG}&type=${TYPE}&timeout=${TO}" >/dev/null 2>&1 || true
}

say(){ echo "=> $*"; }

# pobranie via API /contents (wymaga tokenu)
gh_fetch_api() {
  REL="$1"; OUT="$2"
  [ -n "$GITHUB_TOKEN" ] || return 1
  URL="${API_BASE}/${REL}?ref=${BRANCH}"
  JSON="$(curl -fsSL -H "Authorization: token ${GITHUB_TOKEN}" "$URL" 2>/dev/null || true)" || return 1
  CONTENT="$(printf "%s" "$JSON" | tr -d '\n' | sed -n 's/.*\"content\":\"\([^\"]*\)\".*/\1/p')" || return 1
  [ -n "$CONTENT" ] || return 1
  (command -v base64 >/dev/null && printf "%s" "$CONTENT" | base64 -d > "$OUT") || (printf "%s" "$CONTENT" | openssl base64 -d > "$OUT")
  [ -s "$OUT" ]
}

# pobranie RAW (zadziała tylko, gdy repo/katalog publiczny)
gh_fetch_raw() {
  REL="$1"; OUT="$2"
  URL="${RAW_BASE}/${REL}"
  wget -qO "$OUT" "$URL" 2>/dev/null || curl -fsSL "$URL" -o "$OUT" 2>/dev/null || return 1
  [ -s "$OUT" ]
}

# high-level: API -> RAW (publiczne) -> fail
gh_fetch() {
  REL="$1"; OUT="$2"
  gh_fetch_api "$REL" "$OUT" && return 0
  gh_fetch_raw "$REL" "$OUT" && return 0
  return 1
}
