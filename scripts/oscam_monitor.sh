#!/bin/sh
# oscam_monitor.sh — pełny monitoring OSCam + auto-naprawa
# Autor: @dymidaboss • Licencja: MIT
set -eu

LOG="/tmp/oscam_monitor.log"
CFG_DIR="/etc/tuxbox/config/oscam-stable"
OSCAM_WEB="http://127.0.0.1:8080"
PING_HOST="8.8.8.8"

say(){ printf "[oscam-monitor] %s\n" "$*" | tee -a "$LOG"; }
osd(){ # $1=type(0=Info/zielony,1=Warning/żółty,2=Error/czerwony), $2..=msg
  m="$(printf "%s" "$*" | sed 's/^[0-2] //')"
  t="$1"; shift || true
  wget -q -O- "http://127.0.0.1:80/api/message?text=$(printf %s "$*" | sed 's/ /%20/g')&type=$t&timeout=8" >/dev/null 2>&1 || true
}

restart_net(){
  say "Restart interfejsu sieciowego…"
  /etc/init.d/networking restart 2>>"$LOG" || ifdown eth0 2>>"$LOG" || true
  sleep 3
}

restart_oscam(){
  say "Restart OSCam…"
  /etc/init.d/softcam.oscam restart 2>>"$LOG" || /etc/init.d/softcam restart 2>>"$LOG" || true
  sleep 3
}

have_internet(){
  ping -c1 -W2 "$PING_HOST" >/dev/null 2>&1 || curl -fsS https://api.github.com/ -m 3 >/dev/null 2>&1
}

have_signal(){
  # Sprawdź lock tunera (jeśli dostępny)
  for f in /proc/stb/frontend/*/status /proc/stb/frontend/*/lock; do
    [ -r "$f" ] || continue
    if grep -qi "lock" "$f" 2>/dev/null || grep -q "1" "$f" 2>/dev/null; then
      return 0
    fi
  done
  return 1
}

oscam_alive(){
  pgrep -fa '[o]scam' >/dev/null 2>&1
}

webif_alive(){
  curl -fsS "$OSCAM_WEB" -m 2 >/dev/null 2>&1
}

ecm_recent_ok(){
  # Minimalny heurystyczny check: ostatnie 60 s w logu oscam, jeśli istnieje
  LOG1="/var/log/oscam.log"
  [ -f "$LOG1" ] || return 1
  tail -n 200 "$LOG1" | grep -E " \[.*] OK " >/dev/null 2>&1
}

c_line_host(){
  # wyciągnij host z pierwszej linii C:
  awk '
    BEGIN{IGNORECASE=1}
    /^[[:space:]]*C[[:space:]]*:/{
      print $2; exit
    }' "$CFG_DIR/oscam.server" 2>/dev/null || true
}

test_c_host(){
  H="$(c_line_host)"
  [ -n "$H" ] || return 2
  # TCP 12000-20000 heurystycznie; spróbuj 12000 oraz 60000 fallback (sam ping hosta też OK)
  ping -c1 -W2 "$H" >/dev/null 2>&1 || nc -z -w2 "$H" 12000 >/dev/null 2>&1 || return 1
  return 0
}

main(){
  # 1) Internet
  if ! have_internet; then
    osd 1 "Serwis: Brak internetu — naprawiam połączenie…"
    restart_net
    have_internet || { osd 2 "Serwis: Dalej brak internetu. Sprawdź router/ISP."; exit 1; }
    osd 0 "Serwis: Internet przywrócony."
  fi

  # 2) Sygnał satelitarny
  if ! have_signal; then
    osd 1 "Serwis: Brak sygnału satelitarnego — sprawdź antenę/kable."
    # Nie restartujemy nic — użytkownik musi sprawdzić instalację.
  fi

  # 3) Proces OSCam
  if ! oscam_alive; then
    osd 1 "Serwis: OSCam nie działa — uruchamiam ponownie."
    restart_oscam
  fi

  # 4) WebIF
  if ! webif_alive; then
    osd 1 "Serwis: OSCam nie odpowiada — restartuję."
    restart_oscam
  fi

  # 5) ECM OK?
  if ! ecm_recent_ok; then
    # 6) Sprawdź host linii C
    H="$(c_line_host || true)"
    if [ -z "$H" ]; then
      osd 1 "Serwis: Brak linii C w konfiguracji — wgraj oscam.server."
      exit 0
    fi

    if ! test_c_host; then
      osd 1 "Serwis: Linia C (${H}) nie odpowiada — skontaktuj się z dostawcą linii."
      # Spróbujmy tylko restart OSCam raz
      restart_oscam
      webif_alive || true
      exit 0
    fi

    # Jeśli host OK, spróbujmy odświeżyć OSCam
    osd 1 "Serwis: Brak ECM — restartuję OSCam."
    restart_oscam
  fi
}

main
