# Changelog — Flavos OS

## [Unreleased]

### Flavos Shell Preview 0.1 "Basis" (2026-04-19)
#### Adicionado
- **Shell UI:** Primeira preview estável da shell nativa com painel superior, taskbar inferior, launcher rápido e OSD via GTK3 e Python.
- **Session Daemon:** `flavos-session-daemon` com arquitetura de watchdog para restart automático de componentes da shell.
- **Launcher Confiável:** `flavos-launcher` com PID file control, 300ms focus guard para previnir auto-dismiss, e motor de animações para enter/exit (120ms fade-in, 80ms fade-out).
- **Taskbar Otimizada:** Taskbar v4 incorporado com suporte a Wnck, integração do ícone de volume ao OSD e layout denso (36px).
- **OSD Feedback Visual (v5):** OSD e Toasts com animação (slide Y + fade) via `GLib.timeout_add`, fallbacks limpos em X11 puro, PID file lock para inputs rápidos, e gerenciamento fiel de estado para Mudo/Volume/Brilho.
- **Top Panel DOCK:** `flavos-panel` configurado com hint DOCK, alinhamento flexível, CSS dinâmico com Glass (`rgba(20,24,32,0.96)`) suportado, relógio e botão de sistema.
- **Shellctl Middle-layer:** Subcomandos no `flavos-shellctl` melhorados, operando sobre contratos de PID file com `kill -0` em vez do frágil `pgrep`, garantindo `set -e` safe.

### Etapa 7 — Consolidação V1 (2026-04-05)
#### Adicionado
- Extensão `flavos-diag` para auditoria rápida de métricas core (`RAM`, `Rede`, `Failures`).
- Manual técnico estruturado (`docs/RECOVERY.md`) ensinando Kernel Recovery direto no TTY.
- Drop-in de Segurança SSH para bloquear acesso iterativo root.
- Identidade visual `motd` e `issue` adicionada no boot virtual.
- Automação da Rede delegada estritamente aos profiles `systemd-networkd`.

#### Modificado
- Extração dos dados mutáveis (`SYS_USER`, `SYS_LOCALE`, `SYS_KEYMAP`) do script de rootfs para o topo configurável base `flavos.conf`.
- `systemd-journald` reconfigurado para fixação persistente com lock protetor de 50MB.

### Etapa 2 a Etapa 5 — Build e Boot Framework (2026-04-05)
#### Entregue
- Implantação e refino da suíte Bash com chroot debootstrap ativo gerando `flavos.img`.
- Adoção nativa de flash drivers (`pflash`) para o boot UEFI seguro no emulador QEMU.
- Fix de infraestrutura UserSpace com o download dependente do pacote `systemd-sysv` unindo ABI de kernel ao Pid1.
- Imagem oficialmente declarada como Bootable (Milestone 1).


### Etapa 1 — Arquitetura e Fundações (2026-04-05)

#### Definido
- Abordagem de construção: Debootstrap sobre Debian Stable (Bookworm 12.x)
- Bootloader: systemd-boot (UEFI-only)
- Init system: systemd
- Filesystem: ext4 (root), FAT32 (ESP)
- Particionamento: GPT
- Formato de imagem: raw .img (2GB)
- Sistema de build: Makefile + scripts bash numerados
- Teste: QEMU/KVM + OVMF
- Estrutura de repositório planejada

#### Documentado
- docs/architecture.md — Arquitetura completa
- docs/ROADMAP.md — Plano de evolução
- docs/CHANGELOG.md — Este arquivo

#### Rejeitado (com justificativa)
- LFS: retrabalho alto, sem gerenciador de pacotes
- Buildroot: sem package manager runtime
- Yocto: overengineering para o estágio atual
- GRUB2: complexidade desnecessária para UEFI-only
- Legacy BIOS: sem retorno proporcional para V1
