#!/bin/bash

set -u

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/niri-last-closed-app-id"
APP_ID=$(niri msg -j focused-window | jq -r '.app_id // empty')

if [[ -n "$APP_ID" ]]; then
    printf '%s\n' "$APP_ID" >"$STATE_FILE"
fi

niri msg action close-window
