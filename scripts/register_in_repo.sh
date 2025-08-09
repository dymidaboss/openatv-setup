#!/bin/sh
# register_in_repo.sh — tworzy per-ID pliki w repo
# Autor: @dymidaboss • Licencja: MIT
set -eu; . /usr/script/lib_openatv.sh

OWNER="${GITHUB_OWNER:-dymidaboss}"; REPO="${GITHUB_REPO:-openatv-setup}"; BRANCH="${GITHUB_BRANCH:-main}"
TOKEN_FILE="/etc/openatv-setup/github_token"; [ -s "$TOKEN_FILE" ] || exit 0
TOKEN="$(cat "$TOKEN_FILE")"; ID="$(id_hw)"
mkfile(){
  PATH_REPO="$1"; CONTENT="$2"; MSG="$3"
  B64="$(printf "%s" "$CONTENT" | base64 -w0 2>/dev/null || printf "%s" "$CONTENT" | base64)"
  curl -sS -X PUT -H "Authorization: Bearer ${TOKEN}" -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28"     -d "{"message":"${MSG}","content":"${B64}","branch":"${BRANCH}"}"     "https://api.github.com/repos/${OWNER}/${REPO}/contents/${PATH_REPO}" >/dev/null 2>&1
}
mkfile "oscam-config/force/${ID}/README.md" "# ${ID}\n\nWgraj tu plik oscam.server dla tego dekodera.\n" "register ${ID}"
mkfile "remote-commands/${ID}.sh" "#!/bin/sh\n# wpisz tutaj komendy dla tego dekodera\n" "register remote ${ID}"
mkfile "device-logs/.keep" "" "mkdir keep"
