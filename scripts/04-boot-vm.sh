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

# Valores padrão
DISPLAY_MODE="--serial"
DISK_BUS="virtio"
NET_MODEL="virtio"
DUMMY_DISK=""

# Parse de argumentos
while [[ $# -gt 0 ]]; do
    case "$1" in
        --serial|--gui)
            DISPLAY_MODE="$1"
            shift
            ;;
        --disk-bus)
            DISK_BUS="$2"
            shift 2
            ;;
        --net-model)
            NET_MODEL="$2"
            shift 2
            ;;
        --attach-dummy)
            DUMMY_DISK="$2"
            shift 2
            ;;
        *)
            echo "Uso: $0 [--serial|--gui] [--disk-bus virtio|ahci|nvme] [--net-model virtio|e1000e|rtl8139] [--attach-dummy file.raw]"
            exit 1
            ;;
    esac
done

INPUT_FLAGS=""  # populado apenas no modo --gui
case "$DISPLAY_MODE" in
    --serial)
        DISPLAY_FLAGS="-nographic -serial mon:stdio"
        echo "Display:   serial (texto)"
        ;;
    --gui)
        DISPLAY_FLAGS="-display gtk -serial stdio"
        INPUT_FLAGS="-device usb-ehci,id=ehci -device usb-tablet,bus=ehci.0"
        echo "Display:   GUI (GTK) com usb-tablet"
        ;;
esac

# Configurar Storage (Disk Bus)
case "$DISK_BUS" in
    virtio)
        DRIVE_FLAG="-drive file=$IMAGE,format=raw,if=virtio"
        echo "Storage:   virtio-blk"
        ;;
    ahci)
        DRIVE_FLAG="-drive id=disk0,file=$IMAGE,format=raw,if=none -device ahci,id=ahci -device ide-hd,drive=disk0,bus=ahci.0"
        echo "Storage:   SATA (AHCI)"
        ;;
    nvme)
        DRIVE_FLAG="-drive id=nvme0,file=$IMAGE,format=raw,if=none -device nvme,serial=1234,drive=nvme0"
        echo "Storage:   NVMe"
        ;;
    *)
        echo "ERRO: --disk-bus $DISK_BUS não suportado (use: virtio, ahci, nvme)"
        exit 1
        ;;
esac

# Configurar Rede
NET_FLAG="-net nic,model=$NET_MODEL -net user"
echo "Network:   $NET_MODEL"

# Adicionar Dummy Disk para testes de write-to-disk
DUMMY_FLAG=""
if [[ -n "$DUMMY_DISK" ]]; then
    if [[ ! -f "$DUMMY_DISK" ]]; then
        echo "ERRO: Dummy disk $DUMMY_DISK não encontrado."
        exit 1
    fi
    DUMMY_FLAG="-drive file=$DUMMY_DISK,format=raw,if=virtio"
    echo "Dummy Disk: Anexado ($DUMMY_DISK)"
fi

echo ""

# shellcheck disable=SC2086
qemu-system-x86_64 \
    $KVM_FLAG \
    -m "$QEMU_RAM" \
    -smp "$QEMU_CPUS" \
    $DRIVE_FLAG \
    $DUMMY_FLAG \
    -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
    -drive if=pflash,format=raw,file="$OVMF_VARS" \
    $NET_FLAG \
    $INPUT_FLAGS \
    $DISPLAY_FLAGS
