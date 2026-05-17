# Live Installer Validation Report (14F)

**Status:** APROVADO ✅
**Data:** 2026-05-10
**Ambiente:** QEMU/KVM (Virtual Machine)
**Etapa:** 14F — Live Installer Lab (Payload Sync)

## Objetivo
Validar a execução controlada, isolada e destrutiva do instalador em um disco alvo simulado (Virtual Disk de 20GB) a partir do Live OS, certificando que o particionamento, formatação, extração via `rsync` do `filesystem.squashfs` e configurações de pós-instalação são realizados de maneira correta e segura, sem intervir no host e sem gerar kernel panics ou bloqueios I/O.

## Cenário de Teste
- **Disco Alvo:** Disco virtual raw de 20GB (`/dev/vda`).
- **RAM da VM:** 2GB.
- **CPU da VM:** Host Passthrough + KVM.
- **Origem dos Dados:** `/run/live/rootfs/filesystem.squashfs`.

## Resultados Observados
1. **Verificações de Segurança:** 
   O script impediu execuções acidentais exigindo a variável `FLAVOS_INSTALL_LAB_DESTRUCTIVE=YES` e a confirmação literal `ERASE /dev/vda`.
2. **Particionamento:**
   O `sgdisk` recriou a tabela de partições em GPT corretamente, criando a partição 1 (`EFI` - 512MiB) e a partição 2 (`Linux Root` - Restante do disco). As partições foram nomeadas como `FLAVOS_ESP` e `FLAVOS_ROOT`.
3. **Formatação:**
   Comandos `mkfs.vfat` e `mkfs.ext4` funcionaram perfeitamente criando os labels corretamente.
4. **Extração de Dados (Payload Sync):**
   O `rsync` operou de forma estável extraindo ~2.2GB de dados do squashfs e populando a partição Root montada temporariamente em `/run/flavos-installer-lab/root`. Duração aproximada: ~39s (em torno de 50MB/s em um SSD padrão via imagem qemu raw).
5. **Ajustes Post-Install:**
   O `/etc/fstab` do sistema instalado foi corretamente gerado mapeando os novos UUIDs das partições VDA1 e VDA2 criadas. O arquivo `/etc/machine-id` foi zerado conforme o padrão de imagens golden.
6. **Desmontagem Limpa (Cleanup):**
   A armadilha (`trap`) de limpeza executou o `umount` adequadamente no término do script, evitando data corruption ou cache não-sincronizado.

## Conclusão
A mecânica principal de instalação a frio baseada no paradigma Live OS/Squashfs está validada com excelência. Os mecanismos do particionador, de clonagem de dados e dos preparos offline não apresentaram bugs ou corrupções estruturais.

**Próximo Passo (14G):**
Projetar e instalar o bootloader (`systemd-boot`) no ambiente chroot, viabilizando o primeiro "boot nativo" a partir do disco recém-instalado, fechando o ciclo de implementação do instalador Base.
