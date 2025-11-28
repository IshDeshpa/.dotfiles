#!/bin/bash
yay -Rsn $(yay -Qdtq)
yay -Syy
yay -Scc
rm -rf ~/.cache

yay -Suu

yay -Rsn $(yay -Qdtq)
yay -Syy
yay -Scc
rm -rf ~/.cache
