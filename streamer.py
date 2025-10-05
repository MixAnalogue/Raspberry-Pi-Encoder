#!/usr/bin/env python3
"""
Icecast Streaming Encoder for Raspberry Pi
Streams audio from USB interface to Icecast server using FFmpeg with AAC codec
"""

import subprocess
import time
import json
import os
import sys
import signal
import logging
from datetime import datetime
from pathlib import Path

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/icecast-streamer.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


class IcecastStreamer:
    def __init__(self, config_file='config.json'):
        self.config_file = config_file
        self.config = self.load_config()
        self.ffmpeg_process = None
        self.should_run = True
        self.reconnect_delay = 5
        self.max_reconnect_delay = 60
        self.status_file = '/tmp/streamer_status.json'

        # Register signal handlers for graceful shutdown
        signal.signal(signal.SIGTERM, self.signal_handler)
        signal.signal(signal.SIGINT, self.signal_handler)

    def signal_handler(self, signum, frame):
        """Handle shutdown signals gracefully"""
        logger.info(f"Received signal {signum}, shutting down...")
        self.should_run = False
        self.stop_stream()
        sys.exit(0)

    def load_config(self):
        """Load configuration from JSON file"""
        if not os.path.exists(self.config_file):
            logger.error(f"Configuration file {self.config_file} not found")
            return None

        try:
            with open(self.config_file, 'r') as f:
                config = json.load(f)
            logger.info("Configuration loaded successfully")
            return config
        except Exception as e:
            logger.error(f"Error loading configuration: {e}")
            return None

    def save_config(self, config):
        """Save configuration to JSON file"""
        try:
            with open(self.config_file, 'w') as f:
                json.dump(config, f, indent=4)
            self.config = config
            logger.info("Configuration saved successfully")
            return True
        except Exception as e:
            logger.error(f"Error saving configuration: {e}")
            return False

    def get_usb_audio_device(self):
        """Detect USB audio interface"""
        try:
            # List all audio capture devices
            result = subprocess.run(
                ['arecord', '-l'],
                capture_output=True,
                text=True,
                timeout=5
            )

            if result.returncode != 0:
                logger.error("Failed to list audio devices")
                return None

            # Parse output to find USB devices
            lines = result.stdout.split('\n')
            for line in lines:
                if 'card' in line.lower() and 'usb' in line.lower():
                    # Extract card number
                    parts = line.split(':')
                    if len(parts) > 0:
                        card_part = parts[0].strip()
                        if 'card' in card_part:
                            card_num = card_part.split('card')[1].strip().split()[0]
                            device = f"hw:{card_num},0"
                            logger.info(f"Found USB audio device: {device}")
                            return device

            # If no USB device found, try to find any device
            for line in lines:
                if 'card' in line.lower():
                    parts = line.split(':')
                    if len(parts) > 0:
                        card_part = parts[0].strip()
                        if 'card' in card_part:
                            card_num = card_part.split('card')[1].strip().split()[0]
                            device = f"hw:{card_num},0"
                            logger.warning(f"No USB device found, using: {device}")
                            return device

            logger.error("No audio devices found")
            return None

        except subprocess.TimeoutExpired:
            logger.error("Timeout while detecting audio devices")
            return None
        except Exception as e:
            logger.error(f"Error detecting USB audio device: {e}")
            return None

    def check_usb_connected(self):
        """Check if USB audio interface is connected"""
        device = self.get_usb_audio_device()
        return device is not None

    def start_stream(self):
        """Start FFmpeg streaming process"""
        if not self.config:
            logger.error("No configuration available")
            self.update_status("error", "No configuration")
            return False

        # Check for USB audio device
        audio_device = self.get_usb_audio_device()
        if not audio_device:
            logger.error("No USB audio device found")
            self.update_status("error", "No USB audio device")
            return False

        # Build Icecast URL
        icecast_url = (
            f"icecast://{self.config['username']}:{self.config['password']}"
            f"@{self.config['hostname']}:{self.config['port']}"
            f"/{self.config['mount_point']}"
        )

        # FFmpeg command for AAC encoding
        ffmpeg_cmd = [
            'ffmpeg',
            '-f', 'alsa',                    # Input format: ALSA
            '-i', audio_device,              # Input device
            '-ac', '2',                       # Audio channels: stereo
            '-ar', '44100',                   # Sample rate: 44.1kHz
            '-c:a', 'aac',                    # Audio codec: AAC
            '-b:a', '128k',                   # Bitrate: 128kbps
            '-f', 'adts',                     # Output format: ADTS (AAC transport)
            '-ice_name', self.config.get('stream_name', 'Raspberry Pi Stream'),
            '-ice_description', self.config.get('stream_description', 'Live Audio Stream'),
            '-ice_genre', self.config.get('stream_genre', 'Various'),
            '-content_type', 'audio/aac',
            icecast_url
        ]

        try:
            logger.info(f"Starting FFmpeg with device {audio_device}")
            logger.info(f"Streaming to {self.config['hostname']}:{self.config['port']}/{self.config['mount_point']}")

            self.ffmpeg_process = subprocess.Popen(
                ffmpeg_cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                stdin=subprocess.DEVNULL
            )

            # Give it a moment to start
            time.sleep(2)

            # Check if process is still running
            if self.ffmpeg_process.poll() is None:
                logger.info("Stream started successfully")
                self.update_status("streaming", "Connected")
                return True
            else:
                stderr = self.ffmpeg_process.stderr.read().decode()
                logger.error(f"FFmpeg failed to start: {stderr}")
                self.update_status("error", "FFmpeg failed")
                return False

        except Exception as e:
            logger.error(f"Error starting stream: {e}")
            self.update_status("error", str(e))
            return False

    def stop_stream(self):
        """Stop FFmpeg streaming process"""
        if self.ffmpeg_process:
            try:
                logger.info("Stopping stream...")
                self.ffmpeg_process.terminate()

                # Wait for graceful shutdown
                try:
                    self.ffmpeg_process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    logger.warning("FFmpeg didn't stop gracefully, forcing kill")
                    self.ffmpeg_process.kill()
                    self.ffmpeg_process.wait()

                self.ffmpeg_process = None
                logger.info("Stream stopped")
                self.update_status("stopped", "Manually stopped")
                return True
            except Exception as e:
                logger.error(f"Error stopping stream: {e}")
                return False
        return True

    def is_streaming(self):
        """Check if stream is currently active"""
        if self.ffmpeg_process and self.ffmpeg_process.poll() is None:
            return True
        return False

    def update_status(self, state, message):
        """Update status file for web interface"""
        status = {
            'state': state,
            'message': message,
            'timestamp': datetime.now().isoformat(),
            'usb_connected': self.check_usb_connected(),
            'streaming': self.is_streaming()
        }

        try:
            with open(self.status_file, 'w') as f:
                json.dump(status, f)
        except Exception as e:
            logger.error(f"Error updating status file: {e}")

    def monitor_and_reconnect(self):
        """Main monitoring loop with reconnection logic"""
        logger.info("Starting monitoring loop")
        current_delay = self.reconnect_delay

        while self.should_run:
            try:
                # Check if USB is connected
                if not self.check_usb_connected():
                    logger.warning("USB audio device not connected")
                    self.update_status("waiting", "USB not connected")

                    # Stop stream if running
                    if self.is_streaming():
                        self.stop_stream()

                    # Wait before checking again
                    time.sleep(current_delay)
                    current_delay = min(current_delay * 1.5, self.max_reconnect_delay)
                    continue

                # USB is connected, check if stream is running
                if not self.is_streaming():
                    logger.info("Stream not running, attempting to start...")
                    if self.start_stream():
                        # Reset reconnect delay on success
                        current_delay = self.reconnect_delay
                    else:
                        # Increase delay on failure
                        current_delay = min(current_delay * 1.5, self.max_reconnect_delay)
                        logger.info(f"Will retry in {current_delay} seconds")
                        time.sleep(current_delay)
                        continue
                else:
                    # Stream is running, update status
                    self.update_status("streaming", "Connected")
                    current_delay = self.reconnect_delay

                # Check stream health every 5 seconds
                time.sleep(5)

            except Exception as e:
                logger.error(f"Error in monitoring loop: {e}")
                self.update_status("error", str(e))
                time.sleep(current_delay)

    def run(self):
        """Main entry point"""
        if not self.config:
            logger.error("Cannot run without valid configuration")
            return 1

        logger.info("Icecast Streamer starting...")
        self.update_status("starting", "Initializing")

        try:
            self.monitor_and_reconnect()
        except KeyboardInterrupt:
            logger.info("Received keyboard interrupt")
        finally:
            self.stop_stream()
            self.update_status("stopped", "Shutdown")

        return 0


def setup_config():
    """Interactive configuration setup"""
    print("=== Icecast Streaming Encoder Configuration ===\n")

    config = {}

    config['hostname'] = input("Enter Icecast server IP/hostname: ").strip()
    config['port'] = input("Enter Icecast server port (default: 8000): ").strip() or "8000"
    config['mount_point'] = input("Enter mount point (e.g., stream.aac): ").strip()
    config['username'] = input("Enter username (default: source): ").strip() or "source"
    config['password'] = input("Enter password: ").strip()

    # Optional metadata
    config['stream_name'] = input("Enter stream name (optional): ").strip() or "Raspberry Pi Stream"
    config['stream_description'] = input("Enter stream description (optional): ").strip() or "Live Audio Stream"
    config['stream_genre'] = input("Enter stream genre (optional): ").strip() or "Various"

    # Save configuration
    with open('config.json', 'w') as f:
        json.dump(config, f, indent=4)

    print("\nConfiguration saved to config.json")
    return config


if __name__ == "__main__":
    # Check if config exists, if not, run setup
    if not os.path.exists('config.json'):
        print("No configuration found. Running setup...\n")
        setup_config()

    # Start the streamer
    streamer = IcecastStreamer('config.json')
    sys.exit(streamer.run())
