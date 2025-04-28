{
  # config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/profiles/all-hardware.nix")
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/root";
    fsType = "ext4";
  };

  swapDevices = [
    {
      device = "/dev/disk/by-label/swap";
    }
  ];

  networking.useDHCP = lib.mkDefault true;
  networking.hostName = "nixos";

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # console =  {
  #   earlySetup = true;
  #   font = "ter-v16n";
  #   packages = [ pkgs.terminus_font ];
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # users.users.alice = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  #   packages = with pkgs; [
  #     firefox
  #     tree
  #   ];
  # };

  environment.systemPackages = with pkgs; [
    nano
    gitMinimal
    curl
  ];

  services.openssh.enable = true;

  services.getty.autologinUser = "root";

  users.users.root.initialHashedPassword = "";

  system.stateVersion = "24.11";
}
