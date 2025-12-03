#!/bin/bash

set -e

SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
DEST="$HOME/.config"

echo "Select package list:"
echo "  1) minimal"
echo "  2) base"
echo "  3) full"
read -r -p "Enter choice [1-3]: " choice

case "$choice" in
    1) PKG_FILE="$REPO_ROOT/package-list-minimal.txt" ;;
    2) PKG_FILE="$REPO_ROOT/package-list-base.txt" ;;
    3) PKG_FILE="$REPO_ROOT/package-list-full.txt" ;;
    *) echo "Invalid selection"; exit 1 ;;
esac

yay -Sy --needed - < "$PKG_FILE"
"$REPO_ROOT/scripts/cleanup.sh"

for dir in "$REPO_ROOT"/*; do
    [ -d "$dir" ] || continue

    name="$(basename "$dir")"
    target="$DEST/$name"

    if [ -L "$target" ] || [ -e "$target" ]; then
        echo "Skipping $name (already exists)"
        continue
    fi

    ln -s "$dir" "$target"
    echo "Linked $name → $target"
done
