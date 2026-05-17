# Recuperação de Teclado no TTY — Flavos OS

## Problema

Se o Xorg não iniciar e o sistema cair no TTY, o layout de teclado pode estar em US mesmo com teclado ABNT/ABNT2 físico. Isso dificulta digitação de caracteres essenciais.

## Solução Rápida

```bash
loadkeys br-abnt2
```

Fallback:

```bash
loadkeys br
```

## Verificar Instalação

Se `loadkeys` não for encontrado:

```bash
dpkg -l kbd 2>/dev/null
```

Se não instalado, tente (requer data/hora corretos e rede):

```bash
sudo apt update && sudo apt install -y kbd
loadkeys br-abnt2
```

## Keymaps Disponíveis

Para listar todos os keymaps:

```bash
find /usr/share/keymaps -name "*.map.gz" | sort
```

Para buscar ABNT especificamente:

```bash
find /usr/share/keymaps -name "*abnt*" -o -name "*br-*" | sort
```

## Tabela de Caracteres Problemáticos

Quando o layout está em US com teclado ABNT, estes caracteres ficam trocados:

| Caractere | Posição ABNT | O que sai em US |
|-----------|-------------|-----------------|
| `/` | Tecla ao lado do shift direito | Depende do mapeamento |
| `\|` (pipe) | Shift + `\` | Pode não funcionar |
| `~` | Shift + `´` | Pode estar trocado |
| `;` | Tecla do `ç` | `ç` ou nada |
| `:` | Shift + `ç` | Depende |
| `[` | Tecla do `´` | Pode estar trocado |
| `]` | Tecla do `[` | Pode estar trocado |
| `{` | Shift + `´` | Depende |
| `}` | Shift + `[` | Depende |

## Contornar Sem Pipe

Se o caractere `|` (pipe) não funciona, use redirecionamento:

```bash
# Em vez de:
# dmesg | grep squash

# Use:
dmesg > /tmp/dmesg.txt
grep squash /tmp/dmesg.txt
```

## Contornar Sem Barra

Se `/` não funciona, tente encontrar a tecla correta ou:

```bash
# Definir variáveis para paths comuns
export S=$(printf '\x2f')   # / em hex
# Depois use: ${S}dev${S}sda
```

## Configuração Permanente

Após instalar `kbd` e `console-setup`:

```bash
sudo dpkg-reconfigure keyboard-configuration
```

Selecionar:
- Keyboard model: Generic 105-key PC (intl.)
- Keyboard layout: Portuguese (Brazil)
- Variant: Portuguese (Brazil, ABNT2)

Aplicar:

```bash
sudo setupcon
```

## Helper Futuro

Em versões futuras, o Flavos OS fornecerá:

```bash
flavos-tty-keyboard br-abnt2
```
