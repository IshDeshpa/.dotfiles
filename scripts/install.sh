#!/bin/bash
set -e

usage() {
    echo "Usage: $0 {drive|root|ishdeshpa} [args...]"
    exit 1
}

[[ -z "$1" ]] && usage
cmd="$1"
shift

case "$cmd" in
############################################
# drive
############################################
drive)
    FORMAT="no"

    # Parse flag: only --format exists, no value
    while [[ "$1" == --* ]]; do
        case "$1" in
            --format) FORMAT="yes"; shift ;;
            *) echo "Unknown option: $1"; exit 1 ;;
        esac
    done

    if [ -z "$1" ]; then
        echo "Usage: $0 drive [--format] /dev/sdX"
        exit 1
    fi

    DRIVE="$1"

    echo "Selected drive: $DRIVE"
    echo "Formatting: $FORMAT"
    echo

    if [[ "$FORMAT" == "yes" ]]; then
        echo "Partitioning $DRIVE..."

        parted "$DRIVE" --script mklabel gpt \
            mkpart ESP fat32 1MiB 513MiB \
            set 1 boot on \
            mkpart primary ext4 513MiB 100%

        echo "Formatting partitions..."
        mkfs.fat -F32 "${DRIVE}1"
        mkfs.ext4 "${DRIVE}2"

        DRIVE_EFI="${DRIVE}1"
        DRIVE_ROOT="${DRIVE}2"

    else
        echo "Skipping partitioning and formatting."
        echo "Using existing partitions:"
        lsblk "$DRIVE"
        echo

        DRIVE_EFI="${DRIVE}1"
        DRIVE_ROOT="${DRIVE}2"

        echo "Auto-selecting:"
        echo "  EFI:  $DRIVE_EFI"
        echo "  ROOT: $DRIVE_ROOT"
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

    echo "Entering chroot..."
    exec arch-chroot /mnt
    ;;

############################################
# root
############################################
root)
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
    ;;

############################################
# ishdeshpa
############################################
ishdeshpa)
    SCRIPT_PATH="$(readlink -f "$0")"
    SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
    REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"

    # argument forwarded to restore.sh
    RESTORE_ARG="$1"
    [ -z "$RESTORE_ARG" ] && { 
        echo "Usage: $0 ishdeshpa {minimal|base|full|/path/to/pkglist}"; 
        exit 1; 
    }

    # install yay
    git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
    pushd /tmp/yay-bin
    sudo pacman -S --needed base-devel
    makepkg -si
    popd

    # run restore script with argument
    "$SCRIPT_DIR/restore-packages.sh" "$RESTORE_ARG"
    "$SCRIPT_DIR/config-ln.sh"
    ;;

############################################
# invalid command
############################################
*)
    usage
    ;;
esac
