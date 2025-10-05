#!/bin/bash

##############################################
# Icecast Streamer Installation Script
# For Raspberry Pi with touchscreen
##############################################

set -e

# Save the repository directory
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "======================================"
echo "Icecast Streamer Installation"
echo "======================================"
echo ""

# Check if running on Raspberry Pi
if [ ! -f /proc/device-tree/model ]; then
    echo "Warning: This script is designed for Raspberry Pi"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if running as regular user
if [ "$EUID" -eq 0 ]; then
    echo "Please run this script as a regular user (not root)"
    echo "The script will use sudo when needed"
    exit 1
fi

echo "Step 1: Updating system packages..."
sudo apt-get update

echo ""
echo "Step 2: Installing required packages..."

# Detect Chromium package name (chromium vs chromium-browser)
if apt-cache show chromium &>/dev/null; then
    CHROMIUM_PKG="chromium"
elif apt-cache show chromium-browser &>/dev/null; then
    CHROMIUM_PKG="chromium-browser"
else
    echo "Warning: Chromium package not found. Will try to install chromium."
    CHROMIUM_PKG="chromium"
fi

echo "Using Chromium package: $CHROMIUM_PKG"

sudo apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    ffmpeg \
    alsa-utils \
    $CHROMIUM_PKG \
    unclutter \
    x11-xserver-utils \
    curl

echo ""
echo "Step 3: Installing Python dependencies..."
# Try to install Flask from apt first, fall back to pip if needed
if apt-cache show python3-flask &>/dev/null; then
    echo "Installing Flask from system packages..."
    sudo apt-get install -y python3-flask
else
    echo "Installing Flask via pip..."
    pip3 install --user --break-system-packages flask
fi

echo ""
echo "Step 4: Creating installation directory..."
INSTALL_DIR="/home/$USER/icecast-streamer"

if [ -d "$INSTALL_DIR" ]; then
    echo "Directory $INSTALL_DIR already exists"
    read -p "Overwrite? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled"
        exit 1
    fi
    rm -rf "$INSTALL_DIR"
fi

mkdir -p "$INSTALL_DIR"

echo ""
echo "Step 5: Copying files..."
cp "$REPO_DIR/streamer.py" "$INSTALL_DIR/"
cp "$REPO_DIR/web_interface.py" "$INSTALL_DIR/"
cp "$REPO_DIR/start-kiosk.sh" "$INSTALL_DIR/"
cp -r "$REPO_DIR/templates" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/streamer.py"
chmod +x "$INSTALL_DIR/web_interface.py"
chmod +x "$INSTALL_DIR/start-kiosk.sh"

echo ""
echo "Step 6: Creating configuration..."
cd "$INSTALL_DIR"

if [ ! -f "config.json" ]; then
    echo ""
    echo "Please enter your Icecast server details:"
    echo ""

    read -p "Icecast server hostname/IP: " HOSTNAME
    read -p "Icecast server port [8000]: " PORT
    PORT=${PORT:-8000}
    read -p "Mount point (e.g., stream.aac): " MOUNT
    read -p "Username [source]: " USERNAME
    USERNAME=${USERNAME:-source}
    read -sp "Password: " PASSWORD
    echo ""
    read -p "Stream name [Raspberry Pi Stream]: " STREAM_NAME
    STREAM_NAME=${STREAM_NAME:-Raspberry Pi Stream}

    cat > config.json <<EOF
{
    "hostname": "$HOSTNAME",
    "port": "$PORT",
    "mount_point": "$MOUNT",
    "username": "$USERNAME",
    "password": "$PASSWORD",
    "stream_name": "$STREAM_NAME",
    "stream_description": "Live Audio Stream",
    "stream_genre": "Various"
}
EOF

    echo "Configuration saved to $INSTALL_DIR/config.json"
else
    echo "Configuration file already exists, skipping..."
fi

echo ""
echo "Step 7: Creating log directory..."
sudo mkdir -p /var/log
sudo touch /var/log/icecast-streamer.log
sudo chown $USER:$USER /var/log/icecast-streamer.log

echo ""
echo "Step 8: Installing systemd services..."

# Update service files with correct paths
sed "s|/home/pi|/home/$USER|g" "$REPO_DIR/icecast-streamer.service" > /tmp/icecast-streamer.service
sed "s|User=pi|User=$USER|g" /tmp/icecast-streamer.service > /tmp/icecast-streamer2.service
sudo mv /tmp/icecast-streamer2.service /etc/systemd/system/icecast-streamer.service

sed "s|/home/pi|/home/$USER|g" "$REPO_DIR/icecast-web.service" > /tmp/icecast-web.service
sed "s|User=pi|User=$USER|g" /tmp/icecast-web.service > /tmp/icecast-web2.service
sudo mv /tmp/icecast-web2.service /etc/systemd/system/icecast-web.service

sed "s|/home/pi|/home/$USER|g" "$REPO_DIR/kiosk-mode.service" > /tmp/kiosk-mode.service
sed "s|User=pi|User=$USER|g" /tmp/kiosk-mode.service > /tmp/kiosk-mode2.service
sudo mv /tmp/kiosk-mode2.service /etc/systemd/system/kiosk-mode.service

echo ""
echo "Step 9: Enabling services..."
sudo systemctl daemon-reload
sudo systemctl enable icecast-streamer.service
sudo systemctl enable icecast-web.service
# Note: kiosk-mode.service is installed but NOT enabled
# We use Openbox/LXDE autostart instead for better reliability

echo ""
echo "Step 10: Configuring sudo permissions for web interface..."
# Create sudoers file to allow control without password
sed "s|pi|$USER|g" "$REPO_DIR/icecast-streamer-sudoers" > /tmp/icecast-streamer-sudoers
sudo chown root:root /tmp/icecast-streamer-sudoers
sudo chmod 0440 /tmp/icecast-streamer-sudoers
sudo mv /tmp/icecast-streamer-sudoers /etc/sudoers.d/icecast-streamer

echo ""
echo "Step 11: Configuring autostart..."

# Disable screen blanking
if ! grep -q "xset s off" /home/$USER/.xinitrc 2>/dev/null; then
    cat >> /home/$USER/.xinitrc <<'EOF'
# Disable screen blanking
xset s off
xset -dpms
xset s noblank
EOF
fi

# Configure autostart for both LXDE and Openbox

# LXDE autostart (for full Raspberry Pi OS)
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

# Openbox autostart (for Pi OS Lite with minimal desktop)
OPENBOX_AUTOSTART_DIR="/home/$USER/.config/openbox"
mkdir -p "$OPENBOX_AUTOSTART_DIR"

cat > "$OPENBOX_AUTOSTART_DIR/autostart" <<EOF
# Openbox autostart script for Icecast Streamer Kiosk Mode

# Start kiosk browser
$INSTALL_DIR/start-kiosk.sh &
EOF

chmod +x "$OPENBOX_AUTOSTART_DIR/autostart"

echo ""
echo "Step 12: Testing USB audio device..."
if arecord -l | grep -q "card"; then
    echo "USB audio devices found:"
    arecord -l | grep "card"
else
    echo "Warning: No audio devices detected"
    echo "Please connect a USB audio interface"
fi

echo ""
echo "======================================"
echo "Installation Complete!"
echo "======================================"
echo ""
echo "Services installed:"
echo "  - icecast-streamer: Main streaming service"
echo "  - icecast-web: Web interface (http://localhost:5000)"
echo "  - kiosk-mode: Auto-start browser on boot"
echo ""
echo "Installation directory: $INSTALL_DIR"
echo ""
echo "To start the services now:"
echo "  sudo systemctl start icecast-streamer"
echo "  sudo systemctl start icecast-web"
echo ""
echo "To view logs:"
echo "  sudo journalctl -u icecast-streamer -f"
echo "  sudo journalctl -u icecast-web -f"
echo ""
echo "The web interface will automatically load on boot."
echo "You can also access it from another device at:"
echo "  http://$(hostname -I | awk '{print $1}'):5000"
echo ""
echo "Configuration file: $INSTALL_DIR/config.json"
echo ""
echo "Reboot recommended to start all services automatically."
echo ""
read -p "Reboot now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo reboot
fi
