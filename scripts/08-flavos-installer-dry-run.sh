#!/usr/bin/env bash
#
# 08-flavos-installer-dry-run.sh
# Etapa 14E — Flavos OS Live Installer Strategy (Dry Run)
#
# Este script é um STUB/DRY-RUN. Ele não realiza nenhuma operação
# destrutiva (sem parted, mkfs, dd, wipefs). Apenas analisa o ambiente
# e simula um plano de instalação.

set -euo pipefail

# Cores
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
RESET='\033[0m'

echo -e "${BLUE}=================================================${RESET}"
echo -e "${CYAN}    Flavos OS Installer - TUI Dry Run (14E)      ${RESET}"
echo -e "${BLUE}=================================================${RESET}"
echo -e "MODO: ${YELLOW}Simulação (Somente Leitura)${RESET}"
echo -e "AVISO: Nenhuma alteração real será feita no disco.\n"

# 1. Detectar Live Environment
echo -e "${BLUE}[1] Detectando Ambiente Live...${RESET}"
IS_LIVE=false
if [ -d "/run/live/medium" ] || [ -d "/lib/live/mount/medium" ]; then
    IS_LIVE=true
    echo -e "  ${GREEN}✓ Live Environment detectado.${RESET}"
else
    echo -e "  ${YELLOW}⚠ Não rodando em ambiente LiveBoot padrão.${RESET}"
fi

# 2. Detectar Payload (squashfs)
echo -e "\n${BLUE}[2] Procurando Payload...${RESET}"
if find /run /lib -type f -name "filesystem.squashfs" 2>/dev/null | grep -q .; then
    PAYLOAD_LOC=$(find /run /lib -type f -name "filesystem.squashfs" 2>/dev/null | head -n 1)
    echo -e "  ${GREEN}✓ Payload encontrado:${RESET} $PAYLOAD_LOC"
    PAYLOAD_SIZE=$(du -h "$PAYLOAD_LOC" | cut -f1)
    echo -e "  Tamanho comprimido: $PAYLOAD_SIZE"
else
    echo -e "  ${YELLOW}⚠ filesystem.squashfs não encontrado (execução host?).${RESET}"
fi

# 3. Detectar Firmware (BIOS/UEFI)
echo -e "\n${BLUE}[3] Detectando Firmware...${RESET}"
if [ -d "/sys/firmware/efi" ]; then
    echo -e "  ${GREEN}✓ UEFI Mode${RESET}"
    FIRMWARE="UEFI"
else
    echo -e "  ${GREEN}✓ Legacy BIOS Mode${RESET}"
    FIRMWARE="BIOS"
fi

# 4. Listar Discos Disponíveis
echo -e "\n${BLUE}[4] Varredura de Discos (lsblk)...${RESET}"
lsblk -d -o NAME,SIZE,MODEL,TRAN | grep -E 'sd|nvme|vd|hd' | awk '{printf "  - /dev/%-6s %-10s %-20s (%s)\n", $1, $2, $3, $4}' || echo -e "  ${RED}Nenhum disco compatível encontrado.${RESET}"

echo -e "\n${BLUE}=================================================${RESET}"
echo -e "${CYAN}    PLANO DE INSTALAÇÃO SIMULADO                 ${RESET}"
echo -e "${BLUE}=================================================${RESET}"
echo -e "  1. Selecionar disco destino (ex: /dev/vda)"
if [ "$FIRMWARE" = "UEFI" ]; then
    echo -e "  2. Criar tabela GPT"
    echo -e "  3. Criar Partição 1: 512MB FAT32 (ESP)"
    echo -e "  4. Criar Partição 2: Restante ext4 (Root)"
    echo -e "  5. Instalar systemd-boot na ESP"
else
    echo -e "  2. Criar tabela GPT + partição bios_grub (1MB)"
    echo -e "  3. Criar Partição 2: Restante ext4 (Root)"
    echo -e "  4. Instalar grub-pc na MBR/BIOS"
fi
echo -e "  6. Sincronizar via rsync (squashfs -> /mnt/root)"
echo -e "  7. Post-install chroot (fstab, machine-id, users)"
echo -e "  8. Configuração Final e Unmount"
echo -e "${BLUE}=================================================${RESET}"
echo -e "${GREEN}Simulação concluída com sucesso. Nenhum disco alterado.${RESET}"
exit 0
