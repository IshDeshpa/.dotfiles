#!/bin/bash

set -e

SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"

outfile="$REPO_ROOT/package-list-full.txt"
sed '/yay/d' $outfile

# Save explicitly installed packages (repo + AUR)
yay -Qqe > "$outfile"
echo "Saved to $outfile"
