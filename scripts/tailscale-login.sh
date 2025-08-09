#!/bin/sh
set -eu
. /usr/script/lib_openatv.sh
/etc/init.d/tailscaled enable >/dev/null 2>&1 || true
/etc/init.d/tailscaled start  >/dev/null 2>&1 || true
echo "Jeśli niżej pojawi się link Tailscale — otwórz go w przeglądarce:"
tailscale up 2>&1 | tee /tmp/tailscale_up.log || true
