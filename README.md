# Flavos OS

> **Milestone atual:** Flavos Desktop Preview 1 "Daily" (Etapa 13E)
> **Base do sistema:** 0.1.0-rc1 (Ignition)

Sistema operacional construído do zero com foco em **idempotência**, **segurança** e **simplicidade**, evoluindo para uma experiência desktop nativa e coerente.

---

## Status

### Desktop Preview 1 "Daily" _(milestone atual)_

Desktop funcional para uso diário básico com suporte a navegação, gerenciamento de arquivos, PDF, multimídia, compressão e lock screen. Sistema de perfis de desempenho (Light/Balanced/Full).

- **Veredito:** `EXPERIMENTAL ESTÁVEL`
- **Tag:** `desktop-preview-1-daily`
- **Documentação desktop:** [docs/DESKTOP_DAILY_PREVIEW.md](docs/DESKTOP_DAILY_PREVIEW.md)
- **Documentação performance:** [docs/PERFORMANCE_PROFILES.md](docs/PERFORMANCE_PROFILES.md)
- **Artefatos de release:** [docs/RELEASE_ARTIFACTS.md](docs/RELEASE_ARTIFACTS.md)

### Shell Preview 0.1 "Basis" _(milestone anterior)_

Primeira preview da shell nativa (painel, taskbar, launcher, OSD). Congela as etapas 11A→11E com interface funcional e design system estabelecido.

- **Tag:** `shell-preview-0.1-basis`
- **Documentação:** [docs/SHELL_PREVIEW_0.1_BASIS.md](docs/SHELL_PREVIEW_0.1_BASIS.md)

### Base do Sistema — 0.1.0-rc1 (Ignition) _(fase base)_

Console V1 consolidada. Sistema maduro, seguro e bootável em QEMU e infraestrutura lab.

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
| `make compress` | Comprime `.img` → `.img.xz` (xz -9) |
| `make checksum` | Gera `.img.xz.sha256` |
| `make release` | Pipeline de release (compress+checksum+manifest) |
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
│   ├── 04-boot-vm.sh
│   └── 06-create-live-prototype.sh
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

### Milestones
- [Flavos Desktop Preview 0.1 "Daily"](docs/DESKTOP_PREVIEW_0.1_DAILY.md)
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

### Hardware Lab
- [Hardware Lab Baseline](docs/HARDWARE_LAB_BASELINE.md)
- [Hardware Test Report Template](docs/HARDWARE_TEST_REPORT_TEMPLATE.md)

### Live Environment
- [Live Boot Strategy](docs/LIVE_BOOT_STRATEGY.md)
- [Live Boot Experiment Plan](docs/LIVE_BOOT_EXPERIMENT_PLAN.md)

### Evolução do Projeto
- [Roadmap](docs/ROADMAP.md)
- [Changelog](docs/CHANGELOG.md)
- [Release Artifacts](docs/RELEASE_ARTIFACTS.md)

---

## Login (Ambiente de Desenvolvimento)

- **Usuário:** `flavos` / **Senha:** `123`
- **Elevação:** `sudo` com senha do usuário (root banido da rede)

> [!CAUTION]
> **Credenciais conhecidas.** As senhas acima são DevLocal e estão documentadas publicamente.
> Esta imagem **NÃO é segura para produção**, redes públicas ou armazenamento de dados sensíveis.
> Altere as credenciais antes de qualquer uso fora de ambiente controlado.
> Consulte [docs/RELEASE_ARTIFACTS.md](docs/RELEASE_ARTIFACTS.md) para a classificação de segurança completa.

---

## Observabilidade

- `flavos-debug-report` — auditoria rápida de CPU, disco, serviços
- `flavos-hw-report` — diagnóstico de hardware para testes físicos (somente leitura)
- `flavos-net-check` — diagnóstico de rede e portas
- Logs da shell nativa: `~/.local/share/flavos/logs/`
- [RECOVERY_GUIDE](docs/RECOVERY.md) para emergências de boot
