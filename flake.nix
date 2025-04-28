{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  # inputs.disko.url = "github:nix-community/disko/master";
  # inputs.disko.inputs.nixpkgs.follows = "nixpkgs";

  outputs =
    inputs:
    let
    in
    # pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    # inherit (pkgs) lib;
    # make-disk-image = import "${inputs.nixpkgs}/nixos/lib/make-disk-image.nix";
    {
      nixosConfigurations = {

        nixos-x86 = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            # inputs.disko.nixosModules.disko
            ./configuration.nix
            # ./make-disk-image.nix
          ];
          # disko.devices.disk.main.device = "/dev/sda";
        };

        nixos-arm = inputs.nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            # inputs.disko.nixosModules.disko
            ./configuration.nix
          ];
          # disko.devices.disk.main.device = "/dev/sda";
        };

        iso-x86 = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            targetSystem = inputs.self.nixosConfigurations.nixos-x86;
          };
          modules = [
            ./iso.nix
          ];
        };

        iso-arm = inputs.nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = {
            targetSystem = inputs.self.nixosConfigurations.nixos-arm;
          };
          modules = [
            ./iso.nix
          ];
        };

        # disk-x86 = inputs.nixpkgs.lib.nixosSystem {
        #   system = "x86_64-linux";
        #   specialArgs = {
        #     targetSystem = inputs.self.nixosConfigurations.nixos-x86;
        #   };
        #   modules = [
        #     ./raw.nix
        #   ];
        # };

        # disk-x86 = make-disk-image {
        #   inherit pkgs lib; # where should these come from?
        #   config = inputs.self.nixosConfigurations.nixos-x86.config;
        #   name = "nixos-cloud-x86";
        #   format = "qcow2-compressed";
        #   copyChannel = false;
        #   additionalSpace = "10G";
        # };

      };

    };
}
