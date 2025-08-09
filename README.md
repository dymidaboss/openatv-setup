# openatv-setup — prywatne repo (by @dymidaboss)

## Uruchomienie na dekoderze
```sh
sh -c 'wget -qO /tmp/install.sh https://raw.githubusercontent.com/dymidaboss/openatv-setup/main/install.sh && sh /tmp/install.sh </dev/tty'
```

## W repo MUSZĄ być
- `assets/bootlogo.mvi`
- `assets/satellites.xml`
- `oscam-config/oscam.conf`, `oscam.user`, `oscam.dvbapi`, `oscam.server`
- (opcjonalnie) `oscam-config/force/MODEL-SERIAL/oscam.server`  ← per-dekoder

## Efekt instalacji
- komplet pakietów (myszka20, picony, YT, HbbTV, ServiceApp, OSCam, Tailscale)
- CRON: monitor, git-commands, auto-update (4:30), srvid2 (5:15), heartbeat (co 6h)
- assety/OSCam pobierane z repo przez API (token)
- log instalacji wysyłany do `install-logs/` w repo
