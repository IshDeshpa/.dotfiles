# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  nix = {
    package = pkgs.nixVersions.stable;
    settings.auto-optimise-store = true;
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 7d";
    };
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  imports =
    [ # Include the results of the hardware scan.
     # <nixos-hardware/framework/13-inch/cpu/7040-amd>
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Chicago";

  services.fwupd.enable = true;
  services.spotifyd = {
   enable = true;
   settings ={
     global = {
       username = "ishdeshpa";
       password = "deshpande39";
     };
   };
  };

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Configure keymap in X11
  #services.xserver.xkb = {
  #  layout = "us";
  #  variant = "";
  #};

  programs.niri.enable = true;
  programs.light.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.ishdeshpa = {
    isNormalUser = true;
    description = "Ishan Deshpande";
    extraGroups = [ "wheel" "audio" "video" "networkmanager" "docker" ];
    packages = with pkgs; [];
  };

  fileSystems."/boot" =
    { device = "/dev/nvme0n1p1";
      fsType = "vfat";
    };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
  ];  
 
  environment.systemPackages = with pkgs; [
    # basic
    vim
    neovim
    wget
    networkmanager
    git
    zip
    unzip
    tmux
    gcc # gcc
    rustup # rust (cargo)
    playerctl # media keys
    light # brightness
    firefox-devedition-bin
    spotify-player
    # environment
    alacritty
    fuzzel
    waybar
    swaylock-effects
    # media ctrl
    bluez
    pavucontrol
    # other
    xdg-desktop-portal-gtk # required for waybar & other flatpak-style sandboxed apps
    xdg-desktop-portal-gnome
    gnome-keyring
  ];

  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot

  systemd.user.services.mpris-proxy = {
    description = "Mpris proxy";
    after = [ "network.target" "sound.target" ];
    wantedBy = [ "default.target" ];
    serviceConfig.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
  };

  services.blueman.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}
