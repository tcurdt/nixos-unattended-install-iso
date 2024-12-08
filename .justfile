build-iso-x86:
    nix build -L .#nixosConfigurations.iso-x86.config.system.build.isoImage
    ls -l ./result/iso

build-iso-arm:
    nix build -L .#nixosConfigurations.iso-arm.config.system.build.isoImage
    ls -l ./result/iso

build-raw-x86:
    nix build -L .#nixosConfigurations.raw-x86.config.system.build.rawImage
    ls -l ./result/raw

build-raw-arm:
    nix build -L .#nixosConfigurations.raw-arm.config.system.build.rawImage
    ls -l ./result/raw
