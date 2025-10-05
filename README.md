# Icecast Streaming Encoder for Raspberry Pi

A robust, production-ready Icecast streaming encoder for Raspberry Pi with automatic USB audio device detection, reconnection handling, and a touch-friendly web interface.

## Features

- **AAC Encoding**: High-quality audio streaming using FFmpeg with AAC codec
- **USB Audio Support**: Automatic detection and monitoring of USB audio interfaces
- **Auto-Reconnection**: Handles network and USB disconnections gracefully
- **Web Interface**: Touch-friendly control panel (480x320px) with real-time status
- **Boot-to-Browser**: Automatically loads web interface on startup in kiosk mode
- **Fail-Safe Operation**: Continuous monitoring and automatic recovery
- **Systemd Integration**: Runs as a system service with automatic restart

## Hardware Requirements

- Raspberry Pi (tested on Pi 3/4/5)
- USB audio interface
- 480x320 touchscreen display (or any display)
- Internet connection
- Icecast server (can be remote or local)

## Software Requirements

- Raspberry Pi OS (Bullseye or later)
- Python 3.7+
- FFmpeg
- Chromium browser (for web interface)

## Quick Start Installation

### 1. Download the Repository

On your Raspberry Pi, clone or download this repository:

```bash
cd ~
git clone https://github.com/MixAnalogue/Raspberry-Pi-Encoder.git
cd Raspberry-Pi-Encoder
```

Or download as ZIP and extract:

```bash
cd ~
wget https://github.com/MixAnalogue/Raspberry-Pi-Encoder/archive/main.zip
unzip main.zip
cd Raspberry-Pi-Encoder-main
```

### 2. Run the Installation Script

The installation script will install all dependencies and configure your system:

```bash
chmod +x install.sh
./install.sh
```

The installer will:
- Update system packages
- Install required dependencies (Python, FFmpeg, Chromium, etc.)
- Create installation directory at `/home/pi/icecast-streamer`
- Prompt for your Icecast server configuration
- Install systemd services
- Configure auto-start on boot
- Set up the web interface

### 3. Enter Configuration

During installation, you'll be prompted for:

- **Hostname/IP**: Your Icecast server address (e.g., `stream.example.com` or `192.168.1.100`)
- **Port**: Icecast server port (default: `8000`)
- **Mount Point**: Stream mount point (e.g., `stream.aac` or `live`)
- **Username**: Icecast source username (default: `source`)
- **Password**: Your Icecast source password
- **Stream Name**: Display name for your stream (optional)

### 4. Reboot

After installation, reboot your Raspberry Pi:

```bash
sudo reboot
```

The system will automatically:
- Start the streaming service
- Launch the web interface
- Open Chromium in kiosk mode showing the control panel

## Manual Installation

If you prefer to install manually:

### 1. Install Dependencies

```bash
sudo apt-get update
sudo apt-get install -y python3 python3-pip ffmpeg alsa-utils chromium-browser unclutter x11-xserver-utils
pip3 install --user flask
```

### 2. Copy Files

```bash
sudo mkdir -p /home/pi/icecast-streamer
sudo cp *.py /home/pi/icecast-streamer/
sudo cp -r templates /home/pi/icecast-streamer/
sudo chmod +x /home/pi/icecast-streamer/*.py
```

### 3. Create Configuration

Create `/home/pi/icecast-streamer/config.json`:

```json
{
    "hostname": "your-icecast-server.com",
    "port": "8000",
    "mount_point": "stream.aac",
    "username": "source",
    "password": "your-password",
    "stream_name": "My Stream",
    "stream_description": "Live Audio Stream",
    "stream_genre": "Various"
}
```

### 4. Install Services

```bash
sudo cp *.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable icecast-streamer icecast-web kiosk-mode
sudo systemctl start icecast-streamer icecast-web
```

## Usage

### Web Interface

The web interface displays:

- **Stream Status**: Connected/Disconnected/Waiting
- **USB Audio Status**: Connected/Disconnected
- **Server Information**: Target Icecast server
- **Control Buttons**: Start, Restart, Stop

Access the interface at:
- Local: `http://localhost:5000`
- Network: `http://<raspberry-pi-ip>:5000`

### Manual Control

Start the stream:
```bash
sudo systemctl start icecast-streamer
```

Stop the stream:
```bash
sudo systemctl stop icecast-streamer
```

Restart the stream:
```bash
sudo systemctl restart icecast-streamer
```

Check status:
```bash
sudo systemctl status icecast-streamer
```

View logs:
```bash
sudo journalctl -u icecast-streamer -f
```

### Configuration

Edit configuration file:
```bash
nano /home/pi/icecast-streamer/config.json
```

After editing, restart the service:
```bash
sudo systemctl restart icecast-streamer
```

## Troubleshooting

### No Audio Device Found

Check connected audio devices:
```bash
arecord -l
```

You should see your USB audio interface listed. If not:
- Ensure USB device is properly connected
- Try a different USB port
- Check device compatibility with `lsusb`

### Stream Won't Connect

1. Verify Icecast server is running and accessible
2. Check configuration in `config.json`
3. Test network connectivity: `ping your-icecast-server.com`
4. Check firewall settings
5. View logs: `sudo journalctl -u icecast-streamer -f`

### Web Interface Not Loading

1. Check if web service is running:
   ```bash
   sudo systemctl status icecast-web
   ```

2. Check if port 5000 is in use:
   ```bash
   sudo netstat -tulpn | grep 5000
   ```

3. View web service logs:
   ```bash
   sudo journalctl -u icecast-web -f
   ```

### Browser Not Loading on Boot

1. Check kiosk service status:
   ```bash
   sudo systemctl status kiosk-mode
   ```

2. Ensure X server is running (if using desktop environment)

3. Try manually starting:
   ```bash
   DISPLAY=:0 chromium-browser --kiosk http://localhost:5000
   ```

### Stream Keeps Disconnecting

The streamer includes automatic reconnection logic. Check:

1. Network stability
2. Icecast server logs
3. USB audio interface connection
4. System resources: `top` or `htop`

### Audio Quality Issues

Adjust encoding settings in `streamer.py` (line ~120):

```python
'-ar', '44100',    # Sample rate (44100, 48000)
'-b:a', '128k',    # Bitrate (64k, 128k, 192k, 256k)
'-ac', '2',        # Channels (1=mono, 2=stereo)
```

After editing, restart:
```bash
sudo systemctl restart icecast-streamer
```

## File Structure

```
icecast-streamer/
├── streamer.py              # Main streaming application
├── web_interface.py         # Flask web server
├── templates/
│   └── index.html          # Web UI
├── config.json             # Configuration file
├── install.sh              # Installation script
├── icecast-streamer.service    # Streamer systemd service
├── icecast-web.service         # Web interface systemd service
├── kiosk-mode.service          # Browser kiosk systemd service
└── README.md               # This file
```

## Advanced Configuration

### Custom Audio Settings

Edit `streamer.py` to modify FFmpeg parameters for your specific needs.

### Multiple Streams

To run multiple streams, create additional configuration files and service files with different names.

### Remote Access

To access the web interface from other devices on your network, ensure port 5000 is accessible:

```bash
sudo ufw allow 5000
```

### SSL/HTTPS

For secure connections, set up a reverse proxy with nginx and SSL certificates.

## Systemd Services

### icecast-streamer.service
Main streaming service that connects to Icecast and handles USB audio.

### icecast-web.service
Web interface service running on port 5000.

### kiosk-mode.service
Launches Chromium in kiosk mode on boot to display the control panel.

## Technical Details

### Audio Pipeline

```
USB Audio → ALSA → FFmpeg → AAC Encoding → Icecast Server
```

### Reconnection Logic

- Checks USB connection every 5 seconds
- Automatically restarts stream if USB disconnects
- Uses exponential backoff for failed connections (5s → 60s max)
- Monitors FFmpeg process health

### Status Updates

Status is stored in `/tmp/streamer_status.json` and updated every 2 seconds by the web interface.

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

MIT License - feel free to use and modify for your needs.

## Support

For issues and questions:
- Check the troubleshooting section
- Review system logs: `sudo journalctl -u icecast-streamer -f`
- Open an issue on GitHub

## Credits

Built with:
- Python 3
- FFmpeg
- Flask
- Systemd

---

**Note**: This software is provided as-is. Always test thoroughly before production use.
