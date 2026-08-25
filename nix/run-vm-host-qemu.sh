#!/usr/bin/env bash
set -euo pipefail

runner="result/bin/run-nix-vm-vm"
if [[ "${1:-}" == "--runner" ]]; then
  runner="${2:?missing runner path}"
  shift 2
fi

host_qemu="$(command -v qemu-system-x86_64)"
[[ -x "$host_qemu" ]] || {
  echo "qemu-system-x86_64 was not found on the Arch host" >&2
  exit 1
}

[[ -f "$runner" || -L "$runner" ]] || {
  echo "VM runner not found: $runner" >&2
  exit 1
}

patched_runner="$(mktemp)"
trap 'rm -f "$patched_runner"' EXIT

# The generated runner otherwise uses Nix's QEMU, whose Mesa wrapper expects
# NixOS's /run/opengl-driver layout. Use Arch's native QEMU for host graphics.
sed -E "s#exec /nix/store/[^ ]+/bin/qemu-system-x86_64 #exec $host_qemu #" \
  "$(readlink -f "$runner")" > "$patched_runner"
chmod +x "$patched_runner"
exec "$patched_runner" "$@"
