#!/bin/sh
# openatv_postinstall.sh — @dymidaboss
set -eu
export OSD_SILENT=1
LOG="/home/root/openatv_postinstall_$(date +%Y%m%d-%H%M%S).log"
mkdir -p /etc/openatv-setup /usr/script /var/log >/dev/null 2>&1 || true

say(){ echo "$@"; }
step(){ echo "==> $1" | tee -a "$LOG"; }
info(){ echo "(INFO) $1" | tee -a "$LOG"; }
err(){ echo "(!) $1" | tee -a "$LOG"; }

gh_fetch() {
  REMOTE="$1"; DEST="$2"
  OWNER="${GITHUB_OWNER:-dymidaboss}"; REPO="${GITHUB_REPO:-openatv-setup}"; BRANCH="${GITHUB_BRANCH:-main}"
  TOK=""; [ -f /etc/openatv-setup/github_token ] && TOK="$(cat /etc/openatv-setup/github_token 2>/dev/null)"
  # API (private)
  if [ -n "$TOK" ]; then
    JSON="$(curl -fsS -H "Authorization: token $TOK" "https://api.github.com/repos/$OWNER/$REPO/contents/$REMOTE?ref=$BRANCH" 2>/dev/null || true)"
    CNT="$(printf "%s" "$JSON" | tr -d '\n' | sed -n 's/.*"content":"\([^"]*\)".*/\1/p')"
    if [ -n "$CNT" ]; then
      (command -v base64 >/dev/null && printf "%s" "$CNT" | base64 -d > "$DEST") || (printf "%s" "$CNT" | openssl base64 -d > "$DEST")
      return 0
    fi
  fi
  # RAW (public)
  curl -fsSL "https://raw.githubusercontent.com/$OWNER/$REPO/$BRANCH/$REMOTE" -o "$DEST"
}

step "0/20 Ustawiam hasło root (openatv)"
if echo 'root:openatv' | chpasswd 2>>"$LOG"; then :; else
  HASH=""
  if command -v openssl >/dev/null 2>&1; then HASH="$(openssl passwd -6 'openatv' 2>>"$LOG" || true)"; fi
  if [ -z "$HASH" ] && command -v python3 >/dev/null 2>&1; then
    HASH="$(python3 - <<'PY'
import crypt
print(crypt.crypt("openatv", crypt.mksalt(crypt.METHOD_SHA512)))
PY
)"
  fi
  if [ -n "$HASH" ] && grep -q '^root:' /etc/shadow; then
    sed -i "s|^root:[^:]*:|root:${HASH}:|" /etc/shadow && info "Hasło ustawione przez /etc/shadow"
  else
    info "Nie zmieniono hasła — kontynuuję."
  fi
fi

step "1/20 Aktualizacja list pakietów"
opkg update >>"$LOG" 2>&1 || true

step "2/20 Dodanie feedów (OSCam, myszka20)"
wget -O - -q http://updates.mynonpublic.com/oea/feed | bash >>"$LOG" 2>&1 || true
echo "src/gz myszka20-opkg-feed http://repository.graterlia.tv/chlists" > /etc/opkg/myszka20-opkg-feed.conf

step "3/20 Sprzątanie nieużywanych lokalizacji i telnetu"
opkg remove --autoremove busybox-telnetd enigma2-locale-de enigma2-locale-fr enigma2-locale-ru enigma2-locale-it enigma2-locale-es 2>>"$LOG" || true

step "4/20 Zatrzymanie dekodera (GUI) na czas instalacji"
init 4 >/dev/null 2>&1 || true
sleep 2

step "5/20 Instalacja: kanały/picony, multimedia, SFTP, Wi-Fi, Tailscale, OSCam"
opkg update >>"$LOG" 2>&1 || true
opkg install enigma2-channels-hotbird-polskie-myszka20 enigma2-picons-hotbird-polskie-220x132x8-myszka20   enigma2-plugin-extensions-openwebif openssh-sftp-server tailscale wpa-supplicant wpa-supplicant-cli wireless-tools iw   enigma2-plugin-extensions-hbbtv-qt enigma2-plugin-systemplugins-serviceapp exteplayer3 gstreamer1.0-plugins-good   gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly enigma2-plugin-softcams-oscam-stable python3-logging   >>"$LOG" 2>&1 || true

step "6/20 Kopiowanie skryptów i biblioteki"
for f in scripts/lib_openatv.sh scripts/osd_messages.sh scripts/bootstrap_apply.sh scripts/pull_updates.sh scripts/oscam_server_updater.sh scripts/oscam_monitor.sh scripts/srvid2_updater.sh scripts/auto_update.sh scripts/git_command_runner.sh scripts/tailscale-login.sh scripts/register_in_repo.sh; do
  gh_fetch "$f" "/usr/script/$(basename "$f")" >>"$LOG" 2>&1 || true
done
chmod 755 /usr/script/*.sh 2>/dev/null || true
. /usr/script/lib_openatv.sh 2>/dev/null || true

step "7/20 Ustawianie bootlogo z repo (jeśli nowsze)"
if gh_fetch assets/bootlogo.mvi /tmp/bootlogo.mvi 2>>"$LOG"; then
  if ! cmp -s /tmp/bootlogo.mvi /usr/share/bootlogo.mvi 2>/dev/null; then
    cp -f /tmp/bootlogo.mvi /usr/share/bootlogo.mvi && (command -v showiframe >/dev/null 2>&1 && showiframe /usr/share/bootlogo.mvi >/dev/null 2>&1 || true)
  fi
fi

step "8/20 Ustawianie satellites.xml z repo (jeśli nowsze)"
if gh_fetch assets/satellites.xml /tmp/sat.xml 2>>"$LOG"; then
  if ! cmp -s /tmp/sat.xml /etc/tuxbox/satellites.xml 2>/dev/null; then
    cp -f /tmp/sat.xml /etc/tuxbox/satellites.xml
  fi
fi

step "9/20 Synchronizacja skryptów (ostatnie poprawki)"
/usr/script/bootstrap_apply.sh >>"$LOG" 2>&1 || true

step "10/20 Konfiguracja OSCam (bazowe pliki, bez serwera per-SN)"
CFGDIR="/etc/tuxbox/config/oscam-stable"; mkdir -p "$CFGDIR"
fetch_or_skip(){ if gh_fetch "$1" "$2" 2>>"$LOG"; then echo "  • $1 -> $(basename "$2")" >>"$LOG"; return 0; else echo "  • brak $1" >>"$LOG"; return 1; fi; }
fetch_or_skip "oscam/oscam.conf"   "$CFGDIR/oscam.conf"
fetch_or_skip "oscam/oscam.user"   "$CFGDIR/oscam.user"
fetch_or_skip "oscam/oscam.dvbapi" "$CFGDIR/oscam.dvbapi"
if gh_fetch "oscam/oscam.server" "$CFGDIR/oscam.server" 2>>"$LOG"; then :; else
cat >"$CFGDIR/oscam.server"<<'EOF'
# Placeholder – zostanie podmieniony automatycznie przez oscam_server_updater.sh
# (oscam-config/force/<SN>/oscam.server lub globalny oscam/oscam.server)
EOF
fi
chmod 600 "$CFGDIR"/oscam.* 2>/dev/null || true
/etc/init.d/softcam.oscam-stable restart >>"$LOG" 2>&1 || /etc/init.d/softcam restart >>"$LOG" 2>&1 || true

step "11/20 Ustawienia ServiceApp i exteplayer3"
sed -i 's|^config.plugins.serviceapp.servicemp3.player=.*|config.plugins.serviceapp.servicemp3.player=exteplayer3|' /etc/enigma2/settings 2>/dev/null || true
grep -q 'config.plugins.serviceapp.servicemp3.replace=true' /etc/enigma2/settings 2>/dev/null || echo 'config.plugins.serviceapp.servicemp3.replace=true' >> /etc/enigma2/settings

step "12/20 Start dekodera (GUI)"
init 3 >/dev/null 2>&1 || true

step "13/20 Tailscale — autostart i logowanie w tle"
chmod 755 /usr/script/tailscale-login.sh 2>/dev/null || true
/etc/init.d/tailscaled enable >/dev/null 2>&1 || true
/etc/init.d/tailscaled start  >/dev/null 2>&1 || true
/usr/script/tailscale-login.sh >>"$LOG" 2>&1 || true
[ -f /etc/openatv-setup/tailscale_login_url ] && echo "Tailscale URL: $(cat /etc/openatv-setup/tailscale_login_url)" >>"$LOG"

step "14/20 Aktywacja SFTP"
[ -x /etc/init.d/sshd ] && /etc/init.d/sshd restart >>"$LOG" 2>&1 || true

step "15/20 EPG Importer (opcjonalnie)"
opkg install enigma2-plugin-extensions-epgimport >>"$LOG" 2>&1 || true

step "16/20 Rejestracja logu w repo (jeśli token)"
/usr/script/register_in_repo.sh "$LOG" >>"$LOG" 2>&1 || true

step "17/20 Czyszczenie cache opkg"
opkg clean >>"$LOG" 2>&1 || true

step "18/20 CRON: auto-update/monitor/zdalne polecenia"
/usr/script/bootstrap_apply.sh >>"$LOG" 2>&1 || true

step "19/20 Restart za 10 sekund"
unset OSD_SILENT
sleep 10
reboot
