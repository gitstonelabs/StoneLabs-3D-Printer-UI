# Changelog

All notable changes to **StoneLabs 3D Printer UI** are documented here.
This project follows [Semantic Versioning](https://semver.org/) (`MAJOR.MINOR.PATCH`).

## [1.4.5] - 2026-06-24

### Added
- **Sent-command history in the console.** With the G-code input focused, press
  up-arrow (↑) to step back through previously sent commands, newest to oldest,
  and down-arrow (↓) to come forward; pressing down past the most recent returns
  to a blank input.
- **Smart console auto-scroll.** The console sticks to the newest line only while
  you are already at the bottom. Scroll up to read history and it stays put as new
  output streams in; it re-pins to the bottom when you scroll back down, tap the
  input, or send a command.

### Changed
- **Editable text fields.** The Settings and console text boxes now support
  mouse, touch, and arrow-key cursor positioning, click or tap anywhere in the
  text to place the caret, and the on-screen keyboard inserts at the cursor
  instead of only at the end.
- **Kiosk display fit.** The UI is now pinned to the screen and scaled to fit the
  display exactly, with no surrounding chrome, bezel, or scrollbars on the
  touchscreen.
- **Settings layout.** The Moonraker connection and Camera panels are merged into
  a single card, and the page is tuned to fit without scrolling.

## [1.4.0] - 2026-06-24

### Added
- **Home status tiles are now shortcuts.** Tapping a tile on the Home screen
  jumps straight to the relevant control:
  - **Hotend** → Printer › Extrude
  - **Bed** and **Part fan** → Printer › Temperature
  - **XYZ / Homed** → Printer › Motion
  - **Klippy** → Settings

### Changed
- **Display brightness fixed at 100%.** The kiosk now defaults to full
  brightness and the brightness slider has been suppressed (markup commented out,
  underlying code retained for future use).
- **Disable chamber** moved into the Display card on the Settings page (where the
  brightness control used to be).

### Removed
- **Demo print-state toggle** removed from the Settings → System card.

## [1.3.0] - 2026-06-23

### Added
- **On-screen touch keyboard.** Tapping any text field (Moonraker URL, camera
  URL, signaling path, STUN URL) opens a full QWERTY keyboard with shift, a
  number/symbol layer, space, backspace, and enter. Enter commits the value;
  URL fields apply immediately. Built for touchscreen kiosks with no physical
  keyboard.
- **Numeric keypad for temperatures.** Tapping any temperature reading (hotend,
  bed, chamber, on both the Temperature and Extrude tabs) opens a 0-9 keypad
  with backspace and a range-validated confirm. Confirm is enabled only when the
  value is in range; an empty entry plus enter sets the target to 0, and the X
  cancels with no change.
- **Hotend material presets dropdown.** Off / PLA 220 / PETG 240 / ABS 255 /
  PC 265 / PA6-GF 290, replacing the old fixed quick-heat buttons.
- **Camera settings panel.** Settings now has a Mode selector (WebRTC / MJPEG /
  Disabled), a camera URL, an advanced WebRTC signaling-path field, and an
  optional STUN/ICE-server toggle with a custom STUN URL. All persist across
  reloads.
- **Disable-chamber toggle.** Hides all chamber controls and readouts (Home
  strip, header pill, Temperature tab) for printers without a chamber heater.
- **TouchScreen Restart button** in Settings, full-width above FW Restart /
  Shutdown, reloads the kiosk UI to recover the touchscreen without a reboot.

### Changed
- **Home status** now shows Bed in place of Chamber; chamber moves to the bottom
  status strip and disappears entirely when disabled.
- **Temperature tab** rebuilt around tap-to-type entry (Off buttons and a
  keypad) and a 0/25/50/75/100% part-fan slider, replacing the preset button
  rows.
- **Kiosk Chromium flag.** The systemd service now launches with
  `--disable-features=TranslateUI,WebRtcHideLocalIpsWithMdns` (and the Wayland
  README notes the same) so the WebRTC camera's LAN IP is not hidden behind an
  mDNS `.local` ICE candidate the printer cannot resolve.

### Fixed
- WebRTC camera now honors the configured signaling path and optional STUN
  servers instead of assuming `/call/webrtc_local` with no ICE.

## [1.2.0] - 2026-06-23

### Added
- **WebRTC camera support.** The Home camera view now plays the printer's native
  WebRTC stream (for example Creality `cam_app` at `http://<printer-ip>:8000`) via a
  plain `RTCPeerConnection` using the host's `/call/webrtc_local` signaling. MJPEG is
  still supported: a camera URL containing `action=stream` uses the `<img>` path,
  anything else is treated as a WebRTC base. The connection starts when the camera
  view opens and tears down when you leave it.

### Fixed
- **`[bundle] error` overlay.** The offline bundle's global error sink was
  surfacing benign resource-load failures (a camera stream or favicon that fails
  to load fires an error event with no message). The sink now ignores
  resource-load errors and still reports real JavaScript errors.

## [1.1.0] - 2026-06-23

### Added
- **Color themes.** Six palettes (Cyan, Crimson, Amber + Navy, Mono, Greyscale,
  Sage), each with a **light and dark** mode. Pick them in Settings → Display;
  the choice persists across reloads. All UI colors are now CSS variables, so
  themes swap instantly with no reload.

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
