check:
    nix flake check --show-trace --all-systems

build-iso-x86:
    nix build -L .#nixosConfigurations.iso-x86.config.system.build.isoImage
    ls -l ./result/iso

build-iso-arm:
    nix build -L .#nixosConfigurations.iso-arm.config.system.build.isoImage
    ls -l ./result/iso

build-disk-x86:
    nix build -L .#nixosConfigurations.disk-x86.config.system.build.diskImage
    ls -l ./result/disk

# build-disk-arm:
#     nix build -L .#nixosConfigurations.disk-arm.config.system.build.diskImage
#     ls -l ./result/disk
