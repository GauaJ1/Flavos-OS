# Flavos OS — Release Notes (0.1.0-rc1 "Ignition")

## Visão Geral (Veredito do RC1)
Após extenuante rodada de desenvolvimento da Etapa 1 à Etapa 8, declaramos alcançada a completude técnica da **Fase 1: Console**. O Flavos OS atinge o status de ***Release Candidate 1*** em sua edição mínima `Ignition`. 

Nesta versão, a imagem raw gerada possui plena capacidade operacional baseada num stack userspace de linha de comando blindado e auditável, tendo passado com sucesso na prova de fogo do Laboratório QEMU de hardware dinâmico. O sistema é robusto o suficiente para empacotamento, embora ainda aguarde certificação oficial em Hardware Bare-metal real.

---

## O que a V1 Console Entrega (Escopo Declarado)
- **Init System Seguro:** SystemD e SystemD-boot manipulando perfeitamente a leitura dinâmica via base unicamente PartUUIDs (FSTAB estrito, sem UUID de FS arcaico).
- **Core de Rede Automatizado:** `systemd-networkd` apanhando leases IPv4 dinamicamente usando interface nativa e atrelação de mac-address com resolved atrelado.
- **Isolamento de Segurança:** Login SSH desprovido de premissas inseguras. Conta Root bloqueada perante rede, dependendo inteiramente do sys-user isolado.
- **Logs Controlados e Recovery:** Size-cap de 50mb imposto no `journald` com flush automático no disco persistente, somados a scripts nativos de QA (`flavos-net-check` e `flavos-debug-report`) dentro da root part.
- **Write-to-Disk (Live Burner):** Capacidade inata de flash persistente de imagem em dispositivos secundários através do script interno protegido contra wiping acidental da Host.
- **Flexibilidade de Hardware:** Modulos initramfs (`ahci`, `nvme`, `xhci_hcd`) mapeando controladoras puras, somados ao autodiscovery nativo de Partições EFI reajustado contra falhas em NVRAM de Firmware (Expurgo do Bug de PXE Fallback).

---

## Limitações Conhecidas & Bugs (Known Issues)
Seja íntegro sobre as limitações do RC. O que está escrito abaixo não é "falha", mas sim comportamento esperado para esta janela de maturidade:

1. **[Limitação] Ausência Total de Wireless (Wi-Fi):**
   - **Descrição:** Placas WPA-Sup e adaptadores WLAN não foram instanciadas no init stack. Se você tentar plugar via hardware sem cabo CAT5 cravado, não terá IP dinâmico nem repositórios.

2. **[Limitação] Sem GUI ou Window Manager:**
   - **Descrição:** O `rc1-ignition` não roda Wayland, X11 ou qualquer Desktop. O Mouse virtual/óptico só serve para selecionar texto e copiar no TTY cru (provido pelo driver GPM).

3. **[Falso Bug] Hash Flutuante:**
   - **Descrição:** O manifesto pode apontar um hash SHA256 que nunca mais se repetirá 1:1 se você executar um novo Make no dia seguinte. Motivo: O empacotador base (`debootstrap`) puxa de repositórios dinâmicos do Debian (mirrors) que rotacionam assinaturas de pacotes internamente. A reprodutibilidade do sistema é funcional e mecânica, mas não hegemônica nos metadados.

4. **[Limitação] Módulo Secure Boot:**
   - **Descrição:** O Flavor Systemd-boot incorporado não assina chaves próprias. Requer desabilitar SecureBoot nos hardwares anfitriões ou o bloqueio de UEFI acontecerá sumariamente.

---

## Instruções Oficiais de Teste e Validação

Pedimos que testadores avançados gerem as compilações ou baixem nosso manifesto via binário exportado.
A fim de resguardar o tester, sigam rigorosamente a mecânica abaixo:

### 1. Pré-Requisitos de Gravação
- **Atenção Máxima:** Sob hipótese alguma grave/teste este Release Candidate no SSD primário onde você trabalha diariamente ou armazena fotos.
- **Hardware Ideal:** Pensamos no uso de "Máquinas de Cobaia" secundárias, pen-drives SanDisk de alta velocidade ou M.2 Externos Isolados.

### 2. Gravando na Prática
Compile o RC via pipeline:
```bash
make all
```

Após constatar o manifest de `0.1.0-rc1` gerado na pasta `/build`, espete um disco secundário ou pen-drive `/dev/sdX` e incendeie ele na porta via Host Linux:
```bash
make write-disk DISK=/dev/sdX
```
Siga os 3 prompts de alerta vermelho digitando confirmatoriamente as frases exigidas.

### 3. Reportando Resultados
O uso em ambiente VM foi categoricamente expurgado de falhas em nossa "Etapa 8A1".
- Se você conseguiu plugar o dispositivo físico em um note da Asus, Lenovo, Dell e extraiu TTY via placa de rede, abra uma issue no Github.
- Copie o esqueleto textual guardado em `docs/TEST_REPORT_TEMPLATE.md` e preencha integralmente, despejando a saída que você extraiu executando o `flavos-debug-report` na máquina cobaia.
- Ajudaremos a homologar ou descobrir um hardware exótico que possa ser incluído no roadmap da `1.0`.
