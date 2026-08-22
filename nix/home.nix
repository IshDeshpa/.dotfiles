{ config, lib, pkgs, dotfiles, ... }:

let
  cfg = name: { source = dotfiles + ("/" + name); };
  nirinitService = lib.optionalAttrs (builtins.hasAttr "nirinit" pkgs) {
    Unit = {
      Description = "Nirinit session manager";
      After = [ "niri.service" ];
      PartOf = [ "niri.service" ];
      Requisite = [ "niri.service" ];
    };
    Service = {
      ExecStart = "${(builtins.getAttr "nirinit" pkgs)}/bin/nirinit --save-interval 300";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "niri.service" ];
  };
in
{
  home.username = "ishdeshpa";
  home.homeDirectory = "/home/ishdeshpa";
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    bat
    fzf
    jq
    stylua
    tldr
    typst
    uv
  ];

  home.file = {
    ".bashrc" = cfg ".bashrc";
    ".tmux.conf" = cfg ".tmux.conf";
    ".config/starship.toml" = cfg "starship.toml";
    ".config/kitty/kitty.conf" = cfg "kitty/kitty.conf";
    ".config/niri/config.kdl" = cfg "niri/config.kdl";
    ".config/niri/open.sh" = cfg "niri/open.sh";
    ".config/waybar/config.jsonc" = cfg "waybar/config.jsonc";
    ".config/waybar/style.css" = cfg "waybar/style.css";
    ".config/waybar/macchiato.css" = cfg "waybar/macchiato.css";
    ".config/waybar/waybar_timer" = cfg "waybar/waybar_timer";
    ".config/fuzzel/fuzzel.ini" = cfg "fuzzel/fuzzel.ini";
    ".config/fuzzel/blue.ini" = cfg "fuzzel/blue.ini";
    ".config/mako/config" = cfg "mako/config";
    ".config/swaylock/config" = cfg "swaylock/config";
    ".config/ly/config.ini" = cfg "ly/config.ini";
    ".config/fastfetch/config.jsonc" = cfg "fastfetch/config.jsonc";
    ".config/nvim" = cfg "nvim";
    ".config/tmux/plugins/catppuccin" = cfg "tmux/plugins/catppuccin/tmux";
    ".local/bin/dotfiles-cleanup" = cfg "scripts/cleanup.sh";
    ".local/bin/dotfiles-update" = cfg "scripts/update.sh";
    ".local/share/backgrounds/dark-cat-rosewater.png" = cfg "dark-cat-rosewater.png";
    ".local/share/backgrounds/archppuccin.png" = cfg "archppuccin.png";
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    QT_QPA_PLATFORM = "wayland";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    PINTOS = "/mnt/Work/OS/pintos-dry";
    UV_CACHE_DIR = "/mnt/.uvcache";
    STM32_PRG_PATH = "/home/ishdeshpa/stm32cubeprog/bin";
  };

  programs.home-manager.enable = true;
  programs.bash.enable = true;
  programs.git.enable = true;
  programs.starship.enable = true;
  programs.zoxide.enable = true;
  programs.tmux.enable = true;

  systemd.user.services.nirinit = nirinitService;

  systemd.user.services.swayidle = {
    Unit = {
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      Requisite = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = ''${pkgs.swayidle}/bin/swayidle -w timeout 240 '${pkgs.swaylock}/bin/swaylock --clock --indicator --screenshots --effect-scale 0.4 --effect-vignette 0.2:0.5 --effect-blur 4x2' timeout 360 '${pkgs.sway}/bin/swaymsg "output * dpms off"' resume '${pkgs.sway}/bin/swaymsg "output * dpms on"' idlehint 600 before-sleep '${pkgs.swaylock}/bin/swaylock -f -c 000000'';
      Restart = "on-failure";
    };
  };
}
