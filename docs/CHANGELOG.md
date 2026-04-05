# Changelog — Flavos OS

## [Unreleased]
### Etapa 7 — Consolidação V1 (2026-04-05)
#### Adicionado
- Extensão `flavos-diag` para auditoria rápida de métricas core (`RAM`, `Rede`, `Failures`).
- Manual técnico estruturado (`docs/RECOVERY.md`) ensinando Kernel Recovery direto no TTY.
- Drop-in de Segurança SSH para bloquear acesso iterativo root.
- Identidade visual `motd` e `issue` adicionada no boot virtual.
- Automação da Rede delegada estritamente aos profiles `systemd-networkd`.

#### Modificado
- Extração dos dados mutáveis (`SYS_USER`, `SYS_LOCALE`, `SYS_KEYMAP`) do script de rootfs para o topo configurável base `flavos.conf`.
- `systemd-journald` reconfigurado para fixação persistente com lock protetor de 50MB.

### Etapa 2 a Etapa 5 — Build e Boot Framework (2026-04-05)
#### Entregue
- Implantação e refino da suíte Bash com chroot debootstrap ativo gerando `flavos.img`.
- Adoção nativa de flash drivers (`pflash`) para o boot UEFI seguro no emulador QEMU.
- Fix de infraestrutura UserSpace com o download dependente do pacote `systemd-sysv` unindo ABI de kernel ao Pid1.
- Imagem oficialmente declarada como Bootable (Milestone 1).


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
