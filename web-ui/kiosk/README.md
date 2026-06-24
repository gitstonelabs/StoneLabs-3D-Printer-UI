# StoneLabs Printer UI: kiosk

Boot the printer straight into the StoneLabs web UI (Chromium full-screen),
served by Moonraker. No KlipperScreen, no noVNC.

```
kiosk/
├── install.sh             # one-shot installer (run on the printer host / Jetson)
├── stonelabs-ui.service   # systemd unit (installed to /etc/systemd/system)
└── stonelabs-ui.default   # URL config (installed to /etc/default/stonelabs-ui)
```

Put `stonelabs-printer-ui.html` one folder up from `kiosk/` (the package root),
then on the device:

```bash
cd kiosk
chmod +x install.sh
./install.sh
sudo systemctl restart moonraker     # picks up the static_files section
sudo systemctl start stonelabs-ui    # launches the kiosk now (also boots on power)
```

What the installer does:
1. installs `chromium` + `xinit` + `unclutter`
2. copies the UI to `~/printer_data/www-stonelabs/index.html`
3. adds a `[static_files stonelabs]` section to `moonraker.conf` (idempotent),
   so the UI is same-origin with Moonraker (no CORS needed)
4. installs + enables the systemd service

Change the URL any time in `/etc/default/stonelabs-ui`, then
`sudo systemctl restart stonelabs-ui`. Logs: `journalctl -u stonelabs-ui -f`.

### Wayland (cage) instead of X11
On a Wayland-only Jetson session, swap the `ExecStart` in the service for:

```
ExecStart=/usr/bin/cage -- chromium --kiosk --ozone-platform=wayland \
  --disable-features=WebRtcHideLocalIpsWithMdns \
  --app=${KIOSK_URL}
```

(`sudo apt install cage`) and drop the X-specific `Environment=DISPLAY=:0` line.

> The `--disable-features=WebRtcHideLocalIpsWithMdns` flag is required for the
> WebRTC camera: without it Chromium hides the LAN IP behind an mDNS `.local` ICE
> candidate the printer's WebRTC service can't resolve, and the camera stays black.
> (On the X11 service it's merged into the existing `--disable-features` value.)

### Troubleshooting
- **Black screen** → open `KIOSK_URL` in a normal browser on the device first;
  if that fails, Moonraker isn't serving it or the path differs by version.
- **"Can't connect" in the UI** → the page loaded but the WebSocket didn't; the
  header pill shows DEMO. Check Settings → Moonraker connection, and that
  `[authorization]` in `moonraker.conf` trusts this host.
- **Wrong size** → the UI fills whatever viewport it's given; set your panel to
  1024×600 (or edit `--window-size`).
