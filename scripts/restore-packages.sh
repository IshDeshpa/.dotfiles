#!/bin/bash

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 {minimal|base|full|/path/to/pkglist}"
    exit 1
fi

SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
DEST="$HOME/.config"

case "$1" in
    server)  PKG_FILE="$REPO_ROOT/package-list-server.txt" ;;
    minimal) PKG_FILE="$REPO_ROOT/package-list-minimal.txt" ;;
    base)    PKG_FILE="$REPO_ROOT/package-list-base.txt" ;;
    full)    PKG_FILE="$REPO_ROOT/package-list-full.txt" ;;
    *)       PKG_FILE="$1" ;;  # direct file path
esac

if [ ! -f "$PKG_FILE" ]; then
    echo "Package list not found: $PKG_FILE"
    exit 1
fi

yay -Sy rustup
rustup default stable

yay -Sy --needed - < "$PKG_FILE"

"$REPO_ROOT/scripts/cleanup.sh"
