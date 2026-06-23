# StoneLabs Printer UI: live web control for Klipper

A modern, touch-first web UI for your printer in the StoneLabs look. It talks
directly to **Moonraker** (the same API server KlipperScreen/Mainsail use) over a
WebSocket. No KlipperScreen, no noVNC. Run it full-screen in a browser on the
7" panel (or the Jetson) and it *is* the printer interface.

- **`stonelabs-printer-ui.dc.html`**: the app (development source).
- **`stonelabs-printer-ui.html`**: single self-contained file for deployment
  (generated; works offline, no build step).

---

## How it connects

```
  Browser (this UI)  ──WebSocket JSON-RPC──►  Moonraker :7125  ──►  Klipper
```

A browser can't open Klipper's Unix-socket API directly, so the UI speaks to
**Moonraker**, which mirrors Klipper's object model (`printer.objects.subscribe`,
`printer.gcode.script`, `printer.print.*`, `printer.emergency_stop`) over
`ws://<host>:7125/websocket`. The UI:

- **subscribes** to `extruder`, `heater_bed`, `fan`, `toolhead`, `print_stats`,
  `virtual_sdcard`, `display_status`, `gcode_move`, `idle_timeout`, any
  `temperature_sensor *` (chamber/MCU auto-detected by name), and
  `save_variables` (for CFS), and updates live.
- **sends** real G-code / RPC for every control (jog, home, temps, fan, extrude,
  pause/resume/cancel, e-stop, CFS load/unload, maintenance macros).

### Demo fallback
If it can't reach Moonraker it drops into **DEMO** mode (simulated data) so the
screen is never blank and you can develop/preview anywhere. The header pill shows
**LIVE / LINKING / DEMO**.

---

## Point it at your printer

Open **Settings → Moonraker connection**, type your host, press **Connect**.
Accepts any of:

- `192.168.1.50`            → becomes `ws://192.168.1.50:7125/websocket`
- `printer.local:7125`
- `ws://192.168.1.50:7125/websocket` (full form)

The URL is saved in the browser. By default it auto-tries
`ws://<page-host>:7125/websocket`, so if Moonraker serves the file (see below)
it just works with no typing.

> If Moonraker rejects the connection, add the UI's origin to
> `[authorization] cors_domains` / `trusted_clients` in `moonraker.conf`, or serve
> the file from Moonraker itself (same origin needs no CORS).

---

## Deploy as the printer's UI (kiosk)

### 1. Put the file where the browser can load it
Easiest: let Moonraker serve it (same-origin, no CORS). Copy the standalone file
into Moonraker's static root, e.g.:

```bash
# on the printer host
mkdir -p ~/printer_data/www-stonelabs
cp "stonelabs-printer-ui.html" ~/printer_data/www-stonelabs/index.html
```

Add to `moonraker.conf`:

```ini
[authorization]
cors_domains:
  *://*:7125
trusted_clients:
  192.168.0.0/16
  10.0.0.0/8
  127.0.0.0/8

# serve the UI as a static folder
[static_files stonelabs]
path: ~/printer_data/www-stonelabs
```

Then it's at `http://<printer-ip>:7125/server/files/stonelabs/index.html`
(path depends on Moonraker version. Alternatively drop it in the `mainsail`/
`fluidd` www dir, or serve with any static server / nginx).

> Simplest possible alternative: `cd` to the folder and
> `python3 -m http.server 8080`, then open `http://<host>:8080/`.

### 2. Run a browser full-screen (kiosk) on the panel / Jetson

```bash
# Chromium kiosk at the 7" panel's native resolution
chromium-browser --kiosk --noerrdialogs --disable-infobars \
  --check-for-update-interval=31536000 \
  --app="http://localhost:7125/server/files/stonelabs/index.html"
```

(Use `chromium`, `chromium-browser`, or `google-chrome` per your distro.) To make
it the boot UI, launch that command from your desktop session's autostart, or run
it under a minimal X/Wayland session via a systemd user service. This replaces the
KlipperScreen-over-noVNC view entirely.

### Touchscreen notes (1024 × 600)
- All hit targets are ≥ 44px. The layout is fixed at 1024×600; the device bezel in
  the `.dc.html` is just for preview. The deployable build fills the viewport.
- Hide the mouse cursor with `unclutter -idle 0 &` for a clean touch experience.

---

## What maps to what (rename to fit your config)

| UI action | Sent to Klipper |
|---|---|
| Jog X/Y/Z | `G91` → `G1 {axis}{±step} F{6000/900}` → `G90` |
| Home X / Y / Z / All | `G28 X` / `G28 Y` / `G28 Z` / `G28` |
| Hotend / Bed preset | `M104 S{t}` / `M140 S{t}` |
| Chamber preset | `SET_HEATER_TEMPERATURE HEATER={name} TARGET={t}` (if a chamber `heater_generic` exists) |
| Part fan | `M106 S{0-255}` / `M107` |
| Extrude / Retract | `M83` → `G1 E{±len} F300` (blocked under 170°) |
| Pause / Resume / Cancel | `printer.print.pause` / `.resume` / `.cancel` |
| STOP | `printer.emergency_stop` |
| CFS slot load / unload | `CFS_LOAD UNIT=n SLOT=m` / `CFS_UNLOAD` |
| External load / unload | `CFS_LOAD_EXTERNAL` / `CFS_UNLOAD_EXTERNAL` |
| Maintenance tiles | `BED_MESH_CALIBRATE` · `SHAPER_CALIBRATE` · `FILAMENT_CUT_CALIBRATION` · `PROBE_CALIBRATE` · `PID_CALIBRATE` · `CLEAN_NOZZLE` |
| FW Restart / Shutdown | `printer.firmware_restart` / `machine.shutdown` |

The CFS panel reads the same `save_variables` your `box.py` / `cfs_macros.cfg`
already feed (`cfs_units`, `cfs_active_unit/slot`, `cfs{u}_slot{s}_*`), so the
live tabs and slot colors come straight from the box presence bridge. CFS tabs
appear only for detected units (1 box → 1 tab … 4 → 4).

Macro/G-code names above that don't match your config are the only thing to
adjust. They're all in one `renderVals()` block near the bottom of the
`.dc.html` (search for the command string).

---

## Camera + maintenance batch (added)

- **Home → Camera.** A `Status / Camera` toggle at the top of Home. Camera shows
  a live MJPEG feed (`<img>` stream) with hotend/bed/progress overlay. Set the
  stream URL in **Settings → Camera stream** (defaults to
  `http://<host>/webcam/?action=stream`, the standard Crowsnest/ustreamer path).
  If the stream can't load it shows a "no signal" placeholder.
- **Maintenance → select + run.** Each routine tile is now a toggle (tap to
  select; cyan ring + check). The bottom **Run selected · N** button runs all
  selected routines in order as one queued G-code script. Empty selection is a
  no-op with a hint.

## Fully offline (LAN-only). Yes, completely

✅ **`stonelabs-printer-ui.html` is 100% offline.** Everything is embedded in the
one file: **React + ReactDOM**, the DC runtime, all fonts (Manrope, JetBrains
Mono, Caveat, Indie Flower), and the logo. No external URL is fetched at runtime:
the embedded React loads before the runtime's old unpkg fallback, so that fetch
never fires (the unpkg URL string is still present in the file as dead code).

The only network traffic is the **LAN WebSocket to your printer's Moonraker**
(`ws://<host>:7125/websocket`) and your **LAN camera stream**. No internet is ever
contacted: not at first paint, not at setup, never. You can air-gap the machine
(LAN only) and it works.

Verify if you like: load it with the internet unplugged (LAN up) → it paints and
connects; DevTools → Network shows only your printer + local data URIs.

---

## Why this instead of KlipperScreen
KlipperScreen is a GTK app with hardcoded panel layouts; theming can only go so
far. This is your approved prototype running for real. Same modern UI, driven by
live Moonraker data, deployable as a browser kiosk. Mainsail/Fluidd can keep
running alongside it (multiple Moonraker clients are fine).
