#!/usr/bin/env bash
# Flavos OS — Gerador de Manifesto da Build
# Cria um manifesto verificável após o sucesso da pipeline.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="${PROJECT_ROOT}/build"
ROOTFS="${BUILD_DIR}/rootfs"
IMAGE="${BUILD_DIR}/flavos.img"
MANIFEST="${BUILD_DIR}/manifest.json"

echo "=== Flavos OS — Gerando Metadados (Manifesto) ==="

if [[ ! -f "$IMAGE" ]]; then
    echo "ERRO: Imagem final nao encontrada em $IMAGE."
    exit 1
fi

DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Extraindo Kernel iterativamente do RootFS gerado
KERNEL_VER=$(ls ${ROOTFS}/boot/vmlinuz-* 2>/dev/null | head -1 | awk -F'vmlinuz-' '{print $2}' || echo "N/A")

# Sumario Hash OOB nativo
CHECKSUM=$(sha256sum "$IMAGE" 2>/dev/null | awk '{print $1}' || echo "N/A")
SIZE=$(du -h "$IMAGE" 2>/dev/null | awk '{print $1}' || echo "N/A")

# Gerando payload JSON
cat > "$MANIFEST" <<EOF
{
  "os": "Flavos OS",
  "version": "0.1.0-Ignition",
  "build_date": "${DATE}",
  "kernel": "${KERNEL_VER}",
  "artifacts": {
    "image": "flavos.img",
    "size": "${SIZE}",
    "sha256sum": "${CHECKSUM}"
  }
}
EOF

echo "  -> Manifesto limpo gravado em: $MANIFEST"
echo "  -> Checksum SHA256: $CHECKSUM"
