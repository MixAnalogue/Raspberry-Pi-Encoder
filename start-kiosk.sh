#!/bin/bash

##############################################
# Start Chromium in Kiosk Mode
# Optimized for reliability on Pi OS Lite
##############################################

# Log file for debugging
LOG_FILE="/tmp/kiosk-startup.log"
echo "$(date): Kiosk startup initiated" >> "$LOG_FILE"

# Wait for X server to be fully ready
echo "$(date): Waiting for X server..." >> "$LOG_FILE"
for i in {1..30}; do
    if xset q &>/dev/null; then
        echo "$(date): X server is ready" >> "$LOG_FILE"
        break
    fi
    sleep 1
done

# Additional settling time
sleep 3

# Disable screen blanking and power management
xset s off
xset -dpms
xset s noblank

# Set background to black
xsetroot -solid black &>/dev/null || true

# Hide mouse cursor
unclutter -idle 0.1 -root &

# Wait for web service to be responding
echo "$(date): Waiting for web service..." >> "$LOG_FILE"
for i in {1..60}; do
    if curl -s http://localhost:5000 >/dev/null 2>&1; then
        echo "$(date): Web service is ready" >> "$LOG_FILE"
        break
    fi
    sleep 1
done

# Additional delay to ensure service is fully ready
sleep 2

# Determine which chromium command to use
if command -v chromium-browser &>/dev/null; then
    CHROMIUM_CMD="chromium-browser"
elif command -v chromium &>/dev/null; then
    CHROMIUM_CMD="chromium"
else
    echo "$(date): ERROR - No chromium found!" >> "$LOG_FILE"
    exit 1
fi

echo "$(date): Starting $CHROMIUM_CMD in kiosk mode" >> "$LOG_FILE"

# Start Chromium in kiosk mode
$CHROMIUM_CMD \
    --kiosk \
    --noerrdialogs \
    --disable-infobars \
    --no-first-run \
    --disable-session-crashed-bubble \
    --disable-restore-session-state \
    --disable-features=TranslateUI \
    --check-for-update-interval=31536000 \
    --disable-pinch \
    --overscroll-history-navigation=0 \
    http://localhost:5000 \
    >> "$LOG_FILE" 2>&1
