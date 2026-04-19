# Flavos OS — Requisitos de Sistema

A arquitetura do Flavos OS foi desenhada sob um pilar fundamental: **Eficiência Extrema**. 

Como não utilizamos ambientes de desktop pesados (como GNOME ou KDE Plasma), nossa fundação baseada em Xorg, Openbox, Picom e uma shell nativa escrita em GTK+ garante um sistema operacional incrivelmente responsivo e que consome uma fração dos recursos de um OS convencional.

Abaixo estão os requisitos de hardware, calculados com base no stack atual.

---

## 1. Requisitos Mínimos
_Para computadores legados, máquinas virtuais limitadas ou servidores com saída de vídeo improvisada. O sistema iniciará e operará as funções básicas (arquivos, terminal, web leve), embora animações como o `fade` do launcher possam rodar em detecção de software._

- **Processador (CPU):** Qualquer processador x86_64 single-core (1.0 GHz ou superior).
- **Memória RAM:** 1 GB (o consumo inativo típico fica entre 250MB e 350MB).
- **Armazenamento:** 5 GB de espaço livre em disco (instalação base + espaço para logs temporários e cache apt).
- **Gráficos (GPU):** Qualquer placa de vídeo compatível com VGA/SVGA básico. O compositor Picom cairá automaticamente para fallback caso hardware shadow/blur não seja suportado.
- **Rede:** Qualquer adaptador Ethernet ou Wi-Fi.

---

## 2. Requisitos Médios (Recomendado)
_A configuração esperada para desfrutar da experiência completa do Flavos OS, incluindo 60 FPS na transição do launcher, sombras complexas nas janelas, painel translúcido e multitarefa fluida com aplicativos GTK e navegadores_

- **Processador (CPU):** Dual-core x86_64 (2.0 GHz ou superior).
- **Memória RAM:** 4 GB.
- **Armazenamento:** 16 GB SSD (para leitura instantânea dos binários PyGObject no boot).
- **Gráficos (GPU):** Intel HD Graphics (qualquer geração Core), AMD Radeon ou NVIDIA básica (aceleração de driver via Mesa/Xorg).
- **Rede:** Qualquer adaptador Ethernet ou Wi-Fi moderno.

---

## 3. Requisitos Ideais / Desenvolvedor
_Para uso avançado, compilação de código, dezenas de abas no navegador ao mesmo tempo e virtualização paralela, sem perder nenhum frame nas animações nativas estruturadas._

- **Processador (CPU):** Quad-core ou superior (Intel Core i3/i5/i7/i9, AMD Ryzen).
- **Memória RAM:** 8 GB ou 16 GB.
- **Armazenamento:** 32 GB NVMe ou SSD veloz.
- **Gráficos (GPU):** Hardware com suporte moderno a OpenGL e aceleração X11 plena para maximizar os efeitos do `picom` no backend.

---

### Perfil de Consumo Inativo (Idle)
O design arquitetural centralizado resulta na seguinte estimativa conservadora (em ambiente pós-boot, medido via `htop` / livre de swappiness):

| Componente | Custo (Estimativa RAM) | Responsabilidade |
|---|---|---|
| **Linux Kernel + systemd + dbus** | ~80 MB | Espinha dorsal de I/O, IPC e init. |
| **Xorg (Servidor de Vídeo)** | ~40 MB | Desenho na tela e captura de Input. |
| **Openbox (Gestor de Janelas)** | ~15 MB | Posicionamento (tiling/float) de janelas. |
| **Picom (Compositor)** | ~25 MB | Sombras (shadow), cantos arredondados, transparência nativa X11. |
| **Flavos Native Shell (Python/GTK)** | ~80 MB | `session-daemon`, Taskbar v4, Painel Superior. (Launcher hiberna e só aloca durante o uso). |
| **Serviços Base (Network, Audio, Dunst)** | ~60 MB | Gerenciamento passivo. |
| **Total Estimado** | **Aprox. 300 MB** | — |

**O Flavos OS foca em não roubar a capacidade computacional que deveria pertencer de forma exclusiva aos aplicativos do usuário.**
