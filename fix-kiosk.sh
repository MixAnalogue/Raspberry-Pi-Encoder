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

# Update systemd service
echo "Updating systemd service..."
sed "s|/home/pi|/home/$USER|g" "$REPO_DIR/kiosk-mode.service" > /tmp/kiosk-mode.service
sed "s|User=pi|User=$USER|g" /tmp/kiosk-mode.service > /tmp/kiosk-mode2.service
sudo mv /tmp/kiosk-mode2.service /etc/systemd/system/kiosk-mode.service
sudo systemctl daemon-reload

# Update LXDE autostart
echo "Updating LXDE autostart..."
AUTOSTART_DIR="/home/$USER/.config/lxsession/LXDE-pi"
mkdir -p "$AUTOSTART_DIR"

# Remove old kiosk entries if present
if [ -f "$AUTOSTART_DIR/autostart" ]; then
    sed -i '/start-kiosk.sh/d' "$AUTOSTART_DIR/autostart"
fi

if ! grep -q "start-kiosk.sh" "$AUTOSTART_DIR/autostart" 2>/dev/null; then
    cat >> "$AUTOSTART_DIR/autostart" <<EOF

# Disable screen blanking
@xset s off
@xset -dpms
@xset s noblank

# Hide cursor
@unclutter -idle 0.1 -root

# Start kiosk mode for Icecast Streamer
@$INSTALL_DIR/start-kiosk.sh
EOF
fi

echo ""
echo "Kiosk mode fixed!"
echo ""
echo "The browser will now:"
echo "  - Wait for X server to be ready"
echo "  - Wait for web service to respond"
echo "  - Start automatically on boot"
echo ""
echo "Please reboot to test:"
echo "  sudo reboot"
