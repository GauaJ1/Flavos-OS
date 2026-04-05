# Flavos OS Design System

Este documento rege as leis matemáticas e semânticas da UI (Interface Gráfica) do Flavos OS. 
Deve ser respeitado na evolução do Desktop Shell e de Aplicativos Nativos.

## 1. Princípios de Identidade

1. **Escuridão Confortável:** Fujo do "preto puro" (#000) e do "cinza monótono" (#333). O Flavos utiliza um fundo Navy Slate, que simula o painel técnico de um avião ou estúdio.
2. **Consistência acima da Ornamentação:** Nada pisca, nada transluz ou flutua intensamente se não houver motivo.
3. **Flat, com Delimitação:** A interface inteira recusa sombras sujas; a definição de profundidade é feita pela hierarquia das cores base (Canvas < Surface < Elevated) delimitadas por bordas subdimensionadas de 1px.

## 2. Design Tokens (Paleta Oficial)

### Superfícies Escuras
A profundidade dita o nível de "elevação visual" de um elemento.

| Token | Hexadecimal | Uso Semântico |
|---|---|---|
| `color.bg.canvas` | `#0e1015` | O fundo absoluto. O chão do wallpaper vazio e o fundo mestre traseiro dos Settings. |
| `color.bg.surface` | `#161922` | O painel (tint2), menu do openbox e containers base de UI. |
| `color.bg.elevated` | `#212431` | Elementos de controle iteráveis, blocos (Cards) dentro de configurações. |

### Destaque (Accent) & Bordas
A cor da ação precisa captar a atenção cirurgicamente.

| Token | Hexadecimal | Uso Semântico |
|---|---|---|
| `color.action.accent` | `#4f86f7` | "Flavos Blue" - Marcador de abas selecionadas, Botões primários, seleções do texto. |
| `color.border.subtle` | `#2b2f40` | O traço de 1px que separa o tint2 do desktop ou circunda as caixas do Gtk. |

### Texto e Status
| Token | Hexadecimal | Uso Semântico |
|---|---|---|
| `color.fg.primary` | `#eaecf0` | Cor universal dos rótulos. |
| `color.fg.secondary`| `#858a9d` | Textos inativos, notas de rodapé, placeholders de input. |
| `color.state.error` | `#f87171` | Botões destrutivos (Power off) e Alertas de Falha. |

## 3. Geometria (Shapes and Spacing)
- **Radii (Arredondamento):**
  - Janelas (Openbox): `4px`
  - Botões, Cards e Menus (Gtk / Jgmenu): `4px`
- **Paddings Espaciais (Base-8):**
  - Padding minímo (densos): `4px`, `8px`
  - Margens macro (afastamento de caixa d'água estrutural): `32px`, `24px`
  - Bordas de Window Manager: Stroke Width = `1px`

## 4. Tipografia
- **Família Gráfica:** `Inter` (sans-serif geométrica para alta legibilidade em monitores de qualquer DPI). 
- **Console / Raw Data:** A ser manipulado no futuro (ex. Roboto Mono para os logs).

## 5. Implementação nos Componentes (Mapeamento Prático)

* **Openbox (themerc):** Usa o `bg.surface` para a Window ativa e as linhas `border.subtle` pra enquadrar janelas e menu interno. O botão Hover da janela reage com `action.accent`.
* **Tint2 (Shell Panel):** O Background recebe exatamente `bg.surface` para sumir fisicamente caso uma janela bata nele sem gerar degrau sujo de design.
* **Flavos Settings (GTK/Python):** Injeção pontual através do provider `Gtk.CssProvider()` que amarra 100% o Python a essa documentação via nodes `window, box.card, button, etc`.
