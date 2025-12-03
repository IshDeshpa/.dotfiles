#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Usage: $0 /dev/sdX"
    exit 1
fi

DRIVE="$1"

echo "Selected drive: $DRIVE"
echo
read -p "Do you want to ERASE and FORMAT this drive? [y/N]: " confirm

if [[ "$confirm" =~ ^[Yy]$ ]]; then
    echo "Partitioning $DRIVE..."

    parted "$DRIVE" --script mklabel gpt \
        mkpart ESP fat32 1MiB 513MiB \
        set 1 boot on \
        mkpart primary ext4 513MiB 100%

    echo "Formatting partitions..."

    mkfs.fat -F32 "${DRIVE}1"
    mkfs.ext4 "${DRIVE}2"
else
    echo "Skipping partitioning and formatting."
    echo "Using existing partitions:"
    lsblk "$DRIVE"
    echo
    read -p "Enter EFI partition (e.g., ${DRIVE}1): " EFI_PART
    read -p "Enter root partition (e.g., ${DRIVE}2): " ROOT_PART
    DRIVE_EFI="$EFI_PART"
    DRIVE_ROOT="$ROOT_PART"
fi

# Default partition names if formatting path was taken
if [[ "$confirm" =~ ^[Yy]$ ]]; then
    DRIVE_EFI="${DRIVE}1"
    DRIVE_ROOT="${DRIVE}2"
fi

echo "Mounting partitions..."

mount "$DRIVE_ROOT" /mnt
mkdir -p /mnt/boot
mount "$DRIVE_EFI" /mnt/boot

mkdir -p /mnt/proc /mnt/sys /mnt/dev /mnt/run /mnt/tmp
mount -t proc /proc /mnt/proc
mount --rbind /sys /mnt/sys
mount --rbind /dev /mnt/dev
mount --make-rslave /mnt/sys
mount --make-rslave /mnt/dev

mkdir -p /mnt/etc
cp /etc/resolv.conf /mnt/etc/resolv.conf

echo "Installing base system..."
pacstrap /mnt base linux linux-firmware nvim sudo openssh git

echo "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

echo "Entering chroot environment..."
arch-chroot /mnt

echo "Installing bootloader..."
pacman -S grub efibootmgr

echo "Installing GRUB for BIOS..."
grub-install --target=i386-pc "$DRIVE"
grub-mkconfig -o /boot/grub/grub.cfg

echo "Setup complete. You may now run: arch-chroot /mnt"
