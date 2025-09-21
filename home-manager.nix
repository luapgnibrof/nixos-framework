sudo tee /mnt/etc/nixos/home-manager.nix > /dev/null <<'NIX'
{ config, pkgs, lib, ... }:
{
  home-manager.users.paul = {
    home.stateVersion = "24.11";

    # keep it tiny for install; we’ll expand post-boot
    home.packages = with pkgs; [
      firefox
      vlc
    ];

    programs.zsh.enable = true;
  };
}
NIX
