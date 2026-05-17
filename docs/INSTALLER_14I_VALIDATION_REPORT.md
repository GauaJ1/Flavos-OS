# Flavos OS — 14I: Relatório de Validação (BIOS / GRUB Support)

**Etapa:** 14I — Legacy BIOS / GRUB Support  
**Data de geração:** _(preencher após execução)_  
**Responsável:** _(preencher)_  
**Status:** ⏳ Pendente — aguardando execução em VM

---

## Ambiente de teste

| Campo | Valor |
|---|---|
| Host OS | _(ex: Flavos OS / Ubuntu 24.04)_ |
| QEMU version | `qemu-system-x86_64 --version` |
| KVM | _(sim/não)_ |
| OVMF version | _(ex: 2023.05-2)_ |
| Disco virtual | `build/live/flavos-install-target-20g.img` |
| Tamanho do disco | 20 GiB |

---

## Checklist — Validação estática (pré-build)

| Verificação | Resultado | Observação |
|---|---|---|
| `bash -n flavos-installer-lab` | ✅ / ❌ | |
| `bash -n 10-boot-installed-vm.sh` | ✅ / ❌ | |
| `--force` ausente em código real | ✅ / ❌ | |
| `rm -rf` ausente | ✅ / ❌ | |
| `wipefs` ausente | ✅ / ❌ | |
| `dd if=` ausente | ✅ / ❌ | |
| `grub-pc-bin` em packages.list | ✅ / ❌ | |
| `grub-common` em packages.list | ✅ / ❌ | |
| `grub2-common` em packages.list | ✅ / ❌ | |
| EF02/FLAVOS_BIOSBOOT no installer | ✅ / ❌ | |
| `--mode` obrigatório sem default | ✅ / ❌ | |
| Makefile targets `boot-installed-bios` e `boot-installed-uefi` | ✅ / ❌ | |

---

## Checklist — Payload sync (dentro da VM Live)

| Passo | Resultado | Saída / Observação |
|---|---|---|
| `flavos-live-media-check --full` passou | ✅ / ❌ | |
| `sgdisk -p /dev/vda` mostra 3 partições | ✅ / ❌ | |
| p1 = EF02 FLAVOS_BIOSBOOT (2 MiB) | ✅ / ❌ | |
| p2 = EF00 FLAVOS_ESP (512 MiB) | ✅ / ❌ | |
| p3 = 8304 FLAVOS_ROOT (restante) | ✅ / ❌ | |
| BIOS Boot Partition NÃO formatada | ✅ / ❌ | |
| ESP formatada FAT32 | ✅ / ❌ | |
| Root formatado ext4 | ✅ / ❌ | |
| rsync concluído sem erros | ✅ / ❌ | |
| `/etc/os-release` no target | ✅ / ❌ | |
| `/usr`, `/etc`, `/boot` no target | ✅ / ❌ | |
| `/etc/fstab` gerado (sem BIOS Boot Partition) | ✅ / ❌ | |
| `/etc/machine-id` vazio | ✅ / ❌ | |

---

## Checklist — install-bootloader --mode both

| Passo | Resultado | Saída / Observação |
|---|---|---|
| `sgdisk -i 1` confirmou EF02 | ✅ / ❌ | |
| `grub-install` encontrado no chroot | ✅ / ❌ | |
| `grub-mkconfig` encontrado no chroot | ✅ / ❌ | |
| `/usr/lib/grub/i386-pc` existe no target | ✅ / ❌ | |
| `/etc/default/grub` criado/existente | ✅ / ❌ | |
| `grub-install --target=i386-pc --recheck` concluiu sem erro | ✅ / ❌ | |
| `/boot/grub/` criado | ✅ / ❌ | |
| `/boot/grub/grub.cfg` gerado | ✅ / ❌ | |
| `grub.cfg` referencia vmlinuz/initrd | ✅ / ❌ | |
| `bootctl install` concluiu sem erro | ✅ / ❌ | |
| `BOOTX64.EFI` presente na ESP | ✅ / ❌ | |
| `loader.conf` e `flavos.conf` criados | ✅ / ❌ | |
| Marcadores OOBE criados | ✅ / ❌ | |

---

## Checklist — Boot BIOS (make boot-installed-bios)

| Verificação | Resultado | Observação |
|---|---|---|
| QEMU SeaBIOS iniciou sem pflash OVMF | ✅ / ❌ | |
| GRUB menu exibido | ✅ / ❌ | |
| Kernel selecionado e iniciado | ✅ / ❌ | |
| systemd iniciou sem falhas críticas | ✅ / ❌ | |
| Login/desktop exibido | ✅ / ❌ | |
| `cat /etc/os-release` mostra Flavos OS | ✅ / ❌ | |
| `findmnt /` mostra ROOT correto | ✅ / ❌ | |
| `systemctl --failed` = 0 units | ✅ / ❌ | |

---

## Checklist — Boot UEFI (make boot-installed-uefi) — regressão

| Verificação | Resultado | Observação |
|---|---|---|
| QEMU OVMF iniciou | ✅ / ❌ | |
| systemd-boot menu exibido | ✅ / ❌ | |
| Kernel selecionado e iniciado | ✅ / ❌ | |
| systemd iniciou sem falhas críticas | ✅ / ❌ | |
| Login/desktop exibido | ✅ / ❌ | |
| `cat /etc/os-release` mostra Flavos OS | ✅ / ❌ | |
| `systemctl --failed` = 0 units | ✅ / ❌ | |

---

## Saída de diagnóstico (preencher após teste)

```
# sgdisk -p /dev/vda
(colar saída aqui)

# ls /run/flavos-installer-lab/root/boot/grub/
(colar saída aqui)

# head -30 /run/flavos-installer-lab/root/boot/grub/grub.cfg
(colar saída aqui)

# ls /run/flavos-installer-lab/root/boot/efi/EFI/
(colar saída aqui)
```

---

## Resultado final

| Critério | Status |
|---|---|
| Layout híbrido EF02+EF00+Root | ⏳ |
| GRUB BIOS instalado sem `--force` | ⏳ |
| grub.cfg válido com kernel | ⏳ |
| QEMU BIOS boota sem ISO | ⏳ |
| QEMU UEFI continua bootando | ⏳ |
| Nenhum disco real tocado | ⏳ |

**Veredicto:** ⏳ Pendente

---

## Notas e problemas encontrados

_(preencher durante o teste)_

---

## Próximos passos após validação

- [ ] Validação física em hardware LGA 775 (aguardando aprovação)
- [ ] Iniciar Etapa 14J
