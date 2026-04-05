# ~/.bash_profile
# Lançado apenas em sessões interativas de login.
# Aqui damos match no TTY1 para promover o Display Server.

if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
  # Se logou nativamente e o servidor X11 não está de pé, incendeia ele.
  exec startx
fi
