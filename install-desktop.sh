#!/bin/bash

##############################################
# Install Minimal Desktop for Raspberry Pi Lite
# Required for touchscreen/kiosk mode
##############################################

set -e

echo "======================================"
echo "Installing Desktop Environment"
echo "======================================"
echo ""
echo "This will install a minimal desktop environment"
echo "required for the touchscreen interface."
echo ""
echo "This may take 10-30 minutes depending on your"
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
sudo apt-get upgrade -y

echo ""
echo "Step 2: Installing X server and minimal desktop..."
sudo apt-get install -y \
    xserver-xorg \
    x11-xserver-utils \
    xinit \
    openbox \
    lightdm \
    raspberrypi-ui-mods \
    rpd-plym-splash

echo ""
echo "Step 3: Configuring auto-login to desktop..."
sudo raspi-config nonint do_boot_behaviour B4

echo ""
echo "Step 4: Installing additional desktop tools..."
sudo apt-get install -y \
    libgtk-3-0 \
    libgbm1 \
    libasound2

echo ""
echo "======================================"
echo "Desktop Installation Complete!"
echo "======================================"
echo ""
echo "The system will now boot to a minimal desktop."
echo "You can now run the main install.sh script."
echo ""
echo "Reboot now to start the desktop environment:"
echo "  sudo reboot"
echo ""
read -p "Reboot now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo reboot
fi
