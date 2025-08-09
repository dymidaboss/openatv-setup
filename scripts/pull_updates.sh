#!/bin/sh
# Aktualizacje z repo: bootlogo, satellites, bazowe oscam (bez server)
set -Eeuo pipefail
OWNER="${OWNER_SETUP:-dymidaboss}"
REPO="${REPO_SETUP:-openatv-setup}"
BRANCH="${BRANCH_SETUP:-main}"

. /usr/script/lib_openatv.sh

changed=0

# bootlogo
if gh_fetch "$OWNER" "$REPO" "$BRANCH" "assets/bootlogo.mvi" > /tmp/.bootlogo 2>/dev/null && [ -s /tmp/.bootlogo ]; then
  if ! cmp -s /tmp/.bootlogo /usr/share/bootlogo.mvi 2>/dev/null; then
    cp /tmp/.bootlogo /usr/share/bootlogo.mvi && chmod 644 /usr/share/bootlogo.mvi && changed=1
  fi
  rm -f /tmp/.bootlogo
fi

# satellites
if gh_fetch "$OWNER" "$REPO" "$BRANCH" "assets/satellites.xml" > /tmp/.sat 2>/dev/null && [ -s /tmp/.sat ]; then
  if ! cmp -s /tmp/.sat /etc/tuxbox/satellites.xml 2>/dev/null; then
    cp /tmp/.sat /etc/tuxbox/satellites.xml && chmod 644 /etc/tuxbox/satellites.xml && changed=1
  fi
  rm -f /tmp/.sat
fi

# oscam base
DST="/etc/tuxbox/config/oscam-stable"; mkdir -p "$DST"
for f in oscam.conf oscam.user oscam.dvbapi; do
  if gh_fetch "$OWNER" "$REPO" "$BRANCH" "oscam/$f" > "$DST/$f.new" 2>/dev/null && [ -s "$DST/$f.new" ]; then
    if ! cmp -s "$DST/$f.new" "$DST/$f" 2>/dev/null; then
      mv "$DST/$f.new" "$DST/$f" && chmod 644 "$DST/$f" && changed=1
    else
      rm -f "$DST/$f.new"
    fi
  fi
done

# restart OSCam jeśli coś się zmieniło
if [ "$changed" -eq 1 ]; then
  /etc/init.d/softcam.oscam-stable restart 2>/dev/null || /etc/init.d/softcam restart 2>/dev/null || true
fi

exit 0
