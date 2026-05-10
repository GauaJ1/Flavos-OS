#!/usr/bin/env bash
# Flavos OS — Gerador de Manifesto da Build
# Cria um manifesto verificável após o sucesso da pipeline.
# Prioriza o artefato comprimido (.xz) quando disponível (Etapa 14A).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
# Puxa variáveis do config principal para amarrar a coerência de versão.
source "${PROJECT_ROOT}/config/flavos.conf"

BUILD_DIR="${PROJECT_ROOT}/build"
ROOTFS="${BUILD_DIR}/rootfs"
IMAGE="${BUILD_DIR}/${IMAGE_NAME}"
RELEASE_XZ="${BUILD_DIR}/${RELEASE_IMAGE_BASENAME}.img.xz"
RELEASE_SHA="${RELEASE_XZ}.sha256"
MANIFEST="${BUILD_DIR}/flavos-${FLAVOS_VERSION}-manifest.json"

echo "=== Flavos OS — Gerando Manifesto ==="

# Verificar que pelo menos a imagem raw existe.
if [[ ! -f "$IMAGE" ]]; then
    echo "ERRO: Imagem final nao encontrada em $IMAGE."
    exit 1
fi

DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Extraindo Kernel iterativamente do RootFS gerado
KERNEL_VER=$(ls ${ROOTFS}/boot/vmlinuz-* 2>/dev/null | head -1 | awk -F'vmlinuz-' '{print $2}' || echo "N/A")

# Determinar artefato principal de release.
# Prioridade: .xz comprimido > .img puro
if [[ -f "$RELEASE_XZ" ]]; then
    RELEASE_FILE="$RELEASE_XZ"
    RELEASE_FILENAME="${RELEASE_IMAGE_BASENAME}.img.xz"
    RELEASE_TYPE="xz-compressed"
else
    RELEASE_FILE="$IMAGE"
    RELEASE_FILENAME="${IMAGE_NAME}"
    RELEASE_TYPE="raw-img"
fi

# Hash do artefato de release
CHECKSUM=$(sha256sum "$RELEASE_FILE" 2>/dev/null | awk '{print $1}' || echo "N/A")
SIZE=$(du -h "$RELEASE_FILE" 2>/dev/null | awk '{print $1}' || echo "N/A")

# SHA256 do .img puro (para referência interna)
RAW_CHECKSUM=$(sha256sum "$IMAGE" 2>/dev/null | awk '{print $1}' || echo "N/A")
RAW_SIZE=$(du -h "$IMAGE" 2>/dev/null | awk '{print $1}' || echo "N/A")

# Gerando payload JSON Final
cat > "$MANIFEST" <<EOF
{
  "project": "${FLAVOS_NAME}",
  "version": "${FLAVOS_VERSION}",
  "release_version": "${RELEASE_VERSION}",
  "codename": "${FLAVOS_CODENAME}",
  "milestone": "${RELEASE_MILESTONE}-${RELEASE_TAG}",
  "build_date": "${DATE}",
  "kernel": "${KERNEL_VER}",
  "architecture": "${ARCH}",
  "image_type": "raw-gpt",
  "boot_mode": "UEFI-only (systemd-boot)",
  "minimum_requirements": {
    "ram": "1024MB",
    "disk": "4GB",
    "cpu": "x86_64 compatível com KVM"
  },
  "validation_status": "Desktop Preview (Experimental Estável)",
  "known_limitations": "Credenciais DevLocal conhecidas. Secure Boot desativado. Autologin ativo.",
  "release_artifact": {
    "filename": "${RELEASE_FILENAME}",
    "format": "${RELEASE_TYPE}",
    "size": "${SIZE}",
    "sha256sum": "${CHECKSUM}"
  },
  "raw_image": {
    "filename": "${IMAGE_NAME}",
    "size": "${RAW_SIZE}",
    "sha256sum": "${RAW_CHECKSUM}"
  }
}
EOF

echo "  -> Artefato de release: $RELEASE_FILENAME ($SIZE)"
echo "  -> Checksum SHA256: $CHECKSUM"
echo "  -> Manifesto exportado: $(basename "$MANIFEST")"
