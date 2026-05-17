# Relatório de Teste Físico — Etapa 14H.0

## Contexto

Após a conclusão da Etapa 14G (Bootloader & First Boot) em VM UEFI, foi realizado o primeiro teste do Flavos OS em hardware real dedicado para testes. O objetivo era validar se o Live Boot e a cadeia de instalação funcionavam fora de ambiente virtualizado.

## Hardware

| Item | Detalhe |
|------|---------|
| Plataforma | LGA 775 |
| Placa-mãe | ASUS, modelo ainda não identificado |
| CPU | Intel Pentium Dual-Core |
| Clock reportado | ~400 MHz (provável clock reduzido por economia/BIOS; confirmar com `lscpu` e `/proc/cpuinfo`) |
| GPU/Vídeo | VIA (chipset integrado) |
| HD alvo | `/dev/sda` |
| Pendrive Live | `/dev/sdb` |
| Teclado físico | ABNT / ABNT2 |
| Layout ativo no TTY | US |
| `loadkeys` | ausente na ISO |
| Firmware | BIOS Legacy (sem `/sys/firmware/efi`) |

## Modo de Boot

- Pendrive USB com ISO Live do Flavos OS.
- Boot via BIOS Legacy (USB HDD/USB-ZIP).
- Live Boot chegou ao TTY (multi-user).
- Xorg **não** iniciou.

## Discos Detectados

| Dispositivo | Papel |
|-------------|-------|
| `/dev/sda` | HD interno (alvo de instalação) |
| `/dev/sdb` | Pendrive USB (Live Boot) |

---

## Erros Encontrados

### 3.1 — Xorg falhou em hardware VIA

**Sintoma:** Xorg não iniciou. Erro relacionado a driver VIA / screen não encontrada. Sistema parou no TTY.

**Diagnóstico provável:**
- GPU VIA antiga sem autodetecção adequada pelo Xorg.
- `xserver-xorg-video-all` está instalado (inclui `openchrome`, `vesa`, `fbdev`), mas o Xorg não conseguiu selecionar um driver funcional automaticamente.
- Provavelmente necessário `xorg.conf.d` de fallback.

**Correção:** Criar `flavos-safe-graphics-setup` + entradas de boot dedicadas.

---

### 3.2 — Teclado ABNT no TTY ficou em layout US

**Sintoma:** Teclado ABNT2 conectado, mas layout US ativo. Caracteres como `/`, `|`, `>`, `;`, `:` difíceis de digitar. `loadkeys` não encontrado.

**Impacto:** Instalação manual via TTY ficou extremamente propensa a erros.

**Correção:** Adicionar pacote `kbd` (fornece `loadkeys`) + `console-setup` + `keyboard-configuration`. Documentar procedimento de emergência.

---

### 3.3 — `flavos-installer-lab` bloqueou em máquina real

**Sintoma:** O instalador recusou execução fora de VM.

**Diagnóstico:** Comportamento **correto**. A proteção `require_vm()` funcionou como projetado.

**Decisão:** Manter bloqueio. Modo de instalação física será criado em etapa futura separada com confirmações mais fortes.

---

### 3.4 — Instalação manual tentada em `/dev/sda`

**Cenário:** Foi orientado layout de particionamento compatível com BIOS e UEFI:
- `/dev/sda1` — BIOS Boot, 2 MiB, tipo EF02
- `/dev/sda2` — ESP FAT32, 512 MiB, tipo EF00
- `/dev/sda3` — ROOT ext4, restante

**Status:** Particionamento não finalizado com sucesso. Processo interrompido por erro de leitura da mídia Live durante rsync. Instalação física **não concluída**.

---

### 3.5 — rsync `-X` falhou com erro de xattr

**Erro:** `rsync error: protocol incompatibility (code 2)` — `receiver could not find xattr #99` — arquivo citado: `usr/share/icons/Papirus/...`

**Diagnóstico:** O flag `-X` (extended attributes) causa problemas no ambiente Live com squashfs. Para o fluxo de instalação inicial, xattrs avançados não são necessários.

**Correção:** Remover `-X` do rsync. Usar `rsync -aH --numeric-ids`.

---

### 3.6 — Erros graves de SquashFS / Input-output error

**Mensagens:**
- `SQUASHFS error: Unable to read fragment cache entry`
- `SQUASHFS error: Unable to read page`
- `Input/output error (5)`
- `failed verification -- update discarded`
- Arquivos afetados em `/usr/share/locale/...`

**Diagnóstico:** Falha de leitura da mídia Live. Causas prováveis:
- Pendrive danificado ou com setores ruins
- Porta USB instável
- ISO gravada com erro
- Problema físico no USB antigo

**Conclusão:** A instalação **não deve continuar** quando houver erro de SquashFS. Continuar resulta em sistema corrompido.

**Correção:** Criar `flavos-live-media-check` com modos `--quick` e `--full`. Instalador deve chamar `--full` obrigatoriamente antes de qualquer rsync.

---

### 3.7 — apt update falhou por data/hora incorreta

**Sintoma:** `apt update` falhou com mensagens indicando ~323 dias de diferença temporal. Impediu instalar qualquer pacote durante o teste.

**Diagnóstico provável:**
- Relógio BIOS/CMOS incorreto (bateria fraca)
- Live sem NTP ativo na inicialização
- Rede/NTP não corrigiu a hora antes do apt

**Correção:** Documentar procedimento de correção manual de data. Adicionar checagem de data ao `flavos-live-media-check`.

---

## Decisões Tomadas

1. Não liberar instalação física automática.
2. Não remover proteções VM-only do instalador.
3. Não declarar hardware-ready.
4. Criar verificador de mídia obrigatório antes de qualquer payload-sync.
5. Corrigir rsync para não usar `-X`.
6. Adicionar `kbd` para suporte TTY ABNT.
7. Criar mecanismo real de Safe Graphics (script + boot entries).
8. Documentar que BIOS Legacy precisa de GRUB (Etapa 14I).

## Veredito

Teste físico parcialmente bem-sucedido para boot/TTY, mas instalação física bloqueada por:
- Falha de integridade da mídia Live
- Falta de fallback gráfico para GPU VIA
- Teclado TTY sem `loadkeys`
- Relógio BIOS incorreto impedindo `apt update`
- Ausência de suporte GRUB/BIOS Legacy

O Flavos OS Live/Installer está validado em VM. Hardware real permanece experimental e bloqueado até nova validação.
