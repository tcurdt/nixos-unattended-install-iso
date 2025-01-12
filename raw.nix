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
      targetSystem.config.system.build.toplevel
    ];

    text = ''
      set -euo pipefail

      echo "Partitioning disk"
      parted -s /dev/vda -- mklabel gpt
      parted -s /dev/vda -- mkpart boot fat32 1MB 512MB
      parted -s /dev/vda -- mkpart root ext4 512MB -8GB
      parted -s /dev/vda -- mkpart swap linux-swap -8GB 100%
      parted -s /dev/vda -- set 1 esp on
      sync

      echo "Formatting partitions"
      mkfs.fat -F 32 -n boot /dev/vda1
      mkfs.ext4 -L root /dev/vda2
      mkswap -L swap /dev/vda3
      sync

      echo "Mounting filesystems"
      swapon /dev/vda3
      mkdir -p /mnt
      mount /dev/vda2 /mnt
      mkdir -p /mnt/boot
      mount /dev/vda1 /mnt/boot

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

      umount -R /mnt
      echo "Done!"
    '';
  };
in
{
    # not sure about this start
    fileSystems."/".device = "/dev/null";
    boot.loader.grub.enable = false;
    # not sure about this stop

    imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    (modulesPath + "/profiles/all-hardware.nix")
  ];

  system.build.diskImage = pkgs.vmTools.runInLinuxVM (
    pkgs.runCommand "disk-image" {
      preVM = ''
        mkdir $out
        ${pkgs.vmTools.qemu}/bin/qemu-img create -f raw $out/disk.img 8G
      '';
      buildInputs = [ installer ];
      QEMU_OPTS = "-drive id=drive1,file=$out/disk.img,if=virtio,cache=writeback,format=raw";
      paths = [ targetSystem.config.system.build.toplevel ];
    } ''
      ${lib.getExe installer}
    ''
  );

  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "virtio_pci"
    "virtio_blk"
    "virtio_scsi"
    "sd_mod"
    "sr_mod"
  ];

  system.stateVersion = "24.05";
}
