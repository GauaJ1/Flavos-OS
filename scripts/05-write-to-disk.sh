#!/usr/bin/env bash
# Flavos OS — Write to Disk (Hardware Real)
# Grava a imagem flavos.img em um disco físico com confirmação explícita.
#
# ATENÇÃO: Este script sobrescreve completamente o disco alvo.
#          Todos os dados no disco serão PERMANENTEMENTE PERDIDOS.
#
# USO: sudo bash 05-write-to-disk.sh --disk /dev/sdX
#
# NUNCA execute sem --disk. Nenhum disco será escolhido automaticamente.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
source "${PROJECT_ROOT}/config/flavos.conf"

IMAGE="${PROJECT_ROOT}/${IMAGE_PATH}"
MIN_DISK_BYTES=2684354560  # 2.5 GB em bytes

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m'

# ---------- Verificação de Root ----------
if [[ "$EUID" -ne 0 ]]; then
    echo -e "${RED}ERRO: Este script precisa ser executado como root (sudo).${NC}"
    exit 1
fi

# ---------- Parse de Argumentos ----------
TARGET_DISK=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --disk)
            TARGET_DISK="$2"
            shift 2
            ;;
        *)
            echo "Argumento desconhecido: $1"
            echo "Uso: sudo bash 05-write-to-disk.sh --disk /dev/sdX"
            exit 1
            ;;
    esac
done

# ---------- GUARDA 1: Disco deve ser explícito ----------
if [[ -z "$TARGET_DISK" ]]; then
    echo ""
    echo -e "${RED}ERRO CRÍTICO: Nenhum disco alvo especificado.${NC}"
    echo ""
    echo "  Você DEVE especificar o disco alvo explicitamente:"
    echo "      sudo bash 05-write-to-disk.sh --disk /dev/sdX"
    echo ""
    echo "  Discos disponíveis no sistema:"
    lsblk -d -o NAME,SIZE,MODEL,TRAN,TYPE | grep disk || lsblk -d -o NAME,SIZE,TYPE | grep disk
    echo ""
    echo "  ATENÇÃO: Identifique o disco correto ANTES de continuar."
    echo "           O disco alvo terá TODOS os dados apagados."
    exit 1
fi

# ---------- Verificação da Imagem ----------
if [[ ! -f "$IMAGE" ]]; then
    echo -e "${RED}ERRO: Imagem não encontrada em $IMAGE${NC}"
    echo "Execute 'make all' para gerar a imagem primeiro."
    exit 1
fi

# ---------- Verificação do Disco ----------
if [[ ! -b "$TARGET_DISK" ]]; then
    echo -e "${RED}ERRO: '$TARGET_DISK' não é um dispositivo de bloco válido.${NC}"
    echo "Verifique com: lsblk"
    exit 1
fi

# ---------- GUARDA 2: Não permite raiz do sistema ----------
# Detecta o disco onde está montada a raiz do host
ROOT_DISK=$(lsblk -no PKNAME "$(findmnt -n -o SOURCE /)" 2>/dev/null | head -1 || true)
if [[ -n "$ROOT_DISK" ]]; then
    ROOT_DISK_PATH="/dev/${ROOT_DISK}"
    if [[ "$TARGET_DISK" == "$ROOT_DISK_PATH" ]] || \
       [[ "$TARGET_DISK" == "${ROOT_DISK_PATH}p"* ]] || \
       [[ "$TARGET_DISK" == "/dev/${ROOT_DISK}"* ]]; then
        echo ""
        echo -e "${RED}╔══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║  OPERAÇÃO BLOQUEADA — DISCO DO SISTEMA HOST DETECTADO    ║${NC}"
        echo -e "${RED}╚══════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  O disco ${BOLD}${TARGET_DISK}${NC} parece ser o disco principal do sistema."
        echo -e "  Disco raiz do host detectado: ${BOLD}${ROOT_DISK_PATH}${NC}"
        echo ""
        echo "  Instalar neste disco destruiria seu sistema operacional atual."
        echo "  Use um disco secundário ou pendrive externo."
        exit 1
    fi
fi

# ---------- Verificação de Tamanho Mínimo ----------
DISK_BYTES=$(lsblk -b -d -o SIZE -n "$TARGET_DISK" 2>/dev/null | head -1 || echo 0)
if [[ "$DISK_BYTES" -lt "$MIN_DISK_BYTES" ]]; then
    DISK_HUMAN=$(lsblk -d -o SIZE -n "$TARGET_DISK" | head -1)
    echo -e "${RED}ERRO: Disco pequeno demais.${NC}"
    echo "  Disco: $DISK_HUMAN | Mínimo necessário: 2.5 GB"
    exit 1
fi

# ---------- Informações do Alvo ----------
IMAGE_SIZE=$(du -h "$IMAGE" | awk '{print $1}')
DISK_MODEL=$(lsblk -d -o MODEL -n "$TARGET_DISK" 2>/dev/null | xargs || echo "Desconhecido")
DISK_SIZE=$(lsblk -d -o SIZE -n "$TARGET_DISK" | head -1)
DISK_TRAN=$(lsblk -d -o TRAN -n "$TARGET_DISK" 2>/dev/null | xargs || echo "?")

echo ""
echo -e "${YELLOW}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║         FLAVOS OS — GRAVAÇÃO EM DISCO FÍSICO             ║${NC}"
echo -e "${YELLOW}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${BOLD}Imagem Fonte:${NC}  $IMAGE ($IMAGE_SIZE)"
echo -e "  ${BOLD}Disco Alvo:${NC}    $TARGET_DISK"
echo -e "  ${BOLD}Modelo:${NC}        $DISK_MODEL"
echo -e "  ${BOLD}Tamanho:${NC}       $DISK_SIZE"
echo -e "  ${BOLD}Interface:${NC}     $DISK_TRAN"
echo ""
echo "  Partições atuais do disco alvo:"
lsblk "$TARGET_DISK" || true
echo ""
echo -e "${RED}  ╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}  ║  ATENÇÃO: ESTA OPERAÇÃO É IRREVERSÍVEL                  ║${NC}"
echo -e "${RED}  ║  Todos os dados em ${TARGET_DISK} serão PERMANENTEMENTE     ║${NC}"
echo -e "${RED}  ║  apagados e substituídos pelo Flavos OS.                 ║${NC}"
echo -e "${RED}  ╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# ---------- GUARDA 3: Confirmação Explícita por Digitação ----------
echo -e "  Para confirmar, digite exatamente o caminho do disco: ${BOLD}${TARGET_DISK}${NC}"
echo -n "  Confirmação: "
read -r CONFIRM

if [[ "$CONFIRM" != "$TARGET_DISK" ]]; then
    echo ""
    echo -e "${YELLOW}Operação cancelada. Nenhum dado foi escrito.${NC}"
    exit 0
fi

# ---------- Desmonta partições ativas ----------
echo ""
echo "Desmontando partições ativas do disco alvo..."
for part in $(lsblk -ln -o NAME "$TARGET_DISK" | tail -n +2); do
    umount "/dev/${part}" 2>/dev/null || true
done

# ---------- Gravação via dd ----------
echo ""
echo -e "${GREEN}Iniciando gravação...${NC}"
echo "  Isso pode levar vários minutos dependendo da velocidade do disco."
echo ""

dd if="$IMAGE" of="$TARGET_DISK" bs=4M status=progress conv=fsync

echo ""
sync

echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Gravação concluída com sucesso!                         ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "  Próximos passos:"
echo "  1. Ejete o disco com segurança"
echo "  2. Conecte ao hardware alvo (UEFI, Secure Boot DESABILITADO)"
echo "  3. No BIOS/UEFI, selecione o disco como boot device"
echo "  4. O Flavos OS deve iniciar em modo console"
echo ""
echo "  Em caso de falha de boot, consulte: docs/RECOVERY.md"
