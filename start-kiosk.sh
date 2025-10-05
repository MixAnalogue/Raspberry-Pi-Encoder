#!/bin/bash

# Wait for X server and web service to be ready
sleep 10

# Check if web service is responding
for i in {1..30}; do
    if curl -s http://localhost:5000 >/dev/null 2>&1; then
        break
    fi
    sleep 1
done

# Disable screen blanking
xset s off
xset -dpms
xset s noblank

# Hide mouse cursor
unclutter -idle 0.1 -root &

# Start Chromium in kiosk mode
if command -v chromium-browser &>/dev/null; then
    chromium-browser --kiosk \
        --disable-infobars \
        --noerrdialogs \
        --disable-session-crashed-bubble \
        --disable-restore-session-state \
        --disable-features=TranslateUI \
        --check-for-update-interval=31536000 \
        http://localhost:5000
else
    chromium --kiosk \
        --disable-infobars \
        --noerrdialogs \
        --disable-session-crashed-bubble \
        --disable-restore-session-state \
        --disable-features=TranslateUI \
        --check-for-update-interval=31536000 \
        http://localhost:5000
fi
