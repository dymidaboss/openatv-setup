#!/bin/sh
set -eu
LOG="/home/root/openatv_postinstall_$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG") 2>&1
say(){ echo "==> $*"; }

# 0) hasło
say "0/20 Ustawiam hasło root (openatv)"
( echo "root:openatv" | chpasswd ) || echo "(INFO) Nie zmieniono hasła — kontynuuję."

# 1) opkg update
say "1/20 Aktualizacja list pakietów"
opkg update >/dev/null 2>&1 || true

# 2) feedy
say "2/20 Dodanie feedów (OSCam, myszka20)"
wget -O - -q http://updates.mynonpublic.com/oea/feed | bash || true
echo "src/gz myszka20-opkg-feed http://repository.graterlia.tv/chlists" > /etc/opkg/myszka20-opkg-feed.conf || true
opkg update >/dev/null 2>&1 || true

# 3) sprzątanie
say "3/20 Sprzątanie nieużywanych lokalizacji i telnetu"
opkg remove --autoremove busybox-telnetd >/dev/null 2>&1 || true

# 4) stop GUI
say "4/20 Zatrzymuję dekoder (GUI) na czas instalacji"; init 4 >/dev/null 2>&1 || true; sleep 2

# 5) instalacje
say "5/20 Instalacja: kanały/picony, multimedia, SFTP, Wi‑Fi, Tailscale, OSCam"
opkg install enigma2-channels-hotbird-polskie-myszka20 enigma2-picons-hotbird-polskie-220x132x8-myszka20 enigma2-plugin-softcams-oscam-stable enigma2-plugin-extensions-openwebif openssh-sftp-server tailscale wpa-supplicant wpa-supplicant-cli wireless-tools iw enigma2-plugin-extensions-youtube python3-yt-dlp enigma2-plugin-extensions-ytdlwrapper enigma2-plugin-extensions-hbbtv-qt enigma2-plugin-extensions-e2iplayer enigma2-plugin-extensions-e2iplayer-deps enigma2-plugin-systemplugins-serviceapp exteplayer3 gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly >/dev/null 2>&1 || true

# 6) wstępne pobranie libów i CRON
say "6/20 Integracja biblioteki i CRON"
mkdir -p /usr/script
RAW_BASE="https://raw.githubusercontent.com/${GITHUB_OWNER:-dymidaboss}/${GITHUB_REPO:-openatv-setup}/${GITHUB_BRANCH:-main}"
(wget -qO /usr/script/lib_openatv.sh "$RAW_BASE/scripts/lib_openatv.sh" || true) && chmod 755 /usr/script/lib_openatv.sh || true
(wget -qO /usr/script/osd_messages.sh "$RAW_BASE/scripts/osd_messages.sh" || true) && chmod 755 /usr/script/osd_messages.sh || true
. /usr/script/lib_openatv.sh
. /usr/script/osd_messages.sh
TMP="$(mktemp)"; if gh_fetch "scripts/bootstrap_apply.sh" "$TMP"; then chmod 755 "$TMP"; sh "$TMP"; fi; rm -f "$TMP"

# 7) bootlogo
say "7/20 Ustawianie bootlogo z repo (jeśli nowsze)"
TMP="$(mktemp)"; if gh_fetch "assets/bootlogo.mvi" "$TMP"; then cp -f "$TMP" /usr/share/bootlogo.mvi; command -v showiframe >/dev/null && showiframe /usr/share/bootlogo.mvi || true; fi; rm -f "$TMP"

# 8) satellites
say "8/20 Ustawianie satellites.xml z repo (jeśli nowsze)"
TMP="$(mktemp)"; if gh_fetch "assets/satellites.xml" "$TMP"; then cp -f "$TMP" /etc/tuxbox/satellites.xml; fi; rm -f "$TMP"

# 9) skrypty do /usr/script
say "9/20 Synchronizacja skryptów (chmod 755)"
for s in lib_openatv.sh osd_messages.sh oscam_monitor.sh oscam_server_updater.sh pull_updates.sh srvid2_updater.sh auto_update.sh git_command_runner.sh tailscale-login.sh register_in_repo.sh; do
  gh_fetch "scripts/${s}" "/usr/script/${s}" && chmod 755 "/usr/script/${s}" || true
done

# 10) oscam bazowe
say "10/20 Konfiguracja OSCam (bez serwera)"
CFG="/etc/tuxbox/config/oscam-stable"; mkdir -p "$CFG"
gh_fetch "oscam/oscam.conf" "$CFG/oscam.conf" || true
gh_fetch "oscam/oscam.user" "$CFG/oscam.user" || true
gh_fetch "oscam/oscam.dvbapi" "$CFG/oscam.dvbapi" || true
/etc/init.d/softcam.oscam-stable restart >/dev/null 2>&1 || /etc/init.d/softcam restart >/dev/null 2>&1 || true

# 11) serviceapp
say "11/20 Ustawienia ServiceApp i exteplayer3"
sed -i -e '/^config.plugins.serviceapp/d' -e '/^config.plugins.iptvplayer.exteplayer3path/d' /etc/enigma2/settings 2>/dev/null || true
{ echo "config.plugins.serviceapp.servicemp3.player=exteplayer3"; echo "config.plugins.serviceapp.servicemp3.replace=true"; echo "config.plugins.iptvplayer.exteplayer3path=/usr/bin/exteplayer3"; } >> /etc/enigma2/settings

# 12) oscam.server
say "12/20 Aktualizacja oscam.server (per‑dekoder)"
/usr/script/oscam_server_updater.sh || true

# 13) start GUI
say "13/20 Start dekodera (GUI)"; init 3 >/dev/null 2>&1 || true; sleep 2

# 14) tailscale
say "14/20 Tailscale — autostart i logowanie"
update-rc.d tailscaled defaults 2>/dev/null || true; /etc/init.d/tailscaled enable 2>/dev/null || true; /etc/init.d/tailscaled start 2>/dev/null || true
/usr/script/tailscale-login.sh || true

# 15) sftp
say "15/20 Aktywacja SFTP"; ln -sf /usr/libexec/sftp-server /usr/libexec/sftp-server.real 2>/dev/null || true

# 16) epg-importer
say "16/20 Ustawienia EPG-Importer"; opkg install enigma2-plugin-extensions-epgimport >/dev/null 2>&1 || true

# 17) rejestracja logu w repo
say "17/20 Rejestracja logu instalacji (jeśli token)"; /usr/script/register_in_repo.sh "$LOG" || true

# 18) clean opkg
say "18/20 Czyszczenie cache opkg"; opkg clean >/dev/null 2>&1 || true

# 19) restart
say "19/20 Restart dekodera za 5 s…"; sleep 5; reboot
