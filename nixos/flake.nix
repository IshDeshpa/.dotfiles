{
  description = "flake for nixos";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixos-hardware, home-manager }: {
    nixosConfigurations.ishdeshpa = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
	        nixos-hardware.nixosModules.framework-13-7040-amd
          ./configuration.nix
          
          {
            nixpkgs.overlays = [
              #(import ./overlays/fuzzmoji.nix)
            ];
          }

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
