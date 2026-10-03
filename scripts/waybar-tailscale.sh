#!/usr/bin/env bash

set -u

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
WAYBAR_SIGNAL=9
CONNECTING_STATE="${XDG_RUNTIME_DIR:-/tmp}/waybar-tailscale.connecting"

notify_waybar () {
    pkill -SIGRTMIN+"$WAYBAR_SIGNAL" -x waybar 2>/dev/null || true
}

connecting_status () {
    local owner
    [[ -r "$CONNECTING_STATE" ]] || return 1
    read -r owner < "$CONNECTING_STATE" || return 1
    [[ "$owner" =~ ^[0-9]+$ ]] && kill -0 "$owner" 2>/dev/null
}

tailscale_status () {
    tailscale status --json 2>/dev/null \
        | jq -e '.BackendState == "Running"' >/dev/null 2>&1
}

finish_toggle () {
    rm -f -- "$CONNECTING_STATE"
    notify_waybar
}

run_tailscale () {
    local output
    if output=$(tailscale "$@" 2>&1); then
        return 0
    fi
    if [[ "$output" == *"Access denied"* || "$output" == *"access denied"* || "$output" == *"permission denied"* ]]; then
        output="Tailscale operator permission is required. Run once in a terminal: sudo tailscale set --operator=ishdeshpa"
    fi
    printf '%s\n' "$output" >&2
    notify-send -u critical 'VPN switch failed' "${output:-Tailscale command failed.}" || true
    return 1
}

wait_for_running () {
    local attempt state
    for ((attempt = 0; attempt < 30; attempt++)); do
        state=$(tailscale status --json 2>/dev/null | jq -r '.BackendState')
        [[ "$state" == "Running" ]] && return 0
        sleep 0.5
    done
    notify-send -u critical 'VPN switch timed out' 'Tailscale did not reach Running.' || true
    return 1
}

ensure_running () {
    local state
    state=$(tailscale status --json 2>/dev/null | jq -r '.BackendState')
    if [[ "$state" != "Running" ]]; then
        run_tailscale up --accept-dns --exit-node= || return 1
        wait_for_running || return 1
    fi
}

start_action () {
    exec 9>"${CONNECTING_STATE}.lock"
    flock -n 9 || return 1
    printf '%s\n' "$$" >"$CONNECTING_STATE"
    notify_waybar
    trap 'rm -f -- "$CONNECTING_STATE"; notify_waybar' EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
}

connect_random () {
    start_action || return 0
    ensure_running || return 1
    if bash "$SCRIPT_DIR/random-exit-node.sh" --internet; then
        notify-send 'VPN connected' 'Selected a random exit node from the ten fastest nodes.' || true
    else
        notify-send -u critical 'VPN connection failed' 'No working top-ten exit node was found.' || true
        return 1
    fi
}

connect_region () {
    local region="$1"
    start_action || return 0
    ensure_running || return 1
    if bash "$SCRIPT_DIR/random-exit-node.sh" --internet --region="$region"; then
        notify-send 'VPN connected' "Selected a random ${region^^} exit node from the ten fastest nodes." || true
    else
        notify-send -u critical 'VPN connection failed' "No working top-ten ${region^^} exit node was found." || true
        return 1
    fi
}

disconnect_exit_node () {
    start_action || return 0
    if run_tailscale set --exit-node=; then
        notify-send 'VPN connected' 'Not using an exit node.' || true
    fi
}

show_menu () {
    local choice
    choice=$(printf '%s\n' \
        'Connect to random US node' \
        'Connect to random non-US node' \
        'Do not use an exit node' |
        fuzzel --dmenu --prompt='Tailscale: ') || return 0
    case "$choice" in
        'Connect to random US node') connect_region us ;;
        'Connect to random non-US node') connect_region non-us ;;
        'Do not use an exit node') disconnect_exit_node ;;
    esac
}

toggle_status () {
    local expected state attempt exit_node
    # Ignore repeated clicks while a toggle is still in progress.
    exec 9>"${CONNECTING_STATE}.lock"
    flock -n 9 || return 0
    trap finish_toggle EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    printf '%s\n' "$$" >"$CONNECTING_STATE"
    notify_waybar

    if tailscale_status; then
        expected=Stopped
        run_tailscale down || return 1
    else
        expected=Running
        run_tailscale up --accept-dns --exit-node= || return 1
    fi

    # A successful command can return before the daemon finishes switching.
    for ((attempt = 0; attempt < 30; attempt++)); do
        state=$(tailscale status --json 2>/dev/null | jq -r '.BackendState')
        if [[ "$state" == "$expected" ]]; then
            if [[ "$expected" == Running ]]; then
                if ! bash "$SCRIPT_DIR/random-exit-node.sh" --internet; then
                    notify-send -u critical 'VPN connection failed' 'No working exit node was selected. Internet traffic may use the direct route.' || true
                    return 1
                fi
                exit_node=$(tailscale status --json 2>/dev/null | jq -r '
                    . as $status
                    | ([.Peer[]? | select(.ExitNode == true or
                        (.ID != null and .ID == $status.ExitNodeStatus.ID))][0] // {})
                    | [(.DNSName // "" | split(".")[0]), .HostName,
                        .TailscaleIPs[0], $status.ExitNodeStatus.TailscaleIPs[0],
                        $status.ExitNodeStatus.ID]
                    | map(select(. != null and . != "")) | .[0] // "Unknown exit node"')
                notify-send 'VPN connected' "Exit node: ${exit_node:-Unknown exit node}" || true
            fi
            return 0
        fi
        sleep 0.5
    done
    notify-send -u critical 'VPN switch timed out' "Tailscale did not reach $expected; showing its current state." || true
    return 1
}

case "${1:-}" in
    --status)
        if connecting_status; then
            echo '{"text":"switching…","class":"connecting","alt":"connecting", "tooltip":"Connecting or disconnecting the VPN…"}'
        elif tailscale_status; then
            T=${2:-"green"}
            F=${3:-"red"}

            # Let jq encode newlines and quotes instead of constructing JSON by hand.
            tailscale status --json 2>/dev/null | jq -c --arg T "$T" --arg F "$F" '
                [.Peer[]?] as $peers
                | {
                    text: ([$peers[] | select(.ExitNode == true)
                        | .DNSName | split(".")[0]][0] // "direct"),
                    class: "connected",
                    alt: "connected",
                    tooltip: ([$peers[]
                        | "<span color=\"" + ((if .Online then $T else $F end) | @html)
                            + "\">" + ((.DNSName | split(".")[0]) | @html)
                            + "</span>"] | join("\n"))
                }'
        else
            echo '{"text":"disconnected","class":"stopped","alt":"stopped", "tooltip":"The VPN is not active."}'
        fi
    ;;
    --toggle)
        toggle_status
    ;;
    --random)
        connect_random
    ;;
    --menu)
        show_menu
    ;;
esac
