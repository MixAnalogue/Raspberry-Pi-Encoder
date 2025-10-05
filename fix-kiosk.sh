#!/bin/bash

##############################################
# Fix kiosk mode for existing installations
##############################################

echo "Fixing kiosk mode for Icecast Streamer..."

INSTALL_DIR="/home/$USER/icecast-streamer"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install curl if missing
if ! command -v curl &>/dev/null; then
    echo "Installing curl..."
    sudo apt-get update
    sudo apt-get install -y curl
fi

# Copy updated files
echo "Copying updated files..."
sudo cp "$REPO_DIR/start-kiosk.sh" "$INSTALL_DIR/"
sudo chmod +x "$INSTALL_DIR/start-kiosk.sh"

echo "Configuring autostart..."

# Configure Openbox autostart (Pi OS Lite)
OPENBOX_AUTOSTART_DIR="/home/$USER/.config/openbox"
mkdir -p "$OPENBOX_AUTOSTART_DIR"

cat > "$OPENBOX_AUTOSTART_DIR/autostart" <<EOF
# Openbox autostart script for Icecast Streamer Kiosk Mode

# Start kiosk browser
$INSTALL_DIR/start-kiosk.sh &
EOF

chmod +x "$OPENBOX_AUTOSTART_DIR/autostart"

# Configure LXDE autostart (Full Pi OS)
LXDE_AUTOSTART_DIR="/home/$USER/.config/lxsession/LXDE-pi"
mkdir -p "$LXDE_AUTOSTART_DIR"

if [ -f "$LXDE_AUTOSTART_DIR/autostart" ]; then
    sed -i '/start-kiosk.sh/d' "$LXDE_AUTOSTART_DIR/autostart"
fi

if ! grep -q "start-kiosk.sh" "$LXDE_AUTOSTART_DIR/autostart" 2>/dev/null; then
    cat >> "$LXDE_AUTOSTART_DIR/autostart" <<EOF

# Start kiosk mode for Icecast Streamer
@$INSTALL_DIR/start-kiosk.sh
EOF
fi

# Disable systemd kiosk service if it's enabled
if systemctl is-enabled kiosk-mode.service &>/dev/null; then
    echo "Disabling systemd kiosk service..."
    sudo systemctl disable kiosk-mode.service
    sudo systemctl stop kiosk-mode.service
fi

echo ""
echo "Kiosk mode fixed!"
echo ""
echo "Configuration applied for:"
echo "  - Openbox autostart (Pi OS Lite)"
echo "  - LXDE autostart (Full Pi OS)"
echo ""
echo "To test, reboot your Pi:"
echo "  sudo reboot"
echo ""
echo "To view startup logs:"
echo "  cat /tmp/kiosk-startup.log"
