# Raspberry Pi Icecast Encoder - Quick Start

## Single-Script Installation (Works on Lite and Full Pi OS)

```bash
# Download
cd ~
git clone https://github.com/MixAnalogue/Raspberry-Pi-Encoder.git
cd Raspberry-Pi-Encoder

# Run installer (auto-detects Lite vs Full Pi OS)
chmod +x install.sh
./install.sh

# Follow prompts for Icecast server details
# Say YES to reboot when prompted

# Done! Browser auto-loads in full screen on boot
```

## What the Installer Does

### Raspberry Pi OS Lite:
✓ Detects X server is missing
✓ Installs minimal X server + Openbox
✓ Configures auto-login
✓ Configures auto-start X server
✓ Installs encoder + web interface
✓ Sets up kiosk mode

### Full Raspberry Pi OS:
✓ Detects X server already present
✓ Skips X installation
✓ Installs encoder + web interface
✓ Sets up kiosk mode

## Boot Sequence

```
Power On → Auto-login → startx → Openbox → Browser → Web Interface
```

## Troubleshooting

### Check startup logs:
```bash
cat /tmp/kiosk-startup.log
```

### If browser doesn't load or you see login prompt:
The install script should have configured everything automatically. Try running the installer again (it's safe to re-run):

```bash
cd ~/Raspberry-Pi-Encoder
./install.sh
sudo reboot
```

## Useful Commands

```bash
# Stream control
sudo systemctl start icecast-streamer
sudo systemctl stop icecast-streamer
sudo systemctl restart icecast-streamer

# View logs
cat /tmp/kiosk-startup.log
sudo journalctl -u icecast-streamer -f
```

## Common Issues

- **Login prompt or no browser**: Re-run `./install.sh` and reboot
- **Buttons don't work**: Re-run `./install.sh`
- **No USB audio**: Check with `arecord -l`

## Support

- Full docs: `README.md`
- GitHub: https://github.com/MixAnalogue/Raspberry-Pi-Encoder
