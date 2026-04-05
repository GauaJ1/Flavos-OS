#!/usr/bin/env bash
# Flavos OS — Verificação de dependências do host
# Verifica se todas as ferramentas necessárias estão instaladas.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
source "${PROJECT_ROOT}/config/flavos.conf"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

FAILED=0

check_cmd() {
    local cmd="$1"
    local pkg="${2:-$1}"
    if command -v "$cmd" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $cmd"
    else
        echo -e "  ${RED}✗${NC} $cmd (instale: sudo apt install $pkg)"
        FAILED=1
    fi
}

check_file() {
    local path="$1"
    local pkg="$2"
    if [[ -f "$path" ]]; then
        echo -e "  ${GREEN}✓${NC} $path"
    else
        echo -e "  ${RED}✗${NC} $path (instale: sudo apt install $pkg)"
        FAILED=1
    fi
}

echo "=== Flavos OS — Verificação de Dependências ==="
echo ""
echo "Ferramentas de build:"
check_cmd "debootstrap" "debootstrap"
check_cmd "parted" "parted"
check_cmd "mkfs.fat" "dosfstools"
check_cmd "mkfs.ext4" "e2fsprogs"
check_cmd "losetup" "util-linux"
check_cmd "kpartx" "kpartx"
check_cmd "make" "make"
check_cmd "git" "git"

echo ""
echo "Ferramentas de VM:"
check_cmd "qemu-system-x86_64" "qemu-system-x86"
check_file "$OVMF_CODE" "ovmf"

echo ""
echo "Privilégios:"
if [[ "$EUID" -eq 0 ]]; then
    echo -e "  ${GREEN}✓${NC} Executando como root"
else
    if command -v sudo &>/dev/null; then
        echo -e "  ${YELLOW}!${NC} Não é root (sudo disponível — scripts de build usarão sudo)"
    else
        echo -e "  ${RED}✗${NC} Não é root e sudo não encontrado"
        FAILED=1
    fi
fi

echo ""
echo "Espaço em disco:"
AVAIL_KB=$(df --output=avail "$PROJECT_ROOT" | tail -1 | tr -d ' ')
AVAIL_GB=$((AVAIL_KB / 1024 / 1024))
if [[ "$AVAIL_GB" -ge 5 ]]; then
    echo -e "  ${GREEN}✓${NC} ${AVAIL_GB}GB disponíveis (mínimo: 5GB)"
else
    echo -e "  ${RED}✗${NC} ${AVAIL_GB}GB disponíveis (mínimo: 5GB)"
    FAILED=1
fi

echo ""
if [[ "$FAILED" -eq 0 ]]; then
    echo -e "${GREEN}Todas as dependências satisfeitas.${NC}"
    exit 0
else
    echo -e "${RED}Dependências faltando. Instale antes de continuar.${NC}"
    echo ""
    echo "Comando sugerido:"
    echo "  sudo apt install debootstrap parted dosfstools e2fsprogs kpartx qemu-system-x86 ovmf make git util-linux"
    exit 1
fi
