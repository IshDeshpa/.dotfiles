#!/usr/bin/env bash

set -u

MULLVAD_EXIT_NODE="100.100.131.35"
WAYBAR_SIGNAL=9
CONNECTING_STATE="${XDG_RUNTIME_DIR:-/tmp}/waybar-tailscale.connecting"

notify_waybar () {
    pkill -SIGRTMIN+"$WAYBAR_SIGNAL" -x waybar 2>/dev/null || true
}

connecting_status () {
    local started
    [[ -r "$CONNECTING_STATE" ]] || return 1
    read -r started < "$CONNECTING_STATE" || return 1
    if [[ "$started" =~ ^[0-9]+$ ]] && (( EPOCHSECONDS - started < 60 )); then
        return 0
    fi
    rm -f -- "$CONNECTING_STATE"
    return 1
}

fastest_us_exit_node () {
    local probe_dir node latency best
    local -a nodes

    mapfile -t nodes < <(
        tailscale exit-node list --filter=us 2>/dev/null \
            | awk '{ for (i = 1; i <= NF; i++) if ($i ~ /^100\./) { print $i; break } }'
    )
    [[ ${#nodes[@]} -gt 0 ]] || return 1

    probe_dir=$(mktemp -d)
    trap 'rm -rf -- "$probe_dir"' RETURN

    for node in "${nodes[@]}"; do
        (
            latency=$(tailscale ping --c=1 --timeout=2s --until-direct=false "$node" 2>/dev/null \
                | awk '{ for (i = 1; i <= NF; i++) if ($i ~ /ms$/) { sub(/ms$/, "", $i); print $i; exit } }')
            [[ -n "$latency" ]] && printf '%s %s\n' "$latency" "$node"
        ) >"$probe_dir/$node" &
    done
    wait || true

    best=$(sort -n "$probe_dir"/* 2>/dev/null | awk 'NF >= 2 { print $2; exit }')
    [[ -n "$best" ]] || return 1
    printf '%s\n' "$best"
}

tailscale_status () {
    tailscale status --json 2>/dev/null \
        | jq -e '.BackendState == "Running"' >/dev/null 2>&1
}

toggle_status () {
    if tailscale_status; then
        tailscale down
    else
        printf '%s\n' "$EPOCHSECONDS" >"$CONNECTING_STATE"
        trap 'rm -f -- "$CONNECTING_STATE"' EXIT
        notify_waybar
        exit_node=$(fastest_us_exit_node || printf '%s' "$MULLVAD_EXIT_NODE")
        tailscale up --accept-dns --exit-node="$exit_node"
    fi
    sleep 5
    notify_waybar
}

case "${1:-}" in
    --status)
        if connecting_status; then
            echo '{"text":"connecting…","class":"connecting","alt":"connecting", "tooltip":"Finding the fastest US VPN endpoint…"}'
        elif tailscale_status; then
            T=${2:-"green"}
            F=${3:-"red"}

            peers=$(tailscale status --json 2>/dev/null | jq -r --arg T "$T" --arg F "$F" '.Peer[]? | ("<span color=" + (if .Online then $T else $F end) + ">" + (.DNSName | split(".")[0]) + "</span>")' | tr '\n' '\r')
            exitnode=$(tailscale status --json 2>/dev/null | jq -r '.Peer[]? | select(.ExitNode == true).DNSName | split(".")[0]')
            [[ -n "$exitnode" && "$exitnode" != "null" ]] || exitnode="Mullvad"
            echo "{\"text\":\"${exitnode}\",\"class\":\"connected\",\"alt\":\"connected\", \"tooltip\": \"${peers}\"}"
        else
            echo "{\"text\":\"\",\"class\":\"stopped\",\"alt\":\"stopped\", \"tooltip\": \"The VPN is not active.\"}"
        fi
    ;;
    --toggle)
        toggle_status
    ;;
esac
