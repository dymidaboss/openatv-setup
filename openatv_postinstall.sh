#!/bin/sh
# openatv-setup/openatv_postinstall.sh
# Główny instalator – tryb ścisły, pełne logowanie, twarde egzekwowanie kroków.
set -Eeuo pipefail

OWNER="${OWNER_SETUP:-dymidaboss}"
REPO="${REPO_SETUP:-openatv-setup}"
BRANCH="${BRANCH_SETUP:-main}"

BASE="/etc/openatv-setup"
TOKEN_FILE="$BASE/github_token"
LOG="/home/root/openatv_postinstall_$(date +%Y%m%d-%H%M%S).log"

# --- logowanie wszystkiego ---
exec > >(tee -a "$LOG") 2>&1

# --- narzędzia pomocnicze ---
say(){ printf "%s\n" "$*"; }
step(){ CUR=$((CUR+1)); say "==> $CUR/$TOTAL $*"; }
fail(){ say "💥 Błąd: $*"; exit 1; }

trap 'fail "na linii $LINENO (krok $CUR)"' ERR

require_token() {
  [ -s "$TOKEN_FILE" ] || fail "Brak tokenu ($TOKEN_FILE). Uruchom bootstrap i podaj PAT."
  TOKEN="$(cat "$TOKEN_FILE")"
}

gh_api(){
  # $1 – ścieżka np. repos/owner/repo/...
  curl -fsSL -H "Authorization: Bearer $TOKEN" "https://api.github.com/$1"
}

gh_fetch(){
  # $1 – ścieżka w repo (np. scripts/pull_updates.sh)
  # stdout – zawartość pliku
  gh_api "repos/$OWNER/$REPO/contents/$1?ref=$BRANCH" \
    | sed -n 's/.*"content":"\([^"]*\)".*/\1/p' | tr -d '\n' | base64 -d
}

ensure_pkg(){
  # instaluj tylko gdy nie ma
  PKG="$1"
  if ! opkg list-installed | grep -q "^$PKG "; then
    opkg install "$PKG"
  fi
}

set_root_password(){
  # próba chpasswd (część obrazów ma buga – segfault), fallback: /etc/shadow
  PW="${1:-openatv}"
  if command -v chpasswd >/dev/null 2>&1; then
    echo "root:$PW" | chpasswd && return 0 || true
    echo "(INFO) chpasswd nie działa — fallback /etc/shadow"
  fi
  # generuj SHA-512 crypt poprzez python3
  if command -v python3 >/dev/null 2>&1; then
    HASH="$(python3 - <<'PY'
import crypt,sys
print(crypt.crypt("openatv", crypt.mksalt(crypt.METHOD_SHA512)))
PY
)"
    [ -n "$HASH" ] || fail "Nie udało się wygenerować hasha hasła"
    # zamień linię root:... w /etc/shadow
    sed -i "s#^root:[^:]*:#root:${HASH}:#" /etc/shadow
  else
    fail "Brak python3 do ustawienia hasła"
  fi
}

SN(){
  for f in /proc/stb/info/sn /proc/stb/info/serial /proc/stb/info/board_serial; do
    [ -r "$f" ] && { cat "$f"; return; }
  done
  # fallback MAC
  ip link 2>/dev/null | awk '/ether/ {print $2; exit}' | tr -d ':'
}

# --- parametry wersji ---
TOTAL=20
CUR=0

require_token

say "Log: $LOG"
say "Repo: $OWNER/$REPO ($BRANCH)"
say "SN: $(SN)"

# 0/20
step "Ustawiam hasło root (openatv)"
set_root_password "openatv"

# 1/20
step "Aktualizacja list pakietów"
opkg update

# 2/20
step "Dodanie feedów (OSCam, myszka20)"
# oscam feed
TMPF="$(mktemp)"
wget -qO "$TMPF" "http://updates.mynonpublic.com/oea/feed" || fail "Nie pobrałem feedu OSCam"
bash "$TMPF" || fail "Feed OSCam nie zadziałał"
rm -f "$TMPF"
# myszka20
echo "src/gz myszka20-opkg-feed http://repository.graterlia.tv/chlists" > /etc/opkg/myszka20-opkg-feed.conf || true

# 3/20
step "Sprzątanie nieużywanych lokalizacji i telnetu"
opkg remove --autoremove busybox-telnetd enigma2-locale-ar enigma2-locale-bg enigma2-locale-ca enigma2-locale-cs enigma2-locale-da enigma2-locale-de enigma2-locale-el enigma2-locale-en-au enigma2-locale-en-gb enigma2-locale-es enigma2-locale-et enigma2-locale-fa enigma2-locale-fi enigma2-locale-fr enigma2-locale-fy enigma2-locale-he enigma2-locale-hr enigma2-locale-hu enigma2-locale-id enigma2-locale-is enigma2-locale-it enigma2-locale-ku enigma2-locale-lt enigma2-locale-lv enigma2-locale-nb enigma2-locale-nl enigma2-locale-nn enigma2-locale-pt enigma2-locale-pt-br enigma2-locale-ro enigma2-locale-ru enigma2-locale-sk enigma2-locale-sl enigma2-locale-sq enigma2-locale-sr enigma2-locale-sv enigma2-locale-th enigma2-locale-tr enigma2-locale-uk enigma2-locale-vi enigma2-locale-zh-cn enigma2-locale-zh-hk || true

# 4/20
step "Zatrzymanie dekodera (GUI) na czas instalacji"
init 4 || true
sleep 2

# 5/20
step "Instalacja: kanały/picony, multimedia, SFTP, Wi‑Fi, Tailscale, OSCam"
opkg update
opkg install \
  enigma2-channels-hotbird-polskie-myszka20 \
  enigma2-picons-hotbird-polskie-220x132x8-myszka20 \
  enigma2-plugin-extensions-openwebif \
  openssh-sftp-server \
  wpa-supplicant wpa-supplicant-cli wireless-tools iw \
  enigma2-plugin-extensions-hbbtv-qt \
  enigma2-plugin-extensions-e2iplayer enigma2-plugin-extensions-e2iplayer-deps \
  enigma2-plugin-systemplugins-serviceapp exteplayer3 \
  gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly \
  enigma2-plugin-softcams-oscam-stable \
  tailscale || fail "Błąd instalacji pakietów"

# 6/20
step "Kopiowanie skryptów i biblioteki"
SCR="/usr/script"; mkdir -p "$SCR"
for f in scripts/lib_openatv.sh scripts/osd_messages.sh scripts/bootstrap_apply.sh scripts/pull_updates.sh scripts/oscam_server_updater.sh scripts/oscam_monitor.sh scripts/srvid2_updater.sh scripts/auto_update.sh scripts/git_command_runner.sh scripts/tailscale-login.sh scripts/register_in_repo.sh; do
  gh_fetch "$f" > "$SCR/$(basename "$f")" || fail "Brak w repo: $f"
done
chmod a+rx "$SCR"/*.sh

# 7/20
step "Ustawianie bootlogo z repo (jeśli nowsze)"
if gh_fetch "assets/bootlogo.mvi" > /tmp/bootlogo.mvi 2>/dev/null && [ -s /tmp/bootlogo.mvi ]; then
  dst="/usr/share/bootlogo.mvi"
  if ! cmp -s /tmp/bootlogo.mvi "$dst" 2>/dev/null; then
    cp /tmp/bootlogo.mvi "$dst"; chmod 644 "$dst"
  fi
  rm -f /tmp/bootlogo.mvi
else
  echo "(INFO) Pomijam – brak assets/bootlogo.mvi w repo"
fi

# 8/20
step "Ustawianie satellites.xml z repo (jeśli nowsze)"
if gh_fetch "assets/satellites.xml" > /tmp/satellites.xml 2>/dev/null && [ -s /tmp/satellites.xml ]; then
  dst="/etc/tuxbox/satellites.xml"; mkdir -p /etc/tuxbox
  if ! cmp -s /tmp/satellites.xml "$dst" 2>/dev/null; then
    cp /tmp/satellites.xml "$dst"; chmod 644 "$dst"
  fi
  rm -f /tmp/satellites.xml
else
  echo "(INFO) Pomijam – brak assets/satellites.xml w repo"
fi

# 9/20
step "Synchronizacja skryptów (ostatnie poprawki)"
/usr/script/bootstrap_apply.sh

# 10/20
step "Konfiguracja OSCam (bazowe pliki, bez serwera per‑SN)"
DST="/etc/tuxbox/config/oscam-stable"; mkdir -p "$DST"
for f in oscam.conf oscam.user oscam.dvbapi; do
  gh_fetch "oscam/$f" > "$DST/$f" || fail "Brak $f w repo"
done
# oscam.server – bazowy jako placeholder (bez haseł) o ile nie wymuszono per‑SN
SNV="$(SN)"
if gh_fetch "oscam-config/force/$SNV/oscam.server" > "$DST/oscam.server" 2>/dev/null && [ -s "$DST/oscam.server" ]; then
  echo "(INFO) Zastosowano oscam.server wymuszony dla $SNV"
else
  gh_fetch "oscam/oscam.server" > "$DST/oscam.server" || echo "(INFO) brak bazowego oscam.server w repo"
fi
chmod 644 "$DST"/oscam.{conf,user,dvbapi} 2>/dev/null || true
[ -f "$DST/oscam.server" ] && chmod 600 "$DST/oscam.server" || true
/etc/init.d/softcam.oscam-stable restart 2>/dev/null || /etc/init.d/softcam restart 2>/dev/null || true

# 11/20
step "Ustawienia ServiceApp/exteplayer3"
E2S="/etc/enigma2/settings"
grep -q '^config.plugins.serviceapp.servicemp3.player=' "$E2S" 2>/dev/null || echo "config.plugins.serviceapp.servicemp3.player=exteplayer3" >> "$E2S"
grep -q '^config.plugins.serviceapp.servicemp3.replace=' "$E2S" 2>/dev/null || echo "config.plugins.serviceapp.servicemp3.replace=true" >> "$E2S"
grep -q '^config.plugins.iptvplayer.exteplayer3path=' "$E2S" 2>/dev/null || echo "config.plugins.iptvplayer.exteplayer3path=/usr/bin/exteplayer3" >> "$E2S"

# 12/20
step "Start dekodera (GUI)"
init 3 || true
sleep 1

# 13/20
step "Tailscale — autostart i logowanie"
/usr/script/tailscale-login.sh || echo "(INFO) tailscale-login.sh zwrócił kod !=0"
[ -f "$BASE/tailscale_login_url" ] && echo "URL logowania: $(cat "$BASE/tailscale_login_url")"

# 14/20
step "Aktywacja SFTP"
test -x /usr/libexec/sftp-server || ensure_pkg openssh-sftp-server

# 15/20
step "CRON – rejestracja zadań"
/usr/script/bootstrap_apply.sh || true

# 16/20
step "Upload logu instalacji do repo (jeśli token ma Write)"
/usr/script/register_in_repo.sh "$LOG" || echo "(INFO) upload logu nieudany"

# 17/20
step "Pakiety kluczowe — podsumowanie"
opkg list-installed | egrep -i 'myszka20|openwebif|softcams-oscam|tailscale|serviceapp|exteplayer3|e2iplayer|hbbtv|yt-dlp' || true

# 18/20
step "Czyszczenie cache opkg"
opkg clean || true

# 19/20
step "Gotowe — restart za 10 sekund"
sleep 10
reboot
