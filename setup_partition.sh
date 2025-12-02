#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 /dev/sdX"
    exit 1
fi

DRIVE="$1"

# Partition the drive
parted "$DRIVE" --script mklabel gpt \
    mkpart ESP fat32 1MiB 513MiB \
    set 1 boot on \
    mkpart primary ext4 513MiB 100%

# Format partitions
mkfs.fat -F32 "${DRIVE}1"
mkfs.ext4 "${DRIVE}2"

# Mount partitions
mount "${DRIVE}2" /mnt
mkdir -p /mnt/boot
mount "${DRIVE}1" /mnt/boot

echo "Drive $DRIVE partitioned and mounted."
