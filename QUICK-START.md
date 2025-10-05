# Raspberry Pi Icecast Encoder - Quick Start

## For Raspberry Pi OS Lite (No Desktop)

```bash
# 1. Download
cd ~
git clone https://github.com/MixAnalogue/Raspberry-Pi-Encoder.git
cd Raspberry-Pi-Encoder

# 2. Install Desktop Environment
chmod +x install-desktop.sh
./install-desktop.sh
# Reboot when prompted

# 3. After reboot, install encoder
cd ~/Raspberry-Pi-Encoder
chmod +x install.sh
./install.sh
# Follow prompts for Icecast server details
# Reboot when prompted

# Done! The web interface should auto-load in full screen
```

## For Raspberry Pi OS (With Desktop)

```bash
# 1. Download
cd ~
git clone https://github.com/MixAnalogue/Raspberry-Pi-Encoder.git
cd Raspberry-Pi-Encoder

# 2. Install encoder (skip desktop installation)
chmod +x install.sh
./install.sh
# Follow prompts for Icecast server details
# Reboot when prompted

# Done! The web interface should auto-load in full screen
```

## Accessing the Web Interface

- **On Pi touchscreen**: Auto-loads in kiosk mode on boot
- **From another device**: `http://<raspberry-pi-ip>:5000`
- **Find Pi's IP**: `hostname -I`

## Useful Commands

```bash
# Start/Stop/Restart stream
sudo systemctl start icecast-streamer
sudo systemctl stop icecast-streamer
sudo systemctl restart icecast-streamer

# View logs
sudo journalctl -u icecast-streamer -f

# Check status
sudo systemctl status icecast-streamer
sudo systemctl status icecast-web

# Edit configuration
nano /home/$USER/icecast-streamer/config.json
sudo systemctl restart icecast-streamer

# Fix kiosk mode issues
cd ~/Raspberry-Pi-Encoder
./fix-kiosk.sh
```

## What Each Script Does

- **`install-desktop.sh`**: Installs minimal desktop for Pi OS Lite (only needed for Lite version)
- **`install.sh`**: Main installer - installs encoder, web interface, services
- **`fix-kiosk.sh`**: Fixes browser auto-start issues

## Web Interface Features

- **Stream Status**: Shows if stream is connected
- **USB Status**: Shows if audio interface is detected
- **Start Button**: Starts the stream
- **Restart Button**: Restarts the stream
- **Stop Button**: Stops the stream

## Troubleshooting

### CLI only (no desktop)
```bash
cd ~/Raspberry-Pi-Encoder
./install-desktop.sh
```

### Desktop loads but no browser
```bash
cd ~/Raspberry-Pi-Encoder
./fix-kiosk.sh
```

### Buttons don't work
```bash
# Check if sudoers file exists
sudo cat /etc/sudoers.d/icecast-streamer

# If missing, reinstall
cd ~/Raspberry-Pi-Encoder
./install.sh
```

### No USB audio detected
```bash
# List audio devices
arecord -l

# Check USB devices
lsusb
```

## Support

- Full documentation: `README.md`
- GitHub: https://github.com/MixAnalogue/Raspberry-Pi-Encoder
