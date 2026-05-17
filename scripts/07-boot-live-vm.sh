#!/usr/bin/env bash
# Flavos OS - Live Boot VM Validation Script
# Tests the generated Hybrid ISO in QEMU (BIOS and UEFI modes) with 2GB RAM.

ISO_PATH="build/live/FlavosOS-live-prototype-0.1-daily-amd64.iso"
OVMF_PATH="/usr/share/ovmf/OVMF.fd"

if [ ! -f "$ISO_PATH" ]; then
    echo "ERROR: ISO not found at $ISO_PATH"
    echo "Run 'sudo scripts/06-create-live-prototype.sh' first."
    exit 1
fi

MODE="${1:-bios}"

echo "Starting Flavos OS Live Boot in $MODE mode with 2GB RAM..."

if [ "$MODE" = "uefi" ]; then
    if [ ! -f "$OVMF_PATH" ]; then
        echo "ERROR: OVMF firmware not found at $OVMF_PATH"
        echo "Please install ovmf: sudo apt install ovmf"
        exit 1
    fi
    qemu-system-x86_64 \
        -enable-kvm \
        -m 2048 \
        -cpu host \
        -vga virtio \
        -bios "$OVMF_PATH" \
        -cdrom "$ISO_PATH"
else
    qemu-system-x86_64 \
        -enable-kvm \
        -m 2048 \
        -cpu host \
        -vga virtio \
        -cdrom "$ISO_PATH"
fi
