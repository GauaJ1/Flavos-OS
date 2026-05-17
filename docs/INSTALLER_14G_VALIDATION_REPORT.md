# Validação 14G: Bootloader & First Boot

## Objetivo
Garantir que a instalação do Flavos OS, via sincronização de payload (Etapa 14F), receba o bootloader apropriado e consiga inicializar de forma independente através da UEFI (OVMF) no QEMU, simulando o primeiro boot pós-instalação real.

## Problemas Encontrados e Corrigidos

Durante a validação inicial, a VM instalada não inicializou (caindo na UEFI Shell do QEMU). Uma investigação detalhada apontou para três falhas críticas que impediam a instalação do bootloader:

1. **Falha Silenciosa de Execução:**
   - **Problema:** O instalador `flavos-installer-lab` não exigia explicitamente o argumento de ação na hora da execução por falta de um bloco de controle, o que levava ao encerramento do script sem realizar a instalação ou emitir erros.
   - **Solução:** Adicionada uma verificação estrita (`else usage`) que impede a continuação silenciosa e exige explicitamente a ação `install-bootloader` ou `payload-sync`.

2. **Rejeição do Bootctl por Machine-ID Vazio:**
   - **Problema:** No passo 14F (sincronização do payload), nós limpávamos o arquivo `/etc/machine-id` intencionalmente para gerar um novo ID no primeiro boot. Contudo, a ferramenta `bootctl` exige um `machine-id` válido dentro do chroot para estruturar seus diretórios. A proteção de segurança do script (`set -euo pipefail` e `trap cleanup`) interceptava a falha e fazia a limpeza sem exibir o erro ao usuário.
   - **Solução:** Implementamos a injeção temporária do `machine-id` usando `systemd-machine-id-setup` apenas para a execução do `bootctl`. Adicionamos um erro gigante em vermelho (`if ! chroot ...`) para interceptar quaisquer falhas futuras do `bootctl`, finalizando com a re-remoção do `machine-id`.

3. **Ausência do Kernel no Rootfs (`/boot` vazio):**
   - **Problema:** Para economizar espaço na ISO Live, o script `06-create-live-prototype.sh` estava excluindo o diretório `boot/*` do empacotamento do `mksquashfs`. Como consequência, o rootfs sincronizado para o disco de destino ficava sem `vmlinuz` e `initrd`, causando a quebra do instalador ao tentar copiar o kernel para a ESP (EFI System Partition).
   - **Solução:** O diretório `boot/*` foi removido da lista de exclusões (`-e`) do `mksquashfs`. Com isso, a imagem squashfs passou a carregar as imagens de kernel necessárias para as futuras instalações e atualizações do sistema (`apt upgrade`).

## Resultados Alcançados

- **Sincronização Íntegra:** O sistema agora é clonado corretamente incluindo as dependências de boot e imagens de kernel nativas.
- **Bootloader Operacional:** O sistema de EFI foi estruturado com êxito. A configuração customizada (`loader.conf` e `flavos.conf`) foi validada e está mapeando adequadamente o root filesystem.
- **Transição Live → Instalado Confirmada:** O arquivo `10-boot-installed-vm.sh` consegue ler a partição ESP sem interferência de NVRAM (utilizando fallback `BOOTX64.EFI`) e entra no sistema operacional.

## Próximos Passos
Com o ciclo de boot autônomo perfeitamente funcional e a arquitetura do bootloader finalizada, a base operacional da ISO e do Instalador está sólida. O próximo passo lógico é:

- **Etapa 14H / 14I (Flavos First Boot / OOBE):** Criação de uma interface de boas-vindas executada no primeiro boot, onde o usuário poderá realizar configurações iniciais como criação de usuário, definição de fuso horário, layout de teclado, e ingressar no fluxo estético e utilitário que idealizamos para o Flavos OS.
