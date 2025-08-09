#!/bin/sh
# Monitor OSCam: internet, proces, pliki, port 8080
set -Eeuo pipefail

# 1) internet
if ! ping -c1 -W2 1.1.1.1 >/dev/null 2>&1; then
  exit 0
fi

# 2) proces oscam
if ! pgrep -f '[o]scam' >/dev/null 2>&1; then
  /etc/init.d/softcam.oscam-stable restart 2>/dev/null || /etc/init.d/softcam restart 2>/dev/null || true
  sleep 3
fi

# 3) plik serwera
if [ ! -s /etc/tuxbox/config/oscam-stable/oscam.server ]; then
  exit 0
fi

# 4) port webif
nc -z 127.0.0.1 8080 >/dev/null 2>&1 || true
exit 0
