#!/usr/bin/env bash
set -euo pipefail

echo "[$(date --iso-8601=seconds)] random-exit-node starting"
echo "[$(date --iso-8601=seconds)] user: $(id -un) (uid=$(id -u))"
echo "[$(date --iso-8601=seconds)] PATH: ${PATH}"
echo "[$(date --iso-8601=seconds)] tailscale: $(command -v tailscale || echo 'not found')"

# Get list of Mullvad exit nodes from Tailscale
# Expected output format includes lines like:
# mullvad-us-lax-001   100.xxx.xxx.xxx   ...
echo "[$(date --iso-8601=seconds)] Running: tailscale exit-node list"
EXIT_NODE_LIST="$(tailscale exit-node list)"
echo "[$(date --iso-8601=seconds)] Raw exit-node list:"
printf '%s\n' "${EXIT_NODE_LIST}"

mapfile -t NODES < <(
  printf '%s\n' "${EXIT_NODE_LIST}" |
    awk '/mullvad/ {print $2}'
)

echo "[$(date --iso-8601=seconds)] Parsed Mullvad nodes: ${#NODES[@]}"
if ((${#NODES[@]} > 0)); then
  printf '[%s] node: %s\n' "$(date --iso-8601=seconds)" "${NODES[@]}"
fi

if [[ ${#NODES[@]} -eq 0 ]]; then
  echo "[$(date --iso-8601=seconds)] No Mullvad exit nodes found."
  exit 1
fi

# Pick a random node
RANDOM_INDEX=$((RANDOM % ${#NODES[@]}))
RANDOM_NODE="${NODES[RANDOM_INDEX]}"

echo "[$(date --iso-8601=seconds)] Selected index: ${RANDOM_INDEX}"
echo "[$(date --iso-8601=seconds)] Setting Mullvad exit node to: ${RANDOM_NODE}"
tailscale set --exit-node="$RANDOM_NODE"
echo "[$(date --iso-8601=seconds)] tailscale set completed successfully"
