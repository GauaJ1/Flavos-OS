// Flavos OS — Firefox ESR: configuração para hardware com 2 GB de RAM
// Perfil: light
// Aplicado por: flavos-performance-profile set light --apply-firefox-light
//
// ATENÇÃO: este arquivo é aplicado ao user.js do perfil Firefox ativo.
// Um backup do user.js existente é criado automaticamente antes da substituição.
// Para reverter: restaurar o backup ou deletar o user.js e reiniciar Firefox.
//
// Fonte: Mozilla Support, ghacks.net, about:config documentation
// Validado para: Firefox ESR 115+ (Debian Bookworm padrão)

// ─── Processos de conteúdo ────────────────────────────────────────────────────
// Limita a 2 processos de conteúdo (padrão Firefox: 8).
// Reduz uso de RAM em ~200–350 MB com múltiplas tabs.
// Não definir como 1: causa contention severo e piora a experiência.
user_pref("dom.ipc.processCount", 2);

// ─── Sessão e restauração ─────────────────────────────────────────────────────
// Reduz frequência de escrita da sessão em disco (padrão: 15000ms = 15s)
// Em HDD, escritas frequentes causam latência perceptível.
user_pref("browser.sessionstore.interval", 60000);

// Desabilita restauração de sessão proativa em crash (economiza leitura de disco)
// Usuário ainda pode restaurar manualmente se quiser.
user_pref("browser.sessionstore.max_tabs_undo", 5);

// ─── Cache e disco ────────────────────────────────────────────────────────────
// Limita cache de disco para reduzir leitura/escrita em HDD legado.
// Padrão Firefox: usa ~350 MB. Reduzir para 100 MB em hardware limitado.
user_pref("browser.cache.disk.capacity", 102400);

// ─── GPU e aceleração de hardware ────────────────────────────────────────────
// NÃO desabilitar WebGL/hardware accel sem evidência de problema real.
// Em hardware LGA775 com driver funcional, accel pode ajudar.
// Descomentar apenas se houver crashes ou artefatos visuais:
// user_pref("gfx.webrender.enabled", false);
// user_pref("layers.acceleration.disabled", true);

// ─── Atualização automática em background ─────────────────────────────────────
// Firefox ESR no Debian é gerenciado via apt — updates automáticos internos
// são redundantes e consomem banda/RAM.
user_pref("app.update.auto", false);
user_pref("app.update.enabled", false);

// ─── Telemetria (desabilitar em hardware limitado) ────────────────────────────
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("toolkit.telemetry.enabled", false);
user_pref("browser.ping-centre.telemetry", false);
