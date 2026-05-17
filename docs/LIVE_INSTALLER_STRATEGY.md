# Flavos OS — Estratégia do Instalador Live (Etapa 14E)

## 1. Objetivo
Definir a arquitetura inicial e a estratégia de longo prazo para o instalador do Flavos OS, que será executado a partir do ambiente Live Boot. O foco desta etapa é estabelecer o modelo offline como principal e detalhar os fluxos técnicos e de usuário sem implementar operações destrutivas.

## 2. Relação com Live Boot
O instalador será um aplicativo de primeira classe dentro da sessão Live do Flavos OS. Ele deve aproveitar o ambiente gráfico já carregado na RAM (X11 + Picom) para oferecer uma interface de instalação (TUI/CLI inicialmente, GTK futuramente). O ambiente Live serve como plataforma de homologação do hardware antes do commit final no disco.

## 3. Arquitetura do Payload
O modelo de payload escolhido é a **Instalação a partir do `filesystem.squashfs`**.
Comparado a gravar uma imagem pronta (`.img.xz`) ou usar `debootstrap` do zero, extrair o squashfs oferece o melhor equilíbrio entre velocidade de instalação, flexibilidade de particionamento e ausência de dependência de rede. O instalador montará o squashfs (ou usará o rootfs overlay já montado) e sincronizará os arquivos para o disco alvo.

## 4. Instalação Offline/Local
A premissa absoluta da V1 é a **instalação offline**.
O Flavos OS deve ser instalável em qualquer hardware suportado (LGA 775, 2GB RAM) sem necessitar de conexão à internet. Todo o sistema base, pacotes e configurações essenciais residem no payload presente na própria ISO.

## 5. Modo Online Futuro
A funcionalidade de "NetInstall" ou "Update during Install" será planejada para o futuro. 
Quando implementada, o instalador fará o download de um arquivo `manifest.json`, validará a assinatura/checksum, e baixará o `filesystem.squashfs` mais recente dos servidores do Flavos OS, aplicando-o em vez do payload local. Não será implementada agora.

## 6. Fluxo do Usuário
1. O usuário boota a ISO Híbrida.
2. Chega no Desktop Preview e testa áudio, rede, vídeo.
3. Abre o app "Instalar Flavos OS".
4. Seleciona o disco de destino (com confirmação explícita de deleção de dados).
5. Define um usuário, senha e hostname.
6. Acompanha a barra de progresso (cópia de arquivos).
7. Recebe a mensagem de sucesso e opta por reiniciar.

## 7. Fluxo Técnico
1. Identificação do disco alvo (`lsblk`, validação de tamanho).
2. Particionamento (GPT via `sgdisk` ou `parted`).
3. Formatação (`mkfs.ext4` e `mkfs.vfat`).
4. Montagem das partições de destino em `/mnt/flavos-install`.
5. Cópia dos dados via `rsync -aH` do squashfs para o `/mnt` (sem `-X` — vide 14H.0).
6. Bind mounts (`/dev`, `/proc`, `/sys`) para realizar chroot.
7. Ajustes no chroot (remoção de pacotes live, recriação do initramfs, instalação do bootloader).
8. Desmontagem e finalização.

## 8. Particionamento (14I — Layout Híbrido GPT)
O instalador utiliza GPT por padrão com 3 partições:

| # | Tipo | Label | Tamanho | Filesystem | Ponto de montagem |
|---|---|---|---|---|---|
| p1 | EF02 | FLAVOS_BIOSBOOT | 2 MiB | nenhum | — |
| p2 | EF00 | FLAVOS_ESP | 512 MiB | FAT32 | /boot/efi |
| p3 | 8304 | FLAVOS_ROOT | restante | ext4 | / |

- **BIOS Boot Partition (EF02):** Não formatada. O `grub-install --target=i386-pc` escreve o `core.img` diretamente nela em hardware BIOS Legacy.
- **ESP (EF00):** Usada pelo `systemd-boot` em sistemas UEFI.
- Swap gerido via `zram`, sem partição estática.

## 9. Bootloader (14I)
O instalador suporta dois modos via flag `--mode`:

- **`--mode uefi`:** Instala `systemd-boot` na ESP. Requer UEFI.
- **`--mode bios`:** Instala `grub-pc-bin` (i386-pc) na BIOS Boot Partition. Suporte a hardware LGA 775.
- **`--mode both`:** Instala ambos no mesmo disco (recomendado para laboratório).
- **`--mode auto`:** Detecta firmware via `/sys/firmware/efi` e escolhe automaticamente.

O flag `--mode` é **obrigatório** para `install-bootloader`. Sem ele, o comando aborta.

## 10. Usuário e Senha
Durante a instalação, o usuário criará suas credenciais finais. O script criará este usuário no sistema de destino (`useradd`, `passwd`), adicionará ao grupo `sudo` (ou `wheel`) e configurará seu diretório `home`.

## 11. Diferenças Live vs Instalado
Após a cópia via `rsync`, o instalador deve remover os vestígios do modo Live:
- Excluir o usuário genérico `flavos` (ou configurá-lo apenas para o live).
- Desativar serviços de autologin mascarados para o Live.
- Remover pacotes exclusivos de live (ex: `live-boot`, `live-config`).
- Resetar `/etc/machine-id`.
- Gerar novo `/etc/fstab` com os UUIDs reais das partições criadas.

## 12. Segurança
- O instalador real exigirá elevação de privilégio (`pkexec` ou `sudo`).
- A etapa atual (dry-run) atua com permissões restritas e não invoca ferramentas destrutivas.
- Telas de dupla confirmação serão exigidas antes de qualquer comando `mkfs` ou `parted` no futuro.

## 13. Riscos
- **Apagar disco errado**: Maior risco em TUI. O instalador precisará exibir claramente o modelo, fabricante e tamanho do disco antes de confirmar.
- **Falta de Criptografia**: LUKS não será suportado na V1.
- **Sem Secure Boot**: O kernel atual não possui assinatura válida para Secure Boot da Microsoft. Os usuários precisarão desativá-lo.

## 14. Roadmap Incremental
- **Fase 1 (Atual)**: Arquitetura, documentação e script `dry-run`.
- **Fase 2**: Implementação do particionamento e cópia real via CLI.
- **Fase 3**: Refinamento dos scripts de post-install (chroot, bootloader, fstab).
- **Fase 4**: Interface Gráfica em GTK.
