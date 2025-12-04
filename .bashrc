# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

alias nvmi='nvim'
alias vi='nvim'
alias vim='nvim'
alias cd='z'
alias cdi='zi'
alias firefox='firefox-developer-edition'
# no need if you use uv
#alias pyvenv='[ -n "$VIRTUAL_ENV" ] && echo "Already in a virtualenv: $VIRTUAL_ENV" || { [ -d venv ] && echo "Activating existing venv..." || { echo "Creating venv..."; python -m venv venv; }; source venv/bin/activate; }; pip install -r requirements.txt'
alias pptpdf='soffice --headless --convert-to pdf'

eval "$(starship init bash)"
eval "$(zoxide init bash)"

export PATH="/home/$USER/bin:/home/$USER/.cargo/bin:/home/ishdeshpa/mnt/Work/OS/yash-grading-f25/yash:$PATH"

export PINTOS=/mnt/Work/OS/pintos-dry
export PATH=$PATH:$PINTOS/utils

export UV_CACHE_DIR=/mnt/.uvcache

alias ff='fastfetch --logo /home/ishdeshpa/.dotfiles/archppuccin.png --logo-width 30 --logo-height 15' 

ff
