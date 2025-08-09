#!/bin/sh
# lib_openatv.sh — wspólne funkcje
# Autor: @dymidaboss • Licencja: MIT
set -eu

msg(){ echo; echo "==> $*"; }

get_model() {
  cat /proc/stb/info/boxtype 2>/dev/null   || sed -n 's/^boxmodel=//p' /etc/image-version 2>/dev/null   || sed -n 's/^model=//p' /etc/image-version 2>/dev/null   || echo enigma2
}
get_serial(){
  for f in /proc/stb/info/sn /proc/stb/info/serial /proc/stb/info/boardserial; do
    [ -s "$f" ] && { tr -d '\r\n' <"$f"; return; }
  done
  for i in eth0 wlan0; do
    mac=$(cat "/sys/class/net/$i/address" 2>/dev/null | tr -d :)
    [ -n "$mac" ] && { echo "mac$mac"; return; }
  done
  [ -s /etc/machine-id ] && { head -c 12 /etc/machine-id; return; }
  date +%s
}
id_hw(){ echo "$(get_model)-$(get_serial)"; }

_osd() {
  txt="$1"; type="${2:-0}"; t="${3:-12}"
  esc="$(printf "%s" "$txt" | sed 's/ /%20/g')"
  wget -q -O - "http://127.0.0.1/api/message?text=${esc}&type=${type}&timeout=${t}" >/dev/null 2>&1 || true
}
osd_info(){ _osd "$1" 0 "${2:-10}"; }
osd_warn(){ _osd "$1" 1 "${2:-12}"; }
osd_err(){  _osd "$1" 2 "${2:-12}"; }

# GitHub API fetch (private) — Bearer + API version
gh_fetch() {
  # gh_fetch <owner> <repo> <branch> <token> <repo_path> <dest_path>
  OWNER="$1"; REPO="$2"; BR="$3"; TOKEN="$4"; RP="$5"; DST="$6"
  API="https://api.github.com/repos/${OWNER}/${REPO}/contents/${RP}?ref=${BR}"
  JSON="$(curl -sS -H "Authorization: Bearer ${TOKEN}" -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" "$API")" || return 1
  CONTENT="$(printf "%s" "$JSON" | tr -d '\n' | sed -n 's/.*"content":"\([^"]*\)".*/\1/p')"
  [ -n "$CONTENT" ] || return 2
  (command -v base64 >/dev/null && printf "%s" "$CONTENT" | base64 -d > "$DST") || (printf "%s" "$CONTENT" | openssl base64 -d > "$DST")
  [ -s "$DST" ]
}

cron_ensure() {
  mkdir -p /var/spool/cron/crontabs
  if command -v crond >/dev/null 2>&1; then pgrep -f '[c]rond' >/dev/null 2>&1 || crond -b -c /var/spool/cron/crontabs; fi
  [ -x /etc/init.d/cron ] && /etc/init.d/cron start || true
}
cron_add_once() {
  LINE="$1"
  crontab -l 2>/dev/null | sed '/openatv-setup/d' > /tmp/cron.tmp || true
  printf "%s\n" "$LINE" >> /tmp/cron.tmp
  crontab /tmp/cron.tmp && rm -f /tmp/cron.tmp
}
