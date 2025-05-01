#!/bin/bash
yay -Syy
yay -Scc
yay -Suu
yay -Rsn $(yay -Qdtq)
