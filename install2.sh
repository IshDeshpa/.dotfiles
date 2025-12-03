#!/bin/bash
set -e

# create user 
if ! id -u ishdeshpa >/dev/null 2>&1; then
    useradd -m -G wheel -s /bin/bash ishdeshpa
    passwd ishdeshpa
fi
