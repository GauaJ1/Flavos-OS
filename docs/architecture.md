# Flavos OS — Arquitetura V1

## Fase 1 — Definição do Produto

### Objetivo do sistema
Criar um sistema operacional Linux chamado **Flavos OS**, bootável, instalável, reproduzível e com identidade própria. A V1 deve alcançar um boot funcional em VM com shell operacional, sem interface gráfica.

### Público-alvo (V1)
O próprio desenvolvedor/time. A V1 é uma fundação de engenharia, não um produto de usuário final.

### Hardware-alvo
- **Arquitetura:** x86_64
- **Teste primário:** Máquina virtual (QEMU/KVM)
- **Hardware real:** Não é objetivo da V1

### Modo de uso
Server-first / headless. Boot limpo até TTY com login e shell operacional.

### Filosofia da base
Minimalista, estável, auditável. Cada componente deve justificar sua existência.

---

## Fase 2 — Arquitetura-base

### Comparação de abordagens de construção

Quatro abordagens foram avaliadas para decidir como construir o Flavos OS:

#### Abordagem A: Linux From Scratch (LFS)

Compilação manual de cada componente: toolchain, glibc, coreutils, kernel, shell, etc.

| Critério | Avaliação |
|---|---|
| Controle | Total |
| Reprodutibilidade | Baixa (depende de disciplina manual) |
| Tempo até primeiro boot | Semanas |
| Gerenciador de pacotes | Nenhum (teria que ser criado) |
| Atualizações de segurança | Manuais |
| Retrabalho | Alto (mudança de toolchain = rebuild completo) |
| Mantenibilidade para time pequeno | Inviável |

**Conclusão:** Valor educacional. Valor de engenharia de produto: baixo. **Rejeitado.**

#### Abordagem B: Buildroot

Sistema de build que gera imagens Linux customizadas via menuconfig, compilando todos os pacotes controladamente.

| Critério | Avaliação |
|---|---|
| Controle | Alto |
| Reprodutibilidade | Excelente |
| Tempo até primeiro boot | Dias |
| Gerenciador de pacotes runtime | Nenhum |
| Evolução para desktop/server | Difícil (sem APT/pacman/etc. no runtime) |
| Retrabalho | Moderado (rebuild ao mudar opções fundamentais) |

**Conclusão:** Excelente para appliances e embedded. Se o Flavos OS pretende evoluir para uso geral com gerenciamento de pacotes, Buildroot se torna limitante. **Rejeitado para V1.**

#### Abordagem C: Yocto Project

Framework avançado de build com layers, recipes e BSPs. O padrão ouro para reprodutibilidade de builds Linux.

| Critério | Avaliação |
|---|---|
| Controle | Muito alto |
| Reprodutibilidade | A melhor disponível |
| Tempo até primeiro boot | Dias a semanas (curva de aprendizado) |
| Complexidade de setup | Alta |
| Evolução futura | Excelente (candidato para V2+) |
| Retrabalho | Baixo após setup, mas setup é caro |

**Conclusão:** Desproporcional para o estágio atual. Candidato para migração futura se necessário. **Rejeitado para V1.**

#### Abordagem D: Debootstrap (Debian Stable como package base)

Gerar um rootfs via `debootstrap`, usando pacotes binários do Debian como base, e concentrar o trabalho de engenharia na cadeia de boot, identidade, estrutura e build reproduzível.

| Critério | Avaliação |
|---|---|
| Controle sobre estrutura e identidade | Alto |
| Controle sobre pacotes individuais | Moderado (herda binários Debian) |
| Reprodutibilidade | Boa (debootstrap + scripts + pinning) |
| Tempo até primeiro boot | **Horas** |
| Gerenciador de pacotes | APT/dpkg desde o dia zero |
| Atualizações de segurança | Repositórios Debian security |
| Retrabalho | **Mínimo** |
| Evolução para desktop/server | Alta |

**Conclusão:** Melhor equilíbrio entre velocidade, controle, evolução e baixo retrabalho. **Recomendado.**

#### Tabela comparativa final

| Critério | LFS | Buildroot | Yocto | **Debootstrap** |
|---|---|---|---|---|
| Tempo até boot | Semanas | Dias | Dias/Semanas | **Horas** |
| Retrabalho | Alto | Moderado | Baixo | **Mínimo** |
| Pkg manager runtime | Não | Não | opkg (limitado) | **APT/dpkg** |
| Segurança via upstream | Manual | Upstream release | Recipes | **Repos Debian** |
| Escalabilidade desktop | Baixa | Baixa | Moderada | **Alta** |
| Complexidade de setup | Alta | Moderada | Alta | **Baixa** |

---

### Decisão final

**Abordagem escolhida: Debootstrap sobre Debian Stable (Bookworm, 12.x).**

### Justificativa técnica consolidada

1. **Menor caminho até boot funcional.** `debootstrap --variant=minbase` gera um rootfs operacional em minutos. O trabalho restante é boot chain e configuração.

2. **Zero retrabalho em toolchain.** Não compilamos gcc, glibc, coreutils, bash. Eliminamos uma classe inteira de falhas (ABI mismatch, wrong toolchain version).

3. **Gerenciamento de pacotes maduro.** O rootfs nasce com `dpkg` e `apt`. Instalar, remover e atualizar pacotes funciona desde o primeiro momento.

4. **Segurança herdada.** Patches de segurança do Debian Stable disponíveis via `apt upgrade`.

5. **Foco no diferencial.** O esforço vai para: cadeia de boot, identidade do OS, estrutura do rootfs, scripts de build, experiência operacional.

6. **Compatibilidade com evolução.** Se na V2+ decidirmos migrar para kernel customizado, init alternativo ou compilação total, a estrutura de build permanece. A mudança seria no conteúdo do rootfs, não na estrutura de build.

---

### Componentes escolhidos

#### Bootloader: systemd-boot

| Critério | GRUB2 | systemd-boot |
|---|---|---|
| Complexidade de config | Alta (grub.cfg, grub-mkconfig, módulos) | Mínima (arquivos .conf em texto) |
| UEFI | Sim | Sim (nativo, UEFI-only) |
| Legacy BIOS | Sim | Não |
| Tamanho | ~5MB+ | ~120KB |
| Integração com systemd | Nenhuma | Total (bootctl) |
| Debug | Difícil | Trivial |

**Escolha:** systemd-boot. Não precisamos de Legacy BIOS. Configuração trivial, tamanho mínimo, integração direta.

#### Init system: systemd

**Justificativa:**
- Boot paralelo, reduzindo tempo de inicialização.
- Journald para logging centralizado — essencial para debug de um OS em desenvolvimento.
- Integração com systemd-boot (bootctl).
- Unit files fornecidos nativamente pelos pacotes Debian.
- Suporte futuro a containers (systemd-nspawn), timers, networkd.

**Alternativas avaliadas:**
- OpenRC: mais simples, mas sem journald integrado e menor ecossistema de units para pacotes Debian.
- runit/s6: excelentes para minimalismo extremo, mas exigem escrita manual de scripts de serviço para cada componente Debian. Retrabalho significativo.

#### Filesystem: ext4 para root

**Justificativa:** Estável, bem testado, sem overhead de features não necessárias na V1. btrfs seria candidato para V2+ se snapshots/rollback forem prioritários.

#### Shell: bash

Compatibilidade ampla. Padrão do Debian.

#### libc: glibc

Herda do Debian. Compatibilidade máxima com pacotes binários.

#### Stack de rede (V1): systemd-networkd

Leve, sem dependências gráficas, integrado ao systemd. Adequado para modo server/headless.

#### Política de pacotes (V1): APT/dpkg herdado do Debian

Usamos o repositório Debian como fonte. Pacotes customizados do Flavos OS poderão sobrepor ou adicionar via repositório próprio em fases futuras.

#### Estratégia de atualização (V1): `apt upgrade`

Simples e funcional. Mecanismo de update mais sofisticado (A/B, OTA, rollback) são candidatos para fases posteriores.

---

### Boot chain

```
UEFI Firmware (OVMF em VM)
    │
    ▼
systemd-boot (lê /loader/loader.conf e /loader/entries/*.conf)
    │
    ▼
Linux Kernel (vmlinuz do pacote linux-image-amd64)
    │
    ▼
initramfs (gerado por initramfs-tools dentro do chroot)
    │
    ▼
Root filesystem montado (ext4, /)
    │
    ▼
systemd (PID 1)
    │
    ▼
multi-user.target → login prompt no TTY
```

### Layout de partições

| # | Tipo | Filesystem | Tamanho | Mountpoint | Flags |
|---|---|---|---|---|---|
| 1 | EFI System Partition | FAT32 | 256 MB | /boot/efi | esp, boot |
| 2 | Linux root | ext4 | ~1.7 GB | / | — |

Tabela de partições: GPT.
Tamanho total da imagem: 2 GB (expansível).
Swap: não incluído na V1 (não necessário para boot em VM com 1GB+ RAM).

### Formato de imagem

**Raw disk image (`.img`).**

Justificativa:
- Formato universal. `dd` para gravação em disco real.
- Convertível: `qemu-img convert` para QCOW2, VMDK, VDI.
- Sem dependência de ferramentas proprietárias.
- Montável via `losetup` + `kpartx` no host para inspeção.

---

## Estratégia de build

### Orquestração
`Makefile` como ponto de entrada + scripts Bash numerados para cada fase.

### Padrão dos scripts
Todo script usa `set -euo pipefail`:
- `-e`: para no primeiro erro.
- `-u`: erro em variável não definida.
- `-o pipefail`: captura erros em pipes.

### Privilégios
Scripts de build requerem `sudo` para: `debootstrap`, `mount`, `chroot`, `losetup`, formatação.

### Idempotência
Cada target verifica se o artefato já existe antes de recriar. `make clean` remove tudo para rebuild completo.

### Targets do Makefile

```
make deps          # Verifica/instala dependências do host
make rootfs        # Gera rootfs via debootstrap + configura chroot
make image         # Cria .img, particiona GPT, formata ESP+root
make install       # Copia rootfs para imagem, instala systemd-boot
make boot          # Inicia QEMU com a imagem
make clean         # Remove build/
make all           # Pipeline completo: rootfs → image → install
```

---

## Estratégia de teste em VM

| Parâmetro | Valor |
|---|---|
| Hypervisor | QEMU/KVM (qemu-system-x86_64) |
| Firmware | OVMF (/usr/share/OVMF/OVMF_CODE.fd) |
| RAM | 1024 MB |
| CPUs | 2 vCPUs |
| Disco | build/flavos.img (raw) |
| Rede | User mode (NAT, sem setup no host) |
| Display | GTK para debug visual, -nographic para CI |

### Comando de teste

```bash
qemu-system-x86_64 \
  -enable-kvm \
  -m 1024 \
  -cpu host \
  -smp 2 \
  -drive file=build/flavos.img,format=raw,if=virtio \
  -bios /usr/share/OVMF/OVMF_CODE.fd \
  -net nic -net user \
  -serial stdio
```

### Critérios de sucesso do boot

1. OVMF encontra o binário EFI na ESP.
2. systemd-boot carrega (ou boot direto se entrada única).
3. Kernel inicia sem panic.
4. initramfs monta o root filesystem.
5. systemd sobe como PID 1.
6. multi-user.target é alcançado.
7. Login prompt aparece no TTY.
8. Login como root funciona.
9. Shell operacional (bash).
10. `systemctl status` retorna sem erros críticos.
11. Shutdown/reboot limpo via `systemctl poweroff`.

---

## Estrutura do repositório

```
FlavosOS/
├── Makefile                        # Orquestrador do build
├── README.md                       # Visão geral do projeto
├── .gitignore                      # Exclui build/ e artefatos
│
├── config/
│   ├── flavos.conf                 # Variáveis globais do build
│   ├── packages.list               # Pacotes a instalar no rootfs
│   └── loader/
│       ├── loader.conf             # Config do systemd-boot
│       └── entries/
│           └── flavos.conf         # Boot entry do Flavos OS
│
├── scripts/
│   ├── 00-check-deps.sh            # Verifica dependências do host
│   ├── 01-create-rootfs.sh         # debootstrap + config do chroot
│   ├── 02-create-image.sh          # Cria .img, particiona, formata
│   ├── 03-install-system.sh        # Copia rootfs para imagem, bootloader
│   └── 04-boot-vm.sh              # Inicia QEMU
│
├── overlay/
│   └── etc/
│       ├── hostname                # "flavos"
│       ├── os-release              # Identidade do Flavos OS
│       ├── issue                   # Banner de login
│       └── fstab                   # Tabela de montagem
│
├── build/                          # (gitignored) Artefatos de build
│   ├── rootfs/                     # Root filesystem
│   └── flavos.img                  # Imagem final
│
├── docs/
│   ├── architecture.md             # Este documento
│   ├── BUILD.md                    # Instruções de build
│   └── CHANGELOG.md                # Histórico de mudanças
│
└── tests/
    └── smoke-test.sh               # Validação automática de boot
```

### Princípios da estrutura

- **config/**: Toda configuração declarativa, separada do código. Nenhum valor hardcoded nos scripts.
- **scripts/**: Numerados em ordem de execução. Cada um faz uma coisa. Todos com `set -euo pipefail`.
- **overlay/**: Arquivos que sobreescrevem o rootfs gerado. Identidade e configuração do Flavos OS.
- **build/**: Gitignored. Nunca commitado. Artefatos temporários.
- **docs/**: Documentação técnica. Faz parte do produto.
- **tests/**: Scripts de validação.

---

## Riscos identificados

| Risco | Probabilidade | Impacto | Mitigação |
|---|---|---|---|
| `debootstrap` falha por rede/mirror indisponível | Média | Bloqueia geração do rootfs | Usar mirror confiável, cachear pacotes |
| Kernel não encontra root no boot (UUID mismatch) | Média | Kernel panic | Script verifica UUIDs e os propaga para fstab e boot entry |
| initramfs não inclui módulos necessários (virtio) | Média | Root não monta | Garantir que initramfs-tools inclui módulos virtio no chroot |
| OVMF não encontra ESP ou binário EFI | Baixa | Boot não inicia | Verificar flags da partição e path do .efi |
| Permissões de build (sudo) | Baixa | Falha de script | Documentar requisitos, validar no script 00 |
| Espaço em disco insuficiente no host | Baixa | Build falha | Script valida espaço mínimo antes de iniciar |

---

## O que NÃO entra na V1

- Interface gráfica (DE, WM, display manager)
- Installer interativo
- Branding visual avançado (apenas os-release e issue)
- Suporte a Legacy BIOS
- Kernel customizado (usamos pacote Debian)
- Secure Boot
- Suporte a hardware real
- Sistema de update sofisticado (A/B, OTA)
- Multi-user com permissões granulares
- Firewall configurado
- SSH server habilitado

Esses itens são candidatos para Etapas 6-10.

---

## Dependências do host para build

```
debootstrap          # Geração do rootfs
qemu-system-x86_64   # VM para teste
ovmf                 # Firmware UEFI para QEMU
parted               # Particionamento GPT
dosfstools           # mkfs.fat para ESP
e2fsprogs            # mkfs.ext4 para root
kpartx               # Montagem de partições de .img
util-linux           # losetup, mount
coreutils            # Ferramentas padrão
make                 # Orquestração do build
git                  # Controle de versão
```
