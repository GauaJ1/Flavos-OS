# Safe Graphics e Suporte VIA — Flavos OS

## Problema

Em hardware com GPU VIA (comum em plataformas LGA 775), o Xorg pode falhar na autodetecção de driver e modo de vídeo, resultando em:

- "No screens found"
- Falha ao iniciar sessão gráfica
- Sistema parado no TTY

## Drivers Disponíveis

O `packages.list` já inclui `xserver-xorg-video-all`, que puxa:

| Pacote | Driver | Uso |
|--------|--------|-----|
| `xserver-xorg-video-openchrome` | `openchrome` | VIA UniChrome / Chrome9 |
| `xserver-xorg-video-vesa` | `vesa` | Fallback genérico VESA |
| `xserver-xorg-video-fbdev` | `fbdev` | Framebuffer Linux |

Não é necessário adicionar pacotes extras. O problema é de **autodetecção**, não de pacote ausente.

## Boot Entries da Live

A ISO Live oferece entradas de boot específicas para diagnóstico:

| Entrada | Parâmetro | Efeito |
|---------|-----------|--------|
| Flavos OS Live | (padrão) | Autodetecção normal |
| Flavos OS Live (Safe Graphics) | `nomodeset` | Desativa KMS, força VESA/FBDEV |
| Flavos OS Live (VIA/OpenChrome) | `flavos.graphics=openchrome nomodeset` | Força driver OpenChrome |
| Flavos OS Live (VESA) | `flavos.graphics=vesa nomodeset` | Força driver VESA |
| Flavos OS Live (Framebuffer) | `flavos.graphics=fbdev nomodeset` | Força driver FBDEV |
| Flavos OS Live (TTY Recovery) | `systemd.unit=multi-user.target nomodeset` | Sem Xorg, direto ao TTY |

## Script: `flavos-safe-graphics-setup`

Localização: `/usr/local/bin/flavos-safe-graphics-setup`

Este script roda **antes do Xorg** (via autostart ou getty) e:

1. Lê `/proc/cmdline`
2. Se encontrar `flavos.graphics=<driver>`, cria `/etc/X11/xorg.conf.d/20-flavos-safe-graphics.conf`
3. Se não encontrar parâmetro, não faz nada

O script **não** roda no sistema instalado sem parâmetro explícito.

## Configurações de Fallback

### VIA/OpenChrome

```conf
Section "Device"
    Identifier "Flavos VIA OpenChrome"
    Driver "openchrome"
    Option "NoAccel" "true"
EndSection

Section "Screen"
    Identifier "Screen0"
    Device "Flavos VIA OpenChrome"
    DefaultDepth 16
    SubSection "Display"
        Depth 16
        Modes "1024x768" "800x600"
    EndSubSection
EndSection
```

### VESA

```conf
Section "Device"
    Identifier "Flavos VESA"
    Driver "vesa"
EndSection
```

### Framebuffer (FBDEV)

```conf
Section "Device"
    Identifier "Flavos FBDEV"
    Driver "fbdev"
    Option "fbdev" "/dev/fb0"
EndSection
```

## Recuperação Manual no TTY

Se nenhuma entrada de boot funcionar e você estiver no TTY:

```bash
# Verificar GPU
lspci | grep -iE "vga|display|3d|via"

# Testar OpenChrome manualmente
sudo mkdir -p /etc/X11/xorg.conf.d
sudo tee /etc/X11/xorg.conf.d/20-flavos-safe-graphics.conf << 'EOF'
Section "Device"
    Identifier "Flavos VIA OpenChrome"
    Driver "openchrome"
    Option "NoAccel" "true"
EndSection
EOF

# Tentar iniciar Xorg
startx
```

Se `openchrome` falhar, repetir com `vesa` ou `fbdev`.

## Limitações

- OpenChrome: resolução máxima pode ser limitada (1024x768 ou inferior)
- VESA: sem aceleração, sem composição
- FBDEV: resolução fixa do console, sem aceleração
- Picom (compositor): pode não funcionar em VESA/FBDEV
- Performance Profile deve ser "light" nesses casos

## Diagnóstico

```bash
# Log do Xorg
cat /var/log/Xorg.0.log | grep -iE "error|fatal|no screens|no devices"

# Drivers carregados
grep "Loading.*module" /var/log/Xorg.0.log

# Framebuffer disponível
ls /dev/fb*
cat /sys/class/graphics/fb0/name 2>/dev/null
```
