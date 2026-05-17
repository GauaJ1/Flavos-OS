# Flavos OS - First Boot & OOBE Architecture

Este documento descreve a arquitetura da experiência de "Out-of-Box Experience" (OOBE) implementada a partir da Etapa 14H. O OOBE é a primeira interação do usuário após o sistema ter sido instalado no disco rígido.

## 1. Modos de Operação (Live vs. Installed)

O Flavos OS opera sob um rootfs unificado (`squashfs`), mas o comportamento no boot difere baseado em marcadores de estado:

*   **Modo Live:** O diretório `/run/live/medium` está presente. O sistema ignora a inicialização de OOBE.
*   **Modo Installed-FirstBoot:** Não há midia live montada, mas o arquivo `/var/lib/flavos/firstboot-required` foi gerado pelo instalador. Este modo dispara o aplicativo OOBE ao iniciar a sessão gráfica.
*   **Modo Installed:** O arquivo `firstboot-required` foi removido e `/var/lib/flavos/firstboot-complete` foi criado. O sistema inicia a área de trabalho normalmente.

A detecção é feita através do script `/usr/local/bin/flavos-system-mode`.

## 2. Inicialização Segura (Session Daemon)

O lançador do OOBE (`flavos-firstboot-launcher`) está integrado diretamente no `flavos-session-daemon` como um processo *fire-and-forget*. 
*   **Singleton:** O launcher usa um arquivo PID em `$XDG_RUNTIME_DIR/flavos-firstboot.pid` para garantir que apenas uma instância do OOBE seja iniciada.
*   **Não destrutivo:** Se o daemon de sessão for reiniciado (ex: reload), a proteção por PID e a verificação de estado impedem duplicações, garantindo que a sessão gráfica principal não trave ou sofra degradação de performance.

## 3. Experiência OOBE (Preview Técnica)

O aplicativo `flavos-firstboot` é construído com Python e GTK3. Na sua iteração inicial (Etapa 14H), ele foca na fundação visual e na estabilidade do fluxo de estados:

*   **Simulação de Configuração:** Ele exibe a interface de configuração para *Hostname*, *Timezone*, *Keyboard* e *Performance Profile*, mas registra as seleções em logs (`~/.local/share/flavos/logs/firstboot.log`) ao invés de aplicar configurações destrutivas sem os devidos helpers validados.
*   **Usuários:** A criação de usuários definitivos e a remoção das credenciais de desenvolvimento (`flavos`) foram movidas intencionalmente para as etapas 14H.2 / 14I, garantindo que um erro no OOBE não torne a máquina inacessível ("lockout").
*   **Adiamento:** O OOBE pode ser adiado ("Concluir depois"), mantendo o estado `firstboot-required` para o próximo login.

## 4. Helper de Conclusão Privilegiado

Quando o usuário clica em "Finalizar", o OOBE chama o helper privilegiado de transição de estado: `/usr/local/lib/flavos/helpers/flavos-firstboot-complete`.

Este helper foi projetado seguindo as melhores práticas de segurança de Least Privilege:
*   **Sem argumentos:** Impede ataques de injeção ou travessia de diretório.
*   **Caminhos fixos:** Altera única e exclusivamente o marcador `/var/lib/flavos/firstboot-required` para `firstboot-complete`.
*   **Sudoers restrito:** Configurado em `/etc/sudoers.d/flavos-firstboot` (`0440`), garantindo que o usuário `flavos` só tenha permissão `NOPASSWD` para executar esse script específico como root.

## 5. Próximos Passos (Hardening)

Com a arquitetura do OOBE validada de ponta a ponta sem quebrar a sessão:
1.  Introduzir a gestão real de usuários (substituir usuário dev).
2.  Desabilitar autologin quando um usuário customizado for criado.
3.  Desenvolver os helpers `flavos-set-hostname`, `flavos-set-timezone` com validação estrita.
