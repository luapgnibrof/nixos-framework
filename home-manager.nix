{ config, pkgs, lib, ... }:

{
  # Home Manager as a NixOS module: bind config to your user
  home-manager.users.__USERNAME__ = {
    home.stateVersion = "24.11";

    # --------- Packages (user scope) ---------
    home.packages = with pkgs; [
      # KDE desktop apps
      konsole dolphin kate okular gwenview spectacle ark

      # Browsing / media
      firefox vlc

      # Dev / ops toolbelt
      gh ripgrep fd bat jq yq tree fzf eza
      kubectl k9s helm
      awscli2 azure-cli
      sops age
      opentofu # switch to terraform if you prefer
      ansible
      # Handy utilities
      ncdu duf
    ];

    # --------- Shell, prompt, and tooling ---------
    programs.zsh = {
      enable = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;
      history.size = 50000;
      shellAliases = {
        ll = "eza -lah";
        k = "kubectl";
        g = "git";
        tf = "tofu"; # opentofu alias
      };
    };

    programs.starship.enable = true;

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    programs.kitty = {
      enable = true;
      settings = {
        confirm_os_window_close = 0;
        enable_audio_bell = "no";
      };
    };

    programs.vscode = {
      enable = true;
      userSettings = {
        "editor.fontFamily" = "JetBrains Mono, monospace";
        "editor.fontLigatures" = true;
        "editor.formatOnSave" = true;
        "files.trimTrailingWhitespace" = true;
        "terminal.integrated.defaultProfile.linux" = "zsh";
      };
      extensions = with pkgs.vscode-extensions; [
        ms-python.python
        ms-vscode.cpptools
        ms-azuretools.vscode-docker
        github.vscode-github-actions
        redhat.vscode-yaml
        hashicorp.terraform
      ];
    };

    programs.git = {
      enable = true;
      userName = "__USERNAME__";
      userEmail = "you@example.com"; # update after first boot
      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
        core.editor = "vim";
      };
    };

    programs.ssh = {
      enable = true;
      extraConfig = ''
        AddKeysToAgent yes
        ServerAliveInterval 60
      '';
    };

    services.gpg-agent = {
      enable = true;
      enableSshSupport = true;
      defaultCacheTtl = 7200;
      maxCacheTtl = 86400;
    };

    # --------- XDG & session defaults ---------
    xdg.enable = true;
    xdg.userDirs.enable = true;

    home.sessionVariables = {
      EDITOR = "vim";
      VISUAL = "code";
      PAGER = "bat";
    };
  };
}
