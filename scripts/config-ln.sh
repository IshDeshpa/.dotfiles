#!/bin/bash
SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
DEST="$HOME/.config"

systemctl enable ly.service
systemctl enable NetworkManager.service

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

ln -sf "$REPO_ROOT/.bashrc" "$HOME/.bashrc"
