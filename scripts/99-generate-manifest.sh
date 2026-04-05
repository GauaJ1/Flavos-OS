#!/usr/bin/env bash
# Flavos OS — Gerador de Manifesto da Build
# Cria um manifesto verificável após o sucesso da pipeline.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
# Puxa variáveis do config principal para amarrar a coerência de versão.
source "${PROJECT_ROOT}/config/flavos.conf"

BUILD_DIR="${PROJECT_ROOT}/build"
ROOTFS="${BUILD_DIR}/rootfs"
IMAGE="${BUILD_DIR}/${IMAGE_NAME}"
MANIFEST="${BUILD_DIR}/flavos-${FLAVOS_VERSION}-manifest.json"

echo "=== Flavos OS — Gerando Manifesto do RC ==="

if [[ ! -f "$IMAGE" ]]; then
    echo "ERRO: Imagem final nao encontrada em $IMAGE."
    exit 1
fi

DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Extraindo Kernel iterativamente do RootFS gerado
KERNEL_VER=$(ls ${ROOTFS}/boot/vmlinuz-* 2>/dev/null | head -1 | awk -F'vmlinuz-' '{print $2}' || echo "N/A")

# Hash nativa e isolada pro RC
CHECKSUM=$(sha256sum "$IMAGE" 2>/dev/null | awk '{print $1}' || echo "N/A")
echo "$CHECKSUM  $IMAGE_NAME" > "${IMAGE}.sha256"

SIZE=$(du -h "$IMAGE" 2>/dev/null | awk '{print $1}' || echo "N/A")

# Gerando payload JSON Final
cat > "$MANIFEST" <<EOF
{
  "project": "${FLAVOS_NAME}",
  "version": "${FLAVOS_VERSION}",
  "codename": "${FLAVOS_CODENAME}",
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
  "validation_status": "VM-Lab Only (Tier 2 Virtual)",
  "known_limitations": "Hardware Real não chancelado. Secure Boot desativado.",
  "artifacts": {
    "image": "${IMAGE_NAME}",
    "size": "${SIZE}",
    "sha256sum": "${CHECKSUM}"
  }
}
EOF

echo "  -> Artefato: $IMAGE_NAME"
echo "  -> Checksum SHA256: $CHECKSUM"
echo "  -> Manifesto exportado: $(basename "$MANIFEST")"

