#!/bin/sh
# spójne komunikaty OSD
osd_ok(){ osd "$1" 1 "${2:-8}"; }        # zielone
osd_warn(){ osd "$1" 2 "${2:-10}"; }     # żółte
osd_err(){ osd "$1" 3 "${2:-12}"; }      # czerwone
