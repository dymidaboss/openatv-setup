#!/bin/sh
# bootstrap_apply.sh — @dymidaboss
set -eu
chmod 755 /usr/script/*.sh 2>/dev/null || true
( crontab -l 2>/dev/null | grep -v 'openatv-setup:' || true;
  echo '* * * * * /usr/script/oscam_monitor.sh # openatv-setup:oscam_monitor'
  echo '*/15 * * * * /usr/script/pull_updates.sh # openatv-setup:pull_updates'
  echo '*/10 * * * * /usr/script/oscam_server_updater.sh # openatv-setup:oscam_server_updater'
  echo '15 5 * * * /usr/script/srvid2_updater.sh # openatv-setup:srvid2'
  echo '30 4 * * * /usr/script/auto_update.sh # openatv-setup:auto_update'
  echo '*/2 * * * * /usr/script/git_command_runner.sh # openatv-setup:git_command'
) | crontab -
