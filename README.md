## Build the ISO image

```bash
nix build -L .#nixosConfigurations.iso-x86.config.system.build.isoImage
nix build -L .#nixosConfigurations.iso-arm.config.system.build.isoImage
ls -l ./result/iso
````

## Run QEMU with the ISO image

```bash
nix run -L .
````

based on https://gitlab.com/misuzu/nixos-unattended-install-iso