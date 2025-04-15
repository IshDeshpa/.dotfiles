{
  description = "flake for nixos";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };
  };

  outputs = { self, nixpkgs, nixos-hardware }: {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
	  nixos-hardware.nixosModules.framework-13-7040-amd
          ./configuration.nix
        ];
      };
    };
  };
}
