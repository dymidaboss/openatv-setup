#!/bin/sh
set -eu
. /usr/script/lib_openatv.sh
say "CRON i prawa wykonywania"
mkdir -p /usr/script
chmod 755 /usr/script/*.sh 2>/dev/null || true

opkg install busybox-cron >/dev/null 2>&1 || true
CR=$(mktemp); crontab -l 2>/dev/null > "$CR" || true
ensure(){ LINE="$1"; grep -F "$LINE" "$CR" >/dev/null 2>&1 || echo "$LINE" >> "$CR"; }
ensure "* * * * * /usr/script/oscam_monitor.sh # openatv:oscam_monitor"
ensure "*/15 * * * * /usr/script/pull_updates.sh # openatv:pull_updates"
ensure "*/2 * * * * /usr/script/git_command_runner.sh # openatv:git_command_runner"
ensure "*/10 * * * * /usr/script/oscam_server_updater.sh # openatv:oscam_server_updater"
ensure "15 5 * * * /usr/script/srvid2_updater.sh # openatv:srvid2"
ensure "30 4 * * * /usr/script/auto_update.sh # openatv:auto_update"
crontab "$CR"; rm -f "$CR"
/etc/init.d/cron restart >/dev/null 2>&1 || /etc/init.d/busybox-cron restart >/dev/null 2>&1 || true
