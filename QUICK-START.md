# Raspberry Pi Icecast Encoder - Quick Start

## For Raspberry Pi OS Lite (Recommended for Kiosk Mode)

```bash
# 1. Download
cd ~
git clone https://github.com/MixAnalogue/Raspberry-Pi-Encoder.git
cd Raspberry-Pi-Encoder

# 2. Install Minimal Desktop (X server + Openbox)
chmod +x install-desktop.sh
./install-desktop.sh
# Say YES to reboot when prompted

# 3. After reboot, install encoder
cd ~/Raspberry-Pi-Encoder
chmod +x install.sh
./install.sh
# Follow prompts for Icecast server details
# Say YES to reboot when prompted

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
# Say YES to reboot when prompted

# Done! The web interface should auto-load in full screen
```

## How It Works

### Pi OS Lite Setup:
1. **install-desktop.sh** installs:
   - Minimal X server (Xorg)
   - Openbox window manager
   - Auto-login to console → auto-start X server

2. **install.sh** configures:
   - Openbox autostart to launch browser
   - Browser waits for web service
   - Loads http://localhost:5000 in kiosk mode

### Boot Sequence:
```
Power On → Auto-login → startx → Openbox → Browser → Web Interface
```

## Troubleshooting

### Check if kiosk is working:
```bash
cat /tmp/kiosk-startup.log
```

### Manually test kiosk mode:
```bash
/home/$USER/icecast-streamer/start-kiosk.sh
```

### Fix kiosk mode:
```bash
cd ~/Raspberry-Pi-Encoder
./fix-kiosk.sh
sudo reboot
```

### Check X server is running:
```bash
ps aux | grep X
xset q  # Should show display info
```

### Verify autostart is configured:
```bash
cat ~/.config/openbox/autostart
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
cat /tmp/kiosk-startup.log

# Check status
sudo systemctl status icecast-streamer
sudo systemctl status icecast-web

# Edit configuration
nano /home/$USER/icecast-streamer/config.json
sudo systemctl restart icecast-streamer

# Restart X server (if display freezes)
sudo systemctl restart display-manager
# Or simply reboot:
sudo reboot
```

## Web Interface Features

- **Stream Status**: Shows if stream is connected
- **USB Status**: Shows if audio interface is detected
- **Start Button**: Starts the stream
- **Restart Button**: Restarts the stream
- **Stop Button**: Stops the stream

## Common Issues

### Issue: CLI only (no desktop)
**Solution**: You need to install the desktop environment first
```bash
cd ~/Raspberry-Pi-Encoder
./install-desktop.sh
sudo reboot
```

### Issue: Desktop loads but no browser
**Solution**: Openbox autostart not configured
```bash
cd ~/Raspberry-Pi-Encoder
./fix-kiosk.sh
sudo reboot
```

### Issue: Browser loads but shows "Can't connect"
**Solution**: Web service not running
```bash
sudo systemctl status icecast-web
sudo systemctl start icecast-web
sudo systemctl enable icecast-web
```

### Issue: Buttons don't work
**Solution**: Sudoers file missing
```bash
sudo cat /etc/sudoers.d/icecast-streamer
# If missing, reinstall:
cd ~/Raspberry-Pi-Encoder
./install.sh
```

### Issue: No USB audio detected
**Solution**: Check USB connection
```bash
arecord -l   # List audio devices
lsusb        # List USB devices
```

### Issue: Display goes blank/screensaver activates
**Solution**: Screen blanking not disabled
```bash
xset s off
xset -dpms
xset s noblank
# Then fix permanently:
cd ~/Raspberry-Pi-Encoder
./fix-kiosk.sh
```

## Performance Tips

- **Pi OS Lite** uses ~200MB RAM (recommended for kiosk)
- **Full Pi OS** uses ~500MB RAM (easier setup)
- Use Pi 3B+ or newer for smooth performance
- Chromium may take 30-60 seconds to fully load on first boot

## Support

- Full documentation: `README.md`
- GitHub: https://github.com/MixAnalogue/Raspberry-Pi-Encoder
- Logs: `/tmp/kiosk-startup.log` and `sudo journalctl -u icecast-streamer -f`
