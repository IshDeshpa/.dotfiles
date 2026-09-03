#!/bin/sh

key="$1"

if pgrep -f '^/home/ishdeshpa/.local/opt/waterfox/waterfox ' >/dev/null; then
    case "$key" in
        left)
            /usr/bin/keyd do S-tab
            ;;
        right)
            /usr/bin/keyd do tab
            ;;
    esac
else
    /usr/bin/keyd do "$key"
fi

