#!/bin/bash
yay -Suu
yay -Rsn $(yay -Qdtq)
yay -Syy
yay -Scc

rm -rf ~/.cache
