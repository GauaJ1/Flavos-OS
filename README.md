# Flavos OS

Sistema operacional Linux criado do zero, focado em boot confiável, build reproduzível e arquitetura limpa.

## Status

**V0.1.0 (Ignition)** — Em desenvolvimento. Infraestrutura de build pronta, aguardando geração do primeiro rootfs e boot.

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
| `make boot` | Inicia VM (serial) |
| `make boot-gui` | Inicia VM (gráfico) |
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
- [Roadmap](docs/ROADMAP.md)
- [Changelog](docs/CHANGELOG.md)

## Login (V1 desenvolvimento)

- **Usuário:** root
- **Senha:** flavos
