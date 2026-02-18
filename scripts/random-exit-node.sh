#!/usr/bin/env bash
set -euo pipefail

# Get list of Mullvad exit nodes from Tailscale
# Expected output format includes lines like:
# mullvad-us-lax-001   100.xxx.xxx.xxx   ...
mapfile -t NODES < <(
  tailscale exit-node list \
    | awk '/mullvad/ {print $2}'
)

if [[ ${#NODES[@]} -eq 0 ]]; then
  echo "No Mullvad exit nodes found."
  exit 1
fi

# Pick a random node
RANDOM_NODE="${NODES[RANDOM % ${#NODES[@]}]}"

echo "Setting Mullvad exit node to: $RANDOM_NODE"
tailscale set --exit-node="$RANDOM_NODE"
