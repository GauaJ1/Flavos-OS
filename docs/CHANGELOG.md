# Changelog — Flavos OS

## [Unreleased]

### Etapa 1 — Arquitetura e Fundações (2026-04-05)

#### Definido
- Abordagem de construção: Debootstrap sobre Debian Stable (Bookworm 12.x)
- Bootloader: systemd-boot (UEFI-only)
- Init system: systemd
- Filesystem: ext4 (root), FAT32 (ESP)
- Particionamento: GPT
- Formato de imagem: raw .img (2GB)
- Sistema de build: Makefile + scripts bash numerados
- Teste: QEMU/KVM + OVMF
- Estrutura de repositório planejada

#### Documentado
- docs/architecture.md — Arquitetura completa
- docs/ROADMAP.md — Plano de evolução
- docs/CHANGELOG.md — Este arquivo

#### Rejeitado (com justificativa)
- LFS: retrabalho alto, sem gerenciador de pacotes
- Buildroot: sem package manager runtime
- Yocto: overengineering para o estágio atual
- GRUB2: complexidade desnecessária para UEFI-only
- Legacy BIOS: sem retorno proporcional para V1
