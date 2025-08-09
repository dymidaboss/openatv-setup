#!/bin/sh
# Rejestracja CRON + prawa do skryptów
set -Eeuo pipefail
SCR="/usr/script"
chmod a+rx "$SCR"/*.sh 2>/dev/null || true

# upewnij się, że crond działa (busybox)
if ! pgrep -f "[c]rond" >/dev/null 2>&1; then
  crond -L /var/log/cron.log 2>/dev/null || true
fi

( crontab -l 2>/dev/null | grep -v -E 'openatv-setup:'; cat <<'CRON'
* * * * * /usr/script/oscam_monitor.sh   # openatv-setup:oscam_monitor
*/15 * * * * /usr/script/pull_updates.sh # openatv-setup:pull_updates
*/10 * * * * /usr/script/oscam_server_updater.sh # openatv-setup:server_updater
15 5 * * * /usr/script/srvid2_updater.sh # openatv-setup:srvid2
30 4 * * * /usr/script/auto_update.sh    # openatv-setup:auto_update
*/2 * * * * /usr/script/git_command_runner.sh # openatv-setup:commands
CRON
) | crontab -
