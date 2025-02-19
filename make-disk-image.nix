{
  # config,
  pkgs,
  # lib,
  # modulesPath,
  # targetSystem,
  ...
}:
let
in
{

  # why is this needed? the platform should come from the nixos config
  nixpkgs.hostPlatform = "x86_64-linux";

  imports = [
    "${pkgs}/nixos/modules/profiles/qemu-guest.nix"
    # "${nixpkgs}/nixos/modules/virtualisation/azure-image.nix"
  ];

  boot.loader.grub.device = "/dev/sda";

  fileSystems."/" = {
    label = "nixos";
    fsType = "ext4";
  };

  networking.useDHCP = false;

  services = {
    # cloud-init = {
    #   enable = true;
    #   network.enable = true;
    #   config = ''
    #     system_info:
    #       distro: nixos
    #       network:
    #         renderers: [ 'networkd' ]
    #     datasource_list: [ "Exoscale" ]
    #     cloud_init_modules:
    #       - migrator
    #       - seed_random
    #       - growpart
    #       - resizefs
    #     cloud_config_modules:
    #       - disk_setup
    #       - mounts
    #     cloud_final_modules: []
    #   '';
    # };

    # qemuGuest.enable = true;

    openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
      settings.KbdInteractiveAuthentication = false;
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [
    # ...
  ];

  system.stateVersion = "24.05";
}
