#!/usr/bin/env bash
# Flavos OS — Geração do Root Filesystem
# Executa debootstrap, configura o chroot, instala pacotes, aplica overlay.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
source "${PROJECT_ROOT}/config/flavos.conf"

ROOTFS="${PROJECT_ROOT}/${ROOTFS_DIR}"
PACKAGES_FILE="${PROJECT_ROOT}/${CONFIG_DIR}/packages.list"
OVERLAY="${PROJECT_ROOT}/${OVERLAY_DIR}"

# --- Verificações ---
if [[ "$EUID" -ne 0 ]]; then
    echo "ERRO: Este script precisa ser executado como root (sudo)."
    exit 1
fi

if [[ -d "$ROOTFS" && -f "${ROOTFS}/bin/bash" ]]; then
    echo "rootfs já existe em ${ROOTFS}. Use 'make clean' para recriar."
    exit 0
fi

# --- Parsear lista de pacotes ---
PACKAGES_APT=""
# O debootstrap engasga com X11/DBus por tentar rodar postinst num vácuo de namespaces.
# Forçamos apenas o core-vital nele:
PACKAGES_DEB="systemd,systemd-sysv,dbus,bash,coreutils,sudo,apt,udev,iproute2"

while IFS= read -r line; do
    line="${line%%#*}"        # remove comentários
    line="${line// /}"        # remove espaços
    [[ -z "$line" ]] && continue
    if [[ -z "$PACKAGES_APT" ]]; then
        PACKAGES_APT="$line"
    else
        PACKAGES_APT="${PACKAGES_APT} $line"
    fi
done < "$PACKAGES_FILE"

echo "=== Flavos OS — Criando Root Filesystem ==="
echo "Suite:    $DEBIAN_SUITE"
echo "Mirror:   $DEBIAN_MIRROR"
echo "Arch:     $ARCH"
echo "Target:   $ROOTFS"
echo ""

# --- Debootstrap ---
echo "[1/6] Executando debootstrap minimalista..."
mkdir -p "$ROOTFS"
debootstrap \
    --variant=minbase \
    --arch="$ARCH" \
    --include="$PACKAGES_DEB" \
    "$DEBIAN_SUITE" \
    "$ROOTFS" \
    "$DEBIAN_MIRROR"

# --- Montar filesystems virtuais para chroot ---
echo "[2/6] Montando filesystems virtuais..."
mount --bind /dev  "${ROOTFS}/dev"
mount --bind /dev/pts "${ROOTFS}/dev/pts"
mount -t proc proc "${ROOTFS}/proc"
mount -t sysfs sysfs "${ROOTFS}/sys"
mount -t tmpfs tmpfs "${ROOTFS}/run"

# Cleanup function para desmontar em caso de erro
cleanup_mounts() {
    echo "Desmontando filesystems virtuais..."
    umount -lf "${ROOTFS}/run"   2>/dev/null || true
    umount -lf "${ROOTFS}/sys"   2>/dev/null || true
    umount -lf "${ROOTFS}/proc"  2>/dev/null || true
    umount -lf "${ROOTFS}/dev/pts" 2>/dev/null || true
    umount -lf "${ROOTFS}/dev"   2>/dev/null || true
}
trap cleanup_mounts EXIT

# --- Instalar pacotes da pipeline ---
echo "[2.5/6] Instalando pacotes pesados no ambiente formatado..."
chroot "$ROOTFS" apt-get update
chroot "$ROOTFS" env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $PACKAGES_APT

# --- Configuração básica dentro do chroot ---
echo "[3/6] Configurando sistema base..."

# Hostname
echo "$FLAVOS_ID" > "${ROOTFS}/etc/hostname"
cat > "${ROOTFS}/etc/hosts" <<EOF
127.0.0.1   localhost
127.0.1.1   ${FLAVOS_ID}

::1         localhost ip6-localhost ip6-loopback
ff02::1     ip6-allnodes
ff02::2     ip6-allrouters
EOF

# Locale e Keymap
chroot "$ROOTFS" bash -c "
    sed -i 's/^# *${SYS_LOCALE}/${SYS_LOCALE}/' /etc/locale.gen 2>/dev/null || true
    locale-gen 2>/dev/null || true
    echo 'LANG=${SYS_LOCALE}' > /etc/default/locale
"

cat > "${ROOTFS}/etc/vconsole.conf" <<EOF
KEYMAP=${SYS_KEYMAP}
FONT=latarcyrheb-sun16
EOF

mkdir -p "${ROOTFS}/etc/default"
cat > "${ROOTFS}/etc/default/keyboard" <<EOF
XKBMODEL="pc105"
XKBLAYOUT="br"
XKBVARIANT=""
XKBOPTIONS=""
BACKSPACE="guess"
EOF

# Timezone
chroot "$ROOTFS" ln -sf /usr/share/zoneinfo/${SYS_TIMEZONE} /etc/localtime

# Root password
chroot "$ROOTFS" bash -c "echo 'root:${ROOT_PASSWORD}' | chpasswd"

# Usuário principal não-root
echo "Criando usuário regular: ${SYS_USER}..."
chroot "$ROOTFS" bash -c "
    useradd -m -s /bin/bash '${SYS_USER}' || true
    echo '${SYS_USER}:${SYS_PASSWORD}' | chpasswd
    usermod -aG sudo,video,audio,input,tty,plugdev '${SYS_USER}' 2>/dev/null || true
"

# Permitir login root no TTY
chroot "$ROOTFS" bash -c "
    mkdir -p /etc/securetty
    # systemd já permite root login em tty por padrão
"

echo "[4/6] Configurando rede (NetworkManager)..."
# Habilitar serviços de rede e SSH
chroot "$ROOTFS" systemctl enable NetworkManager 2>/dev/null || true
chroot "$ROOTFS" systemctl disable systemd-networkd 2>/dev/null || true
chroot "$ROOTFS" systemctl enable systemd-resolved 2>/dev/null || true
chroot "$ROOTFS" systemctl enable ssh 2>/dev/null || true
# NTP: habilitar systemd-timesyncd (necessário para timedatectl set-ntp)
chroot "$ROOTFS" systemctl enable systemd-timesyncd 2>/dev/null || true
# Mouse no console (Etapa 7E)
chroot "$ROOTFS" systemctl enable gpm 2>/dev/null || true

# DNS resolve via systemd-resolved
chroot "$ROOTFS" ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf 2>/dev/null || true

echo "[5/6] Aplicando overlay..."
if [[ -d "$OVERLAY" ]]; then
    cp -a "${OVERLAY}/"* "${ROOTFS}/" 2>/dev/null || true
    echo "  Overlay aplicado de ${OVERLAY}"

    # FIX CRÍTICO: Reafirmar permissões do Sudoers injetadas pelo Overlay
    # Sudo ignora arquivos não-root e não-0440.
    if [[ -d "${ROOTFS}/etc/sudoers.d" ]]; then
        chroot "$ROOTFS" chown -R root:root /etc/sudoers.d
        chroot "$ROOTFS" chmod 0440 /etc/sudoers.d/flavos-power 2>/dev/null || true
        chroot "$ROOTFS" chmod 0440 /etc/sudoers.d/flavos-settings 2>/dev/null || true
    fi
fi

# --- Re-sincronizar dotfiles do skel para o home do usuário ---
# O useradd -m (etapa 3) copiou /etc/skel ANTES do overlay injetar os dotfiles.
# Agora que o overlay já atualizou /etc/skel com .bash_profile, .xinitrc, etc.,
# precisamos copiar explicitamente para /home/$SYS_USER.
echo "  Sincronizando dotfiles do skel para /home/${SYS_USER}..."
if [[ -d "${ROOTFS}/etc/skel" ]]; then
    cp -a "${ROOTFS}/etc/skel/."* "${ROOTFS}/home/${SYS_USER}/" 2>/dev/null || true
    # Copiar diretórios ocultos com subdiretórios (.config/openbox/...)
    for item in "${ROOTFS}/etc/skel/".*; do
        bname=$(basename "$item")
        [[ "$bname" == "." || "$bname" == ".." ]] && continue
        cp -a "$item" "${ROOTFS}/home/${SYS_USER}/"
    done
    # Copiar diretórios visíveis do skel (ex: Desktop/)
    for item in "${ROOTFS}/etc/skel/"*; do
        [[ -e "$item" ]] || continue
        cp -a "$item" "${ROOTFS}/home/${SYS_USER}/"
    done
    # Garantir ownership correto
    chroot "$ROOTFS" chown -R "${SYS_USER}:${SYS_USER}" "/home/${SYS_USER}"
    echo "  Dotfiles sincronizados e ownership corrigido."

    # Marcar .desktop files do Desktop como confiáveis/executáveis
    # Nemo exige +x para mostrar como ícone clicável (não como arquivo de texto)
    if [[ -d "${ROOTFS}/home/${SYS_USER}/Desktop" ]]; then
        chmod +x "${ROOTFS}/home/${SYS_USER}/Desktop/"*.desktop 2>/dev/null || true
        echo "  Desktop .desktop files marcados como executáveis."
    fi
fi

# --- Compilar dconf database para nemo-desktop e gsettings ---
# O nemo-desktop lê wallpaper e configurações via gsettings/dconf.
# 'dconf update' compila os arquivos em /etc/dconf/db/local.d/ para o DB binário.
# Sem isso, as chaves do sistema ficam invisíveis e o desktop fica cinza.
echo "  Compilando dconf database do sistema..."
chroot "$ROOTFS" dconf update 2>/dev/null || \
    echo "  AVISO: dconf update falhou (dconf pode nao estar instalado — instalar via packages.list)"

echo "[6/6] Gerando initramfs..."
# O initramfs precisa incluir módulos virtio para boot em QEMU
cat > "${ROOTFS}/etc/initramfs-tools/modules" <<EOF
# Virtio (QEMU/KVM)
virtio
virtio_pci
virtio_blk
virtio_net
virtio_scsi

# Storage físico (SATA, NVMe, USB)
ahci
nvme
xhci_hcd
usb_storage
EOF

chroot "$ROOTFS" update-initramfs -u -k all 2>/dev/null || \
    chroot "$ROOTFS" update-initramfs -c -k all 2>/dev/null || \
    echo "AVISO: initramfs pode precisar ser gerado manualmente"

# --- Limpeza ---
echo "Limpando caches do apt..."
chroot "$ROOTFS" apt-get clean
rm -rf "${ROOTFS}/var/lib/apt/lists/"*
rm -rf "${ROOTFS}/tmp/"*

echo ""
echo "=== Root filesystem criado com sucesso ==="
echo "Caminho: $ROOTFS"
echo "Tamanho: $(du -sh "$ROOTFS" | cut -f1)"
