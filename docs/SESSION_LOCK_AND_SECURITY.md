# Session Lock & Security

O Flavos OS utiliza um ecossistema minimalista focado em leveza e resiliência (Openbox/X11). Com a **Etapa 13C**, introduzimos uma camada de bloqueio de sessão robusta e previsível, desenhada para fornecer uma experiência visual premium garantindo segurança estrutural.

A rota única e sagrada de bloqueio do sistema é:
```
Qualquer Gatilho (Atalho/Menu) → flavos-shellctl session lock → /usr/local/bin/flavos-lock → backend
```

---

## 1. Evolução da Arquitetura de Lock (Decisões de Design)

O histórico de desenvolvimento da solução de lock screen passou por diversas iterações para encontrar o equilíbrio perfeito entre estabilidade em X11 puro e apelo visual:

*   **❌ `cinnamon-screensaver` (Abandonado):**
    O script wrapper foi inicialmente projetado para ele. Contudo, sendo implementado em Python e altamente acoplado ao `cinnamon-session`, ele retornava `None` no proxy D-Bus (`dbus.SessionBus().get_object()`) ao tentar rodar em ambientes standalone (Openbox). Isso gerava tracebacks silenciosos ("AttributeError: 'NoneType' object has no attribute 'call_lock_sync'").
*   **❌ `light-locker` (Descartado):**
    Conhecido por causar bugs de tela preta (*black screen*) por depender estritamente de trocas de terminal virtual (VT switch) coordenadas com o Display Manager (LightDM). Incompatível com o modelo do Flavos OS.
*   **❌ `xsecurelock` (Descartado):**
    Apresentou graves conflitos de composição com o Picom, resultando em artefatos visuais (vazamento do desktop por trás do lock).
*   **✅ `mate-screensaver` (Backend Principal Escolhido):**
    Implementado em C (sem as fragilidades de proxy Python do Cinnamon) e altamente maduro. Funciona de forma totalmente independente do ambiente MATE, registrando o serviço `org.mate.ScreenSaver` diretamente no D-Bus de sessão. Integra-se nativamente com o PAM, fornece um prompt GTK bonito e convive perfeitamente com o compositor Picom (usando janelas *override-redirect*).

---

## 2. A Camada de Resiliência: Wrapper e Fallback

Para evitar travamentos silenciosos e garantir que a máquina **sempre** será bloqueada, o script `/usr/local/bin/flavos-lock` atua como um supervisor implacável:

1.  **Validação Ativa de Daemon:** O wrapper garante que o daemon do `mate-screensaver` esteja rodando (iniciando-o *on-demand* se necessário).
2.  **Validação Estrita de Saída:** Falsos sucessos (onde o binário retorna exit code 0 mas imprime um erro) são eliminados interceptando ativamente as saídas padrão (stdout e stderr) em busca de palavras-chave como `Traceback`, `NoneType`, `Can't connect`, etc.
3.  **Fallback Garantido (`i3lock`):** Se o `mate-screensaver` falhar em ativar, falhar na verificação de query, ou se não estiver instalado, o script recai imediatamente para o `i3lock`.
    *   O `i3lock` usa um background estático premium (`/usr/share/flavos/lock/background.png`). Se a imagem faltar, ele usa uma cor sólida preta/azul escura (`0D1017`).

---

## 3. Alertas de Segurança (Limitações Conhecidas)

> [!WARNING]
> **Lock Screen NÃO substitui Criptografia de Disco (FDE)**
> Uma tela de bloqueio protege a sessão logada apenas contra um ator não autenticado interagindo via teclado/mouse. Se o hardware for roubado ou o sistema reiniciado via USB, todos os seus dados estarão legíveis. A segurança real de dados em repouso exige Full Disk Encryption (ex: LUKS), configurado na instalação.

> [!CAUTION]
> **Auto-login**
> O Flavos OS atualmente inicializa com autologin ativado por conveniência na fase de desenvolvimento. Isso anula parte do valor do bloqueio automático. Se a máquina for desligada e ligada, o atacante acessa a sessão sem senha.

> [!NOTE]
> **Wayland vs X11**
> O modelo de bloqueio baseado no X11 (captura global de teclado/mouse) é inerentemente inseguro contra ataques avançados. O X11 permite que processos isolados leiam inputs globais se não forem perfeitamente tratados. No futuro, a migração para Wayland resolverá essas vulnerabilidades no nível do protocolo do compositor (utilizando `swaylock` ou similar).

---

## 4. Validação e Diagnóstico

**Logs de Operação:**
Todas as chamadas de bloqueio geram logs atômicos em tempo real no diretório temporal do usuário.
```bash
cat ${XDG_RUNTIME_DIR:-/tmp}/flavos-lock.log
```
*Em caso de sucesso, o arquivo exibirá as etapas da chamada e a string: `BACKEND USADO: mate-screensaver` ou `FALLBACK: usando i3lock`.*

**Testes Manuais para QA:**
```bash
# Validar syntaxe do wrapper
bash -n /usr/local/bin/flavos-lock

# Bloquear a tela manualmente
flavos-shellctl session lock

# Simular quebra do MATE para testar fallback para i3lock
pkill mate-screensaver
flavos-shellctl session lock
```
