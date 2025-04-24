#!/bin/bash

CMD="$1"
CUR_VOL=$(pactl get-sink-volume @DEFAULT_SINK@ | sed -n 's/.*: *[0-9]* \/ *\([0-9]*\)%.*/\1/p')

# Default volume step
STEP=5

if [ "$CMD" == "up" ]; then
    NEW_VOL=$((CUR_VOL + STEP))
elif [ "$CMD" == "down" ]; then
    NEW_VOL=$((CUR_VOL - STEP))
else
    echo "Usage: $0 up|down"
    exit 1
fi

# Clamp between 0 and 100
if [ "$NEW_VOL" -gt 100 ]; then
    NEW_VOL=100
elif [ "$NEW_VOL" -lt 0 ]; then
    NEW_VOL=0
fi

# Apply new volume
pactl set-sink-volume @DEFAULT_SINK@ "${NEW_VOL}%"

