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
| 12 | Core Apps & Usability | Navegador, integração de apps, fluxos e refinamento | ✅ Completa |
| 13 | Archives, Directories & Lock Screen | Compressão, diretórios, lock screen, desktop preview 1 | ✅ Completa |
| 14A | Build Artifact Hygiene | Artefatos seguros, verificáveis e padronizados | ✅ Completa |
| 14B | Hardware Lab Baseline | Documentação, template e diagnóstico para testes em hardware real | ✅ Completa |
| 14C | Live Boot Strategy & Prototype | Estratégia de hardware legado, rootfs isolado, squashfs (zstd) | ✅ Completa |
| 14D | Live Boot Prototype Execution & VM Validation | Boot Híbrido, Performance e Estabilidade Validados | ✅ Completa |

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

### Etapa 12 — Core Apps & Daily Usability ✅

> **Milestone:** Flavos Desktop Preview 0.1 "Daily" — `desktop-preview-0.1-daily`

- **12A — Navegador Padrão e Web Experience:** ✅ Firefox ESR integrado como app de primeira classe via pacote apt nativo, com regras Openbox de decor e keybind global (C-A-b).
- **12B — Core Apps Integration:** ✅ Conjunto core consolidado (Terminal/Kitty, Arquivos/Nemo, Editor/Mousepad, Navegador/Firefox, Imagens/Viewnior, Settings e Power). PCManFM removido visualmente; Nemo com dark theme.
- **12C — Defaults, MIME & Open Flows:** ✅ Hierarquia MIME via `/etc/xdg/mimeapps.list`. Pacote `file` corrigindo `xdg-open`. Logo Flavos via SVG. 27 tipos mapeados.
- **12D — Media & Playback:** ✅ Evince (PDF) e Celluloid/mpv (vídeo/áudio) integrados. Stubs NoDisplay eliminam duplicatas. xreader substituído por evince (incompatível com Bookworm).
- **12E — Desktop Usability Preview:** ✅ Consolidação como milestone oficial. Auditoria de consistência, documentação completa (`docs/DESKTOP_PREVIEW_0.1_DAILY.md`), checklist de validação, tag `desktop-preview-0.1-daily`.

### Etapa 12F — Performance Adaptation & Resource Profiles ✅
- **Sistema de 3 perfis:** Light (2 GB/LGA775), Balanced (padrão), Full (hardware moderno). Configs Picom separadas por perfil.
- **Script `flavos-performance-profile`:** controle reversível de perfil (picom, panel, launcher, OSD, nemo-desktop, serviços).
- **Correção Picom:** `use-damage = false` → `use-damage = true` em todos os perfis.
- **zram:** `systemd-zram-generator` instalado; ativação opcional via `--with-zram` (perfil light).
- **Firefox Light:** `firefox-light.js` criado; aplica com `--apply-firefox-light` (com backup automático).
- **Docs:** `docs/PERFORMANCE_PROFILES.md` — viabilidade real em 2 GB, rollback, limitações honestas.

### Etapa 13 — Archives, Directories, Lock Screen & Desktop Preview 1 ✅

> **Milestone:** Flavos Desktop Preview 1 "Daily" — `desktop-preview-1-daily`

- **13A — Flavos Archive Manager:** ✅ File Roller integrado como `flavos-archive`, com stubs NoDisplay e MIME types para compressão.
- **13B — User Directories & Downloads:** ✅ Diretórios XDG criados via skel, downloads integrados ao Firefox.
- **13C — Lock Screen:** ✅ mate-screensaver + D-Bus hierárquico, i3lock-color descartado por instabilidade.
- **13D — Power, Logout & Suspend:** ✅ Fluxos centralizados no session daemon, power menu com lock/logout/suspend/shutdown.
- **13E — Desktop Preview 1 Consolidação:** ✅ Documentação completa, auditoria de consistência, tag `desktop-preview-1-daily`.

### Etapa 14A — Build Artifact Hygiene & Release Image Safety ✅

- **Pipeline de release:** `make release` gera `.img.xz` + `.sha256` + `manifest.json`.
- **Credenciais isoladas:** `config/.secrets` (gitignored), com fallback DevLocal.
- **Documentação:** `docs/RELEASE_ARTIFACTS.md` — o que publicar, riscos, verificação.
- **Limpeza:** Arquivos residuais removidos, `.gitignore` atualizado.

### Etapa 14B — Hardware Lab Baseline ✅

- **Documentação de laboratório:** `docs/HARDWARE_LAB_BASELINE.md` — checklist pré-teste, ficha de hardware, protocolo de boot/desktop/performance, critérios para 2 GB RAM, plano de risco, notas LGA 775.
- **Template de relatório:** `docs/HARDWARE_TEST_REPORT_TEMPLATE.md` — formulário padronizado para registro de resultados em hardware real.
- **Script de diagnóstico:** `overlay/usr/local/bin/flavos-hw-report` — coleta somente leitura de CPU, RAM, discos, GPU, rede, áudio, kernel, sessão, serviços, logs, swap, performance profile. Não exige root, não envia dados.
- **Fluxo de validação:** VM → Pendrive → Disco externo → Disco interno de teste (nunca disco principal).

### Etapa 14C — Live Boot Strategy & Prototype Planning ✅

- **Documentação de Estratégia:** `docs/LIVE_BOOT_STRATEGY.md` — Decisão por live-boot + rootfs atual, sem `toram`, overlay capping (512MB/384MB), compressão zstd otimizada, hibridez BIOS/UEFI, segurança amnésica por default.
- **Plano de Experimento:** `docs/LIVE_BOOT_EXPERIMENT_PLAN.md` — Isolamento seguro em `build/live/`, restrições do protótipo, roteiro de validação futura e integração no pipeline.
- **Protótipo de Validação:** `scripts/06-create-live-prototype.sh` — Stub que injeta live-boot via chroot, comprime o rootfs via mksquashfs e empacota uma ISO Híbrida usando grub-mkrescue, sem modificar as imagens oficiais do disco.

### Etapa 14D — Live Boot Prototype Execution & VM Validation ✅

- **Validação de Boot**: Sucesso no boot Legacy/UEFI com GRUB visível e carregamento correto do ambiente Híbrido Live (X11 + Picom).
- **Validação de Performance**: Inicialização do Desktop em ~4.2s. Consumo de RAM otimizado para 2GB (~562MiB em idle). Limits de overlay testados e dentro do previsto.
- **Relatório de Validação**: `docs/LIVE_BOOT_VALIDATION_REPORT.md` detalhando as métricas finais (overlay, squashfs, tempos e processos).
- **Hardening e Refinamentos**: Correção de processos zumbis do `flavos-session-daemon` e aprimoramentos no `flavos-hw-report` (detecção de processos longos e integração PipeWire/Áudio).
- **Isolamento Confirmado**: Comportamento de amnésia (`nopersistence`) funcional; sem resíduos entre os reboots.

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
