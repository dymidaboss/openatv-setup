#!/bin/sh
# System update – tylko gdy są dostępne aktualizacje
set -Eeuo pipefail
opkg update || exit 0
UP="$(opkg list-upgradable | wc -l)"
[ "$UP" -gt 0 ] || exit 0
opkg upgrade || exit 0
# jeśli kernel/enigma – wymuś restart
reboot
