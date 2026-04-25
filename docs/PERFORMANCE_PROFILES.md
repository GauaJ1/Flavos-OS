# Flavos OS — Performance Profiles

**Etapa 12F — Performance Adaptation & Resource Profiles**

Este documento descreve o sistema de perfis de desempenho do Flavos OS: o que cada perfil faz,
como aplicar, o que muda no sistema, quais são os limites reais de hardware, e como reverter.

---

## 1. Visão Geral

O Flavos OS opera com três perfis de desempenho:

| Perfil     | Alvo de Hardware                          | Padrão? |
|------------|-------------------------------------------|---------|
| `light`    | 2 GB RAM, LGA775, HDD, GPU legada         | Não     |
| `balanced` | 4 GB RAM, hardware pós-2013, GPU integrada | **Sim** |
| `full`     | 8 GB+ RAM, SSD/NVMe, GPU com OpenGL       | Não     |

O perfil ativo é lido por:
- Compositor (Picom)
- Launcher (timing de fade)
- OSD (modo de animação)
- Panel/Taskbar (estilo glass/solid)

---

## 2. Como Aplicar um Perfil

### Perfil de usuário (sem sudo, só efeitos visuais):
```bash
flavos-performance-profile set light
flavos-performance-profile set balanced
flavos-performance-profile set full
```

### Perfil de sistema (com sudo, inclui mascaramento de serviços):
```bash
sudo flavos-performance-profile set light --system
sudo flavos-performance-profile set balanced --system
```

### Verificar perfil ativo:
```bash
flavos-performance-profile current
flavos-performance-profile status
```

### Reaplicar perfil sem mudar qual é:
```bash
flavos-performance-profile apply
```

---

## 3. O Que Cada Perfil Muda

### Picom (compositor)

| Aspecto          | Light             | Balanced         | Full             |
|------------------|-------------------|------------------|------------------|
| Backend          | xrender           | xrender          | glx (ver nota)   |
| use-damage       | true              | true             | true             |
| Fading           | desabilitado      | ativo (delta=3)  | ativo (delta=4)  |
| Shadow radius    | 6                 | 14               | 18               |
| Shadow opacity   | 0.20              | 0.35             | 0.45             |
| Corner-radius    | 0                 | 10               | 12               |
| vsync            | false             | false            | true             |

> **Nota sobre glx no Full**: o backend `glx` requer driver gráfico com OpenGL 2.0 funcional.
> No Debian Bookworm, drivers Intel/AMD modernos atendem. GPU pré-2012 ou com driver incompleto
> pode exibir glitches ou travar. Nesse caso, reverter para `balanced` ou editar
> `/etc/flavos/picom-full.conf` trocando `backend = "glx"` por `backend = "xrender"`.

### Shell visual

| Componente       | Light               | Balanced/Full     |
|------------------|---------------------|-------------------|
| Panel/Taskbar    | solid               | solid / glass     |
| Launcher fade    | 60ms entrada/40ms   | 120ms/80ms        |
| OSD animation    | fade puro (sem Y)   | slide Y + fade    |
| nemo-desktop     | desabilitado        | habilitado        |
| Wallpaper        | via feh (mantido)   | via feh           |

> **nemo-desktop no Light**: ícones de arquivo no desktop são desabilitados para liberar
> ~50 MB RAM. O wallpaper **continua ativo** via `feh` (gerenciado pelo session-daemon).
> Para restaurar ícones, troque para `balanced`.

### Serviços (apenas com --system + sudo)

| Serviço                          | Light       | Balanced/Full |
|----------------------------------|-------------|---------------|
| NetworkManager-wait-online       | mascarado   | padrão        |
| ModemManager                     | mascarado   | padrão        |
| bluetooth                        | mascarado   | padrão        |
| avahi-daemon                     | mascarado   | padrão        |

> **Segurança**: o script só desmascara serviços que ele mesmo mascarou (via marker em
> `/etc/flavos/`). Serviços mascarados manualmente pelo administrador não são tocados.
> Se você mascarou `bluetooth` antes de rodar este script, ele não será desmascarado
> ao trocar para `balanced`.

---

## 4. Opções Avançadas

### zram (swap comprimida em RAM)

Disponível **apenas no perfil `light`**. Não ativado por padrão.

**Quando usar**: hardware com 2 GB de RAM onde picos de uso causam OOM. zram com compressão
`zstd` oferece capacidade efetiva ~1.5× a RAM física, com baixo overhead em CPUs Core2+.

**Quando NÃO usar**: CPUs muito antigas (Celeron D, Pentium 4 pré-dual-core) onde a
compressão pode ser o gargalo. Testar antes de tornar permanente.

```bash
# Ativar zram no perfil light (requer sudo)
sudo flavos-performance-profile set light --system --with-zram

# Verificar se ativo
zramctl
swapon --show

# Reverter zram
sudo rm /etc/systemd/zram-generator.conf
sudo systemctl daemon-reload
sudo swapoff /dev/zram0
```

Configuração aplicada:
```ini
[zram0]
zram-size = ram / 2         # 50% da RAM (1 GB em sistema com 2 GB)
compression-algorithm = zstd
swap-priority = 100         # Usado antes do swap em disco
```

Manter swap em disco (se existir) com prioridade < 100 como safety net.

### Firefox ESR otimizado para 2 GB

Não aplicado automaticamente. Requer flag explícita:

```bash
flavos-performance-profile set light --apply-firefox-light
```

O que aplica (via user.js):
- `dom.ipc.processCount = 2` (padrão Firefox: 8)
- Escrita de sessão a cada 60s (padrão: 15s)
- Cache de disco limitado a 100 MB
- Telemetria desabilitada

**Backup automático**: o user.js existente recebe backup com timestamp antes de ser
substituído. Para reverter, restaurar o backup:
```bash
ls ~/.mozilla/firefox/*.default*/user.js.bak_*
# Restaurar:
cp ~/.mozilla/firefox/PERFIL/user.js.bak_TIMESTAMP ~/.mozilla/firefox/PERFIL/user.js
# Reiniciar Firefox
```

---

## 5. Viabilidade Real em 2 GB de RAM

Esta seção documenta expectativas honestas. Não são metas aspiracionais.

| Cenário                        | Viável?     | Observação                                      |
|--------------------------------|-------------|-------------------------------------------------|
| Boot + desktop idle            | ✓ Sim       | Alvo: < 450 MB RSS. Alcançável com perfil Light |
| Mousepad (texto)               | ✓ Sim       | ~40–60 MB adicional                             |
| Nemo (gerenciador de arquivos) | ✓ Sim       | ~60–80 MB adicional                             |
| Evince (PDF simples, 1 doc)    | ✓ Sim       | ~80–120 MB adicional                            |
| Firefox ESR, 1 tab leve        | ✓ Sim       | ~350–450 MB adicional                           |
| Firefox ESR, 2–3 tabs          | ⚠ Apertado  | Funcional, pode ser lento com sites pesados     |
| Firefox ESR, 4+ tabs           | ✗ Arriscado | Risco de OOM. Usar extensão de suspend de tabs  |
| Celluloid, vídeo 720p          | ✓ Sim       | mpv com decodificação de software moderada      |
| Celluloid, vídeo 1080p         | ⚠ Depende   | Depende da CPU. Core2 Duo: ok. Celeron D: lento |
| Firefox + Evince + Nemo        | ✗ Não recom | Pressão severa. Fechar apps antes de abrir novo |

**Compromissos práticos no perfil Light:**
- Fechar apps não usados antes de abrir o navegador
- Não abrir mais de 2 tabs ativamente pesadas ao mesmo tempo
- Se usar Firefox muito, ativar extensão de "suspend tabs" (Auto Tab Discard)
- Com zram ativo: margem adicional de ~500 MB comprimidos antes de spill para disco

---

## 6. Configuração por Arquivo

```
/etc/flavos/
  performance-profile        # "light" | "balanced" | "full" (sistema)
  picom-light.conf           # Config Picom para Light
  picom-balanced.conf        # Config Picom para Balanced
  picom-full.conf            # Config Picom para Full (glx, validar Etapa 14)
  firefox-light.js           # user.js Firefox para 2 GB RAM

~/.config/flavos/
  performance.json           # Override por usuário (opcional, prevalece sobre sistema)
  panel.json                 # style: solid | glass (atualizado pelo script)
  launcher.json              # fade_in_ms, fade_out_ms (lido pelo launcher)
  osd.json                   # pure_fade: true/false (lido pelo OSD)
  desktop-mode.json          # nemo_desktop: true/false

~/.config/picom/
  picom.conf                 # Sobrescrito pelo script (backup automático)
```

---

## 7. Rollback

### Voltar para Balanced (visual):
```bash
flavos-performance-profile set balanced
```

### Voltar para Balanced (sistema + serviços):
```bash
sudo flavos-performance-profile set balanced --system
```

### Reverter picom.conf manualmente:
```bash
ls ~/.config/picom/picom.conf.bak_*
cp ~/.config/picom/picom.conf.bak_TIMESTAMP ~/.config/picom/picom.conf
flavos-shellctl shell restart
```

### Se use-damage causar flicker/glitch:
Editar o picom.conf ativo:
```bash
# Troca use-damage = true por false no config ativo
sed -i 's/use-damage = true/use-damage = false/' ~/.config/picom/picom.conf
pkill -HUP picom 2>/dev/null || flavos-shellctl shell restart
```

Ou editar diretamente `/etc/flavos/picom-balanced.conf` para persistir via perfil.

---

## 8. Medição e Validação

Executar na VM após build para coletar baseline:

```bash
# Tempo de boot
systemd-analyze
systemd-analyze blame | head -20
systemd-analyze critical-chain

# RAM idle (5 min após login, sem apps)
free -h
ps aux --sort=-%mem | head -15

# CPU idle (3 min após login)
top -b -n 1 | head -20

# Serviços em execução
systemctl list-units --state=running --type=service | grep -v user

# Overhead do compositor
pidstat -p $(pgrep picom) 1 5

# Testar troca de perfil
flavos-performance-profile current
flavos-performance-profile set light
flavos-performance-profile status
flavos-performance-profile set balanced
flavos-performance-profile current
```

---

## 9. Limitações Conhecidas

1. **Sem medição em hardware real**: baseline coletado na VM. Medição em LGA775 real na Etapa 14.
2. **picom `glx` no Full**: não testado em hardware real. `glx` é preparação, não garantia.
3. **zram off por padrão**: hardware LGA775 é variável. CPU muito antiga pode sofrer com compressão.
4. **Firefox no Light**: funcional com 1–2 tabs; não é confortável com sites muito pesados.
5. **Celluloid com vídeo 1080p**: depende do CPU, não do perfil de performance.
6. **nemo-desktop no Light**: ícones de desktop são removidos (comportamento esperado, não bug).
7. **flavos-settings**: UI de configuração de perfil não existe ainda. Prevista na Etapa 12G ou 13.

---

## Histórico

| Versão | Etapa | Descrição |
|--------|-------|-----------|
| 1.0    | 12F   | Implementação inicial dos 3 perfis. Picom por config. Script de controle. |
