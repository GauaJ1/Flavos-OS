# Recuperação de Data/Hora e apt update — Flavos OS

## Problema

Em hardware antigo (especialmente LGA 775), a bateria CMOS pode estar fraca, resultando em relógio do sistema incorreto. Isso causa falha no `apt update` com mensagens de erro temporal (~N dias).

O Live Boot pode não corrigir automaticamente se o NTP não estiver configurado ou a rede não estiver ativa.

## Diagnóstico

```bash
date
timedatectl status
```

Se a data estiver errada (diferença > 1 dia), corrigir antes de qualquer `apt` operação.

## Correção Manual

### Método 1: Via timedatectl (recomendado)

```bash
# Desativar NTP temporariamente
sudo timedatectl set-ntp false

# Definir data/hora manualmente (formato: YYYY-MM-DD HH:MM:SS)
sudo timedatectl set-time "2026-05-17 10:00:00"

# Verificar
date

# Reativar NTP (se rede disponível)
sudo timedatectl set-ntp true
```

### Método 2: Via date

```bash
# Formato: MMDDHHmmYYYY (MêsDiaHoraMinutoAno)
sudo date 051710002026

# Verificar
date
```

### Método 3: Via NTP (se rede disponível)

```bash
# Verificar se rede está ativa
ip a

# Se rede ok, forçar sync NTP
sudo systemctl restart systemd-timesyncd
timedatectl status
```

## Após Corrigir a Data

```bash
# Agora apt deve funcionar
sudo apt update
```

## Prevenção

1. **Substituir bateria CMOS** no hardware de teste (CR2032)
2. **Garantir rede/NTP** no Live Boot
3. **`systemd-timesyncd`** já está habilitado no Flavos OS (Etapa 6)
4. O script `flavos-live-media-check` verifica a data como parte do diagnóstico

## Notas

- `systemd-timesyncd` está no `packages.list` implicitamente via `systemd`
- O serviço é habilitado no `01-create-rootfs.sh` (linha 147)
- Em Live Boot, o NTP só funciona se a rede estiver conectada
- Hardware sem rede: correção manual é obrigatória
