#!/bin/sh

pid=$(pgrep -o -f '^/home/ishdeshpa/.local/opt/waterfox/waterfox ')

if [ -n "$pid" ]; then
    kill -TERM "$pid"
fi

