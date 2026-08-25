#!/bin/bash

set -u

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/niri-last-closed-app-id"
WINDOW_INFO=$(niri msg -j focused-window)
APP_ID=$(jq -r '.app_id // empty' <<<"$WINDOW_INFO")
WINDOW_PID=$(jq -r '.pid // empty' <<<"$WINDOW_INFO")

focused_shell_cwd() {
    local parent_pid=$1
    local pid shell_pid shell_name comm cwd fallback_cwd=
    local -a pending=("$parent_pid")

    # Kitty normally keeps the interactive shell as a direct child. Query it
    # explicitly because /proc/*/children can be unavailable in some setups.
    for shell_name in bash zsh fish dash sh ksh tcsh yash nu pwsh; do
        while read -r shell_pid; do
            cwd=$(readlink -- "/proc/$shell_pid/cwd" 2>/dev/null) || continue
            [[ -d "$cwd" ]] && printf '%s\n' "$cwd" && return 0
        done < <(pgrep -P "$parent_pid" -x "$shell_name" 2>/dev/null)
    done

    while ((${#pending[@]})); do
        pid=${pending[0]}
        pending=("${pending[@]:1}")

        while read -r child_pid; do
            [[ -n "$child_pid" ]] && pending+=("$child_pid")
        done <"/proc/$pid/task/$pid/children" 2>/dev/null || true

        cwd=$(readlink -- "/proc/$pid/cwd" 2>/dev/null) || continue
        [[ -d "$cwd" ]] || continue

        # Kitty's PID is not always the direct parent of the shell. Keep a
        # fallback for process trees where the shell is wrapped or renamed.
        fallback_cwd=$cwd

        comm=$(<"/proc/$pid/comm") || continue
        case "$comm" in
            bash|dash|fish|ksh|nu|pwsh|sh|tcsh|yash|zsh)
                printf '%s\n' "$cwd"
                return 0
                ;;
        esac
    done

    [[ -n "$fallback_cwd" ]] && printf '%s\n' "$fallback_cwd"
}

WORKING_DIR=
if [[ "${APP_ID,,}" == kitty && "$WINDOW_PID" =~ ^[0-9]+$ ]]; then
    WORKING_DIR=$(focused_shell_cwd "$WINDOW_PID" || true)
fi

if [[ -n "$APP_ID" ]]; then
    {
        printf '%s\n' "$APP_ID"
        printf '%s\n' "$WORKING_DIR"
        printf '%s\n' "$WINDOW_PID"
    } >"$STATE_FILE"
fi

niri msg action close-window
