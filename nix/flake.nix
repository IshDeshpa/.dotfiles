{
  description = "NixOS bootstrap for the ishdeshpa desktop dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager }:
    let
      system = "x86_64-linux";
    in {
      nixosConfigurations.arch-fw = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { dotfiles = ../.; };
        modules = [
          ./configuration.nix
          ./hardware-configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.ishdeshpa = import ./home.nix;
          }
        ];
      };

      nixosConfigurations.vm = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { dotfiles = ../.; };
        modules = [
          ./configuration.nix
          ./vm.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.ishdeshpa = import ./home.nix;
          }
        ];
      };
    };
}
