{ lib, ... }:

{
  # This intentionally contains only portable boot/filesystem defaults. For a
  # physical install, replace this file with `nixos-generate-config` output so
  # the exact disk UUIDs, initrd modules, and GPU firmware are captured.
  boot.initrd.availableKernelModules = [ "ahci" "nvme" "xhci_pci" "usbhid" "usb_storage" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    options = [ "defaults" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [ ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
