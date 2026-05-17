#!/usr/bin/env bash
#
# 09-boot-live-install-lab.sh
# Inicializa o Flavos OS Live no QEMU com um disco virtual extra
# para simular a instalação (Laboratório 14F).

set -euo pipefail

# Variáveis
BUILD_DIR="build/live"
ISO_NAME="FlavosOS-live-prototype-0.1-daily-amd64.iso"
TARGET_IMG="flavos-install-target-20g.img"

if [ ! -f "$BUILD_DIR/$ISO_NAME" ]; then
    echo "Erro: Imagem live não encontrada em $BUILD_DIR/$ISO_NAME"
    echo "Execute: sudo scripts/06-create-live-prototype.sh primeiro."
    exit 1
fi

if [ ! -f "$BUILD_DIR/$TARGET_IMG" ]; then
    echo "Criando disco virtual vazio (20GB) para o laboratório de instalação..."
    qemu-img create -f raw "$BUILD_DIR/$TARGET_IMG" 20G
else
    echo "Aviso: O disco virtual de teste $BUILD_DIR/$TARGET_IMG já existe."
    echo "Se você quiser testar do zero, exclua-o manualmente primeiro."
fi

# Tentar encontrar a bios UEFI se necessário.
# Por padrão, vamos fazer UEFI.
OVMF_PATH=""
for p in /usr/share/OVMF/OVMF_CODE.fd /usr/share/qemu/OVMF.fd; do
    if [ -f "$p" ]; then
        OVMF_PATH="$p"
        break
    fi
done

if [ -z "$OVMF_PATH" ]; then
    echo "Aviso: OVMF (UEFI) não encontrado. O QEMU fará boot em modo BIOS Legacy."
    QEMU_BIOS=""
else
    QEMU_BIOS="-bios $OVMF_PATH"
fi

echo "Iniciando QEMU com a ISO Live e o Disco de Laboratório..."
qemu-system-x86_64 \
    -enable-kvm \
    -m 2048 \
    -cpu host \
    -smp 2 \
    -vga virtio \
    -display gtk \
    -device virtio-rng-pci \
    $QEMU_BIOS \
    -cdrom "$BUILD_DIR/$ISO_NAME" \
    -drive file="$BUILD_DIR/$TARGET_IMG",format=raw,if=virtio \
    -boot d
