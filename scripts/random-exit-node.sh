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
MODE="${1:---cloudflare}"
REGION="all"
if [[ "$MODE" == --internet && "${2:-}" == --region=* ]]; then
  REGION="${2#--region=}"
fi
case "$MODE" in
  --cloudflare|--internet) ;;
  *) printf 'Usage: %s [--cloudflare|--internet]\n' "$0" >&2; exit 2 ;;
esac
case "$REGION" in
  all|us|non-us) ;;
  *) printf 'Unknown region: %s\n' "$REGION" >&2; exit 2 ;;
esac

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

# Measure small HTTPS requests through the selected route. This favors
# responsiveness, not bulk-download throughput, and bypasses proxy variables.
internet_latency() {
  local url result code elapsed
  for url in https://www.google.com/generate_204 https://example.com/; do
    if result=$(curl --noproxy '*' --silent --show-error --output /dev/null \
      --connect-timeout 3 --max-time 5 --write-out '%{http_code} %{time_total}' \
      "$url" 2>/dev/null); then
      read -r code elapsed <<<"$result"
      if [[ "$code" == 200 || "$code" == 204 ]]; then
        printf '%s\n' "$elapsed"
        return 0
      fi
    fi
  done
  return 1
}

select_internet_node() (
  local node elapsed choice probe_dir index=0
  local -a scores=() ranked=() candidates=("${NODES[@]}")
  probe_dir=$(mktemp -d)
  trap 'rm -rf -- "$probe_dir"' EXIT
  # Probe peers concurrently without changing the shared exit route. Bound
  # each worker so unreachable peers cost one timeout, not one-at-a-time.
  log "Ranking ${#candidates[@]} exit nodes by ping speed"
  for node in "${candidates[@]}"; do
    (
      if elapsed=$(timeout 3s tailscale ping --c=1 --timeout=2s --until-direct=false "$node" 2>/dev/null |
        awk '/^pong from / {for (i = 1; i <= NF; i++) if ($i ~ /^[0-9]+([.][0-9]+)?ms$/) {sub(/ms$/, "", $i); print $i; exit}}') &&
        [[ -n "$elapsed" ]]; then
        printf '%s %s\n' "$elapsed" "$node"
      fi
    ) >"$probe_dir/$index" &
    ((index += 1))
  done
  wait
  for ((index = 0; index < ${#candidates[@]}; index++)); do
    if read -r elapsed node <"$probe_dir/$index"; then
      scores+=("$elapsed $node")
    fi
  done
  if ((${#scores[@]})); then
    # Pick randomly from the ten fastest measured exit nodes. Keep the
    # ranking based on the latency reported by tailscale ping.
    mapfile -t ranked < <(
      printf '%s\n' "${scores[@]}" | sort -n | head -n 10 | awk '{print $2}' | shuf
    )
  fi
  # Only actual internet checks need route switches. If a fast candidate is
  # unusable, try the next one within the ranked top ten.
  local -A tested=()
  for choice in "${ranked[@]}"; do
    [[ -z "${tested[$choice]:-}" ]] || continue
    tested[$choice]=1
    if tailscale set --exit-node="$choice" && wait_for_exit_route "$choice" &&
      internet_latency >/dev/null; then
      log "Selected responsive random exit node: $choice"
      return 0
    fi
  done
  log "No working top-ten exit node found; clearing the exit route."
  tailscale set --exit-node=
  return 1
)

for command in tailscale shuf ip grep awk timeout bash; do
  if ! command -v "$command" >/dev/null; then
    log "Required command not found: $command"
    exit 1
  fi
done
if [[ "$MODE" == --internet ]] && ! command -v curl >/dev/null; then
  log "Required command not found: curl"
  exit 1
fi

log "random-exit-node starting as $(id -un) (uid=$(id -u)); region=$REGION"
EXIT_NODE_LIST="$(tailscale exit-node list)"

declare -A US_NODES=()
if [[ "$REGION" == non-us ]]; then
  while read -r node; do
    [[ -n "$node" ]] && US_NODES["$node"]=1
  done < <(
    tailscale exit-node list --filter=us 2>/dev/null |
      awk 'tolower($0) ~ /mullvad/ && $2 != "" {print $2}'
  )
elif [[ "$REGION" == us ]]; then
  EXIT_NODE_LIST="$(tailscale exit-node list --filter=us)"
fi

# `tailscale exit-node list` places the node name in column two. Shuffle the
# complete candidate set so an unreachable node does not become sticky.
if [[ "$REGION" == non-us ]]; then
  mapfile -t NODES < <(
    printf '%s\n' "$EXIT_NODE_LIST" |
      awk 'tolower($0) ~ /mullvad/ && $2 != "" {print $2}' |
      while read -r node; do
        [[ -z "${US_NODES[$node]:-}" ]] && printf '%s\n' "$node"
      done |
      shuf
  )
else
  mapfile -t NODES < <(
    printf '%s\n' "$EXIT_NODE_LIST" |
      awk 'tolower($0) ~ /mullvad/ && $2 != "" {print $2}' |
      shuf
  )
fi

if [[ "$MODE" == --internet ]]; then
  select_internet_node
  exit $?
fi

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
