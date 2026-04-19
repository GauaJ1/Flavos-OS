# Flavos Shell Preview 0.1
**"Basis"**

> *"O mínimo que um sistema operacional precisa para parecer um sistema operacional de verdade."*

Data de congelamento: 2026-04-19
Commit de referência: `4a6b301`
Etapas consolidadas: 11A → 11E

---

## 1. O que é esta preview

A **Flavos Shell Preview 0.1 "Basis"** é o primeiro instantâneo estável da shell nativa do Flavos OS. Ela representa a conclusão das etapas fundamentais de UI: sessão supervisionada, painel superior, taskbar, launcher e feedback visual. O nome "Basis" reflete a intenção: não é uma versão de produto final, é a fundação arquitetural sobre a qual o sistema vai crescer.

Esta etapa não adicionou nenhuma feature nova. Ela congela o estado atual como referência de qualidade e ponto de partida para as próximas etapas.

---

## 2. O que está incluso

### 2.1 Session Daemon (`flavos-session-daemon`)
- Supervisor de processos supervisionados: `picom`, `flavos-panel`, `flavos-taskbar`, `dunst`, `pcmanfm --desktop`
- `xcape` inicia via fire-and-forget (não supervisionado, comportamento correto de fork)
- Watchdog com ressurreição automática a cada 2s
- Handler de SIGTERM/SIGHUP para shutdown limpo e reload
- Log individual por componente em `~/.local/share/flavos/logs/`

### 2.2 Painel Superior (`flavos-panel`)
- Altura: 32px — reservado via `rc.xml margins.top`
- Modo DOCK para X11 (não aparece na taskbar, não recebe foco)
- Layout: branding FLAVOS à esquerda, relógio centralizado, ícones Settings/Power à direita
- Relógio atualizado a cada segundo via `GLib.timeout_add_seconds`
- CSS com tokens unificados: `Inter`, `#0D1017`, `#272D3D`, `#4B8BF5`
- Suporte a modo glass via `panel.json`

### 2.3 Taskbar (`flavos-taskbar` v4)
- Altura: 36px — reservado via `rc.xml margins.bottom`
- Componentes: botão menu (Super/launcher), 3 apps fixados, `Wnck.Tasklist`, ícones de status (volume/rede/notif), relógio de duas linhas (HH:MM / DD/MM/AAAA)
- `Wnck.Tasklist` com `halign=START` — botões de janela não se expandem indefinidamente
- CSS com especificidade `window#FlavosTaskbar` — imune a vazamento do tema GTK base
- Status buttons: flat design, sem fundo opaco vazando do Adwaita
- Ícone de volume dispara `flavos-osd volume`

### 2.4 Launcher (`flavos-launcher` — Etapa 11C Final)
- PID file `/tmp/flavos-launcher.pid` — contrato atômico com `shellctl`
- Focus guard de 300ms — elimina fechamento imediato por focus-out transitório do X11
- Fonte única de foco: `map-event → present_with_time(Gdk.CURRENT_TIME)`
- Fade-in 120ms ease-out / Fade-out 80ms ease-in — via `GLib.timeout_add(16ms)`
- Toggle: Super abre se fechado, fecha se aberto — via `flavos-shellctl launcher toggle`
- Barra de busca com filtro em tempo real
- 5 ações rápidas fixadas (Terminal, Settings, Info, Restart, Lock)
- Grade de apps instalados via `Gio.AppInfo`

### 2.5 OSD / Feedback Visual (`flavos-osd` v5 — Etapa 11D)
- OSD de Volume: ícone dinâmico (mudo/baixo/médio/alto) + valor percentual + barra
- OSD de Brilho: lê `/sys/class/backlight`, exibe "Não disponível" se ausente
- Toast de Shell: canal interno para eventos de sistema (Wi-Fi, ações de shell)
- Singleton via PID file — disparo rápido (segurar volume) não acumula instâncias
- Fade-in 120ms / Fade-out 100ms + slide Y 8px — mesmo token de motion da shell
- Fallback: pure opacity fade se `is_composited() == False` (VM sem compositor)
- Toast posicionado via `GLib.idle_add` pós-layout GTK — altura real, sem estimativa

### 2.6 Shell Control (`flavos-shellctl`)
- Middleware bash entre frontend GTK e ações de sistema
- Contratos: `session logout/reboot/poweroff`, `shell restart`, `launcher toggle`, `wallpaper apply`
- Launcher toggle via PID file (`kill -0` para validar, `kill -TERM` para fechar)
- Sem `pgrep`/`pkill` — seguro com `set -e`

### 2.7 Compositor e Tema
- **Picom**: blur, sombras, transparência RGBA para janelas GTK
- **Tema Openbox**: `FlavosOS` — bordas estreitas, tipografia Inter, layout `NLIMC`
- **Ícones**: Papirus — consistente entre launcher, taskbar, OSD e settings
- **Fontes**: Inter (UI), Roboto (fallback)

---

## 3. O que ainda é legado

| Componente | Tecnologia | Motivo de permanência |
|---|---|---|
| **Servidor gráfico** | Xorg / X11 | Wayland fora do escopo até estabilização total da shell |
| **Gerenciador de janelas** | Openbox | WM nativo em C, estável, zero overhead — substituição planejada para após Etapa 12 |
| **Compositor** | Picom | Backend de blur/sombra para X11 — será desnecessário em Wayland nativo |
| **Desktop / Wallpaper** | PCManFM `--desktop` | Gerencia wallpaper e ícones de desktop via EWMH — simples e funcional |
| **Notificações de apps** | Dunst | Daemon de notificações do ecossistema X11 — integração completa planejada |
| **Polkit** | lxpolkit | Agente de autenticação gráfico padrão — não substitui um agente nativo Flavos |
| **Terminal** | Kitty | Adotado como padrão atual — não é um componente nativo Flavos |
| **Gerenciador de arquivos** | PCManFM | Funcional para esta fase — um gerenciador nativo não está no roadmap imediato |

---

## 4. Limitações honestas

### Estabilidade
- **Wnck.Tasklist**: botões de janela podem ocasionalmente não respeitar `max-width` em GTK3 — comportamento dependente do tema e versão. Mitigado pelo `halign=START`.
- **focus-out guard**: o guard de 300ms no launcher é uma heurística baseada no timing médio do X11/Openbox. Em hardware muito lento, pode precisar de ajuste.

### Design
- **Relógio do painel**: mostra formato `Seg, 19 Abr • 14:00` — não há seletor de formato pelo usuário (futuro: settings).
- **Ícone de notificação na taskbar**: é um placeholder estático — dunst não expõa API GTK nativa para contagem de notificações.
- **Ícone de rede**: abre `nm-connection-editor` — não mostra status inline na taskbar.

### Performance
- **Tempo de boot da shell**: `flavos-taskbar` inicia com delay de 1.5s após o daemon (espera o WM estabilizar). É intencional, mas perceptível.
- **Launcher**: carrega `Gio.AppInfo.get_all()` sincronamente na primeira abertura (~80-150ms). Latência aceitável mas mensurável.

### OSD / Brilho
- `flavos-osd brightness-up/down` é sem-op em VMs e monitores externos sem DDC — exibe "Não disponível" corretamente, não trava.
- Toast do sistema não tem histórico nem fila — se dois toasts dispararem em sequência, o singleton cancela o primeiro.

---

## 5. Checklist de Validação

### Boot e Sessão
- [ ] `make clean && make all && make boot-gui` executa sem erros
- [ ] Após login, painel e taskbar aparecem sem interação do usuário
- [ ] Nenhum processo em loop no `htop` (verificar `flavos-*`)
- [ ] `picom` e `dunst` visíveis em `ps aux`

### Painel
- [ ] Relógio atualiza a cada segundo
- [ ] Botão ⚙️ abre `flavos-settings`
- [ ] Botão ⏻ abre `flavos-power`
- [ ] Fundo e tipografia coerentes com design system

### Taskbar
- [ ] Botões de apps fixados abrem Terminal, Arquivos, Editor
- [ ] Janelas abertas aparecem na Wnck.Tasklist com tamanho compacto (não gigante)
- [ ] Relógio de duas linhas visível: hora em cima, data embaixo
- [ ] Ícone de volume abre OSD

### Launcher
- [ ] Pressionar Super → launcher aparece com fade-in
- [ ] Pressionar Escape → launcher fecha com fade-out
- [ ] Clicar fora → launcher fecha
- [ ] Pressionar Super 3 vezes rapidamente → sem instâncias duplicadas
- [ ] Busca filtra apps em tempo real
- [ ] Enter no campo de busca lança o primeiro resultado

### Feedback Visual
- [ ] `XF86AudioRaiseVolume` → OSD aparece com valor, ícone e barra
- [ ] `XF86AudioLowerVolume` → OSD atualiza sem instâncias concorrentes
- [ ] `XF86AudioMute` → OSD mostra "Mudo" com visual diferenciado
- [ ] `flavos-osd notify "Teste" "Mensagem"` → Toast aparece no canto inferior direito
- [ ] OSD desaparece automaticamente após ~1.8s

### Design
- [ ] Paleta consistente entre panel, taskbar, launcher, OSD (fundo `#0D1017`/`rgba(20,24,32)`, accent `#4B8BF5`, texto `#E8ECF4` / `#FFFFFF`)
- [ ] Tipografia Inter em todos os componentes nativos
- [ ] Hover states visíveis e responsivos
- [ ] Nenhum artefato de tema GTK base (botões brancos, bordas inesperadas)

---

## 6. Instruções de Teste

### Build e Boot
```bash
# Na máquina host
cd ~/Imagens/FlavosOS
make clean && make all
make boot-gui
```

### Teste de Singleton do Launcher
```bash
# Na VM — apertar Super 5 vezes rápido, depois:
pgrep -c flavos-launcher
# Esperado: 0 (launcher fechou) ou 1 (launcher aberto)
```

### Teste de OSD com disparo rápido
```bash
# Na VM
for i in $(seq 1 10); do flavos-osd volume-up & done
sleep 2
pgrep -c flavos-osd
# Esperado: 0 (todos os processos concluíram)
```

### Teste de Toast manual
```bash
# Na VM
flavos-osd notify "Wi-Fi" "Conectado à rede Flavos"
```

### Verificar logs de componentes
```bash
# Na VM
ls ~/.local/share/flavos/logs/
cat ~/.local/share/flavos/logs/taskbar.log
cat ~/.local/share/flavos/logs/launcher.log  # apenas se houver crash
```

### Verificar ausência de loops
```bash
# Na VM — nenhuma das linhas deve crescer de contagem ao longo do tempo
watch -n 2 'ps aux | grep flavos'
```

---

## 7. Veredito Técnico

**Estado: `EXPERIMENTAL ESTÁVEL`**

A Flavos Shell Preview 0.1 "Basis" é um sistema funcional e intencionalmente construído. Não é uma coleção de scripts — é uma shell com arquitetura definida, contratos claros entre componentes, sistema de design coerente e motion language estabelecida.

O que a torna **experimental**:
- Roda sobre X11/Openbox (tecnologia legada), não sobre um stack nativo Flavos
- Não foi testada em hardware físico diverso
- Alguns comportamentos dependem de heurísticas de timing do X11
- Sem testes automatizados de integração ainda

O que a torna **estável**:
- Nenhum componente crash-loopa no daemon
- O launcher possui singleton, focus guard e fade limpo
- O OSD possui singleton e fallback de compositing
- CSS sem `!important` nem propriedades não suportadas pelo GTK3
- Todos os binários têm permissão de execução e sintaxe validada

> Esta preview é o ponto de partida para tudo que vem depois.
> O sistema já parece um sistema operacional próprio.
> O próximo passo é fazê-lo parecer inacreditavelmente bom.

---

## Referência de Commits (11A → 11E)

| Commit | Etapa | Descrição |
|---|---|---|
| `d326915` | 11A | Terminal kitty com clipboard |
| `664109e` | 11B | Taskbar CSS fix (max-width) |
| `3143111` | 11B | Tasklist compacto (halign=START) |
| `c270cfc` | 11B | Remoção de !important do CSS |
| `538f174` | 11B | Relógio duas linhas + OSD volume integrado |
| `7d9272e` | 11B | Override GTK artifacts nos botões |
| `08592a6` | 11C | Finalização completa do Launcher |
| `b0d5163` | 11D | Native Visual Feedback System (OSD v5) |
| `4a6b301` | 11D | Fix visibilidade OSD (opacidade e cores) |
