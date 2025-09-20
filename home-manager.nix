{ config, pkgs, ... }:

let
  user = builtins.getEnv "USER"; # not used; HM binds per user below
in
{
  # Attach Home Manager config to your user:
  home-manager.users.__USERNAME__ = {
    home.stateVersion = "24.11";
    programs.zsh.enable = true;
    programs.git.enable = true;
    programs.kitty.enable = true; # example terminal
    programs.starship.enable = true;

    # Some KDE-friendly basics
    home.packages = with pkgs; [
      kate dolphin konsole
      firefox
      vlc
    ];

    # Example dotfile bits
    programs.git.userName = "__USERNAME__";
    programs.git.userEmail = "you@example.com";
  };
}
