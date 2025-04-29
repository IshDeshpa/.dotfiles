#!/bin/sh

sudo nixos-rebuild --flake /home/ishdeshpa/.dotfiles/nixos#ishdeshpa switch --show-trace $@

