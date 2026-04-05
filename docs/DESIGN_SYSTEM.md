# Flavos OS — Design System v3

Documento canônico da linguagem visual do Flavos OS.
Todos os componentes visuais (shell, apps, compositor, WM) devem respeitar estes tokens.

---

## 1. Princípios de Identidade

1. **Dark-native:** O tema escuro é o estado primário. Tons profundos de grafite-azulado, nunca preto puro (`#000`).
2. **Calma com presença:** Superfícies transmitem solidez e confiança. Nenhum elemento pisca, brilha ou flutua sem propósito.
3. **Hierarquia por elevação de cor:** A profundidade é comunicada pela progressão Canvas → Surface → Elevated, reforçada por bordas sutis de 1px. Sem sombras sujas.
4. **Accent cirúrgico:** A cor de destaque aparece apenas em seleções ativas, indicadores de foco e ações primárias. Nunca em áreas largas.
5. **Densidade controlada:** Grid base-8. Espaçamento generoso o suficiente para respirar, denso o suficiente para ser eficiente.

---

## 2. Paleta de Cores (Tokens Oficiais)

### Superfícies

| Token                  | Hex       | Uso                                                        |
|------------------------|-----------|------------------------------------------------------------|
| `color.bg.canvas`      | `#0D1017` | Fundo absoluto. Desktop, fundo de janelas.                 |
| `color.bg.surface`     | `#151921` | Painéis, menus, sidebars, containers primários.            |
| `color.bg.elevated`    | `#1C2030` | Cards, popovers, itens selecionados, barras de título.     |
| `color.bg.overlay`     | `#232838` | Hover states, overlays contextuais, OSD.                   |

### Texto

| Token                  | Hex       | Uso                                                        |
|------------------------|-----------|------------------------------------------------------------|
| `color.fg.primary`     | `#E8ECF4` | Texto principal, rótulos, títulos.                         |
| `color.fg.secondary`   | `#8891A5` | Texto auxiliar, descrições, placeholders.                  |
| `color.fg.muted`       | `#505872` | Texto desabilitado, bordas inativas.                       |

### Accent e Bordas

| Token                  | Hex       | Uso                                                        |
|------------------------|-----------|------------------------------------------------------------|
| `color.accent`         | `#4B8BF5` | Seleção ativa, foco, indicadores, botões primários.        |
| `color.accent.hover`   | `#6BA1FF` | Hover sobre elementos accent.                              |
| `color.border.subtle`  | `#272D3D` | Bordas de containers, separadores, divisões.               |
| `color.border.strong`  | `#3A4260` | Bordas de foco, campos de input ativos.                    |

### Semântica

| Token                  | Hex       | Uso                                                        |
|------------------------|-----------|------------------------------------------------------------|
| `color.state.error`    | `#F87171` | Ações destrutivas, alertas críticos.                       |
| `color.state.success`  | `#4ADE80` | Confirmações, indicadores de status OK.                    |
| `color.state.warning`  | `#FBBF24` | Avisos, atenção necessária.                                |

---

## 3. Tipografia

| Token               | Valor              | Uso                                          |
|----------------------|--------------------|----------------------------------------------|
| `font.family.ui`     | `Inter`            | Toda a interface gráfica.                    |
| `font.family.mono`   | `Monospace`        | Terminal, dados brutos, código.              |
| `font.size.xs`       | `9px`              | Badges, contadores mínimos.                  |
| `font.size.sm`       | `10px`             | Captions, labels do painel.                  |
| `font.size.md`       | `12px`             | Corpo de texto, menus, botões.               |
| `font.size.lg`       | `14px`             | Subtítulos, labels de seção.                 |
| `font.size.xl`       | `18px`             | Títulos de página.                           |
| `font.size.2xl`      | `24px`             | Títulos principais, headers.                 |
| `font.weight.normal` | `400`              | Texto corrido.                               |
| `font.weight.medium` | `500`              | Labels, menu items.                          |
| `font.weight.semi`   | `600`              | Botões, subtítulos ativos.                   |
| `font.weight.bold`   | `700`              | Títulos, destaque forte.                     |

---

## 4. Forma e Espaçamento

### Raios de borda

| Token        | Valor  | Uso                                       |
|--------------|--------|-------------------------------------------|
| `radius.sm`  | `4px`  | Botões inline, badges, chips.             |
| `radius.md`  | `8px`  | Cards, menus, entries.                    |
| `radius.lg`  | `12px` | Diálogos, popovers, power menu.          |
| `radius.xl`  | `16px` | Janelas (via compositor).                 |

### Espaçamento (base-8)

| Token      | Valor  |
|------------|--------|
| `space.2`  | `2px`  |
| `space.4`  | `4px`  |
| `space.8`  | `8px`  |
| `space.12` | `12px` |
| `space.16` | `16px` |
| `space.24` | `24px` |
| `space.32` | `32px` |
| `space.48` | `48px` |

---

## 5. Motion Tokens

| Token            | Valor            | Uso                                        |
|------------------|------------------|--------------------------------------------|
| `motion.micro`   | `100ms`          | Hover, press feedback.                     |
| `motion.fast`    | `150ms`          | Menus, toggles, small controls.            |
| `motion.normal`  | `200ms`          | Diálogos, painéis, popovers.              |
| `motion.slow`    | `300ms`          | Transições de janela, workspace.           |
| `easing.standard`| `ease-in-out`    | Feedback, transições padrão.               |
| `easing.enter`   | `ease-out`       | Elementos surgindo.                        |
| `easing.exit`    | `ease-in`        | Elementos saindo.                          |

### Compositor (Picom)
- Fade-in: `0.028` step (~180ms)
- Fade-out: `0.038` step (~130ms)
- Shadow: `radius 18`, `opacity 0.40`, offset `-16`
- Corner radius: `10px`

---

## 6. Elevação e Sombras

| Token       | Comportamento                                 |
|-------------|-----------------------------------------------|
| `shadow.0`  | Sem sombra. Elementos inline.                 |
| `shadow.1`  | Compositor: sombra padrão de janela.          |
| `shadow.2`  | Menus flutuantes, popovers.                   |
| `shadow.3`  | Diálogos modais, power menu.                  |

A profundidade é primariamente comunicada por diferença de cor de fundo (Canvas → Surface → Elevated), com sombras do compositor como reforço sutil.

---

## 7. Mapeamento para Componentes

| Componente          | Canvas    | Surface   | Elevated  | Accent   | Border Subtle |
|---------------------|-----------|-----------|-----------|----------|---------------|
| Desktop (fundo)     | `#0D1017` |           |           |          |               |
| Tint2 (painel)      |           | `#151921` |           |          | `#272D3D`     |
| Jgmenu (menu)       |           | `#151921` | `#232838` |          | `#272D3D`     |
| Openbox titlebar    |           |           | `#1C2030` |          | `#272D3D`     |
| Settings sidebar    |           | `#151921` |           | `#4B8BF5`| `#272D3D`     |
| Settings cards      |           |           | `#1C2030` |          | `#272D3D`     |
| Buttons (default)   |           |           | `#1C2030` |          | `#272D3D`     |
| Buttons (hover)     |           |           | `#232838` |          |               |
| Terminal (fundo)    |           | `#151921` |           |          |               |
| Power Menu          | `#0D1017` |           | `#1C2030` |          | `#272D3D`     |
