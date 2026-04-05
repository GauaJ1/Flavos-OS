#!/usr/bin/env bash
# Flavos OS — Criação da imagem de disco
# Cria arquivo .img, particiona com GPT (ESP + root), formata.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
source "${PROJECT_ROOT}/config/flavos.conf"

IMAGE="${PROJECT_ROOT}/${IMAGE_PATH}"

if [[ "$EUID" -ne 0 ]]; then
    echo "ERRO: Este script precisa ser executado como root (sudo)."
    exit 1
fi

if [[ -f "$IMAGE" ]]; then
    echo "Imagem já existe em ${IMAGE}. Use 'make clean' para recriar."
    exit 0
fi

echo "=== Flavos OS — Criando Imagem de Disco ==="
echo "Tamanho:  $IMAGE_SIZE"
echo "Destino:  $IMAGE"
echo ""

mkdir -p "$(dirname "$IMAGE")"

# --- Criar arquivo raw ---
echo "[1/4] Criando imagem raw de ${IMAGE_SIZE}..."
truncate -s "$IMAGE_SIZE" "$IMAGE"

# --- Particionar com GPT ---
echo "[2/4] Particionando (GPT: ESP ${ESP_SIZE_MB}MB + root)..."
parted -s "$IMAGE" \
    mklabel gpt \
    mkpart ESP fat32 1MiB "${ESP_SIZE_MB}MiB" \
    set 1 esp on \
    set 1 boot on \
    mkpart root ext4 "${ESP_SIZE_MB}MiB" 100%

# --- Mapear partições via loop device ---
echo "[3/4] Mapeando partições..."
LOOP_DEV=$(losetup --find --show --partscan "$IMAGE")
echo "  Loop device: $LOOP_DEV"

# Aguardar kernel detectar partições
sleep 1
partprobe "$LOOP_DEV" 2>/dev/null || true
sleep 1

PART1="${LOOP_DEV}p1"
PART2="${LOOP_DEV}p2"

# Verificar se as partições apareceram
if [[ ! -b "$PART1" ]] || [[ ! -b "$PART2" ]]; then
    echo "ERRO: Partições não detectadas ($PART1, $PART2)."
    echo "Tentando kpartx..."
    kpartx -av "$IMAGE"
    # kpartx usa /dev/mapper/loopXp1
    LOOP_NAME=$(basename "$LOOP_DEV")
    PART1="/dev/mapper/${LOOP_NAME}p1"
    PART2="/dev/mapper/${LOOP_NAME}p2"
    sleep 1
fi

# --- Formatar partições ---
echo "[4/4] Formatando partições..."
mkfs.fat -F 32 -n FLAVESP "$PART1"
mkfs.ext4 -L flavos-root -F "$PART2"

# Extrair PARTUUIDs
ESP_PARTUUID=$(blkid -s PARTUUID -o value "$PART1")
ROOT_PARTUUID=$(blkid -s PARTUUID -o value "$PART2")

echo ""
echo "  ESP  PARTUUID: $ESP_PARTUUID"
echo "  ROOT PARTUUID: $ROOT_PARTUUID"

# Salvar PARTUUIDs para uso pelos outros scripts
cat > "${PROJECT_ROOT}/${BUILD_DIR}/partuuids.env" <<EOF
ESP_PARTUUID=${ESP_PARTUUID}
ROOT_PARTUUID=${ROOT_PARTUUID}
LOOP_DEV=${LOOP_DEV}
PART1=${PART1}
PART2=${PART2}
EOF

# Desanexar loop device
losetup -d "$LOOP_DEV" 2>/dev/null || true

echo ""
echo "=== Imagem criada com sucesso ==="
echo "Caminho: $IMAGE"
echo "PARTUUIDs salvos em: ${BUILD_DIR}/partuuids.env"
