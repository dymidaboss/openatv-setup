# openatv-setup

Pełny instalator OpenATV (20 kroków) + skrypty serwisowe.

## Użycie
Uruchom **bootstrap** z publicznego repo, podaj token do tego prywatnego repo, a instalator zrobi resztę.

## Struktura
- `openatv_postinstall.sh` — główny instalator
- `scripts/` — skrypty (monitoring, aktualizacje, cron, tailscale, upload logów)
- `assets/` — (wrzuć) `bootlogo.mvi`, `satellites.xml`
- `oscam/` — bazowe: `oscam.conf`, `oscam.user`, `oscam.dvbapi`, (opcjonalnie) `oscam.server`
- `oscam-config/force/<SN>/oscam.server` — jeśli chcesz wymusić serwer dla konkretnego dekodera
- `commands/global.sh`, `commands/<SN>.sh` — zdalne polecenia do wykonania na dekoderach
- `install-logs/` — tu instalator wrzuca log pierwszego uruchomienia

---

_automat wygenerowano: 2025-08-09 21:29:39 UTC_
