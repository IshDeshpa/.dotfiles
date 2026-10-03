#!/bin/bash
SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
DEST="$HOME/.config"
mkdir -p "$DEST"

sudo systemctl enable ly.service
sudo systemctl enable NetworkManager.service

for dir in "$REPO_ROOT"/*; do
    [ -d "$dir" ] || continue

    name="$(basename "$dir")"
    target="$DEST/$name"

    # Never nest links inside an existing directory or directory symlink.
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        echo "Skipped $name: $target already exists and is not a symlink" >&2
        continue
    fi

    if ln -sfnT "$dir" "$target"; then
        echo "Linked $name → $target"
    else
        exit 1
    fi
done

ln -sf "$REPO_ROOT/.bashrc" "$HOME/.bashrc"
