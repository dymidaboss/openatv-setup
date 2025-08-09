# openatv-setup (private)
Kompletny instalator i skrypty dla dekoderów z OpenATV.

## Start
Uruchamiany przez publiczny bootstrap (zapyta o token i odpali ten instalator).

## Najważniejsze ścieżki
- `openatv_postinstall.sh` – główny instalator (20 kroków)
- `scripts/` – biblioteka + serwisy w tle (CRON)
- `assets/` – opcjonalne `bootlogo.mvi`, `satellites.xml`
- `oscam/` – bazowe: `oscam.conf`, `oscam.user`, `oscam.dvbapi` (+ opcjonalny globalny `oscam.server`)
- `oscam-config/force/<SN>/oscam.server` – serwer dla konkretnego dekodera (priorytet)
- `commands/` – `global.sh` i `<SN>.sh` (zdalne komendy, uruchamiane raz na zmianę)
- `install-logs/` – tu trafi log pierwszej instalacji

## Token
- Classic PAT: `repo`
- Fine-grained: Contents (Read, opcjonalnie Write) do repo `openatv-setup`

## Autor
@dymidaboss
