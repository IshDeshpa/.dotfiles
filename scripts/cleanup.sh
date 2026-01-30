#!/bin/bash
set +e

yay -Rsn $(yay -Qdtq)
yay -Syy
yay -Scc
rm -rf ~/.cache/*
journalctl --vacuum-time=7d
