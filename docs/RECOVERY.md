# Flavos OS: Operation & Recovery Guide

## Troubleshooting Básico
Quando você estiver logado (ou travado visualmente em console), a auditoria oficial foca nos logs do **Journald**, que estão com persistência salva na partição ext4 com teto de 50MB.

### Inspeção Via Terminal (Se houver acesso local ou SSH)
- `flavos-debug-report`: Seu comando Mestre. Resume num script conciso o status de uso de RAM/Disco e Serviços falhos por Kernel.
- `flavos-net-check`: Diagnósticos fáticos testando gateway, DNS, link e ICMP pra internet com visualização de Interfaces.
- `journalctl -p 3 -xb`: Lista todos os eventos de criticidade Alta (`ERROR`, `CRIT`, `EMERG`) ocorridos no *Boot Atual*.
- `journalctl -b -1`: Lê de trás pra frente tudo que estourou no *Boot Anterior* (essencial se o sistema crashou as cegas e rebootou do nada).

## Recuperação Hostil (Boot Failures)
Se alguma variável crítica foi mudada na árvore (ex: RootUUID perdido no fstab ou pacote removido acidentalmente), o kernel vai entrar em pani e arremessar pra shell ramfs.

Neste cenário de "Kernel Panic" na tela de boot, intercepte o carregamento:
1. Quando a tela azul/preta do **systemd-boot** aparecer (TianoCore UEFI), use as setas para focar em `Flavos OS`.
2. Aperte exetuamente a tecla **`e`**.
3. Isso vai te revelar os parâmetros da Linux Boot Line.

### Estratégia 1: Emergency Mode Mount
Para verificar pacotes quebrados retendo privilégios e montagens originais, adicione este exato texto ao final da linha (após o quiet):
`systemd.unit=emergency.target`
- Pressione ***Enter***. Ele fará o bypass de montagem paralela e forçará o console log do root puro pra reedição fstab (`mount -o remount,rw /`).

### Estratégia 2: Extinção de Init (Shell Puro)
Se o própio `systemd` corromper os libs C principais e abortar no boot, mate-o.
Adicione ao final da linha boot:
`init=/bin/bash`
- Pressione ***Enter***. O núcleo Linux chamará o compilador Bash diretamente, não subindo nenhum serviço de Rede ou PID. Você tem acesso raw aos binários para usar o `update-initramfs -u -k all` se necessário.
