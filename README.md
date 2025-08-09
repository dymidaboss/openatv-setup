# openatv-setup (PRIVATE)
Komplet instalatora i skryptów. Kluczowe katalogi:
- `scripts/` — wszystkie skrypty, CRON, biblioteka (`lib_openatv.sh`) i komunikaty OSD (`osd_messages.sh`).
- `oscam/` — bazowe pliki konfiguracyjne (bez `oscam.server` per SN).
- `oscam-config/force/<SN>/oscam.server` — serwer OSCam dla konkretnego SN (priorytet).
- `assets/` — `bootlogo.mvi`, `satellites.xml` (opcjonalnie, jeśli chcesz aktualizować).
- `commands/` — `global.sh` (wszyscy) i `<SN>.sh` (pojedyncze urządzenie).
- `install-logs/` — tu trafią logi pierwszej instalacji (wysyłane przez API).

> Uwaga: Pobieranie z prywatnego repo wymaga tokenu zapisanego na dekoderze w `/etc/openatv-setup/github_token`.
