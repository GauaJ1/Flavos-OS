# Flavos OS — Laboratório Avançado de Validação (VM QEMU)

Este documento dita a diretriz de homologação substituta caso não haja Hardware real disponível à equipe dev. Ele utiliza o script refinado de boot `04-boot-vm.sh` para emular os gargalos e overheads mais exóticos de Barramento (Storage) e Rede em ambiente fechado de Máquina Virtual.

---

## O Paradigma da 8A1
Não podemos fingir validações físicas (como conflitos de IRQ em Placas Asus antigas, cabos CAT5 falhando, ACPI suspend states esquisitíssimos). Tudo atestado aqui é **Restrito à capacidade de sobrevivência Base do nosso Userspace e Initramfs frente a drivers virtualizados heterogêneos**.

## 1. Topologias de Boot Mapeadas

Para validar a fundo no laboratório você precisará re-iniciar a Máquina injetando os argumentos abaixo:

### Storage Stress (Disco Virtual)
- **Cenário A (Padrão):** Bus `virtio` - Altamente otimizado, não reage como metal.
- **Cenário B (IDE/SATA):** `--disk-bus ide` ou `--disk-bus ahci` - Emula barramento e controladora IDE Legacy/SATA pesada. (Testará timeout do SystemD no Boot process).
- **Cenário C (NVMe):** `--disk-bus nvme` - Passa por controladora PCI NVMe falsa. Descobrirá se o nosso FSTAB lida com os namespaces `/dev/nvme0n1p2` certinho via PARTUUID ou se crasha o kernel mount.

### Network Stress (Sobrecarga de Ethernet)
- **Cenário A (E1000e):** `--net-model e1000e` - Placas intel gigabit padrões. Testa handshakes corporativos normais. 
- **Cenário B (Realtek):** `--net-model rtl8139` - Dispositivo rudimentar legado. Descobriremos se o rename natural pra `enp*` acontece certinho ou o NetworkD falha de resolver a placa como `eth0`.

### Install Recursivo Stress (Inception Test)
Podemos validar o destrutivo `05-write-to-disk.sh` na mais pura segurança. Basta criar um arquivo nulo na Host, injetar como 2º disco pro Flavos e invocar o comando destrutivo lá dentro da VM:
```bash
# Na host (Fora da VM):
fallocate -l 4G dummy.raw 
make boot-gui DISK_BUS=virtio NET_MODEL=virtio DUMMY_DISK=--attach-dummy dummy.raw

# Dentro do Flavos OS:
lsblk # E veja seu dummy lá brilhando pronto para ser formatado "fisicamente".
sudo bash scripts/05-write-to-disk.sh --disk /dev/vdb
```

---

## 2. Checklist Geral de Execução

Rode as permutações completas e tire a prova cabal da 8A1. O sistema passará para a RC1 com sucesso se:
1. `make boot-gui` aceita todas as 3 permutações de `--disk-bus` sem `Kernel Panics` de ausência de módulo no `Initramfs`.
2. Em qualquer Boot via SATA ou NVme, o `flavos-debug-report` acusar `0 serviços falhos`.
3. Injetando a rede podre da Realtek, `flavos-net-check` pingar externamente o Domain DNS `debian.org`.
4. Os dados salvos (Testes de persistência como arquivos mortos `touch /root/hello`) não corrompem entre 1 Hard Reset e 1 Poweroff. 
5. Gravação em Disco Físico (Install Recursivo em Dummy) executa com o triplo check exigindo confirmação de string literal.

Os gaps descobertos que inviabilizem esse flow irão ser classificados pra resolução pesada na **Etapa 8B (Correções)**.
