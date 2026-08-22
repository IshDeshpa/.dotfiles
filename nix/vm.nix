{ lib, ... }:

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

  networking.hostName = "nix-vm";
  virtualisation = {
    memorySize = 4096;
    cores = 4;
    diskSize = 16384;
    qemu.options = [
      "-display gtk,gl=on"
      "-device virtio-vga-gl"
    ];
  };
}
