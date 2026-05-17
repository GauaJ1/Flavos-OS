#!/usr/bin/env bash
#
# 10-boot-installed-vm.sh
# Inicializa o Flavos OS instalado no QEMU a partir do disco virtual (Etapa 14I)
#
# Uso:
#   bash 10-boot-installed-vm.sh [bios|uefi]
#   Padrão: uefi (retrocompatível com 14G)
#
# Targets Makefile:
#   make boot-installed-vm    → uefi (padrão)
#   make boot-installed-uefi  → uefi explícito
#   make boot-installed-bios  → bios (SeaBIOS, sem OVMF)

set -euo pipefail

BOOT_MODE="${1:-uefi}"
TARGET_PATH="${2:-build/live/flavos-install-target-20g.img}"
BUILD_DIR="$(dirname "$TARGET_PATH")"

if [ ! -f "$TARGET_PATH" ]; then
    echo "Erro: Disco virtual de teste não encontrado ($TARGET_PATH)."
    echo "Execute a instalação antes de testar o boot."
    exit 1
fi

IMG_FORMAT=$(qemu-img info "$TARGET_PATH" 2>/dev/null | awk '/^file format:/ {print $3}')
if [ -z "$IMG_FORMAT" ]; then
    IMG_FORMAT="raw"
fi
echo "Formato detectado: $IMG_FORMAT"

case "$BOOT_MODE" in
    bios)
        echo "Iniciando QEMU em modo BIOS (SeaBIOS — sem OVMF)..."
        echo "Alvo: $TARGET_PATH"
        # Modo BIOS: SeaBIOS nativo do QEMU, sem pflash OVMF.
        # if=ide para máxima compatibilidade com hardware legado (LGA 775).
        qemu-system-x86_64 \
            -enable-kvm \
            -m 2048 \
            -cpu host \
            -smp 2 \
            -vga std \
            -display gtk \
            -device virtio-rng-pci \
            -drive file="$TARGET_PATH",format="$IMG_FORMAT",if=ide \
            -boot c
        ;;
    uefi)
        OVMF_VARS_LOCAL="$BUILD_DIR/OVMF_VARS_14G.fd"

        OVMF_CODE=""
        OVMF_VARS_SYSTEM=""

        # Buscar código OVMF
        for p in /usr/share/OVMF/OVMF_CODE.fd /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/qemu/OVMF_CODE.fd; do
            if [ -f "$p" ]; then
                OVMF_CODE="$p"
                break
            fi
        done

        # Buscar variáveis OVMF originais
        for p in /usr/share/OVMF/OVMF_VARS.fd /usr/share/OVMF/OVMF_VARS_4M.fd /usr/share/qemu/OVMF_VARS.fd; do
            if [ -f "$p" ]; then
                OVMF_VARS_SYSTEM="$p"
                break
            fi
        done

        if [ -z "$OVMF_CODE" ] || [ -z "$OVMF_VARS_SYSTEM" ]; then
            echo "Erro: OVMF_CODE ou OVMF_VARS não encontrados no sistema host."
            echo "Instale os pacotes ovmf ou equivalente."
            exit 1
        fi

        if [ ! -f "$OVMF_VARS_LOCAL" ]; then
            echo "Criando cópia local do OVMF_VARS em $OVMF_VARS_LOCAL..."
            mkdir -p "$BUILD_DIR"
            cp "$OVMF_VARS_SYSTEM" "$OVMF_VARS_LOCAL"
        fi

        echo "Iniciando QEMU em modo UEFI (OVMF)..."
        echo "Alvo: $TARGET_PATH"
        qemu-system-x86_64 \
            -enable-kvm \
            -m 2048 \
            -cpu host \
            -smp 2 \
            -vga virtio \
            -display gtk \
            -device virtio-rng-pci \
            -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
            -drive if=pflash,format=raw,file="$OVMF_VARS_LOCAL" \
            -drive file="$TARGET_PATH",format="$IMG_FORMAT",if=virtio \
            -boot c
        ;;
    *)
        echo "Erro: modo inválido '$BOOT_MODE'. Use: bios | uefi"
        echo "Uso: $0 [bios|uefi]"
        exit 1
        ;;
esac
