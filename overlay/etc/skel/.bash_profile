# ~/.bash_profile
# Lançado apenas em sessões interativas de login.
# Aqui damos match no TTY1 para promover o Display Server.

# Guard: só tenta GUI se startx existir e estivermos no TTY1.
# Se o X falhar, o usuário retorna ao console em vez de ficar preso.
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ] && command -v startx >/dev/null 2>&1; then
  startx -- -keeptty 2>/tmp/xorg-startup.log || {
    echo ""
    echo "[Flavos OS] Sessão gráfica falhou. Retornando ao console."
    echo "  Verifique: /tmp/xorg-startup.log"
    echo "  Para tentar novamente: startx"
    echo ""
  }
fi
