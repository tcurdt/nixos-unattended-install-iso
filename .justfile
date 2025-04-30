set dotenv-load

# list targets
help:
  @just --list

check:
    nix flake check --show-trace --all-systems

build-iso-x86:
    nix build -L .#packages.x86_64-linux.iso

build-raw-x86:
    nix build -L .#packages.x86_64-linux.raw

# list images on hetzner
images:
    hcloud image list --output columns=id,description,type,labels

upload:
    hcloud-upload-image upload \
        --image-path nixos-hetzner-x86.img.xz \
        --architecture x86 \
        --compression xz \
        --description "nixos" \
        --labels nixos=24.11
