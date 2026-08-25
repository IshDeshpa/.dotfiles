{ lib, pkgs, ... }:

{
  # This module is deliberately independent of the physical machine's disk
  # UUIDs. The NixOS VM builder creates and formats this virtual disk.
  fileSystems."/" = {
    device = lib.mkForce "/dev/vda";
    fsType = "ext4";
  };

  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
  boot.loader.grub = {
    enable = true;
    device = "/dev/vda";
  };

  networking.hostName = lib.mkForce "nix-vm";
  # Disposable VM credential only; do not reuse it outside this guest.
  users.users.ishdeshpa.password = "nixos";
  services.fprintd.enable = false;
  security.pam.services.login.fprintAuth = false;
  security.pam.services.ly = {
    fprintAuth = false;
    unixAuth = true;
    enableGnomeKeyring = false;
  };
  security.pam.services.login.enableGnomeKeyring = false;
  virtualisation.vmVariant = {
    virtualisation = {
      memorySize = 4096;
      cores = 4;
      diskSize = 16384;
      qemu.package = pkgs.qemu_full;
      qemu.options = [
        "-display" "sdl,gl=on"
        "-device" "virtio-vga-gl"
      ];
    };
  };
}
