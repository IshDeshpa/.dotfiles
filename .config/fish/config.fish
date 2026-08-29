# Interactive Fish configuration.
# Existing automation remains Bash-based; this file only configures the
# interactive login shell.

set -gx LC_ALL en_US.UTF-8
set -gx LANG en_US.UTF-8
set -gx EDITOR nvim
set -gx PINTOS /mnt/Work/OS/pintos-dry
set -gx UV_CACHE_DIR /mnt/.uvcache
set -gx SSH_AUTH_SOCK "$XDG_RUNTIME_DIR/ssh-agent.socket"
set -gx STM32_PRG_PATH /home/ishdeshpa/stm32cubeprog/bin

fish_add_path \
    "/home/$USER/bin" \
    /home/ishdeshpa/.cargo/bin \
    /home/ishdeshpa/mnt/Work/OS/yash-grading-f25/yash \
    "$PINTOS/utils"

if status is-interactive
    alias vi nvim
    alias vim nvim
    alias vih 'obsidian ~/mnt/vault/home.md'
    alias ll 'ls -lha'
    alias firefox firefox-developer-edition
    alias nm nmtui
    alias bt bluetui
    alias pptpdf 'soffice --headless --convert-to pdf'
    alias icat 'kitten icat'
    alias cleanup '~/.dotfiles/scripts/cleanup.sh'
    alias update '~/.dotfiles/scripts/update.sh'
    alias dmesg 'sudo dmesg --decode --nopager --color --ctime'
    alias ff 'fastfetch --logo /home/ishdeshpa/.dotfiles/archppuccin.png --logo-width 30 --logo-height 15'

    zoxide init fish | source
    alias cd z
    alias cdi zi

    ff
end
