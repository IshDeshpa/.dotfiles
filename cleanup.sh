#!/bin/sh

sudo nix-env --delete-generations old
sudo nix-store --gc
sudo nix-collect-garbage -d
