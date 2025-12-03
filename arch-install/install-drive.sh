#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 /dev/sdX"
    exit 1
fi

DRIVE="$1"

echo "Partitioning $DRIVE..."

# Partition the drive
parted "$DRIVE" --script mklabel gpt \
    mkpart ESP fat32 1MiB 513MiB \
    set 1 boot on \
    mkpart primary ext4 513MiB 100%

echo "Formatting partitions..."

# Format partitions
mkfs.fat -F32 "${DRIVE}1"
mkfs.ext4 "${DRIVE}2"

echo "Mounting partitions..."

# Mount partitions
mount "${DRIVE}2" /mnt
mkdir -p /mnt/boot
mount "${DRIVE}1" /mnt/boot

# Mount virtual filesystems for chroot
mkdir -p /mnt/proc /mnt/sys /mnt/dev /mnt/run /mnt/tmp
mount -t proc /proc /mnt/proc
mount --rbind /sys /mnt/sys
mount --rbind /dev /mnt/dev
mount --make-rslave /mnt/sys
mount --make-rslave /mnt/dev

# Optional: copy resolv.conf for network access
mkdir -p /mnt/etc
cp /etc/resolv.conf /mnt/etc/resolv.conf

echo "Installing base system"
pacstrap /mnt base linux linux-firmware nvim sudo openssh git

echo "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt

echo "Installing bootloader"
pacman -S grub efibootmgr

# Install GRUB for UEFI
grub-install --target=i386-pc /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

echo "Ready to arch-chroot /mnt"
