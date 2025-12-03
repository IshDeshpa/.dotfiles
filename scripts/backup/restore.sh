#!/bin/bash

yay -Sy --needed - < $HOME/.dotfiles/package-list.txt
$HOME/.dotfiles/cleanup.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
DEST="$HOME/.config"

for dir in "$SRC"/*; do
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
