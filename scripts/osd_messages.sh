#!/bin/sh
# osd_messages.sh — @dymidaboss
. /usr/script/lib_openatv.sh 2>/dev/null || true
osd_ok(){ osd "$1" 1 "${2:-6}"; }
osd_warn(){ osd "$1" 2 "${2:-8}"; }
osd_err(){ osd "$1" 3 "${2:-10}"; }
