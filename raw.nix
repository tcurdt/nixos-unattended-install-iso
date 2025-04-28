{
  config,
  pkgs,
  lib,
  modulesPath,
  targetSystem,
  ...
}:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    (modulesPath + "/profiles/all-hardware.nix")
  ];

  fileSystems."/".device = lib.mkDefault "/dev/disk/by-label/root";
  fileSystems."/boot".device = lib.mkDefault "/dev/disk/by-label/boot";

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";
    efiInstallAsRemovable = true;
  };

  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "virtio_pci"
    "virtio_blk"
    "virtio_scsi"
    "sd_mod"
    "sr_mod"
  ];

  system.build.diskImage = import "${pkgs.path}/nixos/lib/make-disk-image.nix" {
    inherit lib pkgs config;

    diskSize = "auto";
    additionalSpace = "512M";
    format = "raw";
    partitionTableType = "efi";

    postVM = ''
      mkdir -p $out/nix-support
      echo "file raw-disk-image $out/disk.img" >> $out/nix-support/hydra-build-products
    '';

    # target system
    contents = [
      {
        source = targetSystem.config.system.build.toplevel;
        target = "/system";
      }
    ];

    # partitions = [
    #   {
    #     name = "ESP";
    #     size = "256M";
    #     fsType = "vfat";
    #     mountPoint = "/boot";
    #     bootable = true;
    #   }
    #   {
    #     name = "root";
    #     size = "100%";
    #     fsType = "ext4";
    #     mountPoint = "/";
    #   }
    # ];

  };

  system.stateVersion = "24.11";
}
