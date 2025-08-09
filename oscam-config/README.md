# OSCam Config – Globalnie i per‑dekoder

Globalne pliki OSCam, pobierane podczas instalacji i aktualizacji.

## Pliki globalne (używane domyślnie)
- **oscam.conf**
- **oscam.user**
- **oscam.dvbapi**
- **oscam.server** (może być pusty — patrz override poniżej)

### Ścieżka docelowa
`/etc/tuxbox/config/oscam-stable/`

## Override per‑dekoder
- Umieść plik: `oscam-config/force/<MODEL-SERIAL>/oscam.server`
- Zawartość: pełny plik **albo** jedna linia `C: host port user pass`
- Jeśli override istnieje, **ma pierwszeństwo** nad plikiem globalnym.
