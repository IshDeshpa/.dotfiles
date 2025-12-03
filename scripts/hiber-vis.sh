#!/bin/bash
# symlinked to /lib/systemd/system-sleep/hiber-vis.sh

mint_entry="/boot/loader/entries/mint.conf"
mint_disabled="/boot/loader/entries/mint.conf.disabled"
linux_default="arch.conf"
BtUsbModule="btusb"

handle_boot_entry() {
  case "$1" in
    pre)
      if [ "$2" == "hibernate" ]; then
        echo "[system-sleep] Hibernation detected. Renaming Mint entry to disable it."

        if [ -f "$mint_entry" ] && [ ! -f "$mint_disabled" ]; then
          mv "$mint_entry" "$mint_disabled"
        fi

        bootctl set-default "$linux_default"
      else
        echo "[system-sleep] Shutdown or Reboot detected. Ensuring Mint entry is enabled."

        if [ -f "$mint_disabled" ] && [ ! -f "$mint_entry" ]; then
          mv "$mint_disabled" "$mint_entry"
        fi
      fi
      ;;
    post)
      # Do nothing on resume
      ;;
  esac
}

handle_bluetooth() {
  case "$1 $2" in
    "pre hibernate" | "pre suspend-then-hibernate")
      systemctl stop bluetooth
      modprobe -r "$BtUsbModule"
      ;;
    "post hibernate" | "post suspend-then-hibernate")
      modprobe "$BtUsbModule"
      systemctl start bluetooth
      ;;
    *)
      # Do nothing for other states
      ;;
  esac
}

# Main dispatcher
handle_boot_entry "$1" "$2"
handle_bluetooth "$1" "$2"
