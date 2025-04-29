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
    optimise = {
      automatic = true;
      dates = ["daily"];
    };
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = true;

  networking.hostName = "nixos"; # Define your hostname.
  
  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # List services that you want to enable:
  swapDevices = [
    {
      device = "/var/lib/swap/swapfile";
      priority = 100;
    }
  ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  services.fwupd.enable = true;
  
  services.avahi = {
    enable = true;
    nssmdns4 = true; # allow .local hostnames to be resolved
    publish.enable = true; # optional, if you want your machine discoverable too
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    jack.enable = true;
  };

  systemd.user.services.mpris-proxy = {
    description = "Mpris proxy";
    after = [ "network.target" "sound.target" ];
    wantedBy = [ "default.target" ];
    serviceConfig.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
  };

  services.blueman.enable = true;

  services.logind = {
    lidSwitch = "suspend"; # already maps to HandleLidSwitch=suspend
    extraConfig = ''
      HandleLidSwitchDocked=ignore
      IdleAction=hybrid-sleep
      IdleActionSec=15min
    '';
  };
  
  virtualisation.docker.enable = true;
  virtualisation.docker.rootless = {
      enable = true;
      setSocketVariable = true;
  };

  virtualisation.libvirtd.enable = true;

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

  programs.niri.enable = true;
  programs.light.enable = true;
  
  users.groups.plugdev = {};
  users.groups.vboxusers = {};

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.ishdeshpa = {
    isNormalUser = true;
    description = "Ishan Deshpande";
    extraGroups = [ "wheel" "audio" "video" "networkmanager" "docker" "jackaudio" "plugdev" "vboxusers" ];
    packages = with pkgs; [];
    shell = pkgs.bash;
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
    nano
    wget
    killall
    wl-clipboard
    networkmanager
    networkmanagerapplet
    git
    zip
    unzip
    ripgrep # for live grep -- searching across all file content in dir
    dos2unix # for awesome
    tmux
    bear # for generating compile_commands
    lm4flash
    gcc # gcc
    clang-tools
    gdb
    gcc-arm-embedded # arm-none-eabi-gcc
    gnumake
    openocd    
    rustup # rust (cargo)
    python314 # python
    playerctl # media keys
    pulseaudio # audio control
    light # brightness
    tshark # terminal wireshark
    fw-ectool
    fwupd
    firefox-devedition-bin
    spotify-player
    spotifyd
    slack
    legcord
    bitwarden
    docker
    pinta
    cheese # basic camera
    realvnc-vnc-viewer
    subversion
    rapidsvn
    inetutils
    #fuzzmoji # emoji picker
    nmap
    sway-contrib.grimshot # screenshot
    (vscode-with-extensions.override {
      vscodeExtensions = with vscode-extensions; [
        bbenoist.nix
        ms-python.python
        ms-azuretools.vscode-docker
        ms-vscode-remote.remote-ssh
      ];
    })
    # environment
    alacritty # terminal
    fuzzel # fuzzy finder
    waybar # toolbar
    mako # notifications
    swaylock-effects
    xwayland-satellite
    # media ctrl
    bluez
    pavucontrol
    # other
    xdg-desktop-portal-gtk # required for waybar & other flatpak-style sandboxed apps
    xdg-desktop-portal-gnome
    gnome-keyring
    rpi-imager
    reaper # music production
    stlink
    virtualbox
  ];
  
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="1234", MODE="0666"
    SUBSYSTEM=="usb_device", ATTRS{idVendor}=="1234", MODE="0666"
  '';

  # enables slack (prolly electron) with wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  
  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot
 
   # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  systemd.sleep.extraConfig = ''
    AllowSuspend=yes
    AllowHibernation=yes
    AllowHybridSleep=yes
    AllowSuspendThenHibernate=yes
    HibernateDelaySec=1h
  '';

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
