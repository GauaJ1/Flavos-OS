#!/usr/bin/env bash
# build-i3lock-color.sh — Compila i3lock-color dentro do chroot do Flavos OS.
# Chamado por 01-create-rootfs.sh após instalar pacotes base.
#
# i3lock-color NÃO está no Debian repos. Precisa compilar do source.
# Ref: https://github.com/Raymo111/i3lock-color
set -euo pipefail

I3LOCK_COLOR_VERSION="2.13.c.5"
I3LOCK_COLOR_URL="https://github.com/Raymo111/i3lock-color/archive/refs/tags/${I3LOCK_COLOR_VERSION}.tar.gz"
BUILD_DIR="/tmp/i3lock-color-build"

echo "[i3lock-color] Instalando build deps..."
apt-get install -y --no-install-recommends \
    autoconf automake libtool gcc make pkg-config \
    libpam0g-dev libcairo2-dev libfontconfig1-dev \
    libxcb-composite0-dev libev-dev libx11-xcb-dev \
    libxcb-xkb-dev libxcb-xinerama0-dev libxcb-randr0-dev \
    libxcb-image0-dev libxcb-util-dev libxcb-xrm-dev \
    libxkbcommon-dev libxkbcommon-x11-dev libjpeg-dev \
    wget ca-certificates

echo "[i3lock-color] Baixando source ${I3LOCK_COLOR_VERSION}..."
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"
wget -q "$I3LOCK_COLOR_URL" -O i3lock-color.tar.gz
tar xzf i3lock-color.tar.gz
cd "i3lock-color-${I3LOCK_COLOR_VERSION}"

echo "[i3lock-color] Compilando..."
autoreconf -fi
./configure --prefix=/usr --sysconfdir=/etc --disable-sanitizers
make -j"$(nproc)"

echo "[i3lock-color] Instalando binário..."
# Instala apenas o binário, sobrescrevendo o i3lock padrão se existir
install -m 755 x86_64-pc-linux-gnu/i3lock /usr/bin/i3lock 2>/dev/null || \
install -m 755 i3lock /usr/bin/i3lock

echo "[i3lock-color] Limpando build artifacts..."
cd /
rm -rf "$BUILD_DIR"

# Remover build deps que não são necessárias no runtime
apt-get remove -y --purge autoconf automake libtool gcc make pkg-config \
    libcairo2-dev libfontconfig1-dev libxcb-composite0-dev \
    libev-dev libx11-xcb-dev libxcb-xkb-dev libxcb-xinerama0-dev \
    libxcb-randr0-dev libxcb-image0-dev libxcb-util-dev \
    libxcb-xrm-dev libxkbcommon-dev libxkbcommon-x11-dev \
    libjpeg-dev wget 2>/dev/null || true
apt-get autoremove -y 2>/dev/null || true
apt-get clean

echo "[i3lock-color] Build concluído. Versão:"
/usr/bin/i3lock --version 2>&1 || true
