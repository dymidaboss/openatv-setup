#!/bin/sh
# openatv_postinstall.sh — PEŁNY instalator OpenATV (20 kroków) + monitor + auto-aktualizacje
# Autor: @dymidaboss • Licencja: MIT
set -eu

START_TS="$(date +%Y%m%d-%H%M%S)"
LOG="/home/root/openatv_postinstall_${START_TS}.log"
exec > >(tee -a "$LOG") 2>&1

say(){ echo "==> $*"; }
quiet(){ "$@" >/dev/null 2>&1 || true; }

# Konfiguracja repo (może być nadpisana przez środowisko)
GITHUB_OWNER="${GITHUB_OWNER:-dymidaboss}"
GITHUB_REPO="${GITHUB_REPO:-openatv-setup}"
GITHUB_BRANCH="${GITHUB_BRANCH:-main}"
RAW_BASE_URL="https://raw.githubusercontent.com/${GITHUB_OWNER}/${GITHUB_REPO}/${GITHUB_BRANCH}"
API_BASE_URL="https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/contents"

# Token (opcjonalny, jeśli repo prywatne)
TOKEN_FILE="/etc/openatv-setup/github_token"
[ -f "$TOKEN_FILE" ] || true

# 1) Hasło root
say "1/20 Ustawiam hasło root (openatv)"
( echo 'root:openatv' | chpasswd ) >/dev/null 2>&1 || true

# 2) Katalogi
say "2/20 Przygotowanie katalogów"
quiet mkdir -p /usr/script /etc/openatv-setup

# 3) Update list pakietów
say "3/20 Aktualizacja list pakietów"
quiet opkg update

# 4) Upgrade systemu
say "4/20 Aktualizacja zainstalowanych pakietów"
quiet opkg upgrade

# 5) Feed OSCam + myszka20
say "5/20 Dodanie feedów (OSCam, myszka20)"
quiet sh -c 'wget -O - -q http://updates.mynonpublic.com/oea/feed | bash'
echo "src/gz myszka20-opkg-feed http://repository.graterlia.tv/chlists" > /etc/opkg/myszka20-opkg-feed.conf
quiet opkg update

# 6) Sprzątanie lokali i telnetu
say "6/20 Sprzątanie lokalizacji i telnetu"
quiet opkg remove --autoremove bash-locale-de bash-locale-fr busybox-telnetd elfutils-locale-de \
  enigma2-locale-ar enigma2-locale-bg enigma2-locale-ca enigma2-locale-cs enigma2-locale-da \
  enigma2-locale-de enigma2-locale-el enigma2-locale-en-au enigma2-locale-en-gb enigma2-locale-es \
  enigma2-locale-et enigma2-locale-fa enigma2-locale-fi enigma2-locale-fr enigma2-locale-fy \
  enigma2-locale-he enigma2-locale-hr enigma2-locale-hu enigma2-locale-id enigma2-locale-is \
  enigma2-locale-it enigma2-locale-ku enigma2-locale-lt enigma2-locale-lv enigma2-locale-meta \
  enigma2-locale-nb enigma2-locale-nl enigma2-locale-nn enigma2-locale-pt enigma2-locale-pt-br \
  enigma2-locale-ro enigma2-locale-ru enigma2-locale-sk enigma2-locale-sl enigma2-locale-sq \
  enigma2-locale-sr enigma2-locale-sv enigma2-locale-th enigma2-locale-tr enigma2-locale-uk \
  enigma2-locale-vi enigma2-locale-zh-cn enigma2-locale-zh-hk

# 7) Stop GUI na czas instalacji
say "7/20 Zatrzymuję dekoder (GUI) na czas instalacji"
quiet init 4
sleep 2

# 8) Instalacja pakietów
say "8/20 Instalacja: kanały/picony, multimedia, SFTP, Wi‑Fi, Tailscale, OSCam"
quiet opkg install enigma2-channels-hotbird-polskie-myszka20 enigma2-picons-hotbird-polskie-220x132x8-myszka20 \
  enigma2-plugin-softcams-oscam-stable enigma2-plugin-extensions-openwebif openssh-sftp-server \
  tailscale wpa-supplicant wpa-supplicant-cli wireless-tools iw \
  enigma2-plugin-extensions-youtube python3-yt-dlp enigma2-plugin-extensions-ytdlwrapper \
  enigma2-plugin-extensions-hbbtv-qt enigma2-plugin-extensions-e2iplayer enigma2-plugin-extensions-e2iplayer-deps \
  enigma2-plugin-systemplugins-serviceapp exteplayer3 gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly

# 9) Integracja monitorów/aktualizacji + CRON (idempotentnie)
say "9/20 Integracja monitorów i auto-aktualizacji (CRON)"
sh -c 'wget -qO- "'"$RAW_BASE_URL"'/scripts/bootstrap_apply.sh" | sh -s --' </dev/tty || true

# 10) Bootlogo z repo (jawny krok)
say "10/20 Ustawianie bootlogo z repo (jeśli nowsze)"
TMP="/tmp/bootlogo.mvi.$$"
if curl -fsS "$RAW_BASE_URL/bootlogo/bootlogo.mvi" -o "$TMP"; then
  cmp -s "$TMP" /usr/share/bootlogo.mvi || cp -f "$TMP" /usr/share/bootlogo.mvi
  rm -f "$TMP"
fi

# 11) satellites.xml z repo (jawny krok)
say "11/20 Ustawianie satellites.xml z repo (jeśli nowsze)"
TMP="/tmp/satellites.xml.$$"
if curl -fsS "$RAW_BASE_URL/satellites/satellites.xml" -o "$TMP"; then
  cmp -s "$TMP" /etc/tuxbox/satellites.xml || cp -f "$TMP" /etc/tuxbox/satellites.xml
  rm -f "$TMP"
fi

# 12) Pull: configi OSCam (bez serwera) + skrypty (dla pewności)
say "12/20 Synchronizacja skryptów i configów OSCam (bez serwera)"
/usr/script/pull_updates.sh || true

# 13) Ustawienia ServiceApp + exteplayer3
say "13/20 Ustawienia ServiceApp + exteplayer3"
grep -q '^config.plugins.serviceapp.servicemp3.player=' /etc/enigma2/settings || {
  {
    echo "config.plugins.iptvplayer.exteplayer3path=/usr/bin/exteplayer3"
    echo "config.plugins.serviceapp.servicemp3.player=exteplayer3"
    echo "config.plugins.serviceapp.servicemp3.replace=true"
  } >> /etc/enigma2/settings
}

# 14) Aktualizacja oscam.server per-dekoder
say "14/20 Aktualizacja oscam.server (per-dekoder)"
/usr/script/oscam_server_updater.sh || true

# 15) Start GUI
say "15/20 Start dekodera (GUI)"
quiet init 3
sleep 2

# 16) Tailscale enable/start + link logowania
say "16/20 Tailscale — autostart i logowanie"
quiet /etc/init.d/tailscaled enable
quiet /etc/init.d/tailscaled start
/usr/script/tailscale-login.sh || true

# 17) SFTP symlink (Total Commander)
say "17/20 Aktywacja SFTP"
[ -x /usr/libexec/sftp-server ] || ln -sf /usr/libexec/sftp-server.real /usr/libexec/sftp-server || true

# 18) Zapis logu lokalnie + opcjonalnie do repo
say "18/20 Zapis logu (lokalnie) i wysyłka do repo (jeśli token)"
SN="$(cat /proc/stb/info/sn 2>/dev/null || hostname)"
mkdir -p /etc/openatv-setup/logs 2>/dev/null || true
cp -f "$LOG" "/etc/openatv-setup/logs/postinstall_${SN}_${START_TS}.log" || true
if [ -f "$TOKEN_FILE" ]; then
  TOKEN="$(cat "$TOKEN_FILE")"
  API="https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/contents/logs/${SN}/postinstall_${START_TS}.log"
  B64="$(openssl base64 -A < "$LOG")"
  curl -fsS -X PUT -H "Authorization: token $TOKEN" -d "{\"message\":\"postinstall ${SN} ${START_TS}\",\"content\":\"${B64}\",\"branch\":\"${GITHUB_BRANCH}\"}" "$API" >/dev/null 2>&1 || true
fi

say "Zakończono. Pełny log: $LOG"
exit 0
