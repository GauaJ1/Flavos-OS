# Flavos OS — Modelo do Install Payload

Este documento detalha o comportamento do instalador ao lidar com a transferência de dados do Live Boot para a instalação persistente no disco (Etapa 14E).

## 1. Fonte do Payload (Squashfs)
O instalador do Flavos OS extrairá o sistema diretamente do `filesystem.squashfs` montado na sessão Live. Em ambientes live padrão, este filesystem geralmente está montado como loop device em `/lib/live/mount/rootfs/filesystem.squashfs` ou similar pelo `live-boot`.

## 2. Transferência de Dados (Rsync)
O método oficial de cópia será o `rsync`.
Ele preserva de forma robusta as permissões, donos, symlinks e ACLs, ao mesmo tempo que permite a filtragem fina do que **não** deve ir para a instalação final.
Comando base planejado:
`rsync -aAXv --exclude-from=/usr/local/etc/installer-excludes.txt /caminho/squashfs/ /mnt/flavos-install/`

## 3. Exclusões Críticas
O ambiente live possui diretórios virtuais e de runtime que não podem ser copiados para a raiz definitiva:
- `/run/*`
- `/tmp/*`
- `/dev/*`
- `/proc/*`
- `/sys/*`
- `/mnt/*`
- `/media/*`
- `/cdrom/*`
- `/lib/live/mount/*`

Além disso, pacotes como `live-boot` e `live-config` e seus respectivos subprodutos no `/etc` devem ser removidos posteriormente ou ignorados durante o rsync.

## 4. Adaptações de Post-Install (Chroot)

Após a cópia, o instalador entrará em chroot em `/mnt/flavos-install` e realizará:

### FSTAB
O `/etc/fstab` original da ISO não tem serventia. O instalador gerará um novo com base nos UUIDs das partições criadas (Root e ESP).

### Machine-ID
O `/etc/machine-id` será apagado e gerado novamente com `systemd-machine-id-setup` para garantir que o sistema recém-instalado seja único.

### Hostname
O hostname, previamente genérico (`flavos`), será atualizado em `/etc/hostname` e `/etc/hosts` conforme escolhido pelo usuário durante o fluxo de instalação.

### Remoção do Autologin
O Live Boot utiliza autologin para o ambiente do usuário genérico (`flavos`). Os overrides do getty ou do lightdm/xdm (se houver no futuro) que forçam esse comportamento precisarão ser removidos. Atualmente, o autologin na TTY deve ser revertido para exigir senha.

### Transição de Usuário
O usuário Live (`flavos`) será desativado ou removido no destino, dependendo da configuração de limpeza. Em seu lugar, será criado o usuário real definido pelo operador na UI do instalador, com as credenciais, groups apropriados (ex: `sudo`, `video`, `audio`) e esqueleto home recriado via `/etc/skel`.
