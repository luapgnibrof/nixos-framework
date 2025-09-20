# NixOS on Framework 13 — Push-Button Install (Option 1)

This repo installs NixOS on a **Framework 13** with:

- **Full-disk LUKS** (encrypted root)
- **Btrfs** with subvolumes: `@` (root), `@home`, `@nix`, `@swap`
- **Swap file** (hibernate-ready)
- **systemd-boot** (UEFI)
- **KDE Plasma 6** + PipeWire
- **Home Manager** (as a NixOS module) with your desktop/dev apps
- System services: **Tailscale**, **Flatpak**, **fwupd**, **printing/Avahi**, **Steam**, **KDE Connect**
- Extras: **Podman** (Docker-compat), quality CLI tools, unfree packages allowed (Edge, VS Code, Slack, etc.)

> ⚠️ **FULL WIPE**: The installer **erases** the target disk. Back up first.

---

## Repo Layout

nixos-framework/
├─ setup.sh # one-button installer (run from the live ISO)
├─ configuration.nix.tpl # system config template (setup.sh fills placeholders)
├─ home-manager.nix # user apps & dotfiles via Home Manager (templated)
└─ README.md # this file

yaml
Copy code

---

## Prerequisites

- Official **NixOS ISO** (graphical or minimal) on USB
- **Internet** during install (Wi-Fi or Ethernet)
- **UEFI** enabled in BIOS (Framework defaults to UEFI)
- **Secure Boot**: disable for simplest setup (you can revisit later)
- **Framework 13** notes:
  - Fingerprint reader is **Goodix** (handled by `fprintd` + TOD driver in this repo)
  - Webcam is **UVC** and works out of the box (ensure the hardware privacy switch is on)

---

## Quick Start (from the live ISO)

1) Boot the ISO, connect to Wi-Fi/Ethernet (graphical ISO UI or `nmtui` on minimal).

2) Open a terminal, install git if needed, then clone the repo:
   ```bash
   nix-shell -p git   # or: nix shell nixpkgs#git
   git clone https://github.com/<you>/nixos-framework.git
   cd nixos-framework
(Optional) Edit variables at the top of setup.sh:

DISK=/dev/nvme0n1 (target disk — will be erased)

HOSTNAME=framework

USERNAME=paul

SWAP_SIZE_GB=32 (≈ RAM size if you want hibernation)

Run the installer:

bash
Copy code
chmod +x setup.sh
./setup.sh
Type YES to confirm the full wipe.

Reboot when it finishes:

bash
Copy code
reboot
What setup.sh does
Partitions disk (GPT): ESP (FAT32 ~512MB) + LUKS root

Creates Btrfs on the LUKS mapping and subvolumes @, @home, @nix, @swap

Mounts with good defaults (compress=zstd,ssd,noatime)

Creates a swapfile safely on Btrfs

Generates hardware config, templates system config, and installs NixOS

First-Boot Checklist
Fingerprint (Framework 13, Goodix)
PAM is already configured for fingerprints (login/SDDM, sudo, polkit).

bash
Copy code
sudo fprintd-enroll $USER
fprintd-verify

# (Optional) update fingerprint firmware & others:
sudo fwupdmgr get-devices
sudo fwupdmgr update
Tip: In SDDM, you may need to press Enter once, then scan.

Tailscale
bash
Copy code
sudo tailscale up
Flatpak (Flathub remote, optional)
bash
Copy code
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
Steam & KDE Connect
Steam is enabled system-wide (programs.steam.enable = true;). Launch from the app menu; Proton will download on demand.

KDE Connect is enabled system-wide; pair your phone from KDE Connect.

Hibernation (Swapfile resume_offset on Btrfs)
To enable suspend-to-disk with a swap file:

Find the resume offset on the installed system:

bash
Copy code
# Preferred (if available):
sudo btrfs inspect-internal map-swapfile -r /swap/swapfile

# Fallback:
sudo filefrag -v /swap/swapfile | awk '/^ *0:/{print $4}' | sed 's/\.\.//'
Add to /etc/nixos/configuration.nix:

nix
Copy code
boot.resumeDevice = "/dev/mapper/luksroot";   # the filesystem that holds /swap/swapfile
boot.kernelParams = [ "resume_offset=OFFSET" ];
Apply & test:

bash
Copy code
sudo nixos-rebuild switch
systemctl hibernate
Verify it resumed:

bash
Copy code
journalctl -b -1 | grep -i -E 'PM:.*hibernat|resume|suspend-to-disk'
Notes

If you recreate/move the swap file, re-compute resume_offset.

To avoid resume_offset entirely, use a small swap partition instead.

Editing the Build (Apps, Services, Settings)
System-wide packages & services → configuration.nix.tpl

User apps & dotfiles → home-manager.nix

Workflow

Edit files in your repo (add/remove packages, change options).

On the installed system:

bash
Copy code
sudo nixos-rebuild switch
Log out/in if a desktop component needs it.

Already enabled system-wide

KDE Plasma 6 (Wayland), SDDM, PipeWire

Printing (CUPS) + Avahi discovery

Firmware updates (fwupd)

Tailscale, Flatpak, Steam, KDE Connect

Podman with docker CLI compat (virtualisation.podman.dockerCompat = true;)

Useful CLIs: curl wget git vim jq yq ripgrep fd bat eza htop btop pciutils usbutils brightnessctl btrfs-progs rsync unzip zip parted cryptsetup fastfetch

Unfree allowed (Edge, VS Code, Slack, etc.)

User-level apps (via Home Manager) include

Office & comms: LibreOffice, Thunderbird, Bitwarden, Element, Signal, WhatsApp (client), KDE Connect

Browsers/editors: Firefox, Chromium, VS Code, Microsoft Edge

Media/creative: VLC, Audacity, Darktable

Remote/chat: RustDesk, Slack, Teams (Linux client), Jitsi Meet (electron)

Utilities: p7zip, PowerShell

Dev/ops: gh, kubectl, k9s, helm, awscli2, azure-cli, sops, age, opentofu, ansible

Bottles (works; Flatpak is often recommended by upstream)

To change the user app set, edit home-manager.nix and rebuild.

Rollbacks & Updates
Roll back to the previous system generation from the boot menu, or:

bash
Copy code
sudo nixos-rebuild switch --rollback
Update to newer packages:

bash
Copy code
sudo nixos-rebuild switch --upgrade
Troubleshooting
Wi-Fi on the live ISO: use the UI (graphical ISO) or nmtui (minimal).

Secure Boot: disable for this setup; add later if needed.

Fingerprint doesn’t enroll: update firmware (fwupdmgr update) and retry.

SDDM + fingerprint: press Enter then scan if the prompt isn’t obvious.

Swapfile creation: the installer prefers btrfs filesystem mkswapfile. If missing, it falls back to a safe manual method (no-CoW, no compression), then mkswap.

Camera: it’s UVC; ensure the hardware privacy switch is on. Test with a browser or a simple camera app.

Customization Ideas (Optional)
TPM auto-unlock for LUKS (e.g., systemd-cryptenroll/clevis)

Btrfs snapshots (e.g., Snapper or manual snapshotting)

Docker instead of Podman (toggle in configuration.nix.tpl)

Browser policies for Edge/Chromium (JSON managed settings)

WinApps (separate project/flake) if you want Windows apps via RDP

License & Warranty
Use at your own risk. This wipes disks and installs an encrypted system. Review the scripts and configs before running in production.
