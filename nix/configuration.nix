{ config, lib, pkgs, dotfiles, ... }:

let
  optionalPackage = name:
    lib.optional (builtins.hasAttr name pkgs) (builtins.getAttr name pkgs);
in
{
  system.stateVersion = "25.11";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages;

  networking.hostName = "arch-fw";
  networking.networkmanager.enable = true;
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  users.users.ishdeshpa = {
    isNormalUser = true;
    description = "ishdeshpa";
    extraGroups = [ "wheel" "networkmanager" "audio" "video" "docker" ];
    shell = pkgs.bash;
  };
  security.sudo.wheelNeedsPassword = true;

  programs.niri.enable = true;
  programs.niri.package = pkgs.niri;
  services.displayManager.ly.enable = true;
  services.power-profiles-daemon.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  services.udisks2.enable = true;
  services.fwupd.enable = true;
  hardware.bluetooth.enable = true;
  virtualisation.docker.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
    configPackages = [ pkgs.xdg-desktop-portal-gnome ];
  };

  environment.systemPackages = with pkgs; [
    _7zz
    bash-completion
    brightnessctl
    dmidecode
    fastfetch
    fd
    firefox-devedition
    git
    github-cli
    gnumake
    inetutils
    iwd
    kitty
    linux-firmware
    lshw
    man-db
    man-pages
    mesa-demos
    nano
    neovim
    networkmanagerapplet
    niri
    noto-fonts
    nodejs
    openssh
    pavucontrol
    pipewire
    python3
    ripgrep
    rustup
    sshfs
    starship
    sudo
    swaybg
    swayidle
    swaylock
    tmux
    tree
    unzip
    usbutils
    valgrind
    waybar
    wget
    which
    wl-clipboard
    wlr-randr
    xdg-utils
    xwayland
    zip
    zoxide
  ] ++ optionalPackage "fuzzel"
    ++ optionalPackage "mako"
    ++ optionalPackage "xwayland-satellite"
    ++ optionalPackage "nirinit"
    ++ optionalPackage "playerctl"
    ++ optionalPackage "jq";

  fonts.packages = with pkgs; [
    fira-code
    nerd-fonts.jetbrains-mono
    noto-fonts
  ];

  environment.etc."dotfiles-source".text = "${dotfiles}\n";

  # The original setup enables these at the host level. NixOS owns the
  # equivalent services declaratively; Ly and NetworkManager are enabled above.
  systemd.services.nix-daemon = {
    enable = true;
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
}
