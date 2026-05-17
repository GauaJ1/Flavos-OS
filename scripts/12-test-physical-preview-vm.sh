#!/usr/bin/env bash
#
# scripts/12-test-physical-preview-vm.sh
# Etapa 14J — Teste do flavos-physical-install-preview em VM (sem hardware real)
#
# Este script NÃO toca nenhum disco físico.
# Ele cria um disco virtual, abre o QEMU com a Live ISO + disco virtual,
# e exibe os comandos que o usuário deve executar manualmente dentro da VM.
#
# Uso:
#   sudo bash scripts/12-test-physical-preview-vm.sh
#
# Para automação (CI/dev, sem hardware envolvido):
#   FLAVOS_PHYSICAL_PREVIEW_VM_TEST=YES sudo bash scripts/12-test-physical-preview-vm.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Configuração ───────────────────────────────────────────────────────────────
LIVE_ISO=""
VIRTUAL_DISK="${PROJECT_ROOT}/build/live/flavos-physical-test.img"
VIRTUAL_DISK_SIZE="8G"
VM_RAM="1024"
VM_SMP="2"

echo -e "${BLUE}=== Flavos OS — 14J: Teste Physical Preview em VM ===${RESET}"
echo ""

# ── Descobrir ISO automaticamente ────────────────────────────────────────────
# Pega o .iso mais recente em build/live/ (mesmo nome gerado por 06-create-live-prototype.sh)
ISO_CANDIDATES=("${PROJECT_ROOT}/build/live/"*.iso)
if [ ${#ISO_CANDIDATES[@]} -eq 0 ] || [ ! -f "${ISO_CANDIDATES[0]}" ]; then
    echo -e "${RED}ERRO: Nenhuma ISO encontrada em ${PROJECT_ROOT}/build/live/${RESET}"
    echo "  Execute primeiro: make live"
    exit 1
fi
# Mais recente (ls -t)
LIVE_ISO="$(ls -t "${PROJECT_ROOT}/build/live/"*.iso 2>/dev/null | head -1)"

echo -e "${GREEN}✓ ISO: $LIVE_ISO${RESET}"

# ── Criar disco virtual se não existir ────────────────────────────────────────
if [ ! -f "$VIRTUAL_DISK" ]; then
    echo -e "${BLUE}Criando disco virtual ($VIRTUAL_DISK_SIZE)...${RESET}"
    qemu-img create -f qcow2 "$VIRTUAL_DISK" "$VIRTUAL_DISK_SIZE"
    echo -e "${GREEN}✓ Disco virtual criado: $VIRTUAL_DISK${RESET}"
else
    echo -e "${YELLOW}⚠ Disco virtual já existe: $VIRTUAL_DISK${RESET}"
    echo -e "  Para recriar: rm $VIRTUAL_DISK e rode novamente."
fi

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════${RESET}"
echo -e "${CYAN}  COMANDOS PARA EXECUTAR DENTRO DA VM (no TTY Live)     ${RESET}"
echo -e "${CYAN}════════════════════════════════════════════════════════${RESET}"
echo ""
echo "  # 1. Diagnóstico inicial"
echo "  flavos-physical-install-preview inspect"
echo ""
echo "  # 2. Verificação completa do ambiente (REQUER SUDO)"
echo "  sudo flavos-physical-install-preview precheck"
echo ""
echo "  # 3. Ver o plano (disco virtual será /dev/vda ou /dev/sdb)"
echo "  flavos-physical-install-preview plan --target /dev/vda"
echo ""
echo "  # 4. Instalação no disco virtual"
echo "  sudo FLAVOS_ALLOW_PHYSICAL_INSTALL_PREVIEW=YES \\"
echo "    flavos-physical-install-preview install \\"
echo "      --target /dev/vda \\"
echo "      --bootloader-mode both \\"
echo "      --i-understand-this-erases-physical-disk"
echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════${RESET}"
echo ""

# ── Modo automatizado (CI/dev) ─────────────────────────────────────────────────
if [ "${FLAVOS_PHYSICAL_PREVIEW_VM_TEST:-}" = "YES" ]; then
    echo -e "${YELLOW}⚠ FLAVOS_PHYSICAL_PREVIEW_VM_TEST=YES — modo automatizado detectado.${RESET}"
    # Verificar que estamos dentro de VM (systemd-detect-virt)
    if ! systemd-detect-virt --vm 2>/dev/null; then
        echo -e "${RED}ERRO: Modo automatizado só permitido dentro de VM (systemd-detect-virt).${RESET}"
        exit 1
    fi
    echo -e "${YELLOW}  VM confirmada. Script não executa install automaticamente.${RESET}"
    echo -e "${YELLOW}  Execute os comandos manualmente conforme listado acima.${RESET}"
fi

# ── Abrir QEMU ────────────────────────────────────────────────────────────────
echo -e "${BLUE}Iniciando QEMU com Live ISO + disco virtual...${RESET}"
echo -e "${YELLOW}Use os comandos acima dentro do TTY da VM.${RESET}"
echo ""

# Verificar OVMF (UEFI) opcional
UEFI_ARGS=""
OVMF_CODE="/usr/share/OVMF/OVMF_CODE.fd"
OVMF_VARS="/usr/share/OVMF/OVMF_VARS.fd"
if [ -f "$OVMF_CODE" ]; then
    UEFI_ARGS="-drive if=pflash,format=raw,readonly=on,file=${OVMF_CODE} \
               -drive if=pflash,format=raw,file=${OVMF_VARS}"
    echo -e "${GREEN}✓ OVMF encontrado — boot UEFI disponível.${RESET}"
else
    echo -e "${YELLOW}⚠ OVMF não encontrado — modo BIOS (SeaBIOS) apenas.${RESET}"
fi

qemu-system-x86_64 \
    -m "${VM_RAM}" \
    -smp "${VM_SMP}" \
    -enable-kvm \
    -cpu host \
    -drive if=ide,format=raw,media=cdrom,file="${LIVE_ISO}",readonly=on \
    -drive if=virtio,format=qcow2,file="${VIRTUAL_DISK}" \
    -netdev user,id=net0 -device virtio-net,netdev=net0 \
    -vga std \
    -display gtk \
    ${UEFI_ARGS} \
    "$@"

echo -e "\n${GREEN}VM encerrada.${RESET}"
echo "  Disco virtual: $VIRTUAL_DISK"
echo "  Para testar o boot do disco instalado:"
echo "    make boot-physical-preview-vm"
