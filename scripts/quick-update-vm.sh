#!/usr/bin/env bash

# Verifica se a imagem existe
IMG="build/live/flavos-install-target-20g.img"
if [ ! -f "$IMG" ]; then
    echo "Imagem $IMG não encontrada!"
    exit 1
fi

echo "Montando a imagem usando qemu-nbd..."
sudo modprobe nbd
sudo qemu-nbd -c /dev/nbd0 "$IMG"
sudo mount /dev/nbd0p2 /mnt

echo "Atualizando scripts do overlay..."
sudo rsync -av overlay/usr/local/bin/ /mnt/usr/local/bin/
sudo rsync -av overlay/usr/local/lib/flavos/ /mnt/usr/local/lib/flavos/
sudo rsync -av overlay/etc/sudoers.d/ /mnt/etc/sudoers.d/

echo "Injetando os marcadores de instalação (simulando a etapa do installer)..."
sudo mkdir -p /mnt/etc/flavos /mnt/var/lib/flavos
echo "installed-firstboot" | sudo tee /mnt/etc/flavos/system-mode > /dev/null
sudo touch /mnt/var/lib/flavos/firstboot-required

echo "Desmontando..."
sudo umount /mnt
sudo qemu-nbd -d /dev/nbd0

echo "Pronto! Agora você pode rodar 'make boot-installed-vm'."
