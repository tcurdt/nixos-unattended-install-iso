{ config, pkgs, lib, modulesPath, targetSystem, ... }:
let
  installer = pkgs.writeShellApplication {
    name = "installer";
    runtimeInputs = [
      pkgs.dosfstools
      pkgs.e2fsprogs
      pkgs.nixos-install-tools
      pkgs.util-linux
      pkgs.parted
      config.nix.package
    ];

    text = ''
      set -euo pipefail

      retry() {
        for _ in seq 10; do
          if "$@"; then
            return 0
          fi
          sleep 1
        done
        echo "retry failed"
        return 1
      }

      DEV=/dev/sda
      [ -b /dev/nvme0n1 ] && DEV=/dev/nvme0n1
      [ -b /dev/vda ] && DEV=/dev/vda

      echo "Partitioning $DEV"
      parted -s "$DEV" -- mklabel gpt
      parted -s "$DEV" -- mkpart boot fat32 1MB 512MB
      parted -s "$DEV" -- mkpart root ext4 512MB -8GB
      parted -s "$DEV" -- mkpart swap linux-swap -8GB 100%
      parted -s "$DEV" -- set 1 esp on
      sync

      echo "Waiting for partition labels"
      retry [ -b /dev/disk/by-partlabel/boot ]
      retry [ -b /dev/disk/by-partlabel/root ]
      retry [ -b /dev/disk/by-partlabel/swap ]

      echo "Formatting"
      retry mkfs.fat -F 32 -n boot /dev/disk/by-partlabel/boot
      retry mkfs.ext4 -L root /dev/disk/by-partlabel/root
      retry mkswap -L swap /dev/disk/by-partlabel/swap
      sync

      echo "Waiting for filesystem labels"
      retry [ -b /dev/disk/by-label/boot ]
      retry [ -b /dev/disk/by-label/root ]
      retry [ -b /dev/disk/by-label/swap ]

      echo "Mounting"
      swapon /dev/disk/by-label/swap
      mkdir -p /mnt
      mount /dev/disk/by-label/root /mnt
      mkdir -p /mnt/boot
      mount -o umask=077 /dev/disk/by-label/boot /mnt/boot

      echo "Generating hardware configuration"
      mkdir -p /mnt/etc/nixos
      nixos-generate-config --root /mnt

      echo "Installing the system"
      nixos-install \
        --no-channel-copy \
        --no-root-password \
        --cores 0 \
        --option substituters "" \
        --system ${targetSystem.config.system.build.toplevel}

      echo "Preparing some files"
      umask 077

      mkdir -p /mnt/root/.ssh
      echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA2CLOzyXcqk4uo6hCkkQAtozJCebA/Dh4ps6Vr2GVNTC7j7nF5HuT+penp/Y9yPAuTorxunmFn7BPwZggzopEgfmUQ4gf0CysTwPQMxt9yK3ZHpxgkGoJyR0n91OdPAbukqwWZHYxGGxvHNoap59kobUrIImIa97gKxW+IVKwL9iyWXyqonRpue1mf1N1ioDtPLS1yvzf4Jo7aDND+4I/34X6436VwZItUwzvhFcuNh/gQmvKpmVjD+ED2Q/yRtGq0EzsPfrDZg1ZKV5V1cT/3w7QtYFcZB9+AQxq88jVRcIlf3K45kpmbsWVfBFN6ND+NeZK1mlp/3TV8C6dNVqU2w== tcurdt@shodan.local" >> /mnt/root/.ssh/authorized_keys

      echo "git clone git@github.com:tcurdt/nixcfg.git" > /mnt/root/clone


      echo "Done!"
      shutdown now
    '';
  };
  installerFailsafe = pkgs.writeShellScript "failsafe" ''
    ${lib.getExe installer} || echo "ERROR: Installation failure!"
    sleep 3600
  '';
in
{
  imports = [
    (modulesPath + "/installer/cd-dvd/iso-image.nix")
    (modulesPath + "/profiles/all-hardware.nix")
  ];

  boot.kernelParams = [ "systemd.unit=getty.target" ];

  # console =  {
  #   earlySetup = true;
  #   font = "ter-v16n";
  #   packages = [ pkgs.terminus_font ];
  # };

  isoImage.isoName = "${config.isoImage.isoBaseName}-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.iso";
  isoImage.makeEfiBootable = true;
  isoImage.makeUsbBootable = true;
  isoImage.squashfsCompression = "zstd -Xcompression-level 15"; # xz takes forever

  systemd.services."getty@tty1" = {
    overrideStrategy = "asDropin";
    serviceConfig = {
      ExecStart = [ "" installerFailsafe ];
      Restart = "no";
      StandardInput = "null";
    };
  };

  system.stateVersion = "24.05";
}
