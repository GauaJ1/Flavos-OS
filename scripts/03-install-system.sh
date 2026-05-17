#!/usr/bin/env bash
# Flavos OS — Instalação do sistema na imagem
# Copia rootfs para a partição root, instala bootloader na ESP,
# configura fstab e boot entry com PARTUUIDs reais.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
source "${PROJECT_ROOT}/config/flavos.conf"

IMAGE="${PROJECT_ROOT}/${IMAGE_PATH}"
ROOTFS="${PROJECT_ROOT}/${ROOTFS_DIR}"
PARTUUIDS_FILE="${PROJECT_ROOT}/${BUILD_DIR}/partuuids.env"
MNT_ROOT="${PROJECT_ROOT}/${BUILD_DIR}/mnt_root"
MNT_ESP="${PROJECT_ROOT}/${BUILD_DIR}/mnt_esp"

if [[ "$EUID" -ne 0 ]]; then
    echo "ERRO: Este script precisa ser executado como root (sudo)."
    exit 1
fi

if [[ ! -f "$IMAGE" ]]; then
    echo "ERRO: Imagem não encontrada em $IMAGE. Execute 'make image' primeiro."
    exit 1
fi

if [[ ! -d "$ROOTFS" ]]; then
    echo "ERRO: rootfs não encontrado em $ROOTFS. Execute 'make rootfs' primeiro."
    exit 1
fi

if [[ ! -f "$PARTUUIDS_FILE" ]]; then
    echo "ERRO: partuuids.env não encontrado. Execute 'make image' primeiro."
    exit 1
fi

echo "=== Flavos OS — Instalando Sistema na Imagem ==="

# --- Carregar PARTUUIDs ---
source "$PARTUUIDS_FILE"

# --- Montar imagem ---
echo "[1/6] Montando imagem..."
LOOP_DEV=$(losetup --find --show --partscan "$IMAGE")
sleep 1
partprobe "$LOOP_DEV" 2>/dev/null || true
sleep 1

PART1="${LOOP_DEV}p1"
PART2="${LOOP_DEV}p2"

if [[ ! -b "$PART1" ]] || [[ ! -b "$PART2" ]]; then
    LOOP_NAME=$(basename "$LOOP_DEV")
    kpartx -av "$IMAGE" 2>/dev/null || true
    PART1="/dev/mapper/${LOOP_NAME}p1"
    PART2="/dev/mapper/${LOOP_NAME}p2"
    sleep 1
fi

# Reler PARTUUIDs atualizado do loop atual
ESP_PARTUUID=$(blkid -s PARTUUID -o value "$PART1")
ROOT_PARTUUID=$(blkid -s PARTUUID -o value "$PART2")

mkdir -p "$MNT_ROOT" "$MNT_ESP"
mount "$PART2" "$MNT_ROOT"
mount "$PART1" "$MNT_ESP"

cleanup() {
    echo "Sincronizando I/O..."
    sync
    echo "Desmontando e limpando..."
    umount "$MNT_ESP"  2>/dev/null || umount -l "$MNT_ESP"  2>/dev/null || true
    umount "$MNT_ROOT" 2>/dev/null || umount -l "$MNT_ROOT" 2>/dev/null || true
    losetup -d "$LOOP_DEV" 2>/dev/null || true
}
trap cleanup EXIT

# --- Copiar rootfs ---
echo "[2/6] Copiando rootfs para partição root..."
cp -a "${ROOTFS}/"* "$MNT_ROOT/"

echo "  Aplicando atualizações do overlay..."
if [[ -d "${PROJECT_ROOT}/overlay" ]]; then
    cp -a "${PROJECT_ROOT}/overlay/"* "$MNT_ROOT/"
fi

# Garantir permissões corretas nos helpers privilegiados (pkexec exige root:root + 0755)
HELPERS_DIR="${MNT_ROOT}/usr/local/lib/flavos/helpers"
if [[ -d "$HELPERS_DIR" ]]; then
    chown root:root "${HELPERS_DIR}/"* 2>/dev/null || true
    chmod 0755 "${HELPERS_DIR}/"*       2>/dev/null || true
    echo "  Helpers privilegiados: permissões aplicadas"
fi

# sudoers.d: deve ser root:root 0440, ou sudo ignora o arquivo completamente
SUDOERS_FILE="${MNT_ROOT}/etc/sudoers.d/flavos-settings"
if [[ -f "$SUDOERS_FILE" ]]; then
    chown root:root "$SUDOERS_FILE"
    chmod 0440 "$SUDOERS_FILE"
    echo "  sudoers.d/flavos-settings: permissões 0440 aplicadas"
fi

# --- Substituir PARTUUIDs no fstab ---
echo "[3/6] Configurando fstab com PARTUUIDs reais..."
sed -i "s|__PARTUUID_ROOT__|${ROOT_PARTUUID}|g" "${MNT_ROOT}/etc/fstab"
sed -i "s|__PARTUUID_ESP__|${ESP_PARTUUID}|g"   "${MNT_ROOT}/etc/fstab"
echo "  fstab:"
cat "${MNT_ROOT}/etc/fstab"

# --- Instalar systemd-boot na ESP ---
echo "[4/6] Instalando systemd-boot na ESP..."
mkdir -p "${MNT_ESP}/EFI/systemd"
mkdir -p "${MNT_ESP}/EFI/BOOT"
mkdir -p "${MNT_ESP}/loader/entries"

# Copiar o binário EFI do systemd-boot
# Em Debian, o binário está em /usr/lib/systemd/boot/efi/
BOOT_EFI="${ROOTFS}/usr/lib/systemd/boot/efi/systemd-bootx64.efi"
if [[ ! -f "$BOOT_EFI" ]]; then
    # Fallback: procurar em locais alternativos
    BOOT_EFI=$(find "$ROOTFS" -name "systemd-bootx64.efi" -type f 2>/dev/null | head -1)
fi

if [[ -z "$BOOT_EFI" ]] || [[ ! -f "$BOOT_EFI" ]]; then
    echo "ERRO: systemd-bootx64.efi não encontrado no rootfs."
    echo "Verify que systemd-boot está instalado via packages.list."
    exit 1
fi

cp "$BOOT_EFI" "${MNT_ESP}/EFI/systemd/systemd-bootx64.efi"
cp "$BOOT_EFI" "${MNT_ESP}/EFI/BOOT/BOOTX64.EFI"
echo "  EFI binário instalado"

# --- Copiar configuração do loader ---
echo "[5/6] Configurando boot entries..."
cp "${PROJECT_ROOT}/config/loader/loader.conf" "${MNT_ESP}/loader/loader.conf"

# Copiar entry e substituir PARTUUID
cp "${PROJECT_ROOT}/config/loader/entries/flavos.conf" "${MNT_ESP}/loader/entries/flavos.conf"
sed -i "s|__PARTUUID_ROOT__|${ROOT_PARTUUID}|g" "${MNT_ESP}/loader/entries/flavos.conf"
echo "  Boot entry:"
cat "${MNT_ESP}/loader/entries/flavos.conf"

# --- Copiar kernel e initramfs para ESP ---
echo "[6/6] Copiando kernel e initramfs para ESP..."
VMLINUZ=$(find "${MNT_ROOT}/boot" -name "vmlinuz-*" -type f | sort -V | tail -1)
INITRD=$(find "${MNT_ROOT}/boot" -name "initrd.img-*" -type f | sort -V | tail -1)

if [[ -z "$VMLINUZ" ]]; then
    echo "ERRO: vmlinuz não encontrado em ${MNT_ROOT}/boot/"
    exit 1
fi

if [[ -z "$INITRD" ]]; then
    echo "ERRO: initrd.img não encontrado em ${MNT_ROOT}/boot/"
    exit 1
fi

cp "$VMLINUZ" "${MNT_ESP}/vmlinuz"
cp "$INITRD"  "${MNT_ESP}/initrd.img"
echo "  Kernel: $(basename "$VMLINUZ")"
echo "  Initrd: $(basename "$INITRD")"

# --- Salvar estado atualizado ---
cat > "$PARTUUIDS_FILE" <<EOF
ESP_PARTUUID=${ESP_PARTUUID}
ROOT_PARTUUID=${ROOT_PARTUUID}
EOF

echo ""
echo "=== Sistema instalado com sucesso ==="
echo "Imagem pronta: $IMAGE"
echo ""
echo "Conteúdo da ESP:"
find "$MNT_ESP" -type f | sed "s|${MNT_ESP}|  |"
