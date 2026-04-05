# Flavos OS

Sistema operacional Linux criado do zero, focado em boot confiável, build reproduzível e arquitetura limpa.

## Status

**V0.1.0 (Ignition)** — Em iteração ativa. O sistema atingiu a **Etapa 7B**: Imagem RAW é bootável (KVM UEFI) com Userspace focado, Rede auto-provisionada pelo Systemd e arquitetura de Logs em disco para Recovery.

## Stack

| Componente | Escolha |
|---|---|
| Base | Debian Bookworm (amd64) via debootstrap |
| Bootloader | systemd-boot (UEFI) |
| Init | systemd |
| Root FS | ext4 |
| Imagem | Raw .img (2GB, GPT) |
| VM | QEMU/KVM + OVMF |

## Requisitos do Host

```bash
sudo apt install debootstrap parted dosfstools e2fsprogs kpartx \
    qemu-system-x86 ovmf make git util-linux
```

## Build

```bash
# Verificar dependências
make deps

# Pipeline completo (requer sudo)
make all

# Boot
make boot       # modo serial
make boot-gui   # modo gráfico
```

## Targets do Makefile

| Target | Descrição |
|---|---|
| `make deps` | Verifica dependências do host |
| `make rootfs` | Gera rootfs via debootstrap (sudo) |
| `make image` | Cria imagem .img particionada (sudo) |
| `make install` | Instala sistema na imagem (sudo) |
| `make test` | Smoke test offline |
| `make manifest` | Gera manifesto `build/manifest.json` |
| `make boot` | Inicia VM (serial) |
| `make boot-gui` | Inicia VM (gráfico) |
| `make write-disk DISK=/dev/sdX` | Grava em disco físico (interativo, seguro) |
| `make all` | Pipeline completo (sudo) |
| `make clean` | Remove build/ |

## Estrutura

```
FlavosOS/
├── Makefile              # Orquestrador do build
├── config/
│   ├── flavos.conf       # Variáveis globais
│   ├── packages.list     # Pacotes do rootfs
│   └── loader/           # Config do systemd-boot
├── scripts/
│   ├── 00-check-deps.sh  # Verificação de deps
│   ├── 01-create-rootfs.sh
│   ├── 02-create-image.sh
│   ├── 03-install-system.sh
│   └── 04-boot-vm.sh
├── overlay/etc/          # Identidade do OS (hostname, os-release, etc)
├── tests/                # Smoke tests
├── docs/                 # Documentação técnica
└── build/                # (gitignored) Artefatos
```

## Documentação

- [Arquitetura](docs/architecture.md)
- [Instalação em Hardware Real](docs/HARDWARE_INSTALL.md)
- [Matriz de Homologação em Bare-metal](docs/VALIDATION_MATRIX.md)
- [Template de Validação](docs/TEST_REPORT_TEMPLATE.md)
- [Recuperação de Falhas](docs/RECOVERY.md)
- [Roadmap](docs/ROADMAP.md)
- [Changelog](docs/CHANGELOG.md)

## Login Base (Ambiente de Desenvolvimento)

- **Usuário Diário:** `flavos`
- **Senha Diária:** `123`
- **Root e Sudo:** Login SSH restrito ao usuário diário (Root banido da rede). O Flavos eleva privilégios via `sudo` com a sua senha de console. O terminal físico local loga diretamente o user principal após o boot.

> [!WARNING]
> **Atenção (Segurança):** A senha `123` para o usuário root e sysadmin está injetada programaticamente apenas para finalidades de **DevLocal**. Esta imagem **não está pronta** para deployments de nuvem pública, possuindo credenciais voláteis conhecidas. Em etapas futuras implementaremos extração segura de Cloud-Init.

## Observabilidade
- Para diagnosticar uso de CPU, disco e serviços danificados: `flavos-debug-report`
- Para diagnosticar status e portas lógicas de interface externa: `flavos-net-check`
- Leia o [RECOVERY_GUIDE](docs/RECOVERY.md) para emergências de Boot.
