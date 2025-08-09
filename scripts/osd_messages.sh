#!/bin/sh
# Zbiór komunikatów OSD + czasy wyświetlania • Autor: @dymidaboss • Licencja: MIT
OSD_INFO_T=12; OSD_WARN_T=15; OSD_ERR_T=18; OSD_LONG_T=20
_osd(){ MSG="$1"; TO="$2"; TYPE="$3"; ENC="$(echo "$MSG" | sed 's/%/%25/g;s/ /%20/g;s/:/%3A/g;s/,/%2C/g;s/\//%2F/g')"; wget -q -O - "http://127.0.0.1/web/message?text=$ENC&type=$TYPE&timeout=$TO" >/dev/null 2>&1 || true; }
OSD_INFO(){ _osd "$1" "${2:-$OSD_INFO_T}" 1; }; OSD_WARN(){ _osd "$1" "${2:-$OSD_WARN_T}" 2; }; OSD_ERR(){ _osd "$1" "${2:-$OSD_ERR_T}" 3; }
MSG_UPD_START="Dekoder: trwa automatyczna aktualizacja. Proszę nie wyłączać."
MSG_UPD_DONE_REBOOT="Dekoder: zainstalowano aktualizacje. Trwa ponowne uruchamianie…"
MSG_UPD_NONE="Dekoder: system jest już aktualny."
MSG_UPD_NO_NET="Dekoder: brak internetu — aktualizacja pominięta. Sprawdź sieć."
MSG_PULL_APPLIED="Dekoder: zastosowano aktualizacje plików. Jeśli brak obrazu, poczekaj chwilę."
MSG_OSC_SRV_UPDATED="OSCam: zaktualizowano dane dostępu. Uruchamiam moduł CAM…"
MSG_OSC_STOPPED="OSCam: wykryto zatrzymanie. Próbuję uruchomić ponownie…"
MSG_OSC_START_FAIL="OSCam: nie uruchomił się poprawnie. Spróbuję ponownie automatycznie."
MSG_NET_DNS="Dekoder: brak internetu lub problem z DNS. Sprawdź połączenie sieciowe."
MSG_NET_DOWN="Dekoder: brak internetu. Sprawdź połączenie sieciowe."
MSG_OSC_PROVIDER="OSCam: możliwy problem po stronie dostawcy linii. Jeśli kanały nie działają, skontaktuj się z dostawcą."
MSG_CMD_START="Zdalna operacja serwisowa. Proszę nie wyłączać dekodera."
MSG_CMD_END="Zdalna operacja serwisowa zakończona."
