#!/bin/bash
SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
DEST="$HOME/.config"

sudo systemctl enable ly.service
sudo systemctl enable NetworkManager.service

for dir in "$REPO_ROOT"/*; do
    [ -d "$dir" ] || continue

    name="$(basename "$dir")"
    target="$DEST/$name"

    ln -sf "$dir" "$target"
    echo "Linked $name → $target"
done

ln -sf "$REPO_ROOT/.bashrc" "$HOME/.bashrc"
