#!/usr/bin/env bash

rofi_cmd="rofi -dmenu -i -p Power"

options=$(
cat <<EOF
Lock
Logout
Suspend
Hibernate
Reboot
Shutdown
EOF
)

choice=$(echo "$options" | $rofi_cmd)

case "$choice" in
    Lock)
        command -v loginctl >/dev/null && loginctl lock-session
        ;;
    Logout)
        loginctl terminate-user "$USER"
        ;;
    Suspend)
        systemctl suspend
        ;;
    Hibernate)
        systemctl hibernate
        ;;
    Reboot)
        systemctl reboot
        ;;
    Shutdown)
        systemctl poweroff
        ;;
esac

