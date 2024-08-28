{ config, pkgs, lib, modulesPath, targetSystem, ... }:
let
  installer = pkgs.writeShellApplication {
    name = "installer";
    runtimeInputs = with pkgs; [
      dosfstools
      e2fsprogs
      gawk
      nixos-install-tools
      util-linux
      config.nix.package
    ];
    text = ''
      set -euo pipefail

      wait-for() {
        for _ in seq 10; do
          if $@; then
            break
          fi
          sleep 1
        done
      }

      echo "Setting up disks"
      for i in $(lsblk -pln -o NAME,TYPE | grep disk | awk '{ print $1 }'); do
        if [[ "$i" == "/dev/fd0" ]]; then
          echo "skipping $i (is a floppy)"
          continue
        fi
        if grep -ql "^$i" /proc/mounts; then
          echo "skipping $i (is in use)"
        else
          DEVICE_MAIN="$i"
          break
        fi
      done
      if [[ -z "$DEVICE_MAIN" ]]; then
        echo "ERROR: No usable disk found on this machine!"
        exit 1
      else
        echo "Found $DEVICE_MAIN"
      fi


      echo "Partitioning $DEVICE_MAIN"
      # DISKO_DEVICE_MAIN=''${DEVICE_MAIN#"/dev/"} ${targetSystem.config.system.build.diskoScript} 2> /dev/null
      parted $DEVICE_MAIN -- mklabel gpt
      parted $DEVICE_MAIN -- mkpart boot fat32 1MB 512MB
      parted $DEVICE_MAIN -- mkpart root ext4 512MB -8GB
      parted $DEVICE_MAIN -- mkpart swap linux-swap -8GB 100%
      parted $DEVICE_MAIN -- set 1 esp on

      echo "Formatting"
      mkfs.fat -F 32 -n boot /dev/disk/by-partlabel/boot
      mkfs.ext4 -L root /dev/disk/by-partlabel/root
      mkswap -L swap /dev/disk/by-partlabel/swap

      echo "Mounting"
      swapon /dev/disk/by-label/swap
      mount /dev/disk/by-label/root /mnt
      mkdir /mnt/boot
      mount -o umask=077 /dev/disk/by-label/boot /mnt/boot

      echo "Generating hardware configuration"
      mkdir -p /mnt/etc/nixos
      nixos-generate-config --root /mnt

      echo "Installing the system"
      nixos-install \
        --no-channel-copy \
        --no-root-password \
        --cores 0 \                    # use as many cores as possible
        --option substituters "" \     # no cache (as the system comes with a derivation)
        --system ${targetSystem.config.system.build.toplevel}

      echo "Preparing some files"
      echo "foo" > /mnt/root/foo

      echo "Done!"
      sleep 3
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
