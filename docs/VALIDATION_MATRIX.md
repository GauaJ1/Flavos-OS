# Flavos OS — Matriz de Validação em Hardware Real (Fase 1: Ignition)

Este documento dita as diretrizes e taxonomia obrigatórias para declarar suporte formal de hardware para o Flavos OS. Ele separa o que hipotetizamos usando máquinas virtuais do comportamento imprevisível do metal físico.

## 1. Escopo de Transição: VM vs Hardware Real

| Domínio | Previamente Garantido por QEMU/KVM | Novo Desafio no Hardware Real |
|---|---|---|
| **Bootloader** | OVMF sempre injeta EFI no setup virtio. | Placas-mãe exóticas bloqueando custom EFI por falha na NVRAM. |
| **Kernel/Storage** | Discos virtuais Raw e Block devices simulados. | Timings erráticos de inicialização de USB Pendrives ou Placas NVMe. |
| **Input/Console** | Teclado emulado e mouse sem delay inerente. | Conflitos IRQ de teclados/USB legacy ou mouses perdendo rate polling. |
| **Rede** | Veth bridges sempre plugadas e DHCP nativo do host. | Handshake das placas físicas `en*`, queda de link em cabos CAT5. |

---

## 2. Taxonomia de Classificação

Todo diagnóstico de ciclo de QA exige o preenchimento explícito utilizando as seguintes Severidades e Status Padrão:

### Status
- ✅ **Aprovado:** Passa impecavelmente sem intervenção do testador.
- ⚠️ **Aprovado com Ressalvas:** Necessita de tweaks (ex. Kernel args para plugar ACPI bugado) ou só passa repetindo processo.
- ❌ **Falhou:** Fere ou não completa o checklist. Bug reproduzível.
- ⏳ **Não Testado:** Teste esquecido ou sem hardware disponível para cumprir critério.

### Severidade
- 💥 **Crítica:** Máquina quebra durante inicialização ou Kernel Panic bloqueia acesso.
- 🔴 **Alta:** Funcionalidade perdida (ex: Interface de rede não levanta, FSTAB corrompe montagem Read/Write).
- 🟡 **Média:** Queda de qualidade (ex: Input de mouse TTY gaguejando, boot muito lento pendurado em timers do systemd).
- 🟢 **Baixa:** Erro puramente cosmético ou verbose do kernel assustador porém redundante.

---

## 3. Matriz de Validação Base

Todo ciclo completo de Homologação de uma Plataforma deve submeter a mídia gerada ao crivo desta matriz:

| Classe | Tópico de Validação | Severidade | Eixo |
|---|---|---|---|
| **Boot** | Detecção da entrada UEFI no Firmware da fabricante | 💥 Crítica | Bare-metal Firmware |
| **Boot** | Initramfs localiza partição raiz e injeta SystemD sem Timeout | 💥 Crítica | Kernel & Storage C-Space |
| **Armazenamento** | FSTAB resolve PARTUUIDs perfeitamente via BLKID dinâmico | 💥 Crítica | Persistence |
| **Console** | Teclado físico responde fluído no TTY1 sem deadlocks | 💥 Crítica | User Output |
| **Rede** | Systemd-networkd apanha IP local validando DHCP lease | 🔴 Alta | Remote Connectivity |
| **Admin** | SSH Server responde conectando externamente o `sys_user` | 🟡 Média | Remote Diagnostics |
| **Estabilidade**| Comando de Hard Reset desliga perfeitamente sem unmounts pendurados | 🔴 Alta | System Safety |
| **Input** | GPM daemon consolida eventos de pointer do Mouse e aceita Text Selection | 🟢 Baixa | Dev Ergonomy |

---

## 4. Checklist Operacional de Execução Direta

Os testadores devem seguir perfeitamente o script de stress listado abaixo:

1. **Burn:** Utilizar o script `make write-disk DISK=/dev/sdX` num USB confiável e conectar ao alvo testado.
2. **Boot:** Fazer Power-on no alvo. Desativar explicitamente "Secure Boot" e pular "Fast Boot" (Windows BIOS quirks). Selecionar o Device.
3. **Init Watch:** Analisar se Systemd-boot prossegue ou trava na passagem pro kernel (`dmesg` watch visual). O Timeout default deve ocorrer natural.
4. **Login Base:** Acertar os dados locais com usuário Default. 
5. **Automação de Debug:** Invocar `flavos-net-check` e varrer todo pacote buscando por falha de DHCP Lease. Invocar em seguida o `flavos-debug-report` para analisar os Timers lentos e services pendurados no boot real.
6. **Ping Test:** Solicitar ping na placa de rede para comprovar gateway reativo `ping -c 3 8.8.8.8` e também checar ping num server em TLD para testar o ResolveD `ping -c 3 debian.org`.
7. **Reboot Clean:** Solicitar `/usr/sbin/reboot`, aguardar e realizar Boot de reencarne e buscar coredumps ou sujeiras deixadas de persistências inativas `journalctl -b -1 -p err`.

O veredicto completo e output desta lista deve ser dumpado utilizando os modelos preenchíveis estabelecidos em `TEST_REPORT_TEMPLATE.md`.
