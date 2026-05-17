# Flavos OS — 14I: Legacy BIOS / GRUB Support

## Objetivo

Adicionar suporte nativo a firmware BIOS Legacy (i386-pc) no Flavos OS instalado, mantendo compatibilidade com UEFI/systemd-boot no mesmo disco.

Hardware alvo primário: LGA 775 com BIOS-only (sem UEFI).

---

## Contexto e motivação

O `systemd-boot` instalado na Etapa 14G é UEFI-only. Em hardware LGA 775 antigo, a placa-mãe frequentemente não oferece suporte UEFI — apenas BIOS Legacy. Sem GRUB i386-pc, o disco instalado não boota nesses sistemas.

A solução é um **layout de disco híbrido** que permite boot em BIOS e UEFI a partir do mesmo disco GPT.

---

## Por que GPT em vez de MBR?

O layout MBR tem limitações (máximo de 4 partições primárias, sem espaço reservado para o GRUB em discos modernos). O layout GPT com uma **BIOS Boot Partition** resolve isso:

- O GRUB embeds o `core.img` diretamente na BIOS Boot Partition (tipo EF02).
- Sem risco de sobrescrita por outras ferramentas.
- Compatível com discos de qualquer tamanho.

Fonte: [GNU GRUB Manual §4.4 — BIOS Installation](https://www.gnu.org/software/grub/manual/grub/html_node/BIOS-installation.html)

---

## Layout híbrido de disco (Etapa 14I)

```
Offset    Tamanho   Tipo    Label              Filesystem   Ponto de montagem
1 MiB     2 MiB     EF02    FLAVOS_BIOSBOOT    nenhum       — (GRUB embeds aqui)
3 MiB     512 MiB   EF00    FLAVOS_ESP         FAT32        /boot/efi
515 MiB   restante  8304    FLAVOS_ROOT        ext4         /
```

### Regras obrigatórias

- **BIOS Boot Partition (EF02) não é formatada.** `grub-install --target=i386-pc` escreve diretamente nela.
- **Nunca montar BIOS Boot Partition.** Não aparece no `/etc/fstab`.
- **Nunca usar `grub-install --force`.** Se a partição EF02 não existir, o comando deve falhar de forma controlada.

### Comandos sgdisk usados

```bash
sgdisk -n 1:1MiB:+2MiB   -t 1:EF02 -c 1:"FLAVOS_BIOSBOOT" /dev/vda
sgdisk -n 2:3MiB:+512MiB -t 2:EF00 -c 2:"FLAVOS_ESP"      /dev/vda
sgdisk -n 3:0:0           -t 3:8304 -c 3:"FLAVOS_ROOT"     /dev/vda
```

---

## Pacotes GRUB no rootfs

| Pacote | Razão |
|---|---|
| `grub-pc-bin` | Módulos i386-pc — fornece `grub-install --target=i386-pc` |
| `grub-common` | Fornece `grub-mkconfig` |
| `grub2-common` | Fornece `update-grub` (wrapper de `grub-mkconfig`) |

> **Por que não instalar `grub-pc`?**
> O `grub-pc` é um meta-pacote que depende de `debconf` e dispara prompts interativos durante a instalação do pacote. Em um build automatizado via `debootstrap`/chroot, isso **quebra o pipeline**. O `grub-pc-bin` fornece tudo que `grub-install` precisa, sem debconf.

---

## Modos do `install-bootloader`

O subcomando `install-bootloader` exige `--mode` obrigatório:

| Modo | Ação |
|---|---|
| `--mode bios` | Instala apenas GRUB i386-pc |
| `--mode uefi` | Instala apenas systemd-boot (comportamento da 14G) |
| `--mode both` | Instala GRUB + systemd-boot (recomendado para laboratório) |
| `--mode auto` | Detecta firmware via `/sys/firmware/efi` e escolhe automaticamente |

**Sem `--mode`, o script aborta com erro explícito.**

---

## Fluxo de instalação BIOS (detalhado)

### 1. Pré-validações (`install_grub_bios`)

```bash
# Confirmar EF02 na partição 1
sgdisk -i 1 /dev/vda | grep -qi "EF02|BIOS boot"

# Confirmar binários no chroot target
chroot /run/flavos-installer-lab/root command -v grub-install
chroot /run/flavos-installer-lab/root command -v grub-mkconfig
test -d /run/flavos-installer-lab/root/usr/lib/grub/i386-pc
```

### 2. `/etc/default/grub` mínimo

Se o arquivo não existir, é criado automaticamente:

```ini
GRUB_DEFAULT=0
GRUB_TIMEOUT=3
GRUB_DISTRIBUTOR="Flavos OS"
GRUB_CMDLINE_LINUX_DEFAULT="quiet"
GRUB_CMDLINE_LINUX=""
GRUB_DISABLE_OS_PROBER=true
```

### 3. Instalação do GRUB

```bash
chroot /run/flavos-installer-lab/root \
    grub-install --target=i386-pc --recheck /dev/vda
```

- `--target=i386-pc` — explícito, sem ambiguidade.
- `--recheck` — força nova varredura do disco.
- Sem `--force` — falha de forma controlada se EF02 ausente.

### 4. Geração do grub.cfg

```bash
# Preferido: update-grub (wrapper)
chroot /run/flavos-installer-lab/root update-grub

# Fallback se update-grub ausente:
chroot /run/flavos-installer-lab/root grub-mkconfig -o /boot/grub/grub.cfg
```

### 5. Validações pós-instalação

```bash
test -d /run/flavos-installer-lab/root/boot/grub
test -f /run/flavos-installer-lab/root/boot/grub/grub.cfg
grep -qEi "vmlinuz|linux" /run/flavos-installer-lab/root/boot/grub/grub.cfg
```

---

## Fluxo de instalação UEFI (detalhado)

Mantém o comportamento da Etapa 14G com `systemd-boot`:

```bash
chroot /run/flavos-installer-lab/root bootctl --esp-path=/boot/efi --no-variables install
```

Arquivos criados:
- `/boot/efi/EFI/BOOT/BOOTX64.EFI` — fallback UEFI
- `/boot/efi/loader/loader.conf`
- `/boot/efi/loader/entries/flavos.conf`
- `/boot/efi/EFI/flavos/vmlinuz-*`
- `/boot/efi/EFI/flavos/initrd.img-*`

---

## Validação em QEMU

### Modo BIOS (SeaBIOS — sem OVMF)

```bash
make boot-installed-bios
# equivale a:
bash scripts/10-boot-installed-vm.sh bios
```

QEMU usa SeaBIOS nativo. `if=ide` para máxima compatibilidade com hardware legado.

### Modo UEFI (OVMF)

```bash
make boot-installed-uefi
# equivale a:
bash scripts/10-boot-installed-vm.sh uefi
```

Mantém OVMF — comportamento da 14G.

---

## Fluxo completo de laboratório recomendado

```bash
# 1. Boot Live com disco extra
make boot-live-lab

# 2. Dentro da VM — verificar integridade
flavos-live-media-check --full

# 3. Payload sync (cria layout híbrido + copia rootfs)
sudo FLAVOS_INSTALL_LAB_DESTRUCTIVE=YES \
    flavos-installer-lab payload-sync \
    --target /dev/vda \
    --i-understand-this-erases-target

# 4. Instalar bootloader (ambos os modos)
sudo FLAVOS_INSTALL_LAB_DESTRUCTIVE=YES \
    flavos-installer-lab install-bootloader \
    --mode both \
    --target /dev/vda \
    --i-understand-this-modifies-target

# 5. Verificar GRUB e layout
sgdisk -p /dev/vda
ls /run/flavos-installer-lab/root/boot/grub/
cat /run/flavos-installer-lab/root/boot/grub/grub.cfg | head -20
ls /run/flavos-installer-lab/root/boot/efi/EFI/

# 6. Sair e testar BIOS
make boot-installed-bios

# 7. Testar UEFI (regressão)
make boot-installed-uefi
```

---

## Limitações conhecidas

- **`grub-pc` não é instalado no rootfs.** Consequência: o `update-grub` automático pós-atualização de kernel pode não funcionar sem intervenção manual (aceito para a fase de laboratório).
- **Hardware físico bloqueado** até validação completa em VM.
- **EFI Secure Boot:** não suportado nesta etapa. O GRUB i386-pc não usa Secure Boot.
- **NVMe em BIOS Legacy:** não testado. BIOS antigo pode não suportar boot NVMe. O alvo LGA 775 usa SATA.

---

## Riscos

| Risco | Mitigação |
|---|---|
| `grub-install` sem EF02 corrompendo setor MBR | Validação prévia via `sgdisk -i 1` — aborta se EF02 ausente |
| `update-grub` gerando grub.cfg sem kernel | Validação pós-geração com `grep vmlinuz` |
| Regressão UEFI (systemd-boot quebrado) | Teste explícito `make boot-installed-uefi` após `--mode both` |
| Debconf interativo no build | Não instalar `grub-pc`; usar apenas `grub-pc-bin` |

---

## Referências

- [GNU GRUB Manual §4.4 — BIOS Installation](https://www.gnu.org/software/grub/manual/grub/html_node/BIOS-installation.html)
- [Debian — grub-pc-bin (bookworm)](https://packages.debian.org/bookworm/grub-pc-bin)
- [Debian — grub-common (bookworm)](https://packages.debian.org/bookworm/grub-common)
- [update-grub(8) — Debian manpages](https://manpages.debian.org/bookworm/grub2-common/update-grub.8.en.html)
