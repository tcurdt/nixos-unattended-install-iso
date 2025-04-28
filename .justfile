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
