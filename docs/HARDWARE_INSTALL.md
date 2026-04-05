# Flavos OS — Hardware Installation Guide

## Status de Maturidade
**V0.1.0 (Ignition)** — `BETA CONTROLADO`

> Esta imagem foi validada **exclusivamente em QEMU/KVM**.
> Testes em hardware físico estão em andamento. Não instale em máquinas de produção ou no seu sistema principal.

---

## Requisitos Mínimos de Hardware

| Componente | Requisito |
|---|---|
| Arquitetura | x86_64 (amd64) |
| Firmware | UEFI (BIOS Legacy **não suportado**) |
| Secure Boot | **Deve estar DESABILITADO** — binários não assinados |
| RAM | 512 MB mínimo (1 GB recomendado) |
| Armazenamento | 3 GB mínimo livre no disco alvo |
| Rede | Ethernet com interface `en*` (ex: `enp2s0`, `ens3`) |

---

## O Que Foi Testado vs. O Que é Hipotético

| Funcionalidade | Status |
|---|---|
| Boot UEFI em QEMU/KVM | ✅ Validado |
| systemd-boot como bootloader | ✅ Validado em VM |
| initramfs com módulos virtio | ✅ Validado em VM |
| initramfs com módulos físicos (ahci, nvme) | ⚠️ Adicionado, não testado em hardware |
| Rede DHCP via systemd-networkd (`en*`) | ✅ Validado em VM |
| Login console local | ✅ Validado em VM |
| SSH com usuário `flavos` | ✅ Validado em VM |
| Boot em hardware físico real | ❌ **Não testado ainda** |
| Suporte a WiFi | ❌ Não configurado |
| Drivers proprietários (Nvidia, Broadcom) | ❌ Ausentes |
| Secure Boot | ❌ Fora de escopo na V1 |

---

## Ordem Segura de Teste

```
1. QEMU/KVM (make boot-gui)         ← Validado
2. Pendrive USB externo             ← Próximo passo seguro
3. Disco secundário dedicado        ← Após validar pendrive
4. Hardware dedicado de testes      ← Após validar disco
5. PC principal                     ← NÃO RECOMENDADO nesta versão
```

---

## Instalação em Disco Físico

### Pré-requisitos
- Imagem gerada: `make all` (sem erros)
- Smoke tests passando: `make test`
- Disco alvo identificado: `lsblk`
- Dados do disco alvo **copiados/descartados** (serão apagados)

### Comando de Instalação
```bash
# Identifique primeiro o disco alvo
lsblk -d -o NAME,SIZE,MODEL,TRAN

# Execute com o disco correto (ex: /dev/sdb para um pendrive)
sudo bash scripts/05-write-to-disk.sh --disk /dev/sdX
```

O script executará três verificações de segurança:
1. **Argumento obrigatório:** `--disk /dev/sdX` deve ser passado explicitamente
2. **Proteção do host:** Bloqueia automaticamente o disco raiz do sistema atual
3. **Confirmação por digitação:** Você deve digitar o caminho completo do disco para confirmar

### Configuração do UEFI
Após a gravação:
1. Acesse o BIOS/UEFI do hardware alvo (tecla `Del`, `F2` ou `F12` durante boot)
2. **Desabilite Secure Boot**
3. Selecione o disco/pendrive como primeiro dispositivo de boot
4. Salve e reinicie

---

## Fluxo de Boot Esperado

```
1. TianoCore UEFI POST
2. systemd-boot (tela com "Flavos OS")     ← Aguardar ou pressionar Enter
3. Kernel Linux descomprimindo initramfs
4. systemd init (PID 1)
5. Serviços: networkd, resolved, ssh
6. Getty TTY1 → Prompt de login
```

**Login:** usuário `flavos`, senha `123`

---

## Checklist de Validação em Hardware Real

Após o primeiro boot físico, verifique:

```bash
# Boot OK?
uname -r && uptime

# Login OK? (feito ao logar)

# Rede OK?
flavos-net-check

# Serviços OK?
flavos-debug-report

# Disco montado corretamente?
df -h /

# Processo de boot sem erros?
journalctl -p err -b

# Shutdown limpo?
sudo shutdown -h now
```

---

## Recovery em Caso de Falha de Boot

Se o sistema não iniciar, intercepte o `systemd-boot` (tela azul/preta) e pressione `e` para editar os parâmetros do kernel.

Opções de recuperação:
- **Emergency mode:** adicione `systemd.unit=emergency.target`
- **Shell puro:** adicione `init=/bin/bash`

Consulte `docs/RECOVERY.md` para detalhes completos.

---

## Riscos Documentados

| Risco | Mitigação |
|---|---|
| Apagar disco errado | Script bloqueia disco do host; exige confirmação por digitação |
| Secure Boot rejeitar binário | Desabilitar Secure Boot no UEFI |
| Hardware sem suporte `en*` para rede | Configurar manualmente após boot |
| Módulos de storage ausentes em hardware exótico | Reportar para incluir no initramfs |
| Sem suporte a WiFi | V1 é console + Ethernet apenas |

---

## Rollback

O Flavos OS é instalado via `dd` (imagem raw). Para reverter:
- **Pendrive:** Reformate com a ferramenta de sua escolha (`mkfs.fat`, `fdisk`)
- **Disco secundário:** Reparticione e reinstale outro sistema

O processo não altera o disco principal do host se executado corretamente.
