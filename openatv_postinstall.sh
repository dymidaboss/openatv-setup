#!/bin/sh
# openatv-setup / openatv_postinstall.sh
# Kompletny postinstall dla OpenATV. 20 kroków. Zero OSD. Log do /home/root/openatv_postinstall_*.log
# Author: @dymidaboss (project owner), helper script prepared as requested

set -Eeuo pipefail

STAMP="$(date +%Y%m%d-%H%M%S)"
LOG="/home/root/openatv_postinstall_${STAMP}.log"
mkdir -p /home/root /usr/script /etc/openatv-setup
umask 022

# -- UTIL ---------------------------------------------------------
log(){ printf "%s\n" "$*" >>"$LOG"; }
say(){ printf "%s\n" "$*"; log "$*"; }
quiet(){ ( "$@" ) >>"$LOG" 2>&1; }

have(){ command -v "$1" >/dev/null 2>&1; }

get_sn(){
  for f in /proc/stb/info/{sn,chip_id,boxtype} /sys/class/dmi/id/product_serial; do
    [ -r "$f" ] && awk 'NR==1{print;exit}' "$f" && return 0
  done
  cat /sys/class/net/*/address 2>/dev/null | head -1 | tr -d ':'
}
SN="$(get_sn || echo unknown)"

get_model(){
  for f in /proc/stb/info/model /proc/stb/info/boxtype; do
    [ -r "$f" ] && awk 'NR==1{print;exit}' "$f" && return 0
  done
  echo "openatv"
}
MODEL="$(get_model)"

# Token
GITHUB_TOKEN="$(cat /etc/openatv-setup/github_token 2>/dev/null || true)"
OWNER="${OWNER_SETUP:-dymidaboss}"
REPO="${REPO_SETUP:-openatv-setup}"
BRANCH="${BRANCH_SETUP:-main}"
API_BASE="https://api.github.com/repos/${OWNER}/${REPO}/contents"
HDR="Authorization: token ${GITHUB_TOKEN}"

api_get_file(){
  # $1 – ścieżka w repo (np. scripts/pull_updates.sh)
  local url="${API_BASE}/$1?ref=${BRANCH}"
  local json content
  json="$(curl -fsSL -H "$HDR" "$url" 2>>"$LOG" || true)"
  printf "%s" "$json" | grep -q '"content"' || return 1
  content="$(printf "%s" "$json" | sed -n 's/.*"content":[[:space:]]*"\([^"]*\)".*/\1/p')"
  base64 -d <<EOF
$content
EOF
}

install_file(){
  # repo_path dest
  local src="$1" dest="$2"
  if api_get_file "$src" > "$dest".tmp; then
    if [ ! -f "$dest" ] || ! cmp -s "$dest".tmp "$dest"; then
      mv "$dest".tmp "$dest"
      log "[install_file] Zmieniono $dest (z $src)"
      return 0
    else
      rm -f "$dest".tmp
      log "[install_file] Bez zmian $dest"
      return 2
    fi
  else
    rm -f "$dest".tmp
    log "[install_file] BRAK w repo: $src"
    return 3
  fi
}

set_root_password(){
  local PASS="openatv"
  say "==> 0/20 Ustawiam hasło root (openatv)"
  # 1) Najpierw chpasswd (najszybsza metoda)
  if have chpasswd; then
    echo "root:$PASS" | chpasswd 2>>"$LOG" && { log "[passwd] chpasswd OK"; return 0; } || true
    log "[passwd] chpasswd nieudane (np. segfault)"
  fi
  # 2) Plan B: passwd w trybie non-interactive (root nie wymaga podawania starego hasła)
  if have passwd; then
    if printf "%s\n%s\n" "$PASS" "$PASS" | passwd root >>"$LOG" 2>&1; then
      log "[passwd] passwd OK"
      return 0
    else
      log "[passwd] passwd nieudane"
    fi
  fi
  # 3) Plan C: bezpośrednia modyfikacja /etc/shadow (SHA-512 przez openssl)
  if have openssl; then
    local SALT HASH
    SALT="$(head -c 12 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 8)"
    HASH="$(openssl passwd -6 -salt "$SALT" "$PASS" 2>>"$LOG" )"
    [ -n "$HASH" ] || { log "[passwd] openssl passwd nie zwrócił hasha"; return 1; }
    awk -v h="$HASH" -F: 'BEGIN{OFS=":"} $1=="root"{$2=h}1' /etc/shadow > /etc/shadow.new && \
      mv /etc/shadow.new /etc/shadow && chmod 600 /etc/shadow
    log "[passwd] /etc/shadow zaktualizowany"
    return 0
  fi
  log "[passwd] brak metody ustawienia hasła"
  return 1
}

# -- START --------------------------------------------------------

say "==> Log: $LOG"
say "==> Repo: ${OWNER}/${REPO} (${BRANCH}), SN=${SN}, MODEL=${MODEL}"

set_root_password || say "(INFO) Hasło niezmienione — kontynuuję."

say "==> 1/20 Aktualizacja list pakietów"
quiet opkg update

say "==> 2/20 Dodanie feedów (OSCam, myszka20)"
quiet sh -c 'wget -O - -q http://updates.mynonpublic.com/oea/feed | bash'
echo "src/gz myszka20-opkg-feed http://repository.graterlia.tv/chlists" >/etc/opkg/myszka20-opkg-feed.conf

say "==> 3/20 Sprzątanie nieużywanych lokali i telnetu"
quiet sh -c 'opkg remove --autoremove busybox-telnetd bash-locale-de elfutils-locale-de enigma2-locale-* 2>/dev/null || true'

say "==> 4/20 Zatrzymanie dekodera (GUI) na czas instalacji"
quiet sh -c 'init 4; sleep 2'

say "==> 5/20 Instalacja: kanały/picony, multimedia, SFTP, Wi-Fi, Tailscale, OSCam"
quiet sh -c 'opkg install -V0 \
  enigma2-channels-hotbird-polskie-myszka20 \
  enigma2-picons-hotbird-polskie-220x132x8-myszka20 \
  enigma2-plugin-extensions-openwebif openssh-sftp-server \
  wpa-supplicant wpa-supplicant-cli wireless-tools iw \
  enigma2-plugin-softcams-oscam-stable \
  enigma2-plugin-systemplugins-serviceapp exteplayer3 \
  gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly \
  enigma2-plugin-extensions-e2iplayer enigma2-plugin-extensions-e2iplayer-deps \
  enigma2-plugin-extensions-hbbtv-qt python3-yt-dlp 2>/dev/null || true'

say "==> 6/20 Kopiowanie skryptów i biblioteki"
for f in lib_openatv.sh osd_messages.sh bootstrap_apply.sh pull_updates.sh oscam_server_updater.sh \
         oscam_monitor.sh srvid2_updater.sh auto_update.sh git_command_runner.sh tailscale-login.sh register_in_repo.sh
do
  install_file "scripts/$f" "/usr/script/$f" || true
done
chmod +x /usr/script/*.sh 2>>"$LOG" || true

say "==> 7/20 Ustawianie bootlogo z repo (jeśli nowsze)"
install_file "assets/bootlogo.mvi" "/usr/share/bootlogo.mvi" || true

say "==> 8/20 Ustawianie satellites.xml z repo (jeśli nowsze)"
install_file "assets/satellites.xml" "/etc/tuxbox/satellites.xml" || true

say "==> 9/20 Synchronizacja skryptów (ostatnie poprawki)"
quiet /usr/script/bootstrap_apply.sh || true

say "==> 10/20 Konfiguracja OSCam (bazowe pliki + per-SN oscam.server jeśli jest)"
install_file "oscam/oscam.conf" "/etc/tuxbox/config/oscam-stable/oscam.conf" || true
install_file "oscam/oscam.user" "/etc/tuxbox/config/oscam-stable/oscam.user" || true
install_file "oscam/oscam.dvbapi" "/etc/tuxbox/config/oscam-stable/oscam.dvbapi" || true
# bazowy server
install_file "oscam/oscam.server" "/etc/tuxbox/config/oscam-stable/oscam.server" || true
# per SN
install_file "oscam-config/force/${SN}/oscam.server" "/etc/tuxbox/config/oscam-stable/oscam.server" || true
quiet sh -c '/etc/init.d/softcam.oscam restart 2>/dev/null || /etc/init.d/softcam restart 2>/dev/null || true'

say "==> 11/20 Ustawienia ServiceApp i exteplayer3"
E2="/etc/enigma2/settings"
grep -q 'config.plugins.serviceapp.servicemp3.player=' "$E2" 2>/dev/null || echo 'config.plugins.serviceapp.servicemp3.player=exteplayer3' >>"$E2"
grep -q 'config.plugins.serviceapp.servicemp3.replace=' "$E2" 2>/dev/null || echo 'config.plugins.serviceapp.servicemp3.replace=true' >>"$E2"
grep -q 'config.plugins.iptvplayer.exteplayer3path=' "$E2" 2>/dev/null || echo 'config.plugins.iptvplayer.exteplayer3path=/usr/bin/exteplayer3' >>"$E2"

say "==> 12/20 Start dekodera (GUI)"
quiet sh -c 'init 3; sleep 1'

say "==> 13/20 Tailscale — autostart i logowanie"
chmod +x /usr/script/tailscale-login.sh 2>>"$LOG" || true
quiet /usr/script/tailscale-login.sh || true

say "==> 14/20 Aktywacja SFTP"
quiet sh -c 'test -x /usr/libexec/sftp-server || ln -sf /usr/lib/ssh/sftp-server /usr/libexec/sftp-server 2>/dev/null || true'

say "==> 15/20 Rejestracja CRON (monitor, aktualizacje, SRVID2, komendy)"
quiet /usr/script/bootstrap_apply.sh || true

say "==> 16/20 Zapis logu (lokalnie) i wysyłka do repo (jeśli token)"
if [ -n "$GITHUB_TOKEN" ]; then
  BN="$(basename "$LOG")"
  DEST="install-logs/${SN}/${BN}"
  B64="$(base64 -w0 "$LOG" 2>/dev/null || openssl base64 -A -in "$LOG")"
  curl -fsSL -X PUT -H "$HDR" \
    -d "{\"message\":\"install log ${SN} ${STAMP}\",\"content\":\"${B64}\"}" \
    "https://api.github.com/repos/${OWNER}/${REPO}/contents/${DEST}" >>"$LOG" 2>&1 || true
fi

say "==> 17/20 Podsumowanie pakietów (do logu)"
quiet opkg list-installed

say "==> 18/20 Czyszczenie cache opkg"
quiet opkg clean || true

say "==> 19/20 Gotowe — restart za 10 s"
sleep 10
reboot
