#!/bin/bash

# install yay
git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
pushd /tmp/yay-bin
sudo pacman -S --needed base-devel
makepkg -si
popd

# run restore script
./restore.sh
