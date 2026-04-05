# Flavos OS — Backfill Técnico (Etapas 2 a 5)

## Objetivo
Consolidar formalmente o rigor de engenharia do trabalho executado de forma unificada nas etapas iniciais, registrando a infraestrutura gerada, o rastreio da imagem e a resolução do Primeiro Boot no QEMU/KVM.

---

### Etapa 2: Estrutura Oficial do Workspace
O workspace do projeto foi arquitetado priorizando idempotência de build e separação de responsabilidades. A estrutura final consolidada em `master` atende a toda a chain de compilação:

```text
FlavosOS/
├── Makefile                          # Entrypoint unificado (deps, rootfs, image, install, boot, clean, test)
├── README.md
├── branding/                         # Asset store da identidade visual
│   └── logo.jpeg
├── config/                           # Definitions declarativas do sistema base
│   ├── flavos.conf                   # Variáveis globais (Image size, Arch, CPU/RAM, CWD paths)
│   ├── packages.list                 # Manifest Debian oficial injetado pelo debootstrap
│   └── loader/                       # Configuração baseline do UEFI
├── docs/                             # Engineering logs e architecture designs
├── overlay/                          # Diretórios que sobrescrevem o vanilla (ex: /etc/os-release)
├── scripts/                          # Pipelines numerados em shell estritos (set -euo pipefail)
│   ├── 00-check-deps.sh
│   ├── 01-create-rootfs.sh
│   ├── 02-create-image.sh
│   ├── 03-install-system.sh
│   └── 04-boot-vm.sh
├── tests/                            # Quality Assurance e validação sintática pré-boot
└── build/                            # .gitignore area (Artifacts e chroot gerados dinamicamente)
```

---

### Etapa 3: Formalização do RootFS Atual
- **Método Adotado:** Cópia cruzada e chroot via `debootstrap` (sem isoladores complexos como Yocto, mantendo transparência total no Debian puro).
- **Alvo:** `Debian Stable (Bookworm) amd64`.
- **Modo:** Minbase minimalista (somente pacotes explicitamente ordenados por `packages.list`).
- **Sistema de Inicialização:** SystemD injetado em layer nativa.
- **Tamanho Atingido:** O rootfs descompactado ocupou cerca de ~660MB após expurgo dos caches APT.

---

### Etapa 4: Formalização da Boot Chain
- **Paradigma de Armazenamento:** Imagem `.img` RAW com particionamento GPT padrão não-legado.
- **Tabela de Partições:**
  - `/dev/loopXp1`: ESP de 256MB, formatada em `vfat` com flag EFI.
  - `/dev/loopXp2`: Root data preenchendo o resto da imagem, formatado em `ext4`.
- **Resolução de UUIDs:** Abandonamos binding estático por bloco (`/dev/sda2`). Adotamos resolução dinâmica via `PARTUUID` (exportado para `partuuids.env`), protegendo o runtime kernel no QEMU que monta o block device via Virtio (`/dev/vdX`).
- **Bootloader Eleito:** `systemd-boot` blindado na ESP. O kernel modular e initramfs são copiados diretamente para o topo da ESP, removendo dependências sobre drivers de filesystem no estágio 0 de firmware.

---

### Etapa 5: O Primeiro Boot Funcional e Debugging Forense

Ao submeter a ISO recém construída ao QEMU para validação do Kernel, deparamo-nos com duas barreiras técnicas que foram identificadas, dissecadas baseadas em logs fáticos e mitigadas no source.

#### Problema 1: Barreira do QEMU Firmware
- **Erro Relatado:** `qemu: could not load PC BIOS '/usr/share/OVMF/OVMF_CODE_4M.fd'`
- **Causa Raiz:** Firmwares OVMF recentes (que suportam boot UEFI robusto de 4MB) retiraram suporte a leitores flash legados. O flag estático de inicialização `-bios` não funciona contra o `OVMF_CODE_4M.fd`.
- **Correção Mínima Aplicada:** Alterou-se o `04-boot-vm.sh` implementando modelagem formal para storage UEFI via `pflash`, alicerçando variáveis NVRAM de volta ao `build/OVMF_VARS_4M.fd` readonly.

#### Problema 2: Falha de Pivot-Root no Initramfs
- **Erro Relatado:** `run-init: /sbin/init: No such file or directory` (Caindo pro shell limítrofe).
- **Diagnóstico (Grupo de Prova):**
  1. Boot flag `root=PARTUUID=...` testado e comprovado (correto, já que driver localizou block interface Virtio ext4 de forma perfeita e extraiu FS-root).
  2. Executou-se `ls -l` post-mortem na varredura local do rootfs. Prova alcançada de que embora `/lib/systemd/systemd` existisse, o link mandatório `/sbin/init` exigido pela ABI de kernel init **não foi criado**.
- **Causa Raiz:** Para Debian moderno, o binário principal do systemd e o symlink obsoleto que acopla o sysv-init para o systemd ocorrem por pacotes separados, falha de manifest na nossa etapa 2. Tinhamos `systemd`, mas não o symlink provider.
- **Correção Mínima Aplicada:** O pacote `systemd-sysv` foi injetado imediatamente após a linha `systemd` em `config/packages.list`.
- **Resultado Pós-Rebuild:** O run-init encontrou o init legadado que aponta para o systemd puro. Todos os services logaram `[OK]` perfeitamente parando a fita na subida robusta do Flavos OS prompt login na ttyS01.

---

*Fim do Backfill de documentação. Projeto consolidado e arquitetado sob estrita revisão. Em prontidão para a Etapa 6.*
