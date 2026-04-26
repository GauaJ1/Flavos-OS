# Session Lock & Security

O Flavos OS utiliza um ecossistema minimalista focado em leveza e resiliência (Openbox/X11). Com a **Etapa 13C**, introduzimos o **xsecurelock** como a camada primária de bloqueio de sessão.

> **Status (13C.2):** `xsecurelock` é o backend de lock atual — funcional, seguro dentro das limitações do X11, e visualmente alinhado ao mínimo do Design System Flavos. Uma lock screen nativa e premium é escopo de etapa futura.

---

## 1. Por que o xsecurelock?

O protocolo X11 tem vulnerabilidades estruturais: qualquer aplicação pode escutar eventos de teclado ou ler a tela. O `xsecurelock`, desenvolvido pelo Google, **reduz os riscos clássicos de lockers X11** por design modular:

- Autenticação, verificação de senha e screen saver correm em **processos separados**. Um crash em qualquer um deles não desbloqueia a tela.
- O processo principal usa apenas C, POSIX e X11 APIs — menor superfície de ataque.
- Grabs de teclado e ponteiro são renovados periodicamente.

**Limitação documentada do X11:** O `xsecurelock` não isola completamente contra clientes maliciosos já em execução (keyloggers root-level ou injeções abaixo do X server). Para mitigação completa desses vetores no *display server*, seria necessária migração para Wayland.

---

## 2. Arquitetura de Lock (13C.2)

```
Super+L / Ctrl+Alt+L
Launcher → Lock
Power Menu → Bloquear
          ↓
  flavos-shellctl session lock
          ↓
  exec /usr/local/bin/flavos-lock   ← wrapper central
          ↓
  xsecurelock
```

**Todos os pontos de entrada** delegam para `flavos-shellctl session lock`, que por sua vez executa `flavos-lock`. Nenhum componente chama `xsecurelock` diretamente.

### Por que um wrapper dedicado (`flavos-lock`)?

- Centraliza tokens visuais, fix do Picom e guards em um único arquivo versionável.
- Facilita substituição futura por lock screen nativa sem alterar callers.
- Mantém `flavos-shellctl` como middleware limpo e sem lógica de ambiente.

---

## 3. Conceitos de Sessão (Shellctl)

O comportamento é orquestrado via `flavos-shellctl session <ação>`:

- **Lock:** Mantém todos os programas abertos no fundo, cortando o acesso interativo à interface visual. Desbloqueável apenas com a senha do usuário. Use para pausas.
- **Logout:** Encerra o gerenciador de janelas e mata os aplicativos da sessão gráfica. Limpeza total do ambiente.
- **Reboot / Poweroff:** Aciona rotinas do `systemd` para finalização ordenada.

---

## 4. Design Visual (xsecurelock)

O visual é configurado via variáveis de ambiente em `flavos-lock`:

| Token | Valor |
|---|---|
| Fundo principal | `#0D1017` |
| Fundo do diálogo auth | `#111620` |
| Texto | `#E8ECF4` |
| Aviso (senha errada) | `#F5A623` |
| Fonte | `Inter:size=14` |
| Prompt de senha | `cursor` (não expõe tamanho) |
| Layout de teclado | Oculto |
| Hostname | Oculto |
| Relógio | `%H:%M` |

> **Nota visual:** O xsecurelock não suporta CSS ou imagens de fundo customizadas. A identidade visual é aplicada via variáveis de ambiente. Uma lock screen com controle visual completo é escopo de etapa futura.

---

## 5. Fix Crítico: Picom (XSECURELOCK_COMPOSITE_OBSCURER=0)

O `flavos-lock` exporta obrigatoriamente `XSECURELOCK_COMPOSITE_OBSCURER=0`.

**Motivo:** O Picom (compositor padrão do Flavos OS) remove janelas fora da ordem esperada pelo xsecurelock, causando uma tela branca com mensagem "INCOMPATIBLE COMPOSITOR, PLEASE FIX!" em vez da tela de lock. Este flag desativa o mecanismo de obscurecimento que conflita com o Picom.

Referência: [xsecurelock Known Compatibility Issues](https://github.com/google/xsecurelock#known-compatibility-issues)

---

## 6. Autologin e Risco de Reboot Físico

O Flavos OS usa **autologin** direto no desktop. Se a máquina for desligada à força (botão físico) com a tela bloqueada, o próximo boot fará login automático, expondo a sessão. O lock serve **estritamente** para impedir acessos enquanto a máquina permanece ligada sob controle.

---

## 7. Ausência de Criptografia de Disco

O bloqueio de tela não protege dados no disco. Se a máquina for desligada e o disco removido, ele pode ser lido livremente. O lock não substitui LUKS (Data-at-Rest), que é escopo de etapa futura.

---

## 8. Atalhos

| Atalho | Ação |
|---|---|
| `Super + L` | Bloqueia (primário; requer `openbox --reconfigure` ativo) |
| `Ctrl + Alt + L` | Bloqueia (fallback confiável, sem dependência de xcape) |
| Launcher → Lock | Bloqueia |
| Power Menu → Bloquear | Bloqueia |

**Nota Super+L:** O `flavos-session-daemon` chama `openbox --reconfigure` automaticamente na inicialização X11, garantindo que o keybind esteja ativo desde o primeiro boot sem intervenção manual.

---

## 9. Hardening Aplicado (Auditoria 13C.1 + 13C.2)

- **Log restrito:** `/tmp/flavos-xsecurelock.log` (ou `$XDG_RUNTIME_DIR/...`) criado com `umask 077` — somente o dono lê/escreve.
- **Prevenção de shell injection:** `flavos-power` usa `shlex.split()` em vez de `shell=True`.
- **Sanitização de path (wallpaper):** `realpath` antes de passar o argumento para `feh`/`gsettings`.
- **Variáveis defensivas:** `DISPLAY`, `XAUTHORITY`, `XDG_SESSION_TYPE` com defaults seguros.
- **Prompt de senha:** `cursor` (não expõe comprimento da senha; `asterisks` foi descartado).
- **Picom fix:** `XSECURELOCK_COMPOSITE_OBSCURER=0` previne bypass visual.

---

## 10. Roadmap de Lock Screen

| Etapa | Status | Escopo |
|---|---|---|
| 13C.1 | ✅ Concluída | Integração funcional do xsecurelock |
| 13C.2 | ✅ Concluída | Fix Picom, wrapper central, Ctrl+Alt+L, openbox reconfigure |
| Futura | ⏳ Planejado | Lock screen nativa Flavos (GTK/Python, design premium completo) |
| Futura | ⏳ Planejado | LUKS / criptografia de disco |
| Futura | ⏳ Planejado | Migração para Wayland (isolamento completo de entrada) |
