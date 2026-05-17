# Checklist de Pré-Instalação Física — Flavos OS

## Quando usar

Antes de **qualquer** tentativa de instalação em hardware real. Este checklist é obrigatório.

## Verificações

### 1. Identificação de Discos

```bash
lsblk -o NAME,PATH,SIZE,TYPE,FSTYPE,MOUNTPOINT,MODEL,SERIAL
```

- [ ] Disco alvo identificado (ex: `/dev/sda`)
- [ ] Pendrive Live identificado (ex: `/dev/sdb`)
- [ ] Confirmar que o disco alvo **NÃO** é o pendrive Live
- [ ] Disco alvo **NÃO** está montado

### 2. Checksum da ISO

Antes de gravar no pendrive:

```bash
sha256sum FlavosOS-live-*.iso
# comparar com o .sha256 publicado
```

- [ ] Checksum confere

### 3. Integridade da Mídia Live

```bash
flavos-live-media-check --quick
```

- [ ] Nenhum erro de SquashFS reportado

Se planeja instalar:

```bash
flavos-live-media-check --full
```

- [ ] Verificação completa passou

### 4. Verificação do Kernel Log

```bash
dmesg | grep -iE "squash|i/o error|failed verification"
```

- [ ] Nenhuma mensagem de erro

### 5. Data e Hora do Sistema

```bash
date
timedatectl status
```

- [ ] Data/hora estão corretas (diferença < 1 dia)
- [ ] Se incorretas, corrigir antes de continuar (ver `docs/APT_TIME_SYNC_RECOVERY.md`)

### 6. Hardware Report

```bash
flavos-hw-report
```

- [ ] Relatório gerado sem erros
- [ ] GPU identificada
- [ ] RAM suficiente (≥ 2 GB)

### 7. Detecção BIOS vs UEFI

```bash
ls /sys/firmware/efi 2>/dev/null && echo "UEFI" || echo "BIOS Legacy"
```

- [ ] Modo identificado

> [!CAUTION]
> Se o sistema é **BIOS Legacy** (sem `/sys/firmware/efi`):
> - `systemd-boot` **não é aplicável**
> - Instalação bootável requer GRUB
> - Necessário: **Etapa 14I — Legacy BIOS / GRUB Support**
> - NÃO prosseguir com instalação física até 14I ser concluída

### 8. Teclado TTY

```bash
loadkeys br-abnt2
```

Se `loadkeys` não funcionar:

```bash
# Verificar se kbd está instalado
dpkg -l kbd 2>/dev/null
```

- [ ] Teclado funcional no TTY

### 9. Modo Gráfico

Testar boot com:
1. Flavos OS Live (normal)
2. Flavos OS Live (Safe Graphics)
3. Flavos OS Live (VIA/OpenChrome) — se GPU VIA
4. Flavos OS Live (TTY Recovery) — se gráfico falhar

- [ ] Pelo menos um modo funcional

### 10. Porta USB

- [ ] Usar porta USB **traseira** / direta na placa-mãe
- [ ] Preferir USB 2.0 em hardware antigo
- [ ] Evitar hubs USB

### 11. Condição para Prosseguir

- [ ] `flavos-live-media-check --full` passou
- [ ] Nenhum I/O error no dmesg
- [ ] Modo de firmware compatível (UEFI ou GRUB disponível)
- [ ] Data/hora corretas
- [ ] Teclado funcional

### 12. Condição para Abortar

Se qualquer um destes for verdadeiro, **NÃO instalar**:

- `flavos-live-media-check` falhou
- SquashFS errors no dmesg
- Data errada e não corrigível
- BIOS Legacy sem GRUB disponível
- Pendrive e disco alvo parecem iguais (perigo de apagar a Live)

### 13. Ação em Caso de Falha de Mídia

1. Trocar o pendrive
2. Trocar a porta USB
3. Regravar a ISO
4. Verificar checksum da ISO antes de regravar
5. NÃO continuar com mídia defeituosa
