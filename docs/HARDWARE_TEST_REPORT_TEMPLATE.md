# Flavos OS — Hardware Test Report

> Preencher este template para cada teste em hardware real.
> Copiar este arquivo e renomear: `HARDWARE_TEST_REPORT_<MÁQUINA>_<DATA>.md`

---

## 1. Identificação do Teste

| Campo | Valor |
|---|---|
| **Data** | |
| **Testador** | |
| **Máquina** | _(nome/apelido do hardware)_ |
| **Versão/tag** | |
| **Artefato** | |
| **SHA256 do artefato** | |
| **Checksum validado** | ☐ Sim / ☐ Não |
| **Tipo de teste** | ☐ VM / ☐ Pendrive / ☐ Disco externo / ☐ Disco interno de teste |
| **Perfil de performance** | ☐ Light / ☐ Balanced / ☐ Full |

---

## 2. Hardware

| Campo | Valor |
|---|---|
| **CPU** | |
| **RAM (total)** | |
| **GPU** | |
| **Disco** | _(modelo, tipo: SSD/HDD/NVMe, capacidade)_ |
| **Rede** | |
| **Áudio** | |
| **Firmware** | ☐ UEFI / ☐ BIOS (Legacy) |
| **Modo SATA** | ☐ AHCI / ☐ IDE / ☐ RAID |
| **Resolução do monitor** | |
| **Observações** | |

---

## 3. Resultado do Boot

| Item | ✅ OK | ⚠️ Parcial | ❌ Falha | Observação |
|---|---|---|---|---|
| Bootloader | ☐ | ☐ | ☐ | |
| Kernel inicia | ☐ | ☐ | ☐ | |
| Desktop aparece | ☐ | ☐ | ☐ | |
| Painel | ☐ | ☐ | ☐ | |
| Taskbar | ☐ | ☐ | ☐ | |
| Wallpaper | ☐ | ☐ | ☐ | |
| Rede | ☐ | ☐ | ☐ | |
| Áudio | ☐ | ☐ | ☐ | |
| Teclado | ☐ | ☐ | ☐ | |
| Mouse | ☐ | ☐ | ☐ | |
| Resolução | ☐ | ☐ | ☐ | |
| Desligamento | ☐ | ☐ | ☐ | |
| Reboot | ☐ | ☐ | ☐ | |

---

## 4. Resultado do Desktop

| Item | ✅ OK | ⚠️ Parcial | ❌ Falha | Observação |
|---|---|---|---|---|
| Launcher | ☐ | ☐ | ☐ | |
| Terminal | ☐ | ☐ | ☐ | |
| Nemo | ☐ | ☐ | ☐ | |
| Firefox | ☐ | ☐ | ☐ | |
| Lock screen | ☐ | ☐ | ☐ | |
| Suspend | ☐ | ☐ | ☐ | |
| Power menu | ☐ | ☐ | ☐ | |
| Arquivos compactados | ☐ | ☐ | ☐ | |
| Downloads | ☐ | ☐ | ☐ | |

---

## 5. Performance

| Métrica | Valor Medido | Comando Usado |
|---|---|---|
| RAM idle (após 5 min) | | `free -h` |
| CPU idle (%) | | `pidstat -u 2 5` |
| Tempo de boot até desktop | | `systemd-analyze` |
| Tempo para abrir launcher | | cronômetro |
| Tempo para abrir terminal | | cronômetro |
| Tempo para abrir Nemo | | cronômetro |
| Tempo para abrir Firefox | | cronômetro |
| RAM com Firefox (1 aba) | | `free -h` |
| RAM após lock/unlock | | `free -h` |
| RAM após suspend/resume | | `free -h` |
| Swap em uso | | `free -h` |

---

## 6. Saída do `flavos-hw-report`

Se o script estiver disponível, colar ou anexar a saída:

```
(colar aqui o conteúdo de ~/flavos-hardware-report.txt)
```

---

## 7. Bugs Encontrados

### Bug 1

| Campo | Detalhe |
|---|---|
| **Descrição** | |
| **Passos para reproduzir** | |
| **Comportamento esperado** | |
| **Comportamento obtido** | |
| **Logs relevantes** | |
| **Severidade** | ☐ Crítica / ☐ Alta / ☐ Média / ☐ Baixa |

### Bug 2

| Campo | Detalhe |
|---|---|
| **Descrição** | |
| **Passos para reproduzir** | |
| **Comportamento esperado** | |
| **Comportamento obtido** | |
| **Logs relevantes** | |
| **Severidade** | ☐ Crítica / ☐ Alta / ☐ Média / ☐ Baixa |

_(Adicionar mais blocos conforme necessário)_

---

## 8. Classificação para 2 GB RAM

_(Preencher apenas se o hardware testado tiver ≤ 2 GB RAM)_

| Classificação | Selecionar |
|---|---|
| ✅ OK — Desktop leve, terminal, arquivos, navegação simples | ☐ |
| ⚠️ Atenção — Firefox com poucas abas, swap ativo mas tolerável | ☐ |
| ⛔ Ruim — Swap excessivo, travamentos, compositor pesado | ☐ |
| ❌ Falha — Não chega ao desktop ou fica inutilizável | ☐ |

**Detalhamento:**

---

## 9. Veredito

| Veredito | Selecionar |
|---|---|
| ✅ Aprovado para VM | ☐ |
| ✅ Aprovado para hardware experimental | ☐ |
| ⚠️ Precisa retestar | ☐ |
| ❌ Reprovado | ☐ |
| 🚫 Não instalar em hardware | ☐ |

**Justificativa:**

---

## 10. Observações Gerais

_(Comentários adicionais, fotos, anotações de campo)_

---

## 11. Próximos Passos

- [ ] _(ações recomendadas com base no teste)_
