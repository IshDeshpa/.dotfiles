#!/bin/bash

# Detect battery (BAT0 or BAT1, etc.)
BATTERY=$(ls /sys/class/power_supply | grep -m1 BAT)

# Pick a sound file (system default alert sound)
SOUND="/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"

while true; do
  bat_lvl=$(cat /sys/class/power_supply/$BATTERY/capacity)
  status=$(cat /sys/class/power_supply/$BATTERY/status)

  if [ "$status" = "Discharging" ] && [ "$bat_lvl" -le 15 ]; then
    notify-send --urgency=CRITICAL "Battery Low" "Level: ${bat_lvl}%"
    # Play sound if available
    if command -v paplay &>/dev/null; then
      paplay "$SOUND" &
    elif command -v aplay &>/dev/null; then
      aplay "$SOUND" &
    fi
    sleep 300 # 5 minutes between warnings
  else
    sleep 120 # check every 2 minutes
  fi
done
