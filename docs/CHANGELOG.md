# Changelog — Flavos OS

## Flavos Desktop Preview 0.1 "Daily" (2026-04-25)

> Milestone: primeiro desktop funcional para uso diário básico.
> Tag: `desktop-preview-0.1-daily` | Etapas: 12A → 12F

---

### Etapa 12F — Performance Adaptation & Resource Profiles (2026-04-25)
#### Adicionado
- **Sistema de perfis de desempenho:** três perfis (`light`, `balanced`, `full`) com configs separadas de Picom, shell e serviços. Perfil padrão: `balanced`.
- **`/etc/flavos/`:** novo diretório de configurações do sistema Flavos. Contém configs Picom por perfil, perfil ativo, firefox-light.js.
- **`picom-light.conf`:** xrender, sem fading, shadow radius 6, corner-radius 0, use-damage=true. Alvo: 2 GB RAM, LGA775.
- **`picom-balanced.conf`:** xrender, fading ativo, shadow 14, corner-radius 10, use-damage=true. Padrão atual (corrige use-damage=false).
- **`picom-full.conf`:** glx (experimental, requer OpenGL 2.0), shadow 18, corner-radius 12. Validação em hardware real prevista na Etapa 14.
- **`/etc/flavos/performance-profile`:** arquivo de perfil global (texto simples: "balanced").
- **Script `flavos-performance-profile`:** gerenciador de perfis em Python. Flags: `set`, `current`, `status`, `apply`, `--system`, `--with-zram`, `--apply-firefox-light`.
- **`/etc/flavos/firefox-light.js`:** user.js Firefox para 2 GB RAM. Aplica com `--apply-firefox-light`. Backup automático antes de sobrescrever.
- **`systemd-zram-generator`:** adicionado a packages.list. Não ativo por padrão. Ativar com `--with-zram` (requer sudo).
- **`~/.config/flavos/launcher.json`:** lido pelo launcher para timing de fade por perfil (Light: 60ms/40ms; Balanced/Full: 120ms/80ms).
- **`~/.config/flavos/osd.json`:** lido pelo OSD para modo de animação (Light: fade puro; Balanced/Full: slide+fade).
- **`~/.config/flavos/desktop-mode.json`:** controla `nemo_desktop` por perfil. Light: false (wallpaper via feh mantido).
- **`docs/PERFORMANCE_PROFILES.md`:** documentação oficial dos perfis, viabilidade real em 2 GB, rollback, zram, Firefox-light.

#### Corrigido
- **`picom.conf` (balanced):** `use-damage = false` → `use-damage = true`. Corrige redesenho total da tela a cada frame.
- **picom-full.conf:** corrigido requisito do backend glx: OpenGL **2.0** (não 3.3). Driver Intel/AMD no Debian Bookworm atende.
- Documentação: alinhamento completo com `evince` (não xreader). xreader nunca existiu nos repos Bookworm.

#### Mascaramento de serviços (apenas `--system` + sudo)
- `NetworkManager-wait-online`, `ModemManager`, `bluetooth`, `avahi-daemon` mascarados no perfil Light.
- Script verifica existência de unit antes de mascarar. Não desmascara units mascaradas externamente pelo admin.

---

### Etapa 12E — Desktop Usability Preview (2026-04-25)
#### Adicionado
- **Documento oficial da preview:** `docs/DESKTOP_PREVIEW_0.1_DAILY.md` — baseline completo com apps, MIME, checklist de validação, limitações honestas e veredito técnico.
- **README:** atualizado para refletir milestone `Desktop Preview 0.1 "Daily"` como estado atual.
- **ROADMAP:** 12D e 12E marcadas como concluídas; 12F adicionada.

#### Auditado e confirmado
- Consistência total: `evince` em packages.list, flavos-pdf.desktop e stubs. Zero referências a `xreader` em qualquer arquivo.
- **27 tipos MIME** mapeados (contagem real: `grep "^[^#\[]" /etc/xdg/mimeapps.list | wc -l`). Corrigido de 28 para 27.
- **8 handlers ativos** no launcher, **7 stubs** NoDisplay, zero duplicatas.

---

### Etapa 12 — Core Apps & Daily Usability (2026-04-25)
#### Adicionado
- **12A / Navegador Padrão:** Firefox ESR como app de primeira classe; `xdg-open` configurado; atalho global `Ctrl+Alt+B`.
- **12B / Core Apps Integration:** Apps core estabelecidos (Terminal/Kitty, Arquivos/Nemo, Editor/Mousepad, Imagens/Viewnior, Settings, Power). PCManFM removido visualmente; Nemo com dark theme.
- **12C / Defaults, MIME & Open Flows:** Hierarquia MIME via `/etc/xdg/mimeapps.list`. Pacote `file` adicionado para `xdg-open` correto. Logo Flavos via SVG direto. Fluxos auditados.
- **12D / Media & Playback:** Evince (PDF) e Celluloid/mpv (vídeo/áudio) integrados. 27 tipos MIME mapeados. Stubs NoDisplay para evitar duplicatas. Nota: xreader não está disponível no Debian Bookworm; substituído por evince.

#### Corrigido
- `flavos-settings`: Crash silencioso ao clicar "Escolher..." no menu de aparência.
- `flavos-settings`: NTP não ativava `systemd-timesyncd`.
- Sudo helpers: bit `+x` nos scripts e regras sudoers ajustadas.
- Áudio: placa Intel HDA no QEMU e autostart PulseAudio via desktop entry.
- `xreader` → `evince` em packages.list e flavos-pdf.desktop (xreader não existe no Debian Bookworm).
- Wallpaper: 3 camadas (feh imediato + gsettings + feh delay 4s) para garantir persistência.
- Logo Flavos: carregamento via `new_from_file()` para evitar cache GTK.

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
