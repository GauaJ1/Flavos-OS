# Physical Install Preview Mode (Etapa 14J)

## Objetivo

O **Physical Install Preview Mode** é a ponte entre o ambiente virtualizado (14I) e o hardware real LGA 775.

Ele permite instalar o Flavos OS em um disco físico com nível extremo de segurança, isolamento do instalador de VM, e rastreabilidade total de cada decisão destrutiva.

---

## Separação de responsabilidades

| Comando                          | Ambiente alvo | Exige VM?     | Descrição                                      |
|----------------------------------|---------------|---------------|------------------------------------------------|
| `flavos-installer-lab`           | VM apenas     | Sim (required)| Instalador de laboratório, bloqueado em físico |
| `flavos-physical-install-preview`| Hardware real | Não           | Instalador físico com segurança extrema        |

> [!IMPORTANT]
> `flavos-installer-lab` recusa execução fora de ambiente virtual.
> `flavos-physical-install-preview` recusa execução dentro de VM, salvo flag explícita.

---

## Pré-requisitos

- Hardware LGA 775 (ou compatível)
- Mídia Live do Flavos OS gravada em pendrive USB
- Disco-alvo **sem** dados críticos (será completamente apagado)
- Sistema iniciado pela mídia Live (não pelo disco interno)
- Permissões de root

---

## Fluxo obrigatório

O fluxo `precheck → plan → install` é sequencial e não pode ser pulado.

```text
1. inspect    (opcional, diagnóstico)
2. precheck   (OBRIGATÓRIO antes de install)
3. plan       (opcional, mas recomendado)
4. install    (exige precheck válido da mesma sessão)
```

---

## Subcomandos

### `inspect`

Diagnóstico do ambiente. Leitura pura, sem escrita.

```bash
flavos-physical-install-preview inspect
```

Exibe: firmware (BIOS/UEFI), RAM, discos disponíveis, disco Live atual, versão do kernel, status SquashFS.

---

### `precheck`

Valida 11 pontos críticos e salva estado em `/run/flavos-physical-install/precheck.env`.

```bash
flavos-physical-install-preview precheck
```

Pontos verificados:
1. Diretório de log (`/run/flavos-physical-install/`)
2. RAM mínima (1.5 GB)
3. Tipo de firmware (BIOS/UEFI)
4. Disco Live detectável (não é o target)
5. Integridade da mídia Live (checksums via `flavos-live-media-check`)
6. Data/hora do sistema (não em 1970)
7. Módulo SquashFS carregado
8. Disco SquashFS montado
9. Erros de I/O do kernel (dmesg)
10. Erros de EXT4 no kernel
11. `rsync` disponível no sistema

O estado é válido por **4 horas** e vinculado ao **boot_id** da sessão atual.

---

### `plan`

Mostra o que **seria** feito em disco, sem escrever nada.

```bash
flavos-physical-install-preview plan --target /dev/sda
```

Exibe: detalhes do disco, layout de partições proposto, modo de bootloader efetivo.

---

### `install`

Executa a instalação completa. **Irreversível.**

```bash
sudo FLAVOS_ALLOW_PHYSICAL_INSTALL_PREVIEW=YES \
  flavos-physical-install-preview install \
    --target /dev/sda \
    --bootloader-mode both \
    --i-understand-this-erases-physical-disk
```

#### Flags obrigatórias

| Flag | Descrição |
|------|-----------|
| `--target DISK` | Disco-alvo (ex: `/dev/sda`, `/dev/disk/by-id/...`) |
| `--i-understand-this-erases-physical-disk` | Confirmação explícita de apagamento |
| `FLAVOS_ALLOW_PHYSICAL_INSTALL_PREVIEW=YES` | Variável de ambiente de autorização |

#### Flags opcionais

| Flag | Padrão | Descrição |
|------|--------|-----------|
| `--bootloader-mode auto\|bios\|uefi\|both` | `auto` | Modo de bootloader |

---

## Confirmações interativas (5 etapas)

Durante o `install`, o usuário deve confirmar manualmente:

1. **Path exato do disco** (ex: `/dev/sda`)
2. **Modelo do disco** (ex: `WDC WD10EZEX`)
3. **Serial do disco** (ex: `WD-WCC3F1234567`)
4. **Frase de apagamento**: `ERASE PHYSICAL DISK /dev/sda`
5. **Token de sessão aleatório** (exibido na tela, não logado)

> [!CAUTION]
> Qualquer confirmação incorreta aborta a operação imediatamente. Não há retentativa.

---

## Layout de partições criado

| # | Tipo | Tamanho | Uso |
|---|------|---------|-----|
| 1 | EF02 (BIOS Boot) | 2 MiB | GRUB i386-pc embed |
| 2 | EF00 (EFI System) | 512 MiB | systemd-boot, FAT32 |
| 3 | 8300 (Linux)     | Restante | Flavos root, ext4 |

Tabela GPT híbrida, compatível com BIOS e UEFI.

---

## Modos de bootloader

| Modo | GRUB i386-pc | systemd-boot | Uso recomendado |
|------|:------------:|:------------:|-----------------|
| `bios` | ✓ (fatal se falhar) | — | Hardware LGA 775 BIOS-only |
| `uefi` | — | ✓ (fatal se falhar) | Hardware UEFI moderno |
| `both` | ✓ (fatal se falhar) | ✓ (best-effort) | Hardware híbrido / incerto |
| `auto` | Detecta firmware atual | | Padrão |

> [!NOTE]
> Em modo `both`, a falha do systemd-boot **não invalida** a instalação se o GRUB BIOS estiver operacional. Esse comportamento é intencional para hardware LGA 775 que pode não ter suporte UEFI.

---

## Bloqueios automáticos de segurança

O disco-alvo é **bloqueado automaticamente** se:

- For o mesmo disco da mídia Live
- Estiver montado em algum ponto do sistema
- For uma partição filha (ex: `/dev/sda1`)
- For um dispositivo de loop (`loop`)
- For um dispositivo óptico (`sr0`, `sr1`)
- For um device mapper ou RAID (`dm-*`, `md*`)
- For um pendrive USB (`TRAN=usb`) — salvo `--allow-usb-target`

---

## Arquivo de relatório

Após instalação bem-sucedida, o relatório é salvo em:

```
/run/flavos-physical-install/install-report.txt
```

Conteúdo: timestamp, target, modo de bootloader, status de cada bootloader, UUIDs de root e ESP.

> O token de confirmação **não é registrado** no relatório por segurança.

---

## Teste em VM (antes do hardware real)

Use o script de teste para validar o fluxo dentro de uma VM antes de tocar no hardware:

```bash
make test-physical-preview-vm
```

Isso abre o QEMU com a ISO Live + disco virtual (8 GB). Execute os subcomandos manualmente dentro da VM conforme as instruções exibidas.

Para iniciar o boot do disco instalado:

```bash
make boot-physical-preview-vm
```

Para validar a sintaxe do comando sem executar:

```bash
make lint-physical-preview
```

---

## Validação pós-instalação

Após instalar e reiniciar pelo disco físico:

```bash
# Dentro do sistema instalado:
cat /etc/flavos-release
uname -r
df -h /
mount | grep "/boot/efi"
```

Bootloader BIOS:
```bash
grub-install --version
cat /boot/grub/grub.cfg | grep "Flavos"
```

Bootloader UEFI:
```bash
bootctl status
ls /boot/efi/EFI/flavos/
```

---

## Troubleshooting

### `ERRO: Precheck de sessão diferente`
O sistema foi reiniciado após o `precheck`. Reexecute `precheck` na sessão de boot atual.

### `ERRO: Precheck tem mais de 4 horas`
Execute `precheck` novamente.

### `ERRO: grub-install i386-pc falhou`
Verifique se `grub-pc-bin` está presente na Live:
```bash
dpkg -l grub-pc-bin grub2-common
ls /usr/lib/grub/i386-pc/ | head
```

### `ERRO: SquashFS não montado`
O sistema não iniciou corretamente pela Live. Verifique a integridade da ISO e reinicie.

### `⚠ BOOTX64.EFI não encontrado`
Hardware é BIOS-only. Use `--bootloader-mode bios` ou `both` (systemd-boot falhará em best-effort sem invaldar a instalação).

### `ERRO: $BIOS_PART não encontrado após partprobe`
Problema de timing em hardware legado. O `install` já faz `partprobe + udevadm settle + sleep 1`. Se persistir, execute `partprobe /dev/sda` manualmente e verifique com `lsblk`.

---

## Status da implementação

| Componente | Status |
|------------|--------|
| `inspect`  | ✓ Implementado |
| `precheck` | ✓ Implementado |
| `plan`     | ✓ Implementado |
| `install` — confirmações | ✓ Implementado |
| `install` — particionamento GPT híbrido | ✓ Implementado |
| `install` — rsync payload | ✓ Implementado |
| `install` — fstab por UUID | ✓ Implementado |
| `install` — GRUB BIOS (i386-pc) | ✓ Implementado |
| `install` — systemd-boot (UEFI) | ✓ Implementado |
| `install` — cleanup trap | ✓ Implementado |
| `install` — relatório | ✓ Implementado |
| Script de teste VM | ✓ Implementado |
| Makefile targets | ✓ Implementado |
| Validação em VM (14J) | ⏳ Pendente |
| Validação em hardware LGA 775 (14J) | ⏳ Pendente |

---

## Próximos passos após validação

1. **Teste em VM**: `make test-physical-preview-vm` → executar `precheck`, `plan`, `install` dentro da VM → `make boot-physical-preview-vm`
2. **Teste em hardware LGA 775**: conectar pendrive Live, iniciar, executar fluxo completo
3. **Etapa 14K**: OOBE (Out-Of-Box Experience) e pós-instalação automatizada
