{ config, pkgs, lib, modulesPath, targetSystem, ... }:
let
  sshKeys = ''
    ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA2CLOzyXcqk4uo6hCkkQAtozJCebA/Dh4ps6Vr2GVNTC7j7nF5HuT+penp/Y9yPAuTorxunmFn7BPwZggzopEgfmUQ4gf0CysTwPQMxt9yK3ZHpxgkGoJyR0n91OdPAbukqwWZHYxGGxvHNoap59kobUrIImIa97gKxW+IVKwL9iyWXyqonRpue1mf1N1ioDtPLS1yvzf4Jo7aDND+4I/34X6436VwZItUwzvhFcuNh/gQmvKpmVjD+ED2Q/yRtGq0EzsPfrDZg1ZKV5V1cT/3w7QtYFcZB9+AQxq88jVRcIlf3K45kpmbsWVfBFN6ND+NeZK1mlp/3TV8C6dNVqU2w== tcurdt@shodan.local
  '';
in
{
  imports = [
    (modulesPath + "/profiles/all-hardware.nix")
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.devices = [ "/dev/sda" ];
  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "virtio_pci"
    "virtio_blk"
    "sd_mod"
    "sr_mod"
  ];

  system.build.diskImage = import "${pkgs.path}/nixos/lib/make-disk-image.nix" {
    inherit pkgs config;
    diskSize = 8192; # Size in MiB
    format = "raw";
    partitionTableType = "gpt";
    copyChannel = false;

    partitionScript = ''
      parted -s /dev/vda -- mklabel gpt
      parted -s /dev/vda -- mkpart boot fat32 1MB 512MB
      parted -s /dev/vda -- mkpart root ext4 512MB -8GB
      parted -s /dev/vda -- mkpart swap linux-swap -8GB 100%
      parted -s /dev/vda -- set 1 esp on
    '';

    postVM = ''
      # Setup SSH keys
      mkdir -p /mnt/root/.ssh
      echo "${sshKeys}" > /mnt/root/.ssh/authorized_keys
      chmod 700 /mnt/root/.ssh
      chmod 600 /mnt/root/.ssh/authorized_keys

      # Add git clone helper
      echo "git clone git@github.com:tcurdt/nixcfg.git" > /mnt/root/clone
    '';
  };

  networking.useDHCP = true;
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "prohibit-password";
  };

  environment.systemPackages = with pkgs; [
    vim
    curl
    wget
  ];

  system.stateVersion = "24.05";
}