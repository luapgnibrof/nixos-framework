#!/usr/bin/env bash
set -euo pipefail

# ======== USER VARS (edit as needed) ========
DISK="/dev/nvme0n1"        # target disk (WILL BE ERASED)
HOSTNAME="framework"
USERNAME="paul"
SWAP_SIZE_GB="32"          # set to RAM size if you want hibernation
# ===========================================

# --- sanity checks ---
for bin in parted cryptsetup mkfs.btrfs btrfs mount nixos-generate-config nixos-install; do
  command -v "$bin" >/dev/null || { echo "Missing required tool: $bin"; exit 1; }
done

echo ">>> This will ERASE $DISK. Continue? (type YES)"
read -r CONFIRM
[[ "$CONFIRM" == "YES" ]] || { echo "Aborted."; exit 1; }

# partition name helper (nvme uses p1,p2; sata uses 1,2)
if [[ "$DISK" =~ [0-9]$ ]]; then
  P1="${DISK}p1"; P2="${DISK}p2"
else
  P1="${DISK}1";  P2="${DISK}2"
fi

# --- wipe & partition ---
echo ">>> Partitioning $DISK"
parted --script "$DISK" \
  mklabel gpt \
  mkpart ESP fat32 1MiB 513MiB \
  set 1 esp on \
  mkpart primary 513MiB 100%

# --- format EFI ---
echo ">>> Formatting EFI $P1"
mkfs.fat -F32 -n EFI "$P1"

# --- LUKS on root ---
echo ">>> Creating LUKS on $P2"
cryptsetup luksFormat "$P2"
cryptsetup open "$P2" luksroot

# --- Btrfs on LUKS mapper ---
echo ">>> Formatting Btrfs on /dev/mapper/luksroot"
mkfs.btrfs -L nixos /dev/mapper/luksroot

# --- subvolumes ---
echo ">>> Creating Btrfs subvolumes"
mount /dev/mapper/luksroot /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@swap
umount /mnt

# --- mount subvols ---
echo ">>> Mounting subvolumes"
mount -o subvol=@,compress=zstd,ssd,noatime /dev/mapper/luksroot /mnt
mkdir -p /mnt/{boot,home,nix,swap}
mount -o subvol=@home,compress=zstd,ssd,noatime /dev/mapper/luksroot /mnt/home
mount -o subvol=@nix,compress=zstd,ssd,noatime  /dev/mapper/luksroot /mnt/nix
mount -o subvol=@swap                            /dev/mapper/luksroot /mnt/swap

# --- swap file on Btrfs (@swap) ---
echo ">>> Creating swapfile (${SWAP_SIZE_GB}G)"
# Prefer the btrfs helper if available
if btrfs filesystem mkswapfile --help >/dev/null 2>&1; then
  btrfs filesystem mkswapfile --size "${SWAP_SIZE_GB}g" /mnt/swap/swapfile
else
  # Fallback: ensure no CoW/compression; then create the file
  chattr +C /mnt/swap || true
  btrfs property set /mnt/swap compression none || true
  fallocate -l "${SWAP_SIZE_GB}G" /mnt/swap/swapfile
  chmod 600 /mnt/swap/swapfile
  mkswap /mnt/swap/swapfile
fi
swapon /mnt/swap/swapfile || true

# --- mount EFI ---
echo ">>> Mounting EFI at /mnt/boot"
mount -o umask=0077 "$P1" /mnt/boot

# --- generate hardware config ---
echo ">>> Generating NixOS hardware config"
nixos-generate-config --root /mnt

# --- gather identifiers for templating ---
echo ">>> Capturing identifiers"
CRYPT_UUID=$(blkid -s UUID -o value "$P2")
LUKS_MAPPER="/dev/mapper/luksroot"

# --- write configuration.nix from template ---
echo ">>> Writing configuration.nix from template"
TPL="$(dirname "$0")/configuration.nix.tpl"
CONF="/mnt/etc/nixos/configuration.nix"

sed \
  -e "s|__HOSTNAME__|$HOSTNAME|g" \
  -e "s|__USERNAME__|$USERNAME|g" \
  -e "s|__CRYPT_UUID__|$CRYPT_UUID|g" \
  -e "s|__LUKS_MAPPER__|$LUKS_MAPPER|g" \
  -e "s|__SWAPFILE__|/swap/swapfile|g" \
  "$TPL" > "$CONF"

# --- home-manager file (optional but handy) ---
echo ">>> Installing home-manager.nix"
cp "$(dirname "$0")/home-manager.nix" /mnt/etc/nixos/home-manager.nix

# --- install ---
echo ">>> Installing NixOS (this may take a while)"
nixos-install --no-root-passwd

echo ">>> Installation complete. You can now 'reboot'."
echo "NOTE: For hibernation, you may need to set resume_offset post-boot (README explains)."
