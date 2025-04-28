{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  # inputs.disko.url = "github:nix-community/disko/master";
  # inputs.disko.inputs.nixpkgs.follows = "nixpkgs";

  outputs =
    inputs:
    let
    in
    # pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    {
      nixosConfigurations = {

        nixos-x86 = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            # inputs.disko.nixosModules.disko
            ./configuration.nix
          ];
        };

        # nixos-arm = inputs.nixpkgs.lib.nixosSystem {
        #   system = "aarch64-linux";
        #   modules = [
        #     # inputs.disko.nixosModules.disko
        #     ./configuration.nix
        #   ];
        # };

        iso-x86 = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            targetSystem = inputs.self.nixosConfigurations.nixos-x86;
          };
          modules = [
            ./iso.nix
          ];
        };

        # iso-arm = inputs.nixpkgs.lib.nixosSystem {
        #   system = "aarch64-linux";
        #   specialArgs = {
        #     targetSystem = inputs.self.nixosConfigurations.nixos-arm;
        #   };
        #   modules = [
        #     ./iso.nix
        #   ];
        # };

        # raw-x86 = inputs.nixpkgs.lib.nixosSystem {
        #   system = "x86_64-linux";
        #   specialArgs = {
        #     targetSystem = inputs.self.nixosConfigurations.nixos-x86;
        #   };
        #   modules = [
        #     ./raw.nix
        #   ];
        # };

        raw-x86 = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            targetSystem = inputs.self.nixosConfigurations.nixos-x86;
          };
          modules = [
            ./raw.nix
          ];
        };
      };

      packages.x86_64-linux = {
        iso = inputs.self.nixosConfigurations.iso-x86.config.system.build.isoImage;
        raw = inputs.self.nixosConfigurations.raw-x86.config.system.build.diskImage;
      };

    };
}
