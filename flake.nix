{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = inputs: {
    nixosConfigurations = {

      nixos-x86 = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
        ];
      };

      nixos-arm = inputs.nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          ./configuration.nix
        ];
      };


      iso-x86 = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          targetSystem = inputs.self.nixosConfigurations.nixos;
        };
        modules = [
          ./iso.nix
        ];
      };

      iso-arm = inputs.nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = {
          targetSystem = inputs.self.nixosConfigurations.nixos;
        };
        modules = [
          ./iso.nix
        ];
      };

    };

    # packages.x86_64-linux.default = let
    #   pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    # in pkgs.writeShellApplication {
    #   name = "iso-test";
    #   runtimeInputs = with pkgs; [
    #     qemu-utils
    #     qemu_kvm
    #   ];
    #   text = ''
    #     disk1=disk1.qcow2
    #     if [ ! -f $disk1 ]; then
    #       qemu-img create -f qcow2 $disk1 8G
    #     fi
    #     exec qemu-kvm \
    #       -boot c \
    #       -cpu host \
    #       -smp cores=2 \
    #       -M pc \
    #       -m 2G \
    #       -device virtio-balloon \
    #       -device virtio-rng-pci \
    #       -drive file=$disk1,format=qcow2,if=none,id=nvm \
    #       -device nvme,serial=deadbeef,drive=nvm \
    #       -bios ${pkgs.OVMF.fd}/FV/OVMF.fd \
    #       -cdrom "$(echo ${inputs.self.nixosConfigurations.iso-x86.config.system.build.isoImage}/iso/*.iso)"
    #   '';
    # };
  };
}
