#!/usr/bin/env bash
# Flavos OS — Boot em VM via QEMU
# Inicia a imagem gerada usando QEMU/KVM com firmware UEFI (OVMF).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
source "${PROJECT_ROOT}/config/flavos.conf"

IMAGE="${PROJECT_ROOT}/${IMAGE_PATH}"

if [[ ! -f "$IMAGE" ]]; then
    echo "ERRO: Imagem não encontrada em $IMAGE."
    echo "Execute 'make all' para gerar a imagem completa."
    exit 1
fi

if [[ ! -f "$OVMF_CODE" ]]; then
    echo "ERRO: OVMF não encontrado em $OVMF_CODE."
    echo "Instale: sudo apt install ovmf"
    exit 1
fi

# OVMF exige pflash para variáveis NVRAM
OVMF_VARS="${PROJECT_ROOT}/${BUILD_DIR}/OVMF_VARS_4M.fd"
if [[ ! -f "$OVMF_VARS" ]]; then
    SYSTEM_VARS="${OVMF_CODE/CODE/VARS}"
    if [[ -f "$SYSTEM_VARS" ]]; then
        cp "$SYSTEM_VARS" "$OVMF_VARS"
    else
        truncate -s 4M "$OVMF_VARS"
    fi
fi

echo "=== Flavos OS — Iniciando VM ==="
echo "Imagem:   $IMAGE"
echo "RAM:      ${QEMU_RAM}MB"
echo "CPUs:     ${QEMU_CPUS}"
echo "Firmware: $OVMF_CODE"
echo ""
echo "Login: root / ${ROOT_PASSWORD}"
echo "Para sair: Ctrl+A, X (modo serial) ou feche a janela"
echo ""

# Detectar se KVM está disponível
KVM_FLAG=""
if [[ -r /dev/kvm ]]; then
    KVM_FLAG="-enable-kvm -cpu host"
    echo "KVM: habilitado"
else
    KVM_FLAG="-cpu qemu64"
    echo "KVM: não disponível (emulação pura — boot será lento)"
fi

# Modo de display
DISPLAY_MODE="${1:---serial}"
INPUT_FLAGS=""  # populado apenas no modo --gui
case "$DISPLAY_MODE" in
    --serial)
        DISPLAY_FLAGS="-nographic -serial mon:stdio"
        echo "Display: serial (texto)"
        ;;
    --gui)
        DISPLAY_FLAGS="-display gtk -serial stdio"
        # usb-tablet usa coordenadas absolutas: elimina drift de cursor entre host e VM
        INPUT_FLAGS="-device usb-ehci,id=ehci -device usb-tablet,bus=ehci.0"
        echo "Display: GUI (GTK) com usb-tablet (sem drift de cursor)"
        ;;
    *)
        echo "Uso: $0 [--serial|--gui]"
        exit 1
        ;;
esac

echo ""

# shellcheck disable=SC2086
qemu-system-x86_64 \
    $KVM_FLAG \
    -m "$QEMU_RAM" \
    -smp "$QEMU_CPUS" \
    -drive file="$IMAGE",format=raw,if=virtio \
    -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
    -drive if=pflash,format=raw,file="$OVMF_VARS" \
    -net nic,model=virtio -net user \
    $INPUT_FLAGS \
    $DISPLAY_FLAGS
