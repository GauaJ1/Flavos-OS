# Etapa 14G: Bootloader & First Boot in VM

## Objetivo
Implementar o bootloader na imagem recém sincronizada pela etapa 14F e permitir o boot autônomo e isolado usando QEMU/KVM com UEFI (OVMF).

## Decisões Arquiteturais
- **Bootloader Exclusivo**: `systemd-boot`.
- **Estratégia do Kernel**: O kernel e o initrd são copiados da partição root (`/boot`) para a ESP (`/boot/efi/EFI/flavos/`).
- **Comando do chroot**: O sistema roda `bootctl --esp-path=/boot/efi --no-variables install` para evitar problemas com firmware EFI de VM e não depender de alterações persistentes de NVRAM. A validação confia na existência do fallback em `EFI/BOOT/BOOTX64.EFI`.
- **Cleanup Seguro**: Não excluímos os pontos de montagem (`rmdir`) de dentro da partição destino (`TARGET_ROOT`) após o script, apenas fazemos `umount` para não afetar pastas do sistema instanciado.

## Instruções de Laboratório

### 1. Iniciar o Laboratório Live
\`\`\`bash
sudo make boot-live-lab
\`\`\`

### 2. Sincronizar o Rootfs (14F) e Instalar Bootloader (14G)
Dentro do ambiente Live logado como `flavos`:
\`\`\`bash
# 1. Copia o rootfs para o disco:
sudo FLAVOS_INSTALL_LAB_DESTRUCTIVE=YES \
  flavos-installer-lab payload-sync \
  --target /dev/vda \
  --i-understand-this-erases-target
# (Confirme com "ERASE /dev/vda")

# 2. Instala o bootloader:
sudo FLAVOS_INSTALL_LAB_DESTRUCTIVE=YES \
  flavos-installer-lab install-bootloader \
  --target /dev/vda \
  --i-understand-this-modifies-target
# (Confirme com "MODIFY /dev/vda")

# Desligue a VM após concluir:
sudo poweroff
\`\`\`

### 3. Validar Boot Instanciado
\`\`\`bash
make boot-installed-vm
\`\`\`
O sistema deverá carregar o menu do `systemd-boot`, e realizar o boot na imagem isolada e independente do CD de instalação.
