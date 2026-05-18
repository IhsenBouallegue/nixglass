#!/usr/bin/env bash
# install.sh — partition a target disk and nixos-install the nixglass flake.
#
# Run from inside a booted NixOS installer (minimal ISO is fine). Network must
# already be up — `nmtui` or DHCP-on-ethernet before this.
#
# Usage, one-shot via curl:
#   curl -fsSL https://github.com/IhsenBouallegue/nixglass/raw/main/install.sh \
#     | sudo bash -s /dev/sdX
#
# Or local:
#   sudo bash install.sh /dev/sdX
#
# WIPES the target disk completely. Other disks are untouched. All interactive
# prompts (yes/no confirmations, reboot prompt) read from /dev/tty so the
# `curl | bash` form still asks you instead of consuming the script as input.

set -euo pipefail

FLAKE_URL="https://github.com/IhsenBouallegue/nixglass.git"
FLAKE_NAME="nixglass"

# ── pretty output ────────────────────────────────────────────────────────────
BOLD='\033[1m'; GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; YELLOW='\033[0;33m'; RESET='\033[0m'
step() { echo -e "\n${BOLD}${CYAN}==>${RESET} ${BOLD}$*${RESET}"; }
ok()   { echo -e "    ${GREEN}✓${RESET} $*"; }
warn() { echo -e "    ${YELLOW}!${RESET} $*"; }
die()  { echo -e "    ${RED}✗${RESET} $*" >&2; exit 1; }

# ── validate args ────────────────────────────────────────────────────────────
[[ $# -eq 1 ]] || die "Usage: $0 /dev/sdX"
TARGET="$1"
[[ $EUID -eq 0 ]] || die "Run as root (sudo bash $0 $TARGET)"
[[ -b "$TARGET" ]] || die "$TARGET is not a block device"

# Refuse the obviously-wrong targets.
case "$TARGET" in
  /dev/sda|/dev/sdb|/dev/sdc|/dev/sdd|/dev/nvme0n1|/dev/nvme1n1) ;;
  *) die "$TARGET doesn't look like a whole-disk device (need /dev/sdX or /dev/nvmeXnY)" ;;
esac

# Partition naming differs between SATA/USB (/dev/sda1) and NVMe (/dev/nvme0n1p1).
if [[ "$TARGET" == *nvme* ]]; then
  ESP="${TARGET}p1"; ROOT="${TARGET}p2"
else
  ESP="${TARGET}1";  ROOT="${TARGET}2"
fi

# Refuse to wipe a currently-mounted disk (root, /boot, etc.).
if mount | awk '{print $1}' | grep -qE "^${TARGET}[0-9p]*$"; then
  die "$TARGET (or a partition of it) is currently mounted. Unmount first."
fi

# ── show the user what's about to happen ────────────────────────────────────
step "Target overview"
lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINT "$TARGET" || true
echo
echo -e "${RED}${BOLD}This will WIPE EVERYTHING on $TARGET.${RESET}"
echo -e "  ESP partition  → $ESP   (1 GB FAT32, label NIXBOOT, mounted /boot)"
echo -e "  Root partition → $ROOT  (rest, ext4, label nixos, mounted /)"
echo
read -rp "Type 'yes' to continue, anything else to abort: " ans </dev/tty
[[ "$ans" == "yes" ]] || die "aborted"

# ── partition ────────────────────────────────────────────────────────────────
step "Partitioning $TARGET"
wipefs -a "$TARGET" >/dev/null
parted -s "$TARGET" \
  mklabel gpt \
  mkpart ESP fat32 1MiB 1GiB \
  set 1 esp on \
  mkpart primary 1GiB 100%
# Let the kernel see the new partitions.
partprobe "$TARGET" || true
udevadm settle
sleep 1
[[ -b "$ESP" ]] || die "$ESP didn't appear after partprobe"
[[ -b "$ROOT" ]] || die "$ROOT didn't appear after partprobe"
ok "Partitions created"

# ── format ───────────────────────────────────────────────────────────────────
step "Formatting"
mkfs.fat -F 32 -n NIXBOOT "$ESP" >/dev/null
mkfs.ext4 -F -L nixos "$ROOT" >/dev/null
ok "Filesystems written"

# ── mount ────────────────────────────────────────────────────────────────────
step "Mounting at /mnt"
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/NIXBOOT /mnt/boot
ok "Mounted"

# ── hardware-config + flake ──────────────────────────────────────────────────
step "Generating hardware-configuration.nix"
nixos-generate-config --root /mnt --no-filesystems
# The flake's own fileSystems are derived from labels (nixos / NIXBOOT) which
# nixos-generate-config won't have included with --no-filesystems, so add
# matching entries to the file before installing.
cat >> /mnt/etc/nixos/hardware-configuration.nix <<'EOF'

  # Added by install.sh — disk layout written by the installer.
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/NIXBOOT";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };
EOF
ok "hardware-configuration.nix ready"

step "Cloning flake from $FLAKE_URL"
mv /mnt/etc/nixos /mnt/etc/nixos.generated
git clone "$FLAKE_URL" /mnt/etc/nixos
cp /mnt/etc/nixos.generated/hardware-configuration.nix /mnt/etc/nixos/nixos/hardware-configuration.nix
ok "Flake at /mnt/etc/nixos, hardware-config merged in"

# ── install ──────────────────────────────────────────────────────────────────
step "Running nixos-install"
echo "    (this is the long step — it'll fetch the closure and build)"
nixos-install --flake "/mnt/etc/nixos#${FLAKE_NAME}"

# ── done ─────────────────────────────────────────────────────────────────────
step "Install complete"
echo
echo "    Set the root password when prompted above."
echo "    User 'ihsen' has the initialPassword set in the flake."
echo
echo "    Reboot, pull the USB, BIOS boot-menu → pick the new disk."
echo "    First login: niri starts automatically."
echo
echo -e "${BOLD}    reboot now? [y/N]${RESET} "
read -rp "" ans </dev/tty
[[ "$ans" == "y" || "$ans" == "Y" ]] && reboot
