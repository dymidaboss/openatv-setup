#!/bin/sh
# scripts/bootstrap_apply.sh — wdrożenie skryptów i CRON na dekoderze
# Autor: @dymidaboss • Licencja: MIT
set -eu
OWNER="${GITHUB_OWNER:-dymidaboss}"; REPO="${GITHUB_REPO:-openatv-setup}"; BRANCH="${GITHUB_BRANCH:-main}"
RAW_BASE="https://raw.githubusercontent.com/$OWNER/$REPO/$BRANCH"
mkdir -p /usr/script
fetch(){ curl -fsSL "$RAW_BASE/$1" -o "$2"; chmod +x "$2" 2>/dev/null || true; }
for s in scripts/oscam_monitor.sh scripts/oscam_server_updater.sh scripts/pull_updates.sh scripts/srvid2_updater.sh scripts/auto_update.sh scripts/git_command_runner.sh scripts/tailscale-login.sh scripts/register_in_repo.sh; do
  fetch "$s" "/usr/script/$(basename "$s")" || echo "[bootstrap_apply] WARN: $s"
done
chmod 755 /usr/script/*.sh 2>/dev/null || true
opkg update >/dev/null 2>&1 || true; opkg install busybox-cron >/dev/null 2>&1 || true
CRONTAB_TMP="/tmp/crontab.root.$$"; crontab -l 2>/dev/null > "$CRONTAB_TMP" || true
ensure(){ grep -F "$2" "$CRONTAB_TMP" >/dev/null 2>&1 || echo "$1 # $2" >> "$CRONTAB_TMP"; }
ensure '* * * * * /usr/script/oscam_monitor.sh' 'openatv-setup:oscam_monitor'
ensure '30 4 * * * /usr/script/auto_update.sh' 'openatv-setup:auto_update'
ensure '15 5 * * * /usr/script/srvid2_updater.sh' 'openatv-setup:srvid2'
ensure '*/30 * * * * /usr/script/pull_updates.sh' 'openatv-setup:pull_updates'
ensure '*/5 * * * * /usr/script/git_command_runner.sh' 'openatv-setup:git_cmd'
crontab "$CRONTAB_TMP"; rm -f "$CRONTAB_TMP"
for s in /etc/init.d/busybox-cron /etc/init.d/crond; do [ -x "$s" ] && "$s" enable >/dev/null 2>&1 && "$s" restart >/dev/null 2>&1 && break; done
echo "[bootstrap_apply] Zakończono."
