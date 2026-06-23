# Changelog

All notable changes to **StoneLabs 3D Printer UI** are documented here.
This project follows [Semantic Versioning](https://semver.org/) (`MAJOR.MINOR.PATCH`).

## [1.1.0] - 2026-06-23

### Added
- **Color themes.** Six palettes (Cyan, Crimson, Amber + Navy, Mono, Greyscale,
  Sage), each with a **light and dark** mode. Pick them in Settings → Display;
  the choice persists across reloads. All UI colors are now CSS variables, so
  themes swap instantly with no reload.
- **WebRTC camera.** The Home camera now plays the printer's native WebRTC
  stream (for example Creality's `cam_app` on port 8000), not just MJPEG. Set the
  camera's WebRTC base URL in Settings → Camera; a URL ending in `action=stream`
  still uses the MJPEG path.

### Changed
- **Maintenance run order** resequenced so a full batch run builds on itself
  (PID → clean → Z-cal → mesh → shaper → cut).

### Fixed
- Macro wrappers (`CLEAN_NOZZLE`, `PROBE_CALIBRATE`) added in `cfs_macros.cfg`
  so those buttons no longer throw "Unknown command"; external spool load/unload
  and filament-cut macros fleshed out as editable templates.

## [1.0.0] - 2026-06-23

First public release. A standalone, touch-first web UI that replaces
KlipperScreen, driven live by Moonraker over the LAN.

### Added
- **Five screens.** Home (status + camera), Printer (XYZ jog, temperatures,
  extrude), Filament (external spool + dynamic CFS tabs), Maintenance, Settings.
- **Live Moonraker client.** WebSocket JSON-RPC with auto-reconnect; subscribes
  to printer objects (temps, position, print state/progress, fans,
  `save_variables`) and sends real G-code / RPC for every control.
- **Demo fallback.** Runs on simulated data when no printer is reachable, so the
  screen is never blank; header pill shows LIVE / LINKING / DEMO.
- **CFS multi-material.** CFS tabs appear only for detected units (1–4 boxes ×
  4 slots); slot colors, fill, and active slot come from `save_variables`.
  External spool gets its own tab.
- **Toggleable camera** on Home. MJPEG stream with a temperature/progress
  overlay; stream URL configurable in Settings.
- **Maintenance batch.** Routines are selectable and run in sequence; the run
  order is sequenced so a full run builds on itself (PID → clean → Z-cal → mesh
  → shaper → cut).
- **100% offline.** React, the runtime, all fonts, and the logo are embedded in
  a single HTML file. No internet at setup, first paint, or ever; the only
  network traffic is the LAN WebSocket to the printer.
- **Kiosk deployment.** systemd service + installer to boot Chromium full-screen
  into the UI, served same-origin from Moonraker.
- **`cfs_macros.cfg`.** Klipper-side `save_variables` scheme + example macros
  (CFS load/unload, external spool feed, nozzle clean, Z-calibrate wrapper) and a
  `CFS_DEMO_SEED` to populate the Filament screen.
- **PolyForm Noncommercial 1.0.0** license.

### Notes
- Maintenance `PROBE_CALIBRATE` and `CLEAN_NOZZLE` are wrappers in
  `cfs_macros.cfg`. Point them at your machine's real commands
  (`[prtouch_v3]` Z-offset, `box.py` nozzle clean).
- The external-spool and filament-cut macros are templates; wire them to your
  hardware before relying on them.

[1.0.0]: https://github.com/gitstonelabs
