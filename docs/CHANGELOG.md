# Changelog — Flavos OS

## Etapa 14H.0 — Physical Hardware Triage & Live Media Integrity (2026-05-17)

> Etapa emergencial de triagem de hardware real (LGA 775) e integridade da mídia Live.
> Status: Em progresso — rebuild obrigatório pendente.

### Novidades

- **`overlay/usr/local/bin/flavos-live-media-check`** — Verificador de integridade da mídia Live com modos `--quick` (readability + dmesg) e `--full` (SHA256 checksum). Bloqueio automático do instalador se a verificação falhar.
- **`overlay/usr/local/bin/flavos-safe-graphics-setup`** — Autodetecção de parâmetro `flavos.graphics=` no cmdline para geração de xorg.conf.d forçando driver VIA/OpenChrome, VESA ou FBDEV.
- **Boot entries expandidas** no `06-create-live-prototype.sh` — Safe Graphics, VIA/OpenChrome, VESA, Framebuffer, TTY Recovery e Low RAM.
- **SHA256 do SquashFS** gerado automaticamente no build (`filesystem.squashfs.sha256`).
- **`docs/PHYSICAL_HARDWARE_TEST_REPORT_14H0.md`** — Relatório do primeiro teste em hardware real LGA 775.
- **`docs/PHYSICAL_INSTALL_PRECHECK.md`** — Checklist de segurança obrigatório para instalação física.
- **`docs/TTY_KEYBOARD_RECOVERY.md`** — Guia de recuperação ABNT2 via `loadkeys`.
- **`docs/SAFE_GRAPHICS_AND_VIA.md`** — Plano técnico de fallback gráfico para GPUs legadas.
- **`docs/APT_TIME_SYNC_RECOVERY.md`** — Recuperação de data/hora para CMOS fraca.

### Mudanças

- `overlay/usr/local/bin/flavos-installer-lab` — rsync corrigido de `-aAXH` para `-aH` (flag `-X` causava erro de xattr em squashfs). Media-check `--full` agora é obrigatório antes do payload-sync.
- `config/packages.list` — Adicionados `kbd`, `console-setup`, `keyboard-configuration` (TTY keyboard), `usbutils` e `dmidecode` (diagnóstico de hardware).
- `overlay/usr/local/bin/flavos-hw-report` — Expandido com seções USB (`lsusb`), DMI/placa-mãe (`dmidecode`), data/hora (`timedatectl`), PCI detalhado (`lspci -nn`) e `/proc/cpuinfo`.
- `ROADMAP.md` — Adicionadas etapas 14G ✅, 14H.0 🔄 e 14H ⏳.

### Notas

- Instalação física permanece bloqueada (`require_vm`) até validação completa em hardware real.
- BIOS Legacy requer Etapa 14I futura — não é escopo da 14H.0.
- Rebuild completo (`make live`) é obrigatório para embutir os novos pacotes e scripts na ISO.

---

## Etapa 14G — Bootloader Install & First Boot Validation (2026-05-17)

> GRUB instalado no sistema alvo via chroot, primeiro boot pós-instalação validado em VM.
> Tag: `14g-bootloader-first-boot`

### Novidades

- **GRUB no target**: `grub-install` + `grub-mkconfig` executados dentro de chroot, gerando boot chain funcional no disco instalado.
- **Primeiro boot sem mídia Live**: Sistema alvo boota com serviços systemd e desktop Openbox/Picom funcionais.

### Mudanças

- `overlay/usr/local/bin/flavos-installer-lab` — Integração de etapas de instalação do GRUB no workflow post-install.
- `ROADMAP.md` e `CHANGELOG.md` — Etapa 14G adicionada como concluída ✅.

---

## Etapa 14F — Live Installer Lab (Payload Sync) (2026-05-10)

> Primeira execução destrutiva, controlada e laboratorial do instalador do Flavos OS de forma offline dentro de VM (QEMU/KVM).
> Tag: `14f-live-installer-payload-sync`

### Novidades

- **`overlay/usr/local/bin/flavos-installer-lab`** — Script final injetado diretamente na Live ISO que efetua o workflow offline seguro da instalação: `sgdisk` para particionar EFI/Root, `mkfs.vfat`/`mkfs.ext4` para formatar e `rsync` isolando diretórios sensíveis (dev/proc/sys/run) para sincronizar ~2.2GB do payload Live num disco alvo de 20GB. Inclui rotinas protetoras (`FLAVOS_INSTALL_LAB_DESTRUCTIVE=YES`, confirmação explícita de `ERASE`).
- **`scripts/09-boot-live-install-lab.sh`** — Helper script no host para subir a Live ISO injetando simultaneamente uma nova imagem virtual crua (`flavos-install-target-20g.img`) alocada por `qemu-img create`, permitindo teste seguro sem risco de formatações acidentais.
- **`docs/INSTALLER_14F_VALIDATION_REPORT.md`** — Documento contendo a validação de sucesso com logs mostrando a finalização segura da cópia do rootfs.

### Mudanças

- `ROADMAP.md` e `CHANGELOG.md` — Marcação da Etapa 14F como concluída ✅.
- `Makefile` — Novo target `boot-live-lab` adicionado chamando o script `09` automaticamente.

### Notas

- Ferramentas inseguras e de alto risco como `rm -rf` indiscriminado ou `wipefs` sem targets rígidos foram explicitamente desencorajadas/banidas do instalador. Toda a limpeza é feita via `trap` com `rmdir` e `umount` explícito no `TARGET_ROOT`.

---

## Etapa 14E — Live Installer Strategy & Install Payload Model (2026-05-10)

> Estruturação e arquitetura do instalador Live do Flavos OS (foco no modo offline) e modelo do payload.
> Tag: `14e-installer-strategy`

### Novidades

- **`docs/LIVE_INSTALLER_STRATEGY.md`** — Documento contendo a visão arquitetural do instalador offline que opera a partir do Live Boot, delineando as regras de particionamento, bootloader e isolamento.
- **`docs/INSTALL_PAYLOAD_MODEL.md`** — Descrição técnica detalhada da cópia via rsync extraindo dados do próprio `filesystem.squashfs`, incluindo caminhos excluídos e requisitos de pós-instalação (chroot).
- **`scripts/08-flavos-installer-dry-run.sh`** — Ferramenta de simulação ("dry-run") que reconhece discos, tipo de firmware e estado do LiveBoot, plotando um plano de instalação sem executar comandos destrutivos.

### Mudanças

- `ROADMAP.md` e `CHANGELOG.md` — Etapa 14E adicionada como concluída ✅.

### Notas

- O design do instalador segue rigorosamente a segurança offline, com planos para modo NetInstall reservados apenas para o futuro e comandos destrutivos banidos até o refino do particionamento.

---

## Etapa 14D — Live Boot Prototype Execution & VM Validation (2026-05-10)

> Validação do protótipo Híbrido Live (X11+Picom) com sucesso, isolamento amnésico comprovado e tempos otimizados para 2GB RAM.
> Tag: `14d-live-boot-vm-validation`

### Novidades

- **`docs/LIVE_BOOT_VALIDATION_REPORT.md`** — Relatório detalhado do teste em VM (2GB RAM), registrando consumo em idle (~562MiB), tamanho final da ISO (720M) e tempo de boot (4.27s), além do comportamento de *nopersistence*.

### Mudanças

- `overlay/usr/local/bin/flavos-hw-report` — Otimizado `pgrep -f` para `mate-screensaver` evitando truncamentos, busca ampliada para `Audio|Multimedia|HDA|AC97` via `lspci` na detecção de som e ajuste não-crítico para o PipeWire ausente.
- `ROADMAP.md` e `CHANGELOG.md` — Marcação da Etapa 14D como concluída ✅.

### Notas

- Zombie process tracking detectou e solucionou pendências do `flavos-session-daemon` em modo Live. O protótipo está validado para uso laboratorial/físico futuro.

---

## Etapa 14C — Live Boot Strategy & Prototype (2026-05-10)

> Estratégia de hardware legado (2GB RAM), proteção de overlay e stub experimental para ISO Live.
> Tag: `14c-live-boot-prototype`

### Novidades

- **`docs/LIVE_BOOT_STRATEGY.md`** — Documento de arquitetura detalhando: uso do rootfs existente + `live-boot`, banimento do boot param `toram` (para salvar os 2GB RAM), controle rígido de `overlay-size`, adoção de compressão zstd (-Xcompression-level 3 -b 256K) e suporte híbrido BIOS/UEFI.
- **`docs/LIVE_BOOT_EXPERIMENT_PLAN.md`** — Plano de execução isolada do protótipo para não quebrar o pipeline principal, incluindo roteiro de validação.
- **`scripts/06-create-live-prototype.sh`** — Script de laboratório stub (execução isolada em `build/live/`) que aplica chroot para instalar live-boot, roda mksquashfs e gera `flavos-live-experiment.iso` empacotado via `grub-mkrescue`.

### Mudanças

- `ROADMAP.md` — Etapa 14C adicionada como ✅.
- `CHANGELOG.md` — Entrada da 14C adicionada.
- `README.md` — Links para as documentações do Live Boot e script na árvore adicionados.

### Notas

- O protótipo usa configuração estritamente *amnésica* (`nopersistence`) como precaução de segurança.
- O script não integra o `make all` e serve exclusivamente para prova de conceito da ISO live em VMs de homologação antes de oficializar o alvo `make live`.

---

## Etapa 14B — Hardware Lab Baseline (2026-05-10)

> Documentação, template e diagnóstico para testes em hardware real.
> Tag: `14b-hardware-baseline`

### Novidades

- **`docs/HARDWARE_LAB_BASELINE.md`** — Protocolo completo para testes em hardware real: checklist pré-teste, ficha de hardware, checklists de boot/desktop/performance, critérios para 2 GB RAM (LGA 775), plano de risco, fluxo de validação e comandos úteis.
- **`docs/HARDWARE_TEST_REPORT_TEMPLATE.md`** — Template preenchível para registro padronizado de resultados de teste em hardware real. Inclui seções de identificação, hardware, boot, desktop, performance, bugs, classificação para 2 GB e veredito.
- **`overlay/usr/local/bin/flavos-hw-report`** — Script de diagnóstico somente leitura. Coleta CPU, RAM, discos, GPU, rede, áudio, kernel, sessão, serviços, logs, swap e performance profile. Não exige root, não altera o sistema, não envia dados pela rede.

### Mudanças

- `README.md` — Links adicionados para Hardware Lab Baseline e Test Report Template.
- `ROADMAP.md` — Etapa 14A marcada como ✅. Etapa 14B adicionada como ✅.
- `CHANGELOG.md` — Entrada da 14B adicionada.

### Notas

- O `flavos-hw-report` complementa o `flavos-debug-report` existente, com foco específico em validação de hardware para testes físicos.
- O fluxo recomendado de teste é: VM → Pendrive → Disco externo → Disco interno de teste.
- Credenciais DevLocal (`flavos/123`) continuam como risco documentado.

---

## Etapa 14A — Build Artifact Hygiene & Release Image Safety (2026-05-10)

> Pipeline de release, credenciais isoladas, documentação de artefatos.
> Tag: `14a-artifact-hygiene`

### Novidades

- **`make release`** — novo pipeline que gera `.img.xz` + `.sha256` + `manifest.json`.
- **`make compress`** — comprime `.img` para `.xz` (xz -9, multi-thread).
- **`make checksum`** — gera SHA256 do artefato comprimido.
- **`config/.secrets`** — credenciais movidas para arquivo gitignored, com fallback DevLocal.
- **`config/.secrets.example`** — template para credenciais personalizadas.
- **`docs/RELEASE_ARTIFACTS.md`** — documentação completa de artefatos, riscos e verificação.

### Mudanças

- `flavos.conf` — adicionado `RELEASE_VERSION`, `RELEASE_MILESTONE`, `RELEASE_TAG`, `RELEASE_IMAGE_BASENAME`. Credenciais carregadas de `.secrets` com fallback.
- `99-generate-manifest.sh` — prioriza artefato `.xz`. Manifest inclui `release_artifact` e `raw_image` separados.
- `Makefile` — 3 novos targets (compress, checksum, release). Help atualizado.
- `README.md` — milestone atualizado para Desktop Preview 1. Warning de credenciais reforçado (CAUTION).
- `ROADMAP.md` — adicionadas Etapas 13 e 14A.
- `.gitignore` — cobre `*.log`, residuais, `config/.secrets`.

### Limpeza

- Removidos do repositório: `esp_files.txt`, `loop_dev.txt`, `arquivo_recebido.txt`, `makeall.log`.

### Riscos Documentados

- Credenciais DevLocal (`flavos/123`) documentadas como risco conhecido.
- Autologin documentado como limitação da preview.
- Classificação de segurança: DevLocal / Preview Técnica.

---

## Flavos Desktop Preview 0.1 "Daily" (2026-04-25)

> Milestone: primeiro desktop funcional para uso diário básico.
> Tag: `desktop-preview-0.1-daily` | Etapas: 12A → 12F.1

---

### Etapa 13C.3c — Migração para i3lock-color (2026-04-26)
#### Migração
- **flavos-lockscreen (Python/GTK) → i3lock-color:** Python lockscreen abandonado por cadeia de
  dependências frágeis (python3-cairo, python3-gi-cairo, python3-pam com API instável).
  i3lock-color oferece visual premium (relógio, indicador ring, cores customizadas, blur) via
  flags CLI, sem nenhum código custom necessário.
- **`/usr/local/bin/flavos-lock`:** Reescrito como wrapper shell puro com todos os design tokens
  do Flavos OS Design System v3 (palette, tipografia Inter, espaçamento).
- **`scripts/build-i3lock-color.sh`:** Script de compilação dentro do chroot (i3lock-color não
  disponível nos repos Debian). Build deps removidas após compilação.
- **`scripts/01-create-rootfs.sh`:** Novo passo [2.7/6] integra compilação do i3lock-color.

#### Removido
- `/usr/local/bin/flavos-lockscreen` (Python/GTK) — substituído por i3lock-color.
- `python3-pam`, `python3-cairo`, `imagemagick` do `packages.list`.
- `i3lock` padrão do `packages.list` (substituído pelo binário compilado).

#### Visual do lock screen
- Fundo: screenshot desfocada (scrot + blur nativo do i3lock-color).
- Relógio: Inter 72px, branco 95% opacity, centrado acima do indicador.
- Data: Inter 16px, `#8891A5`, abaixo do relógio.
- Indicador: ring 90px, borda `#272D3D`, accent `#4B8BF5` ao verificar.
- Greeter: nome do usuário abaixo do indicador, Inter 14px.
- Feedback: keypress = accent azul, backspace = vermelho, erro = ring vermelho.

### Etapa 13C.3 — Lock Reliability, Openbox Keybind Fix & Backend Decision (2026-04-26)
#### Migração de backend
- **xsecurelock → i3lock:** xsecurelock com `COMPOSITE_OBSCURER=0` (necessário para Picom) vaza o desktop por trás da tela de lock. i3lock cobre a tela completamente sem conflito com Picom. Decisão documentada em `docs/SESSION_LOCK_AND_SECURITY.md`.
- **`config/packages.list`:** Substituído `xsecurelock` por `i3lock` com comentário explicativo.

#### Corrigido
- **Desktop visível por trás do lock:** `COMPOSITE_OBSCURER=0` desabilitava a janela de cobertura do xsecurelock. Resolvido pela migração para i3lock.
- **Launcher → Lock não funcionava (race condition):** Launcher escondia a janela enquanto mantinha grabs GTK; i3lock não conseguia adquirir seus próprios grabs. Corrigido com `hide()` → `GLib.timeout_add(150ms)` → spawn locker → `Gtk.main_quit()`.
- **Paths relativos no rc.xml:** Keybinds `W-l` e `C-A-l` usavam `flavos-shellctl` sem path absoluto. Corrigido para `/usr/local/bin/flavos-shellctl session lock`.

#### Alterado
- **`/usr/local/bin/flavos-lock`:** Reescrito para usar `exec i3lock -n -c 0D1017`. Mantidas: validação de sessão X11, verificação de binário, prevenção de duplicata (`pgrep -x i3lock`), log restrito com `umask 077`.
- **`docs/SESSION_LOCK_AND_SECURITY.md`:** Adicionada seção de histórico de backend, tabela comparativa xsecurelock vs i3lock, trade-off de segurança documentado.

### Etapa 13C.2 — Lock Screen UX, Design & Action Routing (2026-04-26)
#### Adicionado
- **`/usr/local/bin/flavos-lock`:** Wrapper central e único ponto de entrada para o xsecurelock. Todos os callers (shellctl, launcher, power menu, keybinds) delegam para este wrapper.
- **Keybind `Ctrl+Alt+L`:** Fallback confiável de bloqueio no `rc.xml`, sem dependência do xcape.
- **`openbox --reconfigure` automático:** Chamado pelo `flavos-session-daemon` na inicialização X11 e pelo `flavos-shellctl shell restart`, garantindo que keybinds do `rc.xml` estejam ativos desde o primeiro boot.

#### Corrigido
- **Fundo branco / INCOMPATIBLE COMPOSITOR:** Adicionado `XSECURELOCK_COMPOSITE_OBSCURER=0` ao `flavos-lock`, corrigindo incompatibilidade documentada entre xsecurelock e Picom.
- **Prompt de senha inseguro:** Substituído `asterisks` por `cursor` — o modo `asterisks` expõe o tamanho da senha.
- **Lógica duplicada em `flavos-shellctl`:** Seção `session lock` simplificada para `exec /usr/local/bin/flavos-lock`, sem duplicação de variáveis de ambiente.

#### Alterado
- **`XSECURELOCK_AUTH_BACKGROUND_COLOR`:** Atualizado de `#0D1017` para `#111620` para criar profundidade visual no diálogo de autenticação.
- **`XSECURELOCK_AUTH_WARNING_COLOR`:** Atualizado de `#F87171` (red) para `#F5A623` (amber) — alinhado à paleta de aviso do Design System Flavos.
- **Log path:** Migrado de `/tmp/...` fixo para `${XDG_RUNTIME_DIR:-/tmp}/flavos-xsecurelock.log`.
- **Documentação `SESSION_LOCK_AND_SECURITY.md`:** Reescrita completa — arquitetura de delegação, tabela de tokens visuais, roadmap de lock screen futura, hardening aplicado.

### Etapa 13A — Archive & Compression Support (2026-04-26)
#### Adicionado
- **Suporte nativo a arquivos compactados:** Integração profunda ao Nemo e ao desktop via `file-roller` e `nemo-fileroller`.
- **Ações de Contexto:** Menus "Extrair Aqui", "Extrair para..." e "Comprimir..." disponíveis com clique direito no Nemo.
- **Flavos Archives:** Stub `.desktop` personalizado (`flavos-archive.desktop`) ocultando a identidade original do GNOME no launcher.
- **Suporte de Backend CLI:** Adicionados `zip`, `unzip`, `p7zip-full` e `unrar-free` ao `packages.list` garantindo amplo suporte (zip, 7z, tar, gzip, xz, rar leitura limitada).
- **Integração MIME:** Mapeamentos padrão para arquivos compactados associados ao Flavos Archives, tanto na camada global (`/etc/xdg/mimeapps.list`) quanto no diretório do usuário (`/etc/skel/.config/mimeapps.list`).


### Etapa 12F.1 — Performance Adaptation Fixes & Settings UI (2026-04-25)
#### Adicionado
- **Tab Desempenho no `flavos-settings`:** nova interface para monitorar e alternar perfis de performance.
- **Detecção de Fallback GLX:** a aba Desempenho exibe um banner de aviso caso o hardware não suporte aceleração GLX, mostrando o compositor efetivo usado (Balanced/xrender em vez de Full/glx).
- **Controle de Otimizações na UI:** botões e status para `zram` e `Firefox Light` com confirmação.
- **Detecção `glxinfo`:** script `flavos-performance-profile` agora verifica dinamicamente a presença de `glxinfo` e suporte real OpenGL >= 2.0 antes de forçar o backend `glx`.
- **`mesa-utils`:** adicionado ao `packages.list` para prover `glxinfo`.

#### Corrigido
- **Tela preta no perfil Full:** prevenido crash-loop do Picom em máquinas virtuais (QEMU/KVM sem virgl) fazendo fallback seguro e silencioso para o backend `xrender` se OpenGL não for detectado.

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
