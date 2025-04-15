#!/bin/sh

sudo mount /dev/nvme0n1p1 /boot
sudo nixos-rebuild --flake ./nixos switch

