#!/usr/bin/env python3
"""
Web interface for Icecast Streamer
Provides status monitoring and control via HTTP
"""

from flask import Flask, render_template, jsonify, request
import json
import os
import signal
import subprocess
from pathlib import Path

app = Flask(__name__)

CONFIG_FILE = 'config.json'
STATUS_FILE = '/tmp/streamer_status.json'
PID_FILE = '/tmp/streamer.pid'


def get_status():
    """Read current status from status file"""
    try:
        if os.path.exists(STATUS_FILE):
            with open(STATUS_FILE, 'r') as f:
                return json.load(f)
    except Exception as e:
        print(f"Error reading status: {e}")

    return {
        'state': 'unknown',
        'message': 'No status available',
        'timestamp': '',
        'usb_connected': False,
        'streaming': False
    }


def get_config():
    """Read current configuration"""
    try:
        if os.path.exists(CONFIG_FILE):
            with open(CONFIG_FILE, 'r') as f:
                return json.load(f)
    except Exception as e:
        print(f"Error reading config: {e}")

    return None


def is_streamer_running():
    """Check if streamer process is running"""
    try:
        # First check systemd
        result = subprocess.run(
            ['systemctl', 'is-active', 'icecast-streamer'],
            capture_output=True,
            text=True,
            timeout=5
        )
        if result.returncode == 0 and result.stdout.strip() == 'active':
            return True

        # Fall back to PID file check
        if os.path.exists(PID_FILE):
            with open(PID_FILE, 'r') as f:
                pid = int(f.read().strip())

            # Check if process with this PID exists
            try:
                os.kill(pid, 0)
                return True
            except OSError:
                return False
    except Exception as e:
        print(f"Error checking streamer status: {e}")

    return False


def start_streamer():
    """Start the streamer service"""
    try:
        # Use systemd if available, otherwise start directly
        result = subprocess.run(
            ['sudo', 'systemctl', 'start', 'icecast-streamer'],
            capture_output=True,
            text=True,
            timeout=10
        )

        if result.returncode == 0:
            return True, "Streamer started"
        else:
            error_msg = result.stderr.strip() if result.stderr else "Unknown error"
            print(f"systemctl start failed: {error_msg}")
            # Try starting directly
            subprocess.Popen(
                ['python3', 'streamer.py'],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                stdin=subprocess.DEVNULL,
                start_new_session=True
            )
            return True, "Streamer started"

    except Exception as e:
        print(f"Error in start_streamer: {e}")
        return False, f"Error starting streamer: {e}"


def stop_streamer():
    """Stop the streamer service"""
    try:
        # Try systemd first
        result = subprocess.run(
            ['sudo', 'systemctl', 'stop', 'icecast-streamer'],
            capture_output=True,
            text=True,
            timeout=10
        )

        if result.returncode == 0:
            return True, "Streamer stopped"

        error_msg = result.stderr.strip() if result.stderr else "Unknown error"
        print(f"systemctl stop failed: {error_msg}")

        # Try killing by PID
        if os.path.exists(PID_FILE):
            with open(PID_FILE, 'r') as f:
                pid = int(f.read().strip())

            os.kill(pid, signal.SIGTERM)
            # Wait a moment for process to stop
            import time
            time.sleep(1)
            return True, "Streamer stopped"

        return False, "Streamer not running"

    except Exception as e:
        print(f"Error in stop_streamer: {e}")
        return False, f"Error stopping streamer: {e}"


def restart_streamer():
    """Restart the streamer service"""
    try:
        # Try systemd first
        result = subprocess.run(
            ['sudo', 'systemctl', 'restart', 'icecast-streamer'],
            capture_output=True,
            text=True,
            timeout=10
        )

        if result.returncode == 0:
            return True, "Streamer restarted"

        error_msg = result.stderr.strip() if result.stderr else "Unknown error"
        print(f"systemctl restart failed: {error_msg}")

        # Otherwise stop and start
        stop_streamer()
        import time
        time.sleep(2)
        return start_streamer()

    except Exception as e:
        print(f"Error in restart_streamer: {e}")
        return False, f"Error restarting streamer: {e}"


@app.route('/')
def index():
    """Serve main page"""
    return render_template('index.html')


@app.route('/api/status')
def api_status():
    """Get current status"""
    status = get_status()
    config = get_config()

    response = {
        'status': status,
        'config': {
            'hostname': config.get('hostname', 'N/A') if config else 'N/A',
            'port': config.get('port', 'N/A') if config else 'N/A',
            'mount_point': config.get('mount_point', 'N/A') if config else 'N/A',
        } if config else None,
        'streamer_running': is_streamer_running()
    }

    return jsonify(response)


@app.route('/api/start', methods=['POST'])
def api_start():
    """Start streaming"""
    success, message = start_streamer()
    return jsonify({'success': success, 'message': message})


@app.route('/api/stop', methods=['POST'])
def api_stop():
    """Stop streaming"""
    success, message = stop_streamer()
    return jsonify({'success': success, 'message': message})


@app.route('/api/restart', methods=['POST'])
def api_restart():
    """Restart streaming"""
    success, message = restart_streamer()
    return jsonify({'success': success, 'message': message})


@app.route('/api/config', methods=['GET', 'POST'])
def api_config():
    """Get or update configuration"""
    if request.method == 'GET':
        config = get_config()
        return jsonify({'success': True, 'config': config})

    elif request.method == 'POST':
        try:
            new_config = request.json

            # Validate required fields
            required = ['hostname', 'port', 'mount_point', 'username', 'password']
            for field in required:
                if field not in new_config:
                    return jsonify({'success': False, 'message': f'Missing field: {field}'})

            # Save configuration
            with open(CONFIG_FILE, 'w') as f:
                json.dump(new_config, f, indent=4)

            return jsonify({'success': True, 'message': 'Configuration saved'})

        except Exception as e:
            return jsonify({'success': False, 'message': str(e)})


if __name__ == '__main__':
    # Create templates directory if it doesn't exist
    Path('templates').mkdir(exist_ok=True)

    # Run Flask app
    app.run(host='0.0.0.0', port=5000, debug=False)
