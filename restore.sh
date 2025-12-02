#!/bin/bash

yay -Sy --needed - < $HOME/.dotfiles/package-list.txt
$HOME/.dotfiles/cleanup.sh

