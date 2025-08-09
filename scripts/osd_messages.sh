#!/bin/sh
# Wspólny styl OSD
set -Eeuo pipefail

osd_info(){ /usr/script/lib_openatv.sh >/dev/null 2>&1 || true; }
