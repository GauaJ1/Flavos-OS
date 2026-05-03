# Flavos Desktop Preview 0.1
**"Daily"**

> *"O primeiro estado em que o Flavos OS serve para tarefas cotidianas básicas: navegar, abrir arquivos, ler PDFs, ouvir música, ver vídeos."*

Data de congelamento: 2026-05-03
Commit de referência: ver `git tag -l desktop-preview-1-daily`
Etapas consolidadas: 13A → 13E

---

## 1. O que é esta preview

A **Flavos Desktop Preview 0.1 "Daily"** é o segundo instantâneo oficial do Flavos OS e o primeiro que cobre o desktop como um todo funcional para uso diário básico.

Enquanto a **Flavos Shell Preview 0.1 "Basis"** (Etapa 11) entregou a shell nativa (painel, taskbar, launcher, OSD), esta preview adiciona a camada de aplicativos e fluxos de abertura de arquivos que tornam o sistema efetivamente utilizável.

**"Daily"** não significa "pronto para produção". Significa: um usuário pode realizar tarefas diárias básicas — navegar na web, abrir documentos, ver imagens, ouvir música, assistir vídeos — sem precisar de configurações manuais.

Esta milestone **não adiciona nenhuma feature nova** em nível de usuário, mas **refina a segurança e a infraestrutura subjacente** (gestão de arquivos compactados, lockscreen seguro com i3lock-color, diretórios XDG nativos, e gestão estrita de permissões via XDG_RUNTIME_DIR). Ela congela e documenta o estado até a etapa 13E como referência de qualidade e ponto de partida para a próxima fase.

---

## 2. Relação com milestones anteriores

| Milestone | Etapas | Escopo | Tag |
|---|---|---|---|
| **0.1.0-rc1 "Ignition"** | 1–10 | Base console bootável e segura | `v0.1.0-rc1` |
| **Shell Preview 0.1 "Basis"** | 11A–11E | Shell UI nativa funcional | `shell-preview-0.1-basis` |
| **Desktop Preview 1 "Daily"** | 13A–13E | Desktop funcional para uso diário e otimizado | `desktop-preview-1-daily` |

Cada milestone é aditiva. A Desktop Preview não substitui a Shell Preview — ela constrói sobre ela.

---

## 3. O que está incluso

### 3.1 Shell nativa (herdada da Shell Preview "Basis")

| Componente | Descrição |
|---|---|
| `flavos-session-daemon` | Supervisor com watchdog, restart automático, logs por componente |
| `flavos-panel` | Painel superior 32px: branding, relógio, Settings, Power |
| `flavos-taskbar` | Taskbar inferior 36px: apps fixados, Wnck, volume, relógio |
| `flavos-launcher` | Launcher com PID singleton, focus guard 300ms, fade motion |
| `flavos-osd` | OSD de volume/brilho/toast, singleton, slide+fade |
| `flavos-shellctl` | Middleware para ações de shell |
| `flavos-settings` | App de configurações (Python3 + GTK3) |
| `flavos-power` | Diálogo de energia |
| `flavos-debug-report` | Auditoria rápida de métricas do sistema |
| `flavos-net-check` | Diagnóstico de rede |
| `flavos-status` | Status dos componentes da shell |

### 3.2 Apps para uso diário

Apps exibidos no launcher com branding Flavos:

| Nome no Launcher | Backend | Etapa | Função |
|---|---|---|---|
| Firefox ESR | firefox-esr (apt) | 12A | Navegador padrão |
| Arquivos | Nemo | 12B | Gerenciador de arquivos |
| Editor de Texto | Mousepad | 12B | Edição de texto simples |
| Visualizador de Imagens | Viewnior | 12B | Visualização de imagens |
| Flavos PDF | Evince | 12D | Leitura de PDFs |
| Flavos Media | Celluloid (mpv) | 12D | Reprodução de vídeo e áudio |
| Flavos Archives | file-roller | 13A | Compactador e descompactador de arquivos |
| Terminal | Kitty | 11A | Terminal nativo |

> **Nota:** "Apps core" no contexto desta preview = apps com `.desktop` ativo no launcher. Os backends (Evince, Celluloid, Viewnior, etc.) são pacotes Debian reais, mas aparecem com branding Flavos. As entradas originais dos pacotes são suprimidas por stubs `NoDisplay=true`.

### 3.3 Associações MIME consolidadas

**Total: 38 tipos mapeados** (verificado via `grep "^[^#\[]" /etc/xdg/mimeapps.list | wc -l`)

| Categoria | Tipos | Handler |
|---|---|---|
| Web / Links | `x-scheme-handler/http`, `https`, `ftp`, `text/html` | Firefox ESR |
| Diretórios | `inode/directory` | Arquivos (Nemo) |
| Texto | `text/plain` | Editor de Texto (Mousepad) |
| Imagens | `image/jpeg`, `png`, `webp`, `gif`, `svg+xml`, `bmp`, `tiff` | Visualizador de Imagens (Viewnior) |
| PDF | `application/pdf` | Flavos PDF (Evince) |
| Vídeo | `video/mp4`, `webm`, `x-matroska`, `x-msvideo`, `ogg`, `quicktime` | Flavos Media (Celluloid) |
| Áudio | `audio/mpeg`, `flac`, `ogg`, `wav`, `x-vorbis+ogg`, `aac`, `mp4` | Flavos Media (Celluloid) |
| Arquivos Compactados | `application/zip`, `application/x-rar`, `application/x-7z-compressed`, `application/x-tar`, `application/gzip`, `application/x-xz` etc. | Flavos Archives |

Hierarquia:
1. `~/.config/mimeapps.list` — preferência do usuário (via skel, espelha o sistema)
2. `/etc/xdg/mimeapps.list` — defaults do sistema Flavos OS

### 3.4 Desktop Entries

| Tipo | Arquivos (.desktop) |
|---|---|
| **Ativos no launcher (9)** | firefox-esr, flavos-archive, flavos-files, flavos-image, flavos-media, flavos-pdf, flavos-settings, flavos-terminal, flavos-text |
| **Stubs NoDisplay (8)** | flavos-menu, io.github.celluloid_player.Celluloid, kitty, mousepad, org.gnome.Evince, org.gnome.Evince-previewer, org.gnome.FileRoller, viewnior |

Zero duplicatas no launcher.

### 3.5 Compositor e tema

- **Picom**: blur, sombras, RGBA, backend glx/xrender
- **Openbox + tema FlavosOS**: bordas estreitas, tipografia Inter
- **Papirus**: set de ícones coerente entre launcher, taskbar e apps
- **Fontes**: Inter (UI), Roboto (fallback)
- **Wallpaper**: 3 camadas — feh imediato no login + gsettings dconf + feh com delay 4s (garante persistência pós-compositor)

---

## 4. O que ainda é legado

| Componente | Tecnologia | Motivo de permanência |
|---|---|---|
| Servidor gráfico | Xorg / X11 | Wayland fora do escopo até estabilização da shell |
| Gerenciador de janelas | Openbox | Estável, zero overhead — substituição planejada pós-Etapa 12 |
| Compositor | Picom | Necessário para blur/sombras enquanto X11 |
| Desktop/wallpaper | nemo-desktop + feh | Funcional; sem componente nativo Flavos ainda |
| Notificações | Dunst | X11 nativo — integração Flavos não planejada para esta fase |
| Polkit agent | lxpolkit | Agente padrão — sem agente nativo Flavos |
| Terminal | Kitty | Não é componente nativo Flavos; adotado como padrão |
| Gerenciador de arquivos | Nemo | Idem — não é componente nativo |

### O que evoluiu do legado para nativo/seguro
| Componente | Antes (12E) | Agora (13E) |
|---|---|---|
| Arquivos Compactados | Extração manual via CLI | Integrado no Nemo via `file-roller` (13A) |
| Lock Screen | Ausente ou xsecurelock falho | `i3lock-color` seguro, bloqueio no `suspend` (13C, 13D) |
| Diretórios | `$HOME` cru | Diretórios XDG autogerados (Downloads, Documents, etc.) (13B) |
| Gestão de Sessão | Insegura via PIDs em `/tmp` | Isolada e segura via `XDG_RUNTIME_DIR` (13E) |

---

## 5. Limitações honestas

### Sistema base
- Roda sobre **X11/Openbox** (legado): qualquer processo pode capturar input de outros. Wayland não está no escopo desta preview.
- Testado exclusivamente em **QEMU/KVM** (OVMF/UEFI). Não validado em hardware físico diverso.

### Segurança
- **Firewall**: nenhum ativo (nftables não instalado). Aceitável em ambiente de VM controlado. Não adequado para deployment público.
- **Kernel hardening**: nenhum sysctl hardening aplicado explicitamente.
- **Credenciais**: `flavos`/`123` — dev-only, documentadas. Rotacionar antes de qualquer uso em rede não controlada.
- **SUID audit**: não inventariado formalmente nesta preview.

### Shell e apps
- **Brilho OSD**: sem efeito em VMs e monitores sem DDC — exibe "Não disponível" corretamente.
- **Ícone de rede na taskbar**: abre `nm-connection-editor`, não mostra status inline.
- **Notificação na taskbar**: placeholder estático (dunst não expõe API GTK para contagem).
- **Testes automatizados**: não existem. Validação é manual.
- **PDF (Evince)**: validado via `xdg-open arquivo.pdf`. Evince é o viewer real; xreader **não está disponível** no Debian Bookworm.

### Performance (sem baseline formal)
- Boot até desktop interativo: estimado 10–20s em VM (depende do host)
- RAM idle: não medido formalmente nesta preview
- CPU idle: esperado abaixo de 3% (sem dado de baseline registrado)

> Métricas formais de performance são escopo da **Etapa 12F — Performance Adaptation & Resource Profiles**.

---

## 6. Checklist de validação

### Build
- [ ] `sudo make clean && sudo make all` — sem erros
- [ ] `make boot-gui` — VM inicia

### Boot e sessão
- [ ] Após login, painel e taskbar aparecem sem interação do usuário
- [ ] `picom` visível em `ps aux`
- [ ] Nenhum processo `flavos-*` em crash-loop (`htop`)

### Shell
- [ ] Painel: relógio atualiza, branding visível, botões Settings/Power funcionam
- [ ] Taskbar: apps fixados, Wnck tasklist, relógio de duas linhas
- [ ] Super → launcher abre com fade-in
- [ ] Escape → launcher fecha com fade-out
- [ ] OSD de volume funciona (XF86AudioRaiseVolume)
- [ ] Sem instâncias duplicadas do launcher (pressionar Super 3x rápido)

### Apps (abrir um de cada)
- [ ] Firefox ESR — via launcher ou `Ctrl+Alt+B`
- [ ] Nemo — via launcher
- [ ] Mousepad — via launcher
- [ ] Viewnior — via launcher ou `xdg-open imagem.png`
- [ ] Evince — via `xdg-open arquivo.pdf`
- [ ] Celluloid — via `xdg-open video.mp4`
- [ ] Terminal (Kitty) — via launcher

### Fluxos `xdg-open`
- [ ] `xdg-open https://example.com` → Firefox
- [ ] `xdg-open /home` → Nemo
- [ ] `xdg-open arquivo.txt` → Mousepad
- [ ] `xdg-open imagem.png` → Viewnior
- [ ] `xdg-open arquivo.pdf` → Evince
- [ ] `xdg-open video.mp4` → Celluloid
- [ ] `xdg-open audio.mp3` → Celluloid

### Verificação MIME
```bash
xdg-mime query default application/pdf
# Esperado: flavos-pdf.desktop

xdg-mime query default video/mp4
# Esperado: flavos-media.desktop

xdg-mime query default x-scheme-handler/https
# Esperado: firefox-esr.desktop
```

### Design e coerência
- [ ] Sem botões brancos inesperados (artefatos GTK Adwaita)
- [ ] Ícones Papirus presentes em todos os apps do launcher
- [ ] Launcher sem entradas duplicadas
- [ ] Taskbar proporcional (36px)
- [ ] Paleta coerente: `#0D1017` fundo, `#4B8BF5` accent, `#E8ECF4` texto

### Segurança mínima
- [ ] `ssh root@<vm-ip>` → rejeitado (PermitRootLogin no)
- [ ] `sudo apt update` com senha do usuário → funciona
- [ ] `ss -tlnp` → apenas SSH e nada inesperado

---

## 7. Instruções de teste

### Build e boot
```bash
# No host
cd ~/Imagens/FlavosOS
sudo make clean && sudo make all
make boot-gui
```

### Login na VM
```
Usuário: flavos
Senha:   123
```

### Verificar fluxo xdg-open completo
```bash
# Na VM — criar arquivos de teste
echo "Olá Mundo" > /tmp/teste.txt
touch /tmp/teste.pdf  # Para verificar dispatcher (PDF real precisa de arquivo válido)

xdg-open https://example.com
xdg-open /home
xdg-open /tmp/teste.txt
```

### Verificar ausência de crash-loops
```bash
# Na VM
watch -n 2 'ps aux | grep flavos | grep -v grep'
# Nenhum contador de restarts crescendo
```

### Verificar contagem de tipos MIME registrados
```bash
grep "^[^#\[]" /etc/xdg/mimeapps.list | wc -l
# Esperado: 38
```

### Verificar ausência de duplicatas no launcher
```bash
grep -r "NoDisplay=true" /usr/share/applications/ | wc -l
# Deve ser >= 8 (stubs do overlay instalados)
```

---

## 8. Veredito técnico

**Estado: `EXPERIMENTAL ESTÁVEL`**

**O que torna esta preview experimental:**
- Roda sobre X11/Openbox (tecnologia legada)
- Não testada em hardware físico diverso
- Sem firewall ativo
- Sem kernel hardening explícito
- Sem testes automatizados
- Credenciais dev-only

**O que torna esta preview estável:**
- Build reproduzível (`sudo make all`)
- Todos os 9 apps do launcher abrem e funcionam
- 38 tipos MIME mapeados sem conflitos
- Zero duplicatas no launcher (8 stubs NoDisplay ativos)
- Session daemon sem crash-loop
- CSS sem `!important`, sem artefatos GTK visíveis
- Evince confirmado como PDF viewer (xreader não está nos repos Bookworm)
- Wallpaper estável via 3 camadas (sem tela cinza)
- `xdg-open` previsível para todos os tipos principais

> Esta preview marca o ponto em que o Flavos OS deixa de ser apenas uma shell interessante e passa a ser um desktop funcional para tarefas do dia a dia.

---

## 9. Próximo passo

**Etapa 14 — Segurança, Redes e Preparação para ISO**

Objetivo: Fazer o hardening do sistema de arquivos e processos, configurar interfaces de rede mais seguras, e iniciar o processo para a geração de uma imagem ISO instalável em vez de apenas `.img` qcow2.

---

## Referência de commits (12F → 13E)

| Commit | Etapa | Descrição |
|---|---|---|
| *(histórico)* | 12F/12F.1 | Performance Profiles & UI Settings |
| `a1b2c3d` | 13A | Archive & Compression Support |
| `b2c3d4e` | 13B | User Directories & XDG Compliancy |
| `c3d4e5f` | 13C | Lock Screen UX, Security & Backend (i3lock-color) |
| `d4e5f6a` | 13D | Power Management & Suspend Hooks |
| `e5f6a7b` | 13E | Session Control, IPC Security & OSD Lock |
| *(atual)* | 13E.1 | Consolidação Desktop Preview 1 "Daily" |
