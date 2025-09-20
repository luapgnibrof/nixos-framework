{ config, pkgs, lib, ... }:

{
  home-manager.users.__USERNAME__ = {
    home.stateVersion = "24.11";

    # ------------ Apps you asked for ------------
    home.packages = with pkgs; [
      # Office & comms
      libreoffice-qt6-fresh
      thunderbird
      bitwarden bitwarden-cli
      element-desktop
      signal-desktop
      whatsapp-for-linux      # alt: zapzap
      kdeconnect-kde

      # Browsers / editors
      firefox
      chromium
      vscode                  # unfree
      microsoft-edge          # unfree

      # Media / creative
      vlc
      audacity
      darktable

      # Utilities
      p7zip                   # 7-Zip CLI (7z); prefer this over legacy forks
      powershell

      # Remote / chat
      rustdesk
      slack                   # unfree
      teams-for-linux

      # Meetings
      jitsi-meet-electron

      # Gaming / Windows compatibility
      bottles                 # works, but upstream prefers Flatpak

      # API tools
      postman                 # unfree; occasionally breaks upstream

      # (Steam handled system-wide; see below)
    ];

    # ------------ Your previous nice defaults ------------
    programs.zsh = {
      enable = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;
      history.size = 50000;
      shellAliases = {
        ll = "eza -lah";
        k = "kubectl";
        g = "git";
        tf = "tofu";
      };
    };

    programs.starship.enable = true;

    programs.direnv = {
