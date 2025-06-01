#!/bin/bash

git clone git@github.com:IshDeshpa/.dotfiles.git

ln -s /home/cc/.dotfiles/* /home/cc/.config/

sudo add-apt-repository ppa:neovim-ppa/unstable
sudo apt-get update
sudo apt-get install neovim

