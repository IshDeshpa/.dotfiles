#!/bin/bash

# Detect first available battery (BAT0, BAT1, etc.)
BATTERY=$(ls /sys/class/power_supply | grep -m1 '^BAT')
BAT_PATH="/sys/class/power_supply/$BATTERY"

# Sound file for warnings
SOUND="/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"

# Minimum battery threshold
THRESHOLD=15

# Notification cooldown (in seconds)
WARN_INTERVAL=300   # 5 minutes
CHECK_INTERVAL=120  # General check frequency

last_warn=0

play_sound() {
    if command -v paplay &>/dev/null; then
        paplay "$SOUND" &
    elif command -v aplay &>/dev/null; then
        aplay "$SOUND" &
    fi
}

while true; do
    # Ensure battery path still exists
    if [ ! -d "$BAT_PATH" ]; then
        sleep "$CHECK_INTERVAL"
        continue
    fi

    bat_lvl=$(cat "$BAT_PATH/capacity" 2>/dev/null)
    status=$(cat "$BAT_PATH/status" 2>/dev/null)
    now=$(date +%s)

    if [ "$status" = "Discharging" ] && [ "$bat_lvl" -le "$THRESHOLD" ]; then
        if (( now - last_warn >= WARN_INTERVAL )); then
            notify-send --urgency=CRITICAL "Battery Low" "Level: ${bat_lvl}%"
            play_sound
            last_warn=$now
        fi
    fi

    sleep "$CHECK_INTERVAL"
done
