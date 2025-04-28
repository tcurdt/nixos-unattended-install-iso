These image WIPE the target disk! Be careful!
And then installs NixOS on it.

# Build an ISO image

```bash
nix build -L .#packages.x86_64-linux.iso
nix build -L .#packages.x86_64-linux.raw

find ./result
````


# Credits

based on https://gitlab.com/misuzu/nixos-unattended-install-iso
