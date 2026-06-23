#!/usr/bin/env bash
# ============================================================
#  StoneLabs Printer UI: kiosk installer
#  Serves the UI from Moonraker and boots a Chromium kiosk into it.
#  Tested on Debian/Ubuntu/Jetson (X11 + Chromium).
#
#  Usage:
#     chmod +x install.sh
#     ./install.sh
#  Re-run any time after replacing "stonelabs-printer-ui.html".
# ============================================================
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_NAME="${SUDO_USER:-$USER}"
HOME_DIR="$(getent passwd "$USER_NAME" | cut -d: -f6)"
UI_SRC="$HERE/../stonelabs-printer-ui.html"   # the offline build (one folder up)
WWW_DIR="$HOME_DIR/printer_data/www-stonelabs"
MOONRAKER_CONF="$HOME_DIR/printer_data/config/moonraker.conf"

echo "==> Installing StoneLabs Printer UI kiosk for user: $USER_NAME"

# ---- 0. find the standalone HTML (fallbacks) ----
if [[ ! -f "$UI_SRC" ]]; then
  UI_SRC="$HERE/stonelabs-printer-ui.html"
fi
if [[ ! -f "$UI_SRC" ]]; then
  echo "!! Could not find 'stonelabs-printer-ui.html'. Put it next to this script or one folder up." >&2
  exit 1
fi

# ---- 1. deps ----
echo "==> Installing packages (chromium, xinit, unclutter)…"
sudo apt-get update -y
# chromium package name differs by distro; try both.
sudo apt-get install -y xserver-xorg xinit unclutter || true
sudo apt-get install -y chromium || sudo apt-get install -y chromium-browser || true

# ---- 2. publish the UI into Moonraker's static dir ----
echo "==> Publishing UI to $WWW_DIR"
mkdir -p "$WWW_DIR"
cp "$UI_SRC" "$WWW_DIR/index.html"

# ---- 3. register a static_files section in moonraker.conf (idempotent) ----
if [[ -f "$MOONRAKER_CONF" ]]; then
  if ! grep -q "\[static_files stonelabs\]" "$MOONRAKER_CONF"; then
    echo "==> Adding [static_files stonelabs] to moonraker.conf"
    cat >> "$MOONRAKER_CONF" <<EOF

# Added by StoneLabs kiosk installer
[static_files stonelabs]
path: $WWW_DIR
EOF
    echo "   (restart Moonraker for it to take effect:  sudo systemctl restart moonraker)"
  else
    echo "==> moonraker.conf already has [static_files stonelabs]. Leaving it."
  fi
else
  echo "!! $MOONRAKER_CONF not found. Serve the UI yourself, or set KIOSK_URL in the default file."
fi

# ---- 4. defaults + service ----
echo "==> Installing /etc/default/stonelabs-ui"
sudo cp "$HERE/stonelabs-ui.default" /etc/default/stonelabs-ui

echo "==> Installing systemd service"
sudo sed "s/__USER__/$USER_NAME/g" "$HERE/stonelabs-ui.service" | sudo tee /etc/systemd/system/stonelabs-ui.service >/dev/null
sudo systemctl daemon-reload
sudo systemctl enable stonelabs-ui.service

cat <<EOF

============================================================
 Done.

 Start now:        sudo systemctl start stonelabs-ui
 Boots on power:   already enabled (graphical.target)
 Change the URL:   edit /etc/default/stonelabs-ui  then restart
 Logs:             journalctl -u stonelabs-ui -f

 If the screen stays black, confirm Moonraker is up and the URL
 in /etc/default/stonelabs-ui loads in a normal browser first.
============================================================
EOF
