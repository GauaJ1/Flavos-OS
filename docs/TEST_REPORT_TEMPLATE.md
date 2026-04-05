# Relatório de Homologação em Hardware Físico

> **Instruções:** Copie este template para arquivar um relatório dentro de eventuais Pull Requests ou nos repositórios de Issues do Flavos OS visando declarar um Hardware como estavelmente suportado. Siga a Matriz de Validação presente em `docs/VALIDATION_MATRIX.md`.

## 1. Metadados do Teste 📋

- **Data da Execução:** [ DD/MM/AAAA ]
- **Versão do Target OS:** V0.1.0 Ignition
- **Mídia Criadora:** [ Pendrive USB SANDisk 32GB / SSD Kingston SATA Externo / SSD Interno Host ]
- **Gerado com Manifest Hash:** [ Output de `cat build/manifest.json` ]

## 2. Alvo de Hardware 💻

- **Fabricante e Modelo:** [ Ex: Lenovo Thinkpad T480 / Desktop Montado Asus B450 ]
- **Processador (CPU):** [ Ex: Intel Core i5 8350U ]
- **Modo de Firmware:** [ UEFI | Legacy (Atenção, Legacy Invalida o Teste) ]
- **Secure Boot:** [ Desativado ]
- **Chip de Rede Local:** [ Ex: Intel I219-LM via lspci / ethtool ]
- **Teclado:** [ Local Notebook Padrão US / USB Externo Mecânico ABNT2 ]

## 3. Matriz Preenchida 🧪

*(Taxonomia `Status`: ✅ Aprovado | ⚠️ Com Ressalvas | ❌ Falhou | ⏳ Não Testado)*

| Domínio de Teste | Status Reportado |
|---|---|
| **Firmware/UEFI Boot Entry** | [ ] |
| **Kernel/Initramfs Mount** | [ ] |
| **Armazenamento e PARTUUID (FSTAB)** | [ ] |
| **Console TTY Input Type** | [ ] |
| **GPM Mouse Selection Copy/Paste** | [ ] |
| **DHCP Local Lease via systemd** | [ ] |
| **Conectividade Internet (DNS ping)** | [ ] |
| **Estabilidade Acpi Shutdown/Dumps** | [ ] |

## 4. Resultado Geral ✅ Erro ou Glória

**Veredito Oficial:** [ ✅ Hardware Aprovado | ⚠️ Aprovado Sujo | ❌ Reprovado ]

### 5. Análise de Falhas ou Dumps do `flavos-debug-report` 🔍

*(Caso obteve Kernel Panic, erro de init, falha bizarra de teclado pendurado ou rede intermitente. Rode `flavos-debug-report` e despeje saídas aqui):*

```bash
# Output do Journal ou do Report
```

### 6. Considerações Adicionais 📝

*(Descreva a sensação de responsividade, delays excessivos observados para apanhar IP do gateway local da placa de rede física ou timeouts pendurados de systemd perceptíveis após a VM):*

- ...
