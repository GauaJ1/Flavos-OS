# Plano de Teste em Hardware Físico — Etapa 14K

Este documento define o roteiro passo a passo para a validação da **instalação física do Flavos OS** em hardware real (LGA 775, BIOS Legacy), que será executado na Etapa 14K.

## 1. Preparação (Pré-Teste)

Antes de iniciar o teste no PC alvo, certifique-se de ter:
1. **Pendrive Live (Flavos OS):** Gravado com a ISO mais recente (pós-Etapa 14J). Recomenda-se usar o BalenaEtcher ou `dd`.
2. **Conexão com a Internet:** Cabo de rede (Ethernet) conectado ao PC (o Live OS usa DHCP automático via `systemd-networkd`).
3. **Hardware Alvo (LGA 775):**
   - Teclado e mouse USB conectados.
   - Monitor conectado.
   - Disco rígido interno (HD/SSD) que pode ser **completamente apagado** (destrutivo).

## 2. Boot do Live OS

1. Ligue o PC e acesse o menu de boot da BIOS (geralmente `F8`, `F11` ou `F12`).
2. Selecione o pendrive USB.
3. No menu do GRUB, você verá várias opções.
4. **Para hardware VIA/antigo (LGA 775):**
   - Selecione a opção: `Flavos OS Live (Safe Graphics - VIA/OpenChrome)` ou `Flavos OS Live (Safe Graphics - VESA)`.
   - Isso adiciona as flags corretas para contornar a falha do Xorg em GPUs VIA antigas.
5. Aguarde o boot. O desktop XFCE/Openbox deve aparecer.

### Troubleshooting de Boot
- **Se parar no TTY (tela preta com texto):** O layout ABNT2 agora funciona (`loadkeys br-abnt2` automático/disponível). Tente iniciar o X manualmente se necessário (`startx`) ou inspecione logs (`journalctl -xe`).
- **Data e Hora incorretas:** Verifique se o relógio da BIOS está defasado. Se estiver, o `apt` e o instalador podem falhar. Corrija a hora no terminal se necessário:
  ```bash
  sudo date -s "YYYY-MM-DD HH:MM:SS"
  ```

## 3. Validações Pré-Instalação (Ambiente Live)

Antes de iniciar o instalador, abra um terminal e rode:

1. **Checar a Integridade da Mídia:**
   ```bash
   sudo flavos-live-media-check --full
   ```
   *Deve retornar sucesso. Se falhar, o pendrive está corrompido ou mal gravado. **Não prossiga com a instalação.***

2. **Gerar Relatório de Hardware (Opcional):**
   ```bash
   flavos-hw-report
   ```
   *Isso confirmará se rede, discos e placa de vídeo foram detectados corretamente.*

3. **Verificar os Discos:**
   ```bash
   lsblk
   ```
   *Identifique qual é o seu disco interno (ex: `/dev/sda`) e qual é o pendrive (ex: `/dev/sdb`). Cuidado para não errar o disco alvo.*

## 4. Execução da Instalação Física (Destrutiva)

Abra o terminal e execute o novo instalador físico preview:

```bash
sudo flavos-physical-install-preview
```

### O que esperar do instalador:
1. **Disclaimer e Aceite:** Digite `ESTOU CIENTE` quando solicitado.
2. **Seleção de Disco:** Digite o caminho do disco interno (ex: `/dev/sda`).
3. **Modo de Boot (BIOS vs UEFI):**
   - Como é uma placa LGA 775, o instalador deve perguntar ou assumir BIOS. Escolha o modo `bios` ou `both` (híbrido).
4. **Confirmação Final:** Confirme os dados e deixe o processo rodar.
5. **Logs e Andamento:** O script fará particionamento (GPT com EF02), formatação, sync do rootfs (sem `-X` xattr errors), instalará o GRUB (i386-pc) e ajustará o fstab/machine-id.
6. **Sucesso:** Após a mensagem de sucesso, reinicie o PC:
   ```bash
   sudo reboot
   ```

## 5. Pós-Instalação e OOBE (First Boot)

1. Remova o pendrive durante o reboot.
2. O PC deve fazer boot pelo GRUB do disco rígido local.
3. O desktop será carregado automaticamente (login automático configurado no perfil).
4. **Wizard de OOBE:** A janela de First Boot deve aparecer na tela.
5. Clique em **Finalizar** no Wizard. O `pkexec` atuará silenciosamente (graças à policy `allow_active=yes`).
6. Reinicie o PC novamente.
7. Confirme se o OOBE **não** abriu mais.

## 6. Registro de Resultados

Após o teste, use o template `docs/HARDWARE_TEST_REPORT_TEMPLATE.md` para anotar os resultados, tempos e eventuais falhas (kernel panics, erros de Xorg, falhas de rsync). Se tudo der verde, a Etapa 14K estará concluída e o foco mudará para a Etapa 14H (refinar o conteúdo real do wizard OOBE).
