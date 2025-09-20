# NixOS Framework — Push-Button Installer

This repo installs NixOS on a Framework laptop with:
- Full-disk LUKS
- Btrfs subvolumes (@, @home, @nix, @swap)
- Swap file
- systemd-boot
- KDE Plasma
- Home Manager module

## Use

1) Boot the official NixOS ISO (graphical or minimal). Get network online.

2) Install git on the live ISO if needed, then clone:
```bash
nix-shell -p git || nix shell nixpkgs#git
git clone https://github.com/luapgnibrof/nixos-framework.git
cd nixos-framework
