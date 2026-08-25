#!/bin/bash

set -u

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/niri-last-closed-app-id"

if [[ ! -s "$STATE_FILE" ]]; then
    notify-send "Reopen app" "No recently closed app recorded."
    exit 0
fi

APP_ID=$(sed -n '1p' "$STATE_FILE")
WORKING_DIR=$(sed -n '2p' "$STATE_FILE")

desktop_entry_for_app_id() {
    local app_id_lower=${1,,}
    local desktop_file desktop_id wm_class

    while IFS= read -r -d '' desktop_file; do
        desktop_id=$(basename "$desktop_file" .desktop)
        if [[ "${desktop_id,,}" == "$app_id_lower" ]]; then
            printf '%s\n' "$desktop_id"
            return 0
        fi
        wm_class=$(awk -F= '/^(StartupWMClass|X-GNOME-WMClass)=/ { print tolower($2); exit }' "$desktop_file")
        if [[ "$wm_class" == "$app_id_lower" ]]; then
            printf '%s\n' "$desktop_id"
            return 0
        fi
    done < <(find "$HOME/.local/share/applications" /usr/share/applications "$HOME/.local/share/flatpak/exports/share/applications" /var/lib/flatpak/exports/share/applications -maxdepth 1 -type f -name '*.desktop' -print0 2>/dev/null)
}

if [[ "${APP_ID,,}" != kitty ]] && DESKTOP_ID=$(desktop_entry_for_app_id "$APP_ID"); then
    if gtk-launch "$DESKTOP_ID" >/dev/null 2>&1 & then
        exit 0
    fi
fi

if [[ "${APP_ID,,}" == kitty ]]; then
    COMMAND=(kitty)
    if [[ -n "$WORKING_DIR" && -d "$WORKING_DIR" ]]; then
        COMMAND+=(--directory "$WORKING_DIR")
    fi
fi

case "${APP_ID,,}" in
    kitty)
        ;;
    waterfox|*waterfox*) COMMAND=(waterfox) ;;
    firefox|*firefox*|org.mozilla.firefox) COMMAND=(firefox-developer-edition) ;;
    chromium|*chromium*) COMMAND=(chromium) ;;
    spotify|*spotify*) COMMAND=(spotify) ;;
    legcord|*legcord*) COMMAND=(legcord) ;;
    *)
        notify-send "Reopen app" "No launch command mapped for: $APP_ID"
        exit 1
        ;;
esac

if ! command -v "${COMMAND[0]}" >/dev/null 2>&1; then
    notify-send "Reopen app" "Command not found: ${COMMAND[0]}"
    exit 1
fi

"${COMMAND[@]}" >/dev/null 2>&1 &
