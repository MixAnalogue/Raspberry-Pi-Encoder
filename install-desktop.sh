#!/bin/bash

##############################################
# Install Minimal Desktop for Raspberry Pi Lite
# Optimized for kiosk/touchscreen mode
##############################################

set -e

echo "======================================"
echo "Installing Minimal Kiosk Environment"
echo "======================================"
echo ""
echo "This will install a minimal X server and"
echo "configure automatic browser startup."
echo ""
echo "This may take 5-15 minutes depending on your"
echo "internet connection and Pi model."
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled"
    exit 1
fi

echo ""
echo "Step 1: Updating system..."
sudo apt-get update

echo ""
echo "Step 2: Installing minimal X server..."
sudo apt-get install -y \
    xserver-xorg \
    x11-xserver-utils \
    xinit \
    xorg

echo ""
echo "Step 3: Installing window manager..."
sudo apt-get install -y \
    openbox \
    obconf

echo ""
echo "Step 4: Installing required libraries..."
sudo apt-get install -y \
    libgtk-3-0 \
    libgbm1 \
    libasound2 \
    libxss1 \
    libnss3

echo ""
echo "Step 5: Configuring auto-login to console..."
# Auto-login to console, we'll start X from .bash_profile
sudo raspi-config nonint do_boot_behaviour B2

echo ""
echo "Step 6: Configuring auto-start X server..."
# Create .bash_profile to start X on login
if ! grep -q "startx" /home/$USER/.bash_profile 2>/dev/null; then
    cat >> /home/$USER/.bash_profile <<'EOF'
# Auto-start X server on login
if [ -z "$DISPLAY" ] && [ $(tty) = /dev/tty1 ]; then
    startx
fi
EOF
fi

# Create minimal .xinitrc
cat > /home/$USER/.xinitrc <<'EOF'
#!/bin/sh
# Disable screen blanking
xset s off
xset -dpms
xset s noblank

# Set background to black
xsetroot -solid black

# Start openbox
exec openbox-session
EOF

chmod +x /home/$USER/.xinitrc

echo ""
echo "======================================"
echo "Minimal Desktop Installation Complete!"
echo "======================================"
echo ""
echo "The system will now:"
echo "  - Auto-login to console"
echo "  - Auto-start X server"
echo "  - Run kiosk browser in full screen"
echo ""
echo "Next steps:"
echo "  1. Reboot: sudo reboot"
echo "  2. After reboot, run: ./install.sh"
echo ""
read -p "Reboot now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo reboot
fi
