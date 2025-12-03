#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"

outfile="$REPO_ROOT/package-list-full.txt"

# Save explicitly installed packages (repo + AUR)
yay -Qqe > "$outfile"
echo "Saved to $outfile"
