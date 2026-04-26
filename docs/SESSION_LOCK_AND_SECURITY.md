# Session Lock & Security

O Flavos OS utiliza um ecossistema minimalista focado em leveza e resiliência (Openbox/X11). Com a **Etapa 13C**, introduzimos uma camada de bloqueio de sessão.

> **Status (13C.3):** `i3lock` é o backend de lock atual — funcional, visualmente correto e sem conflito com o Picom. Uma lock screen nativa e premium é escopo de etapa futura.

---

## 1. Histórico de Backend: xsecurelock → i3lock

### 13C.1 — Integração inicial com xsecurelock
O `xsecurelock` foi escolhido inicialmente por sua arquitetura de segurança robusta: autenticação, verificação de senha e screen saver correm em **processos separados**, tornando crash-based bypasses mais difíceis.

### 13C.2 — Conflito com Picom (fundo branco)
O Picom remove janelas fora da ordem esperada pelo xsecurelock, causando a mensagem "INCOMPATIBLE COMPOSITOR, PLEASE FIX!". Corrigimos com `XSECURELOCK_COMPOSITE_OBSCURER=0`.

### 13C.3 — Desktop vazando por trás do lock (migração para i3lock)

`XSECURELOCK_COMPOSITE_OBSCURER=0` resolve o erro visual do Picom, mas **desabilita a janela que cobre o conteúdo do desktop**. O resultado: a sessão ficava visível por trás da tela de lock — falha de privacidade visual inaceitável.

O dilema do xsecurelock + Picom sem `picom.conf` customizado não tem saída via variáveis de ambiente:

| Configuração | Resultado |
|---|---|
| `COMPOSITE_OBSCURER=1` (default) | "INCOMPATIBLE COMPOSITOR" com Picom |
| `COMPOSITE_OBSCURER=0` | Desktop vaza por trás do lock |

**Decisão:** Migrar para `i3lock`. O i3lock cobre a tela completamente sem conflito com Picom, está disponível no Debian Bookworm e é adequado para a fase atual do Flavos OS.

### Trade-off documentado

| Aspecto | xsecurelock | i3lock |
|---|---|---|
| Arquitetura | Multi-processo (auth, UI, saver separados) | Single-process |
| Segurança X11 | Mais robusta contra crash-bypass | Adequada para uso desktop |
| Compatibilidade Picom | Problemática sem picom.conf customizado | Sem conflito |
| Cobertura visual | ❌ Vaza desktop com COMPOSITE_OBSCURER=0 | ✅ Cobre completamente |
| Disponibilidade | Debian Bookworm | Debian Bookworm |

> Para a fase atual (desktop preview, usuário único, QEMU), i3lock entrega a proteção visual necessária. A arquitetura multi-processo do xsecurelock só agrega valor quando a cobertura visual está garantida — sem ela, oferece menos proteção do que o i3lock.

---

## 2. Arquitetura de Lock (13C.3)

```
Super+L / Ctrl+Alt+L
Launcher → Lock
Power Menu → Bloquear
          ↓
  /usr/local/bin/flavos-shellctl session lock
          ↓
  exec /usr/local/bin/flavos-lock
          ↓
  exec i3lock -n -c 0D1017
```

**Todos os pontos de entrada** delegam para `flavos-shellctl session lock`, que executa `flavos-lock`, que executa `i3lock`. Nenhum componente chama `i3lock` diretamente.

### Por que um wrapper dedicado (`flavos-lock`)?
- Centraliza validações (sessão X11, binário, duplicata) em um único ponto
- Facilita substituição futura por lock screen nativa sem alterar callers
- Mantém `flavos-shellctl` como middleware limpo

---

## 3. Conceitos de Sessão

O comportamento é orquestrado via `flavos-shellctl session <ação>`:

- **Lock:** Mantém todos os programas abertos no fundo, cortando o acesso interativo à interface. Desbloqueável apenas com a senha do usuário.
- **Logout:** Encerra o gerenciador de janelas e mata os aplicativos da sessão gráfica.
- **Reboot / Poweroff:** Aciona rotinas do `systemd` para finalização ordenada.

---

## 4. Design Visual (i3lock)

O i3lock usa fundo sólido configurado via argumento de linha de comando:

| Parâmetro | Valor |
|---|---|
| Cor de fundo | `#0D1017` (via `-c 0D1017`) |
| Modo | Foreground (`-n` / `--nofork`) |

> **Nota visual:** O i3lock com `-c` oferece apenas fundo sólido. Uma lock screen com relógio, tipografia e controle visual completo é escopo de etapa futura.

---

## 5. Atalhos

| Atalho | Ação |
|---|---|
| `Super + L` | Bloqueia (primário) |
| `Ctrl + Alt + L` | Bloqueia (fallback confiável, sem dependência de xcape) |
| Launcher → Lock | Bloqueia (com delay de 150ms para release de grabs GTK) |
| Power Menu → Bloquear | Bloqueia |

**Keybinds:** Ambos usam path absoluto `/usr/local/bin/flavos-shellctl session lock` no `rc.xml`. O `flavos-session-daemon` chama `openbox --reconfigure` na inicialização X11.

**Launcher race condition (13C.3):** O launcher esconde sua janela antes de aguardar 150ms para então disparar o lock. Isso garante que os grabs GTK sejam liberados antes de o i3lock tentar adquirir seus próprios grabs de teclado e ponteiro.

---

## 6. Limitações Sérias de Segurança

### Autologin
O Flavos OS usa **autologin** direto no desktop. Se a máquina for desligada à força com a tela bloqueada, o próximo boot fará login automático. O lock serve **estritamente** para impedir acessos enquanto a máquina permanece ligada sob controle.

### Sem criptografia de disco
O bloqueio de tela não protege dados no disco. Se a máquina for desligada e o disco removido, ele pode ser lido livremente. O lock não substitui LUKS.

### Limitações X11
O protocolo X11 permite que aplicações já em execução leiam eventos de teclado ou capturem a tela. Lock screens em X11 não oferecem isolamento completo. Para mitigação definitiva, seria necessária migração para Wayland.

> O agente **não promete segurança absoluta** para lock screens em X11. O i3lock é adequado para proteção básica contra acesso físico casual enquanto a máquina está ligada.

---

## 7. Hardening Aplicado (Auditoria 13C.1 → 13C.3)

- **Log restrito:** `${XDG_RUNTIME_DIR:-/tmp}/flavos-lock.log` com `umask 077`
- **Prevenção de duplicata:** `pgrep -x i3lock` antes de iniciar
- **Validação de sessão:** Verifica `XDG_SESSION_TYPE=x11` antes de prosseguir
- **Validação de binário:** `command -v i3lock` antes de tentar executar
- **Prevenção de shell injection:** `flavos-power` usa `shlex.split()` em vez de `shell=True`
- **Sanitização de path:** `realpath` antes de passar o argumento de wallpaper
- **Variáveis defensivas:** `DISPLAY`, `XAUTHORITY`, `XDG_SESSION_TYPE` com defaults seguros
- **Launcher race condition:** `hide()` + delay 150ms antes de disparar o locker

---

## 8. Roadmap de Lock Screen

| Etapa | Status | Escopo |
|---|---|---|
| 13C.1 | ✅ Concluída | Integração funcional do xsecurelock |
| 13C.2 | ✅ Concluída | Fix Picom, wrapper central, Ctrl+Alt+L, openbox reconfigure |
| 13C.3 | ✅ Concluída | Migração para i3lock, fix launcher race, paths absolutos rc.xml |
| Futura | ⏳ Planejado | Lock screen nativa Flavos (design premium, relógio, tipografia) |
| Futura | ⏳ Planejado | LUKS / criptografia de disco |
| Futura | ⏳ Planejado | Migração para Wayland (isolamento completo de entrada) |
| Futura | ⏳ Planejado | `xss-lock` para lock automático por inatividade |
