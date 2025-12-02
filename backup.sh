#!/bin/bash

outfile="$HOME/.dotfiles/package-list.txt"

# Save explicitly installed packages (repo + AUR)
yay -Qqe > "$outfile"
echo "Saved to $outfile"
