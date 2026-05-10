# Flavos OS — Hardware Lab Baseline

> **Etapa:** 14B — Hardware Lab Baseline
> **Status:** Preparação para testes em hardware real
> **Prerequisito:** Etapa 14A concluída

Este documento define o protocolo formal para testar o Flavos OS em hardware real.
A Etapa 14B **NÃO** instala o sistema em hardware. Ela prepara a infraestrutura de testes, checklists e critérios para quando a validação física acontecer.

---

## 1. Objetivo

Criar uma base formal de laboratório para testes controlados em hardware real.

**O que a 14B faz:**
- Define checklist de hardware
- Cria ficha de máquina
- Estabelece protocolo de teste
- Fornece comandos de diagnóstico
- Define critérios de sucesso/falha
- Documenta plano de risco
- Prepara validação para hardware antigo (LGA 775 / 2 GB RAM)

**O que a 14B NÃO faz:**
- Não instala em hardware
- Não cria live boot
- Não cria instalador
- Não altera bootloader
- Não mexe em partições
- Não modifica credenciais
- Não faz performance tuning agressivo

---

## 2. Antes de Testar

### Checklist obrigatório antes de qualquer teste

- [ ] Artefato gerado com `make release`
- [ ] SHA256 verificado: `sha256sum -c *.sha256`
- [ ] `docs/RELEASE_ARTIFACTS.md` revisado
- [ ] Disco de teste identificado (nunca disco com dados importantes)
- [ ] VM testada antes de hardware físico
- [ ] Pendrive ou disco externo separado para gravação
- [ ] Hardware fotografado e anotado antes do teste
- [ ] Backup de qualquer dado no disco de teste realizado
- [ ] Mídia de recuperação disponível (live USB, outro OS)
- [ ] Credenciais conhecidas documentadas para o testador

### Artefatos esperados (14A)

| Artefato | Nome |
|---|---|
| Imagem comprimida | `FlavosOS-desktop-preview-0.1-daily-amd64.img.xz` |
| Checksum | `FlavosOS-desktop-preview-0.1-daily-amd64.img.xz.sha256` |
| Manifest | `flavos-0.1-preview-manifest.json` |

### Regras de segurança para testes

1. Todo teste começa validando SHA256.
2. Não usar `.img` puro publicado — sempre descomprimir do `.xz`.
3. Não testar arquivo sem checksum.
4. Não gravar em disco interno por acidente — usar `lsblk` antes.
5. Documentar riscos de `dd` e `make write-disk`.
6. Preferir VM primeiro, hardware real depois.
7. Hardware real só com disco/pendrive de teste dedicado.

---

## 3. Ficha de Hardware

Preencher para cada máquina de teste:

| Campo | Valor |
|---|---|
| **Nome da máquina** | _(ex: "Lab-775", "Notebook-Test-1")_ |
| **Placa-mãe** | |
| **CPU** | |
| **RAM (total)** | |
| **GPU** | |
| **Disco de teste** | |
| **Interface de rede** | |
| **Áudio** | |
| **Firmware (BIOS/UEFI)** | |
| **Modo SATA** | _(AHCI/IDE/RAID)_ |
| **Resolução do monitor** | |
| **Teclado** | _(layout, interface)_ |
| **Mouse** | _(interface)_ |
| **Data do teste** | |
| **Build/tag usada** | |
| **Artefato (nome)** | |
| **SHA256 validado** | _(sim/não)_ |

---

## 4. Checklist de Boot

| Item | Status | Observação |
|---|---|---|
| Máquina liga | ☐ | |
| Passa pelo bootloader | ☐ | |
| Kernel inicia | ☐ | |
| Chega ao login/desktop | ☐ | |
| Painel aparece | ☐ | |
| Taskbar aparece | ☐ | |
| Wallpaper aparece | ☐ | |
| Teclado funciona | ☐ | |
| Mouse funciona | ☐ | |
| Resolução aceitável | ☐ | |
| Rede funciona | ☐ | |
| Áudio funciona | ☐ | |
| Desligamento funciona | ☐ | |
| Reboot funciona | ☐ | |

---

## 5. Checklist de Desktop

| Item | Status | Observação |
|---|---|---|
| Launcher abre | ☐ | |
| Terminal abre | ☐ | |
| Nemo (file manager) abre | ☐ | |
| Firefox abre | ☐ | |
| Lock screen funciona | ☐ | |
| Suspend funciona | ☐ | |
| Power menu funciona | ☐ | |
| Arquivos compactados funcionam | ☐ | |
| Diretório Downloads funciona | ☐ | |

---

## 6. Checklist de Performance

| Métrica | Valor Medido | Observação |
|---|---|---|
| RAM em idle (após 5 min) | | `free -h` |
| CPU em idle (%) | | `pidstat -u 2 5` ou `htop` |
| Tempo de boot até desktop | | Cronômetro ou `systemd-analyze` |
| Tempo de abrir launcher | | |
| Tempo de abrir terminal | | |
| Tempo de abrir Nemo | | |
| Tempo de abrir Firefox | | |
| RAM com Firefox aberto (1 aba) | | `free -h` |
| RAM após lock/unlock | | |
| RAM após suspend/resume | | |

---

## 7. Critérios para 2 GB RAM

Hardware antigo (LGA 775 / ~2 GB DDR2) é o alvo de validação mais restritivo.

### Classificação de viabilidade

| Classificação | Comportamento | Ação |
|---|---|---|
| **✅ OK** | Desktop leve, terminal, gerenciador de arquivos, navegação simples. Idle < 600 MB. | Registrar como viável. |
| **⚠️ Atenção** | Firefox com poucas abas. Swap ativo mas não agressivo. Idle 600–900 MB. | Registrar limitações específicas. |
| **⛔ Ruim** | Swap excessivo, travamentos perceptíveis, compositor pesado. Idle > 900 MB. | Investigar otimizações. Documentar bottleneck. |
| **❌ Falha** | Sistema não chega ao desktop, fica inutilizável, OOM killer ativo. | Não aprovar para hardware. Documentar causa. |

### Expectativas realistas para 2 GB

- **Boot até desktop:** ≤ 30s em SSD, ≤ 60s em HDD
- **Idle RAM:** 350–600 MB (perfil Light ativo)
- **Firefox com 1 aba:** adiciona ~300–500 MB
- **Swap ativo:** aceitável com zram; preocupante com swap em HDD
- **Compositor (Picom):** deve funcionar com backend `xrender` ou `glx` mínimo

> [!WARNING]
> **Hardware de 2 GB impõe limites reais.** Não prometer navegação confortável com múltiplas abas. A honestidade sobre as limitações é mais valiosa que promessas de compatibilidade.

---

## 8. Plano de Risco

### Regras obrigatórias

| Regra | Justificativa |
|---|---|
| **Não instalar em disco principal** | Impedir perda de sistema operacional existente |
| **Não substituir sistema pessoal** | Flavos OS é preview técnica, não replacement |
| **Não usar dados importantes** | A imagem contém credenciais conhecidas |
| **Manter mídia de recuperação** | Ter como restaurar a máquina se o teste falhar |
| **Manter backup** | Do disco de teste e de qualquer dado relevante |
| **Documentar falhas** | Cada problema é informação de engenharia |

### Riscos conhecidos da imagem atual

| Risco | Detalhe |
|---|---|
| Credenciais DevLocal | `flavos/123` — qualquer pessoa com a imagem sabe a senha |
| Autologin ativo | Sem tela de login — acesso imediato ao desktop |
| Sem criptografia de disco | Partição root é ext4 sem LUKS |
| Sem firewall | Nenhuma regra nftables/iptables configurada |
| SSH pode estar ativo | Se `sshd` estiver habilitado, aceita login com senha conhecida |
| Sem atualizações | O sistema não busca updates |
| Lock screen ≠ criptografia | Lock screen protege contra uso casual, não contra acesso ao disco |
| Secure Boot desabilitado | Imagem sem shim/MOK assinados |

### O que fazer se algo quebrar

1. **Boot falha:** Remover o disco/pendrive. A máquina retorna ao boot original.
2. **Desktop não aparece:** Tentar `Ctrl+Alt+F2` para console. Rodar `journalctl -b -p err`.
3. **Sistema congela:** Reset forçado. Anotar o estado antes do congelamento.
4. **Disco de teste corrompido:** Re-gravar a imagem. Dados no disco de teste são sacrificáveis.

---

## 9. Comandos Úteis

### Informações do sistema

```bash
# CPU
lscpu

# Memória
free -h
cat /proc/meminfo

# Discos
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,MODEL

# Hardware PCI (GPU, rede, áudio)
lspci

# Rede
ip a

# Informações do host
hostnamectl
uname -a
```

### Diagnóstico de problemas

```bash
# Serviços com falha
systemctl --failed

# Warnings e erros do boot atual
journalctl -b -p warning --no-pager | tail -100

# Mensagens do kernel
dmesg -T | tail -100

# Processos por consumo de memória
ps aux --sort=-%mem | head -20

# Processos por consumo de CPU
ps aux --sort=-%cpu | head -15
```

### Performance

```bash
# Boot timing
systemd-analyze
systemd-analyze blame | head -20

# Wakeups (se powertop estiver disponível)
powertop --time=15 2>/dev/null

# I/O
iostat -x 1 5 2>/dev/null || echo "iostat não disponível"
```

### Relatório automatizado

```bash
# Gera relatório completo em ~/flavos-hardware-report.txt
flavos-hw-report
```

---

## 10. Fluxo de Teste Recomendado

### Ordem de validação

```
1. VM (QEMU/KVM)
   ↓ aprovado
2. Pendrive USB (boot externo)
   ↓ aprovado
3. Disco externo dedicado
   ↓ aprovado
4. Disco interno de teste (nunca disco principal)
```

### Para cada nível

1. **Verificar checksum** antes de gravar.
2. **Gravar** com `make write-disk DISK=/dev/sdX` ou `dd`.
3. **Bootar** e verificar o checklist de boot.
4. **Testar** desktop e apps (checklist de desktop).
5. **Medir** performance (checklist de performance).
6. **Rodar** `flavos-hw-report` para capturar diagnóstico.
7. **Preencher** relatório usando `HARDWARE_TEST_REPORT_TEMPLATE.md`.
8. **Classificar** viabilidade conforme critérios da Seção 7.

---

## 11. Notas para Hardware LGA 775

### Considerações específicas

| Aspecto | Detalhe |
|---|---|
| **CPU** | Core 2 Duo / Core 2 Quad — suporta x86_64, clock moderado |
| **RAM** | DDR2 — tipicamente 2 GB, máx 4–8 GB dependendo da placa |
| **GPU** | Intel GMA 3100/X3500, ou placa discreta PCIe antiga |
| **BIOS/UEFI** | Maioria é BIOS (Legacy). Algumas placas com UEFI básico |
| **SATA** | SATA II (3 Gbps). Verificar modo AHCI vs IDE |
| **USB** | USB 2.0 — boot lento a partir de pendrive |
| **Rede** | Ethernet integrada (Realtek, Intel) — geralmente suportada |

### Riscos específicos de LGA 775

- **BIOS vs UEFI:** Flavos OS atualmente requer UEFI. Se a máquina for BIOS-only, o boot falhará. Documentar como "não compatível" neste caso.
- **GPU:** Intel GMA pode não ter suporte OpenGL suficiente para Picom com `glx`. Testar com `xrender`.
- **RAM DDR2:** 2 GB é o mínimo absoluto. Firefox consumirá ~50% da RAM com uma aba.
- **USB 2.0:** Boot e gravação serão lentos. Paciência necessária.
- **Drivers:** Kernel Debian stable geralmente tem suporte bom para hardware desta era.

### Perfil recomendado

Para LGA 775 / 2 GB RAM, usar o perfil **Light** do Flavos OS:

```bash
# Verificar perfil ativo
flavos-performance-profile
```

Se o perfil Light não estiver ativo, ativar antes do teste.
