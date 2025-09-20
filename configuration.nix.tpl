{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./home-manager.nix
  ];

  networking.hostName = "__HOSTNAME__";

  # ----- Bootloader / EFI -----
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ----- Encrypted root (LUKS) -----
  boot.initrd.luks.devices.luksroot = {
    device = "/dev/disk/by-uuid/__CRYPT_UUID__";
    preLVM = true;
  };

  # Btrfs subvols were mounted during install (@, @home, @nix, @swap)
  # Swap file created by setup.sh:
  swapDevices = [
    { device = "__SWAPFILE__"; }
  ];

  # ===== Desktop & hardware =====
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

  # Network
  networking.networkmanager.enable = true;

  # Firmware/microcode (good for Framework 13)
  hardware.cpu.intel.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;

  # Power management
  services.power-profiles-daemon.enable = true;
  powerManagement.powertop.enable = true;

  # ===== Fingerprint reader (Goodix) =====
  services.fprintd.enable = true;
  services.fprintd.tod.enable = true;
  services.fprintd.tod.driver = pkgs.libfprint-2-tod1-goodix;

  # Enable fingerprint auth in PAM for login, SDDM, sudo, & polkit dialogs
  security.pam.services.login.fprintAuth = true;
  security.pam.services.sddm.fprintAuth = true;
  security.pam.services.sudo.fprintAuth = true;
  security.pam.services.polkit-1.fprintAuth = true;

  # ===== System-wide apps & services =====
  environment.systemPackages = with pkgs; [
    # Core CLI
    curl wget git vim
    htop btop jq yq ripgrep fd bat tree fzf eza
    # System utils
    pciutils usbutils brightnessctl fastfetch btrfs-progs
    parted cryptsetup rsync unzip zip
    # Browser (optional system-wide; user-level also fine)
    chromium
  ];

  # Printing & discovery
  services.printing.enable = true;
  services.avahi.enable = true;     # mDNS/Bonjour

  # Firmware updates
  services.fwupd.enable = true;

  # VPN
  services.tailscale.enable = true;

  # Containers (choose one; Podman by default)
  virtualisation.podman.enable = true;
  virtualisation.podman.dockerCompat = true;
  # virtualisation.docker.enable = true;

  # Flatpak (nice for a few desktop apps like Bottles)
  services.flatpak.enable = true;

  # Desktop portals (KDE integration + Flatpak)
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-kde ];

  # Optional remote access
  services.openssh.enable = false;

  # ===== Extras requested earlier =====
  programs.steam.enable = true;       # Steam (pulls required 32-bit bits)
  programs.kdeconnect.enable = true;  # Opens required firewall ports

  # ===== Users =====
  users.users."__USERNAME__" = {
    isNormalUser = true;
    description = "__USERNAME__";
    extraGroups = [ "wheel" "networkmanager" "video" ];
    shell = pkgs.zsh;
  };
  programs.zsh.enable = true;

  # sudo for wheel
  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = true;

  # ===== Nix QoL =====
  nixpkgs.config.allowUnfree = true;
  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [ "nix-command" "flakes" ];
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # ===== Locale / time =====
  time.timeZone = "America/Indiana/Indianapolis";
  i18n.defaultLocale = "en_US.UTF-8";

  # Match your install release
  system.stateVersion = "24.11";
}
