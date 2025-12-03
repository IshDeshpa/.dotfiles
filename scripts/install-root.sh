#!/bin/bash
set -e

# create user 
if ! id -u ishdeshpa >/dev/null 2>&1; then
    useradd -m -G wheel -s /bin/bash ishdeshpa
    passwd ishdeshpa
fi

# enable wheel group for sudo
if ! grep -q '^%wheel ALL=(ALL:ALL) ALL' /etc/sudoers; then
    echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers
fi

pacman -Sy grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
