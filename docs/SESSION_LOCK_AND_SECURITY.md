# Session Lock & Security

O Flavos OS utiliza um ecossistema minimalista focado em leveza e resiliência (Openbox/X11). Com a **Etapa 13C**, introduzimos o **xsecurelock** como a camada primária de bloqueio de sessão. 

## 1. Por que o xsecurelock?

O protocolo X11 tem vulnerabilidades estruturais (qualquer aplicação pode escutar eventos do teclado ou ler a tela). O `xsecurelock`, desenhado pelo Google, isola ativamente as entradas de teclado criando múltiplas árvores de janelas invisíveis e delegando a interface a submódulos não-privilegiados. Ele **reduz drasticamente os riscos clássicos de lockers X11**, evitando que aplicações mal-comportadas burlem a tela de bloqueio.

**Limitação do X11:** O `xsecurelock` não isola completamente contra clientes maliciosos já em execução (keyloggers com privilégios de root, ou injeções shellcode profundas) que estejam operando por debaixo do próprio X server. Para uma mitigação absoluta desses vetores no *display server*, seria necessária uma transição para Wayland.

## 2. Conceitos de Sessão (Shellctl)

O comportamento do sistema é orquestrado através do `flavos-shellctl session <ação>`:

*   **Lock (`flavos-shellctl session lock`)**:
    Mantém todos os seus programas e documentos abertos no fundo, cortando o acesso interativo à interface visual. Desbloqueável apenas com a senha do usuário logado. Funciona para pausas (ida ao café, afastamento temporário).

*   **Logout (`flavos-shellctl session logout`)**:
    Encerra o gerenciador de janelas e "mata" todos os aplicativos abertos atrelados à sessão gráfica do usuário. Ideal para limpeza total do ambiente.

*   **Reboot / Poweroff**:
    Aciona as rotinas do `systemd` para iniciar a finalização da máquina de forma ordenada.

## 3. Autologin e Risco de Reboot Físico

O Flavos OS atualmente é configurado (em sua base Debian customizada) para efetuar o **autologin** diretamente no desktop.

**Atenção:** Se o computador estiver bloqueado com `xsecurelock` e alguém forçar o desligamento físico (segurando o botão de energia do equipamento), o próximo boot efetuará o login automaticamente, expondo a sessão novamente. O lock serve **estritamente** para impedir acessos enquanto a máquina permanece ligada sob o seu controle. 

## 4. Ausência de Criptografia de Disco

O Bloqueio de Tela não protege seus dados no disco rígido. Se a máquina for desligada, o disco pode ser removido e lido livremente. O "Lock" não substitui o uso futuro de tecnologias como o LUKS para Data-at-Rest.

## 5. Atalhos Rápidos

*   **Bloquear Tela:** Pressione `Super + L`
*   Alternativamente, use o **Power Menu** (Flavos Power) e clique em "Bloquear".

## 6. Hardening Aplicado (Auditoria 13C.1)

*   **Log do xsecurelock:** O arquivo `/tmp/flavos-xsecurelock.log` é criado com `umask 077` (somente o dono lê/escreve), impedindo leak de informações de diagnóstico para outros usuários.
*   **Prevenção de shell injection:** O `flavos-power` utiliza `shlex.split()` em vez de `shell=True` no `subprocess.Popen`, eliminando vetores de injeção de comandos.
*   **Sanitização de path (wallpaper):** O comando `wallpaper apply` sanitiza o argumento com `realpath` antes de passar para `feh`/`gsettings`, prevenindo injeção via metacaracteres no caminho do arquivo.
*   **Variáveis de ambiente defensivas:** `DISPLAY`, `XAUTHORITY` e `XDG_SESSION_TYPE` são tratadas com defaults seguros (`${VAR:-default}`) para evitar falhas sob `set -e` em sessões autologin.
*   **Design System integrado:** O xsecurelock exibe fundo `#0D1017`, texto `#E8ECF4`, fonte Inter e horário — alinhado ao Design System do Flavos OS.
