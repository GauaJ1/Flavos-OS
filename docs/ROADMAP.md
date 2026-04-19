# Flavos OS — Roadmap até V1

## Macro Plan

| Etapa | Nome | Entrega | Status |
|---|---|---|---|
| 1 | Arquitetura e Fundações | Decisões técnicas documentadas | ✅ Completa |
| 2 | Workspace e Build Scripts | Repositório estruturado, Makefile, scripts prontos | ✅ Completa |
| 3 | Root Filesystem Mínimo | rootfs funcional em build/rootfs/ | ✅ Completa |
| 4 | Boot Chain | Imagem .img com ESP + root + bootloader | ✅ Completa |
| 5 | Primeiro Boot em VM | Boot até login prompt no QEMU | ✅ Completa |
| 6 | Userspace e Serviços | Rede, SSH, usuário não-root | ✅ Completa |
| 7 | Branding Inicial | os-release, issue, motd, hostname | ✅ Completa |
| 8 | Imagem Reproduzível | Pipeline completo make all funcional | ✅ Completa |
| 9 | Update/Recovery/Logging | Estratégia de atualização e fallback | ✅ Completa |
| 10 | Refinamento V1 | Documentação final, testes, limpeza | ✅ Completa |
| 11 | Flavos Shell Preview | Shell UI nativa funcional (Basis) | ✅ Completa |
| 12 | Core Apps & Usability | Navegador, integração de apps, fluxos e refinamento | 🔄 Em Progresso |

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

### Etapa 2 — Workspace e Build Scripts ✅
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

### Etapa 3 — Root Filesystem Mínimo ✅
- Executar debootstrap dentro de scripts/01-create-rootfs.sh
- Configurar chroot (locale, timezone, root password, hostname)
- Instalar pacotes essenciais via apt dentro do chroot
- Copiar overlay para rootfs
- Gerar initramfs dentro do chroot
- Validar: chroot funcional com bash

### Etapa 4 — Boot Chain ✅
- Criar imagem .img com scripts/02-create-image.sh
- Particionar GPT (ESP + root)
- Formatar partições (FAT32 + ext4)
- Copiar rootfs para partição root
- Instalar systemd-boot na ESP
- Configurar loader.conf e boot entry
- Copiar kernel + initramfs
- Validar: imagem montável e inspecionável

### Etapa 5 — Primeiro Boot em VM ✅
- Executar scripts/04-boot-vm.sh
- Verificar cadeia de boot completa
- Login como root
- Verificar serviços systemd
- Verificar shutdown limpo
- Documentar resultado
- Validar: todos os 11 critérios de boot

### Etapa 11 — Flavos Shell Preview 0.1 "Basis" ✅
- **11A:** Terminal nativo com funcionalidade aprimorada (Kitty clipboard).
- **11B:** Gerenciamento central — Session Daemon, Taskbar Wnck e Top Panel (DOCK).
- **11C:** Launcher confiável — PID File, motion enter/exit, focus guard.
- **11D:** OSD Visual Feedback — Singleton, glass, motion translateY, volume/brilho.
- **11E:** Preview Consolidação — Freeze feature-set, documentation "Basis", estabilidade garantida.

### Etapa 12 — Core Apps & Daily Usability 🔄
- **12A — Navegador Padrão e Web Experience:** ✅ Firefox ESR integrado como app de primeira classe via pacote apt nativo, com regras Openbox de decor e keybind global (C-A-b).
- **12B — Core Apps Integration:** ✅ Conjunto core consolidado (Terminal/Kitty, Arquivos/Nemo, Editor/Mousepad, Navegador/Firefox, Imagens/Viewnior, Settings e Power). Resolvidos bugs críticos e substituição do PCManFM visual pelo Nemo.
  - *Nota Documental Importante:* A Etapa 12B introduziu defaults mínimos necessários para os apps core, mas isto NÃO substitui a Etapa 12C, que continuará responsável por consolidar e auditar de forma mais profunda e sistêmica os fluxos de abertura, associações MIME e comportamento final do `xdg-open`.

## Decisões Fixas (Base)

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
