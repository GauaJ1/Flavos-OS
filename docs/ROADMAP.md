# Flavos OS — Roadmap até V1

## Macro Plan

| Etapa | Nome | Entrega | Status |
|---|---|---|---|
| 1 | Arquitetura e Fundações | Decisões técnicas documentadas | ✅ Completa |
| 2 | Workspace e Build Scripts | Repositório estruturado, Makefile, scripts prontos | ⬜ Próxima |
| 3 | Root Filesystem Mínimo | rootfs funcional em build/rootfs/ | ⬜ |
| 4 | Boot Chain | Imagem .img com ESP + root + bootloader | ⬜ |
| 5 | Primeiro Boot em VM | Boot até login prompt no QEMU | ⬜ |
| 6 | Userspace e Serviços | Rede, SSH, usuário não-root | ⬜ |
| 7 | Branding Inicial | os-release, issue, motd, hostname | ⬜ |
| 8 | Imagem Reproduzível | Pipeline completo make all funcional | ⬜ |
| 9 | Update/Recovery/Logging | Estratégia de atualização e fallback | ⬜ |
| 10 | Refinamento V1 | Documentação final, testes, limpeza | ⬜ |

## Roadmap Detalhado até Primeiro Boot (Etapas 1-5)

### Etapa 1 — Arquitetura e Fundações ✅
- Comparação de 4 abordagens (LFS, Buildroot, Yocto, Debootstrap)
- Escolha: Debootstrap + Debian Bookworm
- Stack definido: systemd-boot, systemd, ext4, GPT, UEFI
- Formato: raw .img (2GB)
- Build: Makefile + scripts bash numerados
- Teste: QEMU/KVM + OVMF
- Estrutura de repositório definida
- Riscos mapeados

### Etapa 2 — Workspace e Build Scripts
- Criar estrutura de diretórios
- Escrever Makefile
- Escrever config/flavos.conf
- Escrever config/packages.list
- Escrever scripts/00-check-deps.sh
- Escrever esqueletos dos scripts 01-04
- Escrever overlay files (hostname, os-release, issue, fstab)
- Escrever .gitignore
- Inicializar git
- Validar: `make deps` passa

### Etapa 3 — Root Filesystem Mínimo
- Executar debootstrap dentro de scripts/01-create-rootfs.sh
- Configurar chroot (locale, timezone, root password, hostname)
- Instalar pacotes essenciais via apt dentro do chroot
- Copiar overlay para rootfs
- Gerar initramfs dentro do chroot
- Validar: chroot funcional com bash

### Etapa 4 — Boot Chain
- Criar imagem .img com scripts/02-create-image.sh
- Particionar GPT (ESP + root)
- Formatar partições (FAT32 + ext4)
- Copiar rootfs para partição root
- Instalar systemd-boot na ESP
- Configurar loader.conf e boot entry
- Copiar kernel + initramfs
- Validar: imagem montável e inspecionável

### Etapa 5 — Primeiro Boot em VM
- Executar scripts/04-boot-vm.sh
- Verificar cadeia de boot completa
- Login como root
- Verificar serviços systemd
- Verificar shutdown limpo
- Documentar resultado
- Validar: todos os 11 critérios de boot

## Decisões Fixas (V1)

| Aspecto | Decisão |
|---|---|
| Abordagem | Debootstrap (Debian Bookworm amd64) |
| Bootloader | systemd-boot |
| Firmware | UEFI (OVMF para VM) |
| Init | systemd |
| Filesystem | ext4 (root), FAT32 (ESP) |
| Particionamento | GPT |
| Imagem | Raw .img, 2GB |
| Build | Makefile + bash scripts |
| Teste | QEMU/KVM |
| Shell | bash |
| libc | glibc (Debian) |
| Rede | systemd-networkd |
