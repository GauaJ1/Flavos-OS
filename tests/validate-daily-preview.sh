#!/usr/bin/env bash
# Flavos OS — Checklist de validação para Desktop Preview 0.1 "Daily"
# Executar DENTRO da VM após boot-gui com login como 'flavos'
#
# Uso: bash /tmp/validate-daily.sh

set -euo pipefail

PASS=0
FAIL=0
WARN=0

ok()   { echo "[OK]   $1";   ((PASS++)); }
fail() { echo "[FAIL] $1";   ((FAIL++)); }
warn() { echo "[WARN] $1";   ((WARN++)); }

echo "============================================"
echo " Flavos Desktop Preview 0.1 'Daily' — Validação"
echo "============================================"
echo ""

# --- BUILD ---
echo "[ Sessão e Processos ]"
pgrep -x picom        && ok "picom rodando"     || fail "picom não encontrado"
pgrep -f flavos-panel && ok "flavos-panel rodando" || fail "flavos-panel não encontrado"
pgrep -f flavos-taskbar && ok "flavos-taskbar rodando" || fail "flavos-taskbar não encontrado"
pgrep -f flavos-launcher && ok "flavos-launcher pronto" || warn "flavos-launcher (normal se não aberto)"
pgrep -x dunst        && ok "dunst rodando"     || warn "dunst não encontrado"
echo ""

# --- MIME ---
echo "[ MIME defaults ]"
MIME_COUNT=$(grep "^[^#\[]" /etc/xdg/mimeapps.list 2>/dev/null | wc -l)
[ "$MIME_COUNT" -eq 27 ] && ok "27 tipos MIME registrados" || fail "MIME count=$MIME_COUNT (esperado: 27)"

xdg-mime query default x-scheme-handler/https 2>/dev/null | grep -q "firefox" \
  && ok "https → firefox-esr" || fail "https → $(xdg-mime query default x-scheme-handler/https 2>/dev/null)"

xdg-mime query default application/pdf 2>/dev/null | grep -q "flavos-pdf" \
  && ok "PDF → flavos-pdf (evince)" || fail "PDF → $(xdg-mime query default application/pdf 2>/dev/null)"

xdg-mime query default video/mp4 2>/dev/null | grep -q "flavos-media" \
  && ok "video/mp4 → flavos-media (celluloid)" || fail "video/mp4 → $(xdg-mime query default video/mp4 2>/dev/null)"

xdg-mime query default audio/mpeg 2>/dev/null | grep -q "flavos-media" \
  && ok "audio/mpeg → flavos-media (celluloid)" || fail "audio/mpeg → $(xdg-mime query default audio/mpeg 2>/dev/null)"

xdg-mime query default inode/directory 2>/dev/null | grep -q "flavos-files" \
  && ok "inode/directory → flavos-files (nemo)" || fail "inode/directory → $(xdg-mime query default inode/directory 2>/dev/null)"
echo ""

# --- DESKTOP ENTRIES ---
echo "[ Desktop Entries ]"
NODISPLAY_COUNT=$(grep -rl "NoDisplay=true" /usr/share/applications/ 2>/dev/null | wc -l)
[ "$NODISPLAY_COUNT" -ge 7 ] && ok "${NODISPLAY_COUNT} stubs NoDisplay (>= 7)" || fail "stubs NoDisplay=${NODISPLAY_COUNT} (esperado >= 7)"
echo ""

# --- APPS INSTALADOS ---
echo "[ Apps instalados ]"
command -v firefox-esr 2>/dev/null || command -v firefox 2>/dev/null \
  && ok "Firefox instalado" || fail "Firefox não encontrado"
command -v nemo   2>/dev/null && ok "Nemo instalado"      || fail "Nemo não encontrado"
command -v mousepad 2>/dev/null && ok "Mousepad instalado"  || fail "Mousepad não encontrado"
command -v viewnior 2>/dev/null && ok "Viewnior instalado"  || fail "Viewnior não encontrado"
command -v evince   2>/dev/null && ok "Evince instalado"    || fail "Evince não encontrado"
command -v celluloid 2>/dev/null && ok "Celluloid instalado" || warn "Celluloid não no PATH (verifique manualmente)"
command -v kitty    2>/dev/null && ok "Kitty instalado"     || fail "Kitty não encontrado"
echo ""

# --- SEGURANÇA MÍNIMA ---
echo "[ Segurança ]"
grep -q "PermitRootLogin no" /etc/ssh/sshd_config.d/*.conf 2>/dev/null \
  && ok "PermitRootLogin no (drop-in)" || warn "Verificar /etc/ssh/sshd_config.d/ manualmente"
[ "$(whoami)" != "root" ] && ok "Usuário não é root" || fail "Rodando como root"
echo ""

# --- RESULTADO ---
echo "============================================"
echo " Resultado: ${PASS} OK | ${WARN} WARN | ${FAIL} FAIL"
echo "============================================"
[ "$FAIL" -eq 0 ] && echo " VEREDITO: PASSA para tag" || echo " VEREDITO: CORRIGIR antes de taguear"
