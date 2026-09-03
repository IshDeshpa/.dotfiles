#!/usr/bin/env bash
set -euo pipefail

# Only keep a Mullvad exit node when Cloudflare Tunnel can reach an edge
# through it. Cloudflare Tunnel requires outbound TCP or UDP port 7844;
# this script probes TCP/7844 because cloudflared is configured for HTTP/2.

readonly ROUTE_PROBE_IP="198.41.192.167"
readonly -a CLOUDFLARE_PROBE_HOSTS=(
  "region1.v2.argotunnel.com"
  "region2.v2.argotunnel.com"
)
readonly PROBE_CONNECT_TIMEOUT="${PROBE_CONNECT_TIMEOUT:-5}"
readonly MAX_EXIT_NODE_ATTEMPTS="${MAX_EXIT_NODE_ATTEMPTS:-12}"

log() {
  printf '[%s] %s\n' "$(date --iso-8601=seconds)" "$*"
}

restart_cloudflared() {
  # The script normally runs as a root systemd service. Do not fail an
  # interactive invocation merely because it cannot manage system services.
  if [[ $EUID -eq 0 ]] && command -v systemctl >/dev/null; then
    systemctl reset-failed cloudflared.service || true
    systemctl restart --no-block cloudflared.service || true
  fi
}

wait_for_exit_route() {
  local expected_node="$1"
  local attempt active_node status_output
  for attempt in {1..15}; do
    status_output="$(tailscale status 2>/dev/null || true)"
    active_node="$(
      awk '/active; exit node/ {print $2; exit}' <<<"$status_output"
    )"
    if [[ "$active_node" == "$expected_node" ]] &&
      ip -4 route get "$ROUTE_PROBE_IP" 2>/dev/null | grep -q 'dev tailscale0'; then
      return 0
    fi
    sleep 1
  done
  return 1
}

cloudflare_is_reachable() {
  local host
  for host in "${CLOUDFLARE_PROBE_HOSTS[@]}"; do
    # Test only whether TCP/7844 accepts a connection. A generic HTTPS request
    # is not a valid Tunnel handshake and some edges close it with a nonzero
    # curl result even though the required port is reachable.
    if timeout "${PROBE_CONNECT_TIMEOUT}s" \
      bash -c 'exec 3<>"/dev/tcp/$1/7844"' bash "$host" 2>/dev/null; then
      log "Cloudflare TCP/7844 reachable through exit node: $host"
      return 0
    fi
  done
  return 1
}

for command in tailscale shuf ip grep awk timeout bash; do
  if ! command -v "$command" >/dev/null; then
    log "Required command not found: $command"
    exit 1
  fi
done

log "random-exit-node starting as $(id -un) (uid=$(id -u))"
EXIT_NODE_LIST="$(tailscale exit-node list)"

# `tailscale exit-node list` places the node name in column two. Shuffle the
# complete candidate set so an unreachable node does not become sticky.
mapfile -t NODES < <(
  printf '%s\n' "$EXIT_NODE_LIST" |
    awk 'tolower($0) ~ /mullvad/ && $2 != "" {print $2}' |
    shuf
)

if ((${#NODES[@]} == 0)); then
  log "No Mullvad exit nodes found; using the direct route."
  tailscale set --exit-node=
  restart_cloudflared
  exit 0
fi

log "Testing up to $MAX_EXIT_NODE_ATTEMPTS of ${#NODES[@]} Mullvad exit-node candidates"
attempts=0
for node in "${NODES[@]}"; do
  ((attempts += 1))
  if ((attempts > MAX_EXIT_NODE_ATTEMPTS)); then
    break
  fi

  log "Trying Mullvad exit node: $node"
  if ! tailscale set --exit-node="$node"; then
    log "Could not select exit node: $node"
    continue
  fi

  if ! wait_for_exit_route "$node"; then
    log "Tailscale route did not become active for: $node"
    continue
  fi

  if cloudflare_is_reachable; then
    log "Selected working Mullvad exit node: $node"
    restart_cloudflared
    exit 0
  fi

  log "Cloudflare TCP/7844 is unreachable through: $node"
done

# Availability wins over a VPN route that breaks the tunnel. Returning success
# prevents Restart=on-failure from cycling through every node every 15 seconds.
log "No Mullvad exit node could reach Cloudflare TCP/7844; using direct routing."
tailscale set --exit-node=
restart_cloudflared
exit 0
