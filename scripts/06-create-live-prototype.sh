#!/usr/bin/env bash
# Stage 14C - Live Boot Prototype Stub
# This script is an experimental stub and is not called by the default Makefile.
# It demonstrates the process of generating a Hybrid ISO from the existing rootfs.
# It writes ONLY to the build/live/ directory.

set -e

# ==========================================
# Logging Automático
# ==========================================
LOG_FILE="build/live-prototype-build.log"
mkdir -p build
# Redireciona stdout e stderr para o log e para o terminal
exec > >(tee -i "$LOG_FILE") 2>&1
echo "========================================="
echo " Log da execução salvo em: $LOG_FILE"
echo "========================================="

# ==========================================
# Variables
# ==========================================
BUILD_DIR="build"
LIVE_DIR="${BUILD_DIR}/live"
ROOTFS_DIR="${BUILD_DIR}/rootfs"

STAGING_DIR="${LIVE_DIR}/rootfs_stage"
ISO_DIR="${LIVE_DIR}/iso"
ISO_LIVE_DIR="${ISO_DIR}/live"
ISO_BOOT_DIR="${ISO_DIR}/boot/grub"
OUTPUT_ISO="${LIVE_DIR}/FlavosOS-live-prototype-0.1-daily-amd64.iso"

# ==========================================
# Safety Checks
# ==========================================
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: This script must be run as root (requires chroot and mounts)."
    exit 1
fi

if [ ! -d "$ROOTFS_DIR" ]; then
    echo "ERROR: Base rootfs not found at $ROOTFS_DIR."
    echo "Please run 01-create-rootfs.sh first."
    exit 1
fi

echo "========================================="
echo " Flavos OS - Live Boot Prototype Builder"
echo "========================================="
echo "WARNING: This is an experimental stub."
echo "It isolates all changes to $LIVE_DIR."

[ -n "$STAGING_DIR" ]    || { echo "ERRO: STAGING_DIR vazio"; exit 1; }
[ "$STAGING_DIR" != "/" ] || { echo "ERRO: STAGING_DIR é /"; exit 1; }

case "$LIVE_DIR" in
    build/live|build/live/*) ;;
    *) echo "ERRO: caminho inseguro para remoção: $LIVE_DIR"; exit 1 ;;
esac

# Clean up previous runs
# VERY IMPORTANT: Ensure no stale mounts exist before running rm -rf!
echo "Checking for stale mounts from previous runs..."
for mp in "${STAGING_DIR}/run" "${STAGING_DIR}/sys" "${STAGING_DIR}/proc" "${STAGING_DIR}/dev/pts" "${STAGING_DIR}/dev"; do
    if mountpoint -q "$mp" 2>/dev/null; then
        echo "WARNING: Found stale mount at $mp. Unmounting..."
        umount -lf "$mp" || true
    fi
done

# Safe to remove now
rm -rf "$LIVE_DIR"
mkdir -p "$STAGING_DIR"
mkdir -p "$ISO_LIVE_DIR"
mkdir -p "$ISO_BOOT_DIR"

# ==========================================
# 1. Prepare Staging Rootfs
# ==========================================
echo "[1/4] Copying rootfs for Live preparation..."
cp -a "$ROOTFS_DIR/." "$STAGING_DIR/"

echo "      Applying overlay updates to staging..."
if [ -d "overlay" ]; then
    cp -a overlay/* "$STAGING_DIR/"
    chown root:root "$STAGING_DIR"/usr/local/lib/flavos/helpers/* 2>/dev/null || true
    chmod 0755 "$STAGING_DIR"/usr/local/lib/flavos/helpers/* 2>/dev/null || true
    if [ -f "$STAGING_DIR/etc/sudoers.d/flavos-settings" ]; then
        chown root:root "$STAGING_DIR/etc/sudoers.d/flavos-settings"
        chmod 0440 "$STAGING_DIR/etc/sudoers.d/flavos-settings"
    fi
    if [ -f "$STAGING_DIR/etc/sudoers.d/flavos-firstboot" ]; then
        chown root:root "$STAGING_DIR/etc/sudoers.d/flavos-firstboot"
        chmod 0440 "$STAGING_DIR/etc/sudoers.d/flavos-firstboot"
    fi
fi

echo "      Mounting virtual filesystems and setting up DNS..."
mount --bind /dev "${STAGING_DIR}/dev"
mount --bind /dev/pts "${STAGING_DIR}/dev/pts"
mount -t proc proc "${STAGING_DIR}/proc"
mount -t sysfs sysfs "${STAGING_DIR}/sys"
mount -t tmpfs tmpfs "${STAGING_DIR}/run"

# Use host's DNS resolution temporarily (avoid systemd-resolved issues inside chroot)
if [ -f "${STAGING_DIR}/etc/resolv.conf" ]; then
    cp -a "${STAGING_DIR}/etc/resolv.conf" "${STAGING_DIR}/etc/resolv.conf.flavos-bak"
fi
rm -f "${STAGING_DIR}/etc/resolv.conf"
echo "nameserver 8.8.8.8" > "${STAGING_DIR}/etc/resolv.conf"
echo "nameserver 1.1.1.1" >> "${STAGING_DIR}/etc/resolv.conf"

cleanup_chroot() {
    set +e
    echo "      Cleaning up mounts and restoring DNS..."
    if [ -f "${STAGING_DIR}/etc/resolv.conf.flavos-bak" ]; then
        mv "${STAGING_DIR}/etc/resolv.conf.flavos-bak" "${STAGING_DIR}/etc/resolv.conf"
    else
        rm -f "${STAGING_DIR}/etc/resolv.conf"
        ln -sf /run/systemd/resolve/stub-resolv.conf "${STAGING_DIR}/etc/resolv.conf"
    fi
    umount -lf "${STAGING_DIR}/run" 2>/dev/null || true
    umount -lf "${STAGING_DIR}/sys" 2>/dev/null || true
    umount -lf "${STAGING_DIR}/proc" 2>/dev/null || true
    umount -lf "${STAGING_DIR}/dev/pts" 2>/dev/null || true
    umount -lf "${STAGING_DIR}/dev" 2>/dev/null || true
}
trap cleanup_chroot EXIT INT TERM

# Install live-boot dependencies inside the chroot
echo "      Installing live-boot inside staging environment..."
chroot "$STAGING_DIR" /bin/bash -c "apt-get update && env DEBIAN_FRONTEND=noninteractive apt-get install -y live-boot live-boot-initramfs-tools"
# Clean up apt to save space
chroot "$STAGING_DIR" /bin/bash -c "apt-get clean && rm -rf /var/lib/apt/lists/*"

# Rebuild initramfs to include live hooks
echo "      Rebuilding initramfs..."
chroot "$STAGING_DIR" /bin/bash -c "update-initramfs -u -k all"

# Extract kernel and initrd to ISO directory
echo "      Copying kernel and initramfs to ISO..."
cp "$STAGING_DIR"/boot/vmlinuz-* "$ISO_LIVE_DIR/vmlinuz"
cp "$STAGING_DIR"/boot/initrd.img-* "$ISO_LIVE_DIR/initrd.img"

# Explicitly unmount virtual filesystems BEFORE mksquashfs
echo "      Unmounting virtual filesystems before squashfs compression..."
cleanup_chroot
trap - EXIT INT TERM # Remove the trap since we manually cleaned up

echo "Verificando mounts restantes dentro do rootfs..."
if findmnt -R "$STAGING_DIR" | grep -q "$STAGING_DIR"; then
    echo "ERRO: ainda existem mounts dentro do rootfs."
    findmnt -R "$STAGING_DIR"
    exit 1
fi

# ==========================================
# 2. Prepare Live Configs & Compress Squashfs
# ==========================================
echo "[2/4] Preparing live configs and compressing to squashfs..."

# Limpar o fstab para o Live Boot (evita erros do systemd-fstab-generator e systemd-remount-fs)
echo "# UNCONFIGURED FSTAB FOR LIVE SYSTEM" > "${STAGING_DIR}/etc/fstab"

echo "[2/4] Compressing filesystem to squashfs (this may take a while)..."
# Using moderate Zstd compression to balance size and decompression speed for old CPUs
mksquashfs "$STAGING_DIR" "${ISO_LIVE_DIR}/filesystem.squashfs" -comp zstd -Xcompression-level 3 -b 256K -mem 2G -processors 2 -wildcards -e "proc/*" "sys/*" "run/*" "tmp/*" "mnt/*" "media/*" "lost+found/*"

# Generate SHA256 checksum for Live media integrity verification (14H.0)
echo "      Generating filesystem.squashfs.sha256..."
(cd "${ISO_LIVE_DIR}" && sha256sum filesystem.squashfs > filesystem.squashfs.sha256)
echo "      SHA256: $(cat "${ISO_LIVE_DIR}/filesystem.squashfs.sha256")"

# ==========================================
# 3. Create GRUB Configuration
# ==========================================
echo "[3/4] Generating GRUB configuration..."
cat << 'EOF' > "${ISO_BOOT_DIR}/grub.cfg"
set default=0
set timeout=5

menuentry "Flavos OS Live" {
    linux /live/vmlinuz boot=live components nopersistence noeject overlay-size=512M quiet splash
    initrd /live/initrd.img
}

menuentry "Flavos OS Live (Safe Graphics)" {
    linux /live/vmlinuz boot=live components nopersistence noeject overlay-size=512M flavos.graphics=safe nomodeset quiet splash
    initrd /live/initrd.img
}

menuentry "Flavos OS Live (VIA/OpenChrome)" {
    linux /live/vmlinuz boot=live components nopersistence noeject overlay-size=512M flavos.graphics=openchrome nomodeset quiet splash
    initrd /live/initrd.img
}

menuentry "Flavos OS Live (VESA)" {
    linux /live/vmlinuz boot=live components nopersistence noeject overlay-size=512M flavos.graphics=vesa nomodeset quiet splash
    initrd /live/initrd.img
}

menuentry "Flavos OS Live (Framebuffer)" {
    linux /live/vmlinuz boot=live components nopersistence noeject overlay-size=384M flavos.graphics=fbdev nomodeset quiet
    initrd /live/initrd.img
}

menuentry "Flavos OS Live (TTY Recovery)" {
    linux /live/vmlinuz boot=live components nopersistence noeject overlay-size=384M systemd.unit=multi-user.target nomodeset quiet
    initrd /live/initrd.img
}

menuentry "Flavos OS Live (Low RAM)" {
    linux /live/vmlinuz boot=live components nopersistence noeject overlay-size=384M quiet splash
    initrd /live/initrd.img
}
EOF

# ==========================================
# 4. Generate ISO
# ==========================================
echo "[4/4] Generating Hybrid ISO..."
# Requires grub-mkrescue, xorriso, grub-pc-bin, grub-efi-amd64-bin
if command -v grub-mkrescue >/dev/null 2>&1; then
    grub-mkrescue -o "$OUTPUT_ISO" "$ISO_DIR"
    echo ""
    echo "========================================="
    echo "SUCCESS: Experimental Live ISO created at $OUTPUT_ISO"
    echo "You can test it in a VM (VirtualBox/QEMU)."
    echo "========================================="
else
    echo "ERROR: grub-mkrescue not found. Please install grub-common, xorriso, grub-pc-bin, and grub-efi-amd64-bin."
    exit 1
fi
