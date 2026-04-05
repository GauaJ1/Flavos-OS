#!/usr/bin/env bash
# Flavos OS — Smoke Test
# Verifica se a imagem foi construída corretamente antes do boot.
# Teste offline: valida estrutura da imagem e conteúdo sem precisar bootar.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
source "${PROJECT_ROOT}/config/flavos.conf"

IMAGE="${PROJECT_ROOT}/${IMAGE_PATH}"
ROOTFS="${PROJECT_ROOT}/${ROOTFS_DIR}"
PARTUUIDS_FILE="${PROJECT_ROOT}/${BUILD_DIR}/partuuids.env"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

PASSED=0
FAILED=0

check() {
    local desc="$1"
    local result="$2"
    if [[ "$result" == "ok" ]]; then
        echo -e "  ${GREEN}✓${NC} $desc"
        ((PASSED++))
    else
        echo -e "  ${RED}✗${NC} $desc"
        ((FAILED++))
    fi
}

echo "=== Flavos OS — Smoke Test ==="
echo ""

# --- Teste 1: Imagem existe ---
echo "Imagem:"
if [[ -f "$IMAGE" ]]; then
    check "Imagem existe" "ok"
    SIZE=$(stat -c%s "$IMAGE")
if [[ "$SIZE" -gt 0 ]]; then
    check "Tamanho > 0" "ok"
else
    check "Tamanho > 0" "fail"
fi
else
    check "Imagem existe" "fail"
fi

# --- Teste 2: rootfs ---
echo ""
echo "Root Filesystem:"
check "/bin/bash existe"      "$( [[ -f "${ROOTFS}/bin/bash" ]]       && echo ok || echo fail )"
check "/sbin/init existe"     "$( [[ -L "${ROOTFS}/sbin/init" || -f "${ROOTFS}/sbin/init" ]] && echo ok || echo fail )"
check "/etc/os-release existe" "$( [[ -f "${ROOTFS}/etc/os-release" ]] && echo ok || echo fail )"
check "/etc/hostname existe"   "$( [[ -f "${ROOTFS}/etc/hostname" ]]   && echo ok || echo fail )"
check "/etc/fstab existe"      "$( [[ -f "${ROOTFS}/etc/fstab" ]]      && echo ok || echo fail )"

# Verificar que os-release contém "Flavos"
if [[ -f "${ROOTFS}/etc/os-release" ]]; then
    check "os-release contém Flavos" "$( grep -q 'Flavos' "${ROOTFS}/etc/os-release" && echo ok || echo fail )"
fi

# --- Teste 3: Kernel e initramfs ---
echo ""
echo "Kernel e Initramfs:"
check "vmlinuz presente"  "$( ls "${ROOTFS}/boot/vmlinuz-"* &>/dev/null && echo ok || echo fail )"
check "initrd presente"   "$( ls "${ROOTFS}/boot/initrd.img-"* &>/dev/null && echo ok || echo fail )"

# --- Teste 4: Módulos virtio no initramfs config ---
echo ""
echo "Configuração Virtio:"
if [[ -f "${ROOTFS}/etc/initramfs-tools/modules" ]]; then
    check "virtio_blk em initramfs modules" "$( grep -q 'virtio_blk' "${ROOTFS}/etc/initramfs-tools/modules" && echo ok || echo fail )"
    check "virtio_pci em initramfs modules" "$( grep -q 'virtio_pci' "${ROOTFS}/etc/initramfs-tools/modules" && echo ok || echo fail )"
else
    check "initramfs-tools/modules existe" "fail"
fi

# --- Teste 5: PARTUUIDs ---
echo ""
echo "Build Artifacts:"
if [[ -f "$PARTUUIDS_FILE" ]]; then
    check "partuuids.env existe" "ok"
    source "$PARTUUIDS_FILE"
    check "ESP_PARTUUID definido"  "$( [[ -n "${ESP_PARTUUID:-}" ]]  && echo ok || echo fail )"
    check "ROOT_PARTUUID definido" "$( [[ -n "${ROOT_PARTUUID:-}" ]] && echo ok || echo fail )"
else
    check "partuuids.env existe" "fail"
fi

# --- Teste 6: Rede configurada ---
echo ""
echo "Rede:"
check "systemd-networkd config" "$( [[ -f "${ROOTFS}/etc/systemd/network/20-wired.network" ]] && echo ok || echo fail )"

# --- Teste 7: V1 Userspace & Segurança (Etapas 6 e 7) ---
echo ""
echo "V1 Userspace e Policies:"
check "Usuário Diário Configurado" "$( grep -q "${SYS_USER}" "${ROOTFS}/etc/passwd" 2>/dev/null && echo ok || echo fail )"
check "OpenSSH Hardened (Root Ban)" "$( grep -q "PermitRootLogin no" "${ROOTFS}/etc/ssh/sshd_config.d/90-flavos.conf" 2>/dev/null && echo ok || echo fail )"
check "Ferramenta Debug Report (flavos-debug-report)" "$( [[ -x "${ROOTFS}/usr/local/bin/flavos-debug-report" ]] && echo ok || echo fail )"
check "Ferramenta Net Check (flavos-net-check)" "$( [[ -x "${ROOTFS}/usr/local/bin/flavos-net-check" ]] && echo ok || echo fail )"
check "JournalD Configurado (50MB lim)" "$( grep -q "SystemMaxUse=50M" "${ROOTFS}/etc/systemd/journald.conf.d/90-flavos.conf" 2>/dev/null && echo ok || echo fail )"

# --- Resultado ---
echo ""
echo "=== Resultado ==="
TOTAL=$((PASSED + FAILED))
echo -e "Passaram: ${GREEN}${PASSED}${NC}/${TOTAL}"
echo -e "Falharam: ${RED}${FAILED}${NC}/${TOTAL}"
echo ""

if [[ "$FAILED" -eq 0 ]]; then
    echo -e "${GREEN}TODOS OS TESTES PASSARAM${NC}"
    exit 0
else
    echo -e "${RED}HÁ FALHAS — verifique antes de bootar${NC}"
    exit 1
fi
