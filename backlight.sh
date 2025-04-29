#!/bin/sh

# Path to store last backlight state
STATE_FILE="/tmp/kblight_state"

# Default to 0 if state file doesn't exist
if [[ -f "$STATE_FILE" ]]; then
    last=$(cat "$STATE_FILE")
else
    last=0
fi

# Toggle value
if [[ "$last" -eq 0 ]]; then
    new=100
else
    new=0
fi

# Set new value and store it
sudo ectool pwmsetkblight "$new"
echo "$new" > "$STATE_FILE"

echo "Keyboard backlight set to $new%"

