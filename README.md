# Flavos OS

> **Milestone atual:** Flavos Shell Preview 0.1 "Basis"
> **Base do sistema:** 0.1.0-rc1 (Ignition)

Sistema operacional construído do zero com foco em **idempotência**, **segurança** e **simplicidade**, evoluindo para uma experiência desktop nativa e coerente.

---

## Status

### Shell Nativa — Flavos Shell Preview 0.1 "Basis" _(milestone atual)_

A primeira preview oficial da shell nativa do Flavos OS. Congela as etapas 11A→11E com uma interface funcional, estável e com design system estabelecido. O sistema já se comporta como um OS com identidade própria.

- **Veredito:** `EXPERIMENTAL ESTÁVEL`
- **Congelada em:** 2026-04-19
- **Commit de referência:** `b9bf43f`
- **Tag:** `shell-preview-0.1-basis`
- **Documentação:** [docs/SHELL_PREVIEW_0.1_BASIS.md](docs/SHELL_PREVIEW_0.1_BASIS.md)

### Base do Sistema — 0.1.0-rc1 (Ignition) _(fase anterior)_

Console V1 consolidada. Sistema maduro, seguro e bootável em QEMU e infraestrutura lab. Release Candidate 1 da base console, sobre a qual a shell nativa foi construída.

- **Tag:** `v0.1.0-rc1`
- **Release Notes:** [docs/RELEASE_NOTES_0.1.0-rc1.md](docs/RELEASE_NOTES_0.1.0-rc1.md)

---

## Stack

| Camada | Componente |
|---|---|
| **Base** | Debian Bookworm (amd64) via debootstrap |
| **Bootloader** | systemd-boot (UEFI) |
| **Init** | systemd |
| **Root FS** | ext4 |
| **Imagem** | Raw .img (2GB, GPT) |
| **VM** | QEMU/KVM + OVMF |
| **Servidor gráfico** | Xorg / X11 |
| **Gerenciador de janelas** | Openbox |
| **Compositor** | Picom |
| **Shell UI** | Python 3 + GTK 3 (nativa Flavos) |

---

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
make boot-gui   # modo gráfico (shell nativa)
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

---

## Estrutura

```
FlavosOS/
├── Makefile              # Orquestrador do build
├── config/
│   ├── flavos.conf       # Variáveis globais
│   ├── packages.list     # Pacotes do rootfs
│   └── loader/           # Config do systemd-boot
├── scripts/
│   ├── 00-check-deps.sh
│   ├── 01-create-rootfs.sh
│   ├── 02-create-image.sh
│   ├── 03-install-system.sh
│   └── 04-boot-vm.sh
├── overlay/
│   ├── etc/              # Identidade do OS (hostname, os-release, etc)
│   ├── usr/local/bin/    # Shell nativa (flavos-panel, taskbar, launcher, osd…)
│   └── usr/share/        # Temas, ícones, aplicativos .desktop
├── tests/                # Smoke tests
├── docs/                 # Documentação técnica
└── build/                # (gitignored) Artefatos
```

---

## Documentação

### Milestone Atual
- [Flavos Shell Preview 0.1 "Basis"](docs/SHELL_PREVIEW_0.1_BASIS.md)
- [Requisitos do Sistema](docs/REQUIREMENTS.md)

### Base do Sistema (Ignition)
- [Arquitetura](docs/architecture.md)
- [Release Notes 0.1.0-rc1](docs/RELEASE_NOTES_0.1.0-rc1.md)
- [Instalação em Hardware Real](docs/HARDWARE_INSTALL.md)
- [Laboratório de Homologação em VM](docs/VM_LAB_VALIDATION.md)
- [Matriz de Homologação Bare-metal](docs/VALIDATION_MATRIX.md)
- [Template de Validação](docs/TEST_REPORT_TEMPLATE.md)
- [Recuperação de Falhas](docs/RECOVERY.md)

### Evolução do Projeto
- [Roadmap](docs/ROADMAP.md)
- [Changelog](docs/CHANGELOG.md)

---

## Login (Ambiente de Desenvolvimento)

- **Usuário:** `flavos` / **Senha:** `123`
- **Elevação:** `sudo` com senha do usuário (root banido da rede)

> [!WARNING]
> A senha `123` está configurada apenas para **DevLocal**. Esta imagem **não está pronta** para deployment público. Credenciais devem ser rotacionadas antes de qualquer uso em rede não controlada.

---

## Observabilidade

- `flavos-debug-report` — auditoria rápida de CPU, disco, serviços
- `flavos-net-check` — diagnóstico de rede e portas
- Logs da shell nativa: `~/.local/share/flavos/logs/`
- [RECOVERY_GUIDE](docs/RECOVERY.md) para emergências de boot
