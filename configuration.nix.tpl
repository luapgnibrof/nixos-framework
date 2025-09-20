{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./home-manager.nix
  ];

  networking.hostName = "__HOSTNAME__";

  # Bootloader (UEFI) + allow touching NVRAM
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # LUKS root device: match the partition UUID of encrypted root
  boot.initrd.luks.devices.luksroot = {
    device = "/dev/disk/by-uuid/__CRYPT_UUID__";
    preLVM = true;
  };

  # Filesystems come from hardware-configuration.nix generated at install time.
  # We mounted with subvol=@, @home, @nix, @swap and compression=zstd.

  # Swap file (created during install)
  swapDevices = [
    { device = "__SWAPFILE__"; }
  ];

  # Graphical environment: KDE Plasma 6 + SDDM (Wayland by default)
  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma6.enable = true;

  # PipeWire audio
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # NetworkManager
  networking.networkmanager.enable = true;

  # Firmware & microcode (good for Framework)
  hardware.cpu.intel.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;

  # Common laptop niceties
  powerManagement.powertop.enable = true;   # optional tuning
  services.power-profiles-daemon.enable = true;

  # User
  users.users."__USERNAME__" = {
    isNormalUser = true;
    description = "__USERNAME__";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.zsh;
  };

  # sudo for wheel
  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = true;

  # Home Manager as a NixOS module
  programs.home-manager.enable = true;

  # Let unfree packages be installed
  nixpkgs.config.allowUnfree = true;

  # Helpful defaults
  time.timeZone = "America/Indiana/Indianapolis";
  i18n.defaultLocale = "en_US.UTF-8";

  # Set your NixOS release for state compatibility
  system.stateVersion = "24.11";
}
