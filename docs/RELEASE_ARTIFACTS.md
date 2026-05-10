# Flavos OS — Release Artifacts

> **Etapa:** 14A — Build Artifact Hygiene & Release Image Safety
> **Status:** Experimental Estável (Desktop Preview)

Este documento define quais artefatos são gerados pelo build, quais podem ser publicados, como verificá-los e quais riscos existem.

---

## 1. Artefatos Gerados

### Pipeline de Desenvolvimento (`make all`)

Gera a imagem para testes em VM. Rápido, não comprimido.

| Artefato | Descrição | Publicável |
|---|---|---|
| `flavos-0.1-basis-amd64.img` | Imagem raw GPT (4 GB) | ❌ Não |
| `rootfs/` | Root filesystem montado | ❌ Não |
| `partuuids.env` | PARTUUIDs para scripts internos | ❌ Não |
| `OVMF_VARS_4M.fd` | Variáveis UEFI da VM | ❌ Não |
| `mnt_esp/`, `mnt_root/` | Diretórios de montagem temporários | ❌ Não |

### Pipeline de Release (`make release`)

Gera artefatos verificáveis e comprimidos para publicação.

| Artefato | Descrição | Publicável |
|---|---|---|
| `FlavosOS-desktop-preview-0.1-daily-amd64.img.xz` | Imagem comprimida (~526 MB) | ✅ Sim |
| `FlavosOS-desktop-preview-0.1-daily-amd64.img.xz.sha256` | Checksum SHA256 | ✅ Sim |
| `flavos-0.1-preview-manifest.json` | Metadados da build | ✅ Sim |

---

## 2. O Que Publicar

### Deve ser publicado juntos

1. **`FlavosOS-desktop-preview-0.1-daily-amd64.img.xz`** — a imagem.
2. **`FlavosOS-desktop-preview-0.1-daily-amd64.img.xz.sha256`** — o checksum.
3. **`flavos-0.1-preview-manifest.json`** — os metadados (opcional mas recomendado).

### O que NUNCA publicar

| Artefato | Motivo |
|---|---|
| `.img` puro (4 GB) | Muito grande, sem compressão, sem verificação |
| `rootfs/` | Contém filesystem completo com credenciais |
| `partuuids.env` | Dados internos de build |
| `OVMF_VARS_4M.fd` | Específico para VM local |
| `config/.secrets` | Credenciais de build |

---

## 3. Verificação de Checksum

### Verificar integridade após download

```bash
# Verificar que o arquivo não foi corrompido ou alterado
sha256sum -c FlavosOS-desktop-preview-0.1-daily-amd64.img.xz.sha256
```

Saída esperada:
```
FlavosOS-desktop-preview-0.1-daily-amd64.img.xz: OK
```

### Verificar manualmente

```bash
# Calcular o hash e comparar visualmente
sha256sum FlavosOS-desktop-preview-0.1-daily-amd64.img.xz
# Comparar com o conteúdo de:
cat FlavosOS-desktop-preview-0.1-daily-amd64.img.xz.sha256
```

---

## 4. Como Descomprimir

```bash
# Descomprimir (mantém o .xz original)
xz -dk FlavosOS-desktop-preview-0.1-daily-amd64.img.xz

# Resultado: FlavosOS-desktop-preview-0.1-daily-amd64.img (4 GB)
```

---

## 5. Como Gravar em Disco

### Via Makefile (recomendado)

```bash
# Usa o script com 3 camadas de proteção
make write-disk DISK=/dev/sdX
```

O script `05-write-to-disk.sh`:
- Exige disco explícito (nunca escolhe automaticamente).
- Bloqueia gravação no disco do sistema host.
- Verifica tamanho mínimo (2.5 GB).
- Exige confirmação por digitação do caminho completo.

### Via `dd` (manual)

```bash
# CUIDADO: substitua /dev/sdX pelo disco correto
# Use lsblk para identificar o disco ANTES de executar
xz -dk FlavosOS-desktop-preview-0.1-daily-amd64.img.xz
sudo dd if=FlavosOS-desktop-preview-0.1-daily-amd64.img of=/dev/sdX bs=4M status=progress conv=fsync
sync
```

> [!CAUTION]
> O comando `dd` sobrescreve TODO o conteúdo do disco alvo. Não há confirmação.
> Identifique o disco correto com `lsblk` antes de executar.
> Nunca use `/dev/sda` se for o disco do seu sistema.

---

## 6. Requisitos para Boot

- **Firmware:** UEFI (Legacy/BIOS não é suportado)
- **Secure Boot:** Deve estar **desabilitado**
- **Disco mínimo:** 4 GB
- **RAM mínima:** 1 GB (2 GB recomendado)
- **Arquitetura:** x86_64 (amd64)

---

## 7. Riscos e Limitações Conhecidas

> [!WARNING]
> Esta imagem é uma **preview técnica experimental**. Não é um produto pronto para produção.

### Credenciais Conhecidas

| Credencial | Valor | Contexto |
|---|---|---|
| Usuário do sistema | `flavos` | Login principal |
| Senha do usuário | `123` | Senha DevLocal |
| Senha do root | `flavos` | Acesso de emergência |

**Qualquer pessoa com acesso à imagem conhece essas credenciais.**
Elas existem para facilitar testes em ambientes controlados.

Para uso em qualquer rede não controlada:
1. Altere as senhas imediatamente após o primeiro boot.
2. Ou reconstrua a imagem com credenciais personalizadas via `config/.secrets`.

### Outras Limitações

| Limitação | Detalhe |
|---|---|
| **Autologin ativo** | O usuário `flavos` faz login automaticamente. Não há tela de login. |
| **Secure Boot desabilitado** | A imagem não possui shim ou MOK assinados. |
| **Sem criptografia de disco** | A partição root é ext4 sem LUKS. |
| **Sem firewall ativo** | Nenhuma regra nftables/iptables configurada. |
| **SSH pode estar ativo** | Se o sshd estiver habilitado, aceita login com senha conhecida. |
| **Sem atualizações automáticas** | O sistema não busca nem aplica updates. |
| **Validação limitada** | Testada apenas em QEMU/KVM. Hardware real não homologado para esta release. |

### Classificação de Segurança

```
┌─────────────────────────────────────────────────┐
│  CLASSIFICAÇÃO: DevLocal / Preview Técnica      │
│                                                 │
│  ✗ NÃO usar em redes públicas sem hardening     │
│  ✗ NÃO usar como servidor                       │
│  ✗ NÃO armazenar dados sensíveis                │
│  ✓ OK para testes em VM isolada                  │
│  ✓ OK para avaliação técnica em hardware lab     │
│  ✓ OK para desenvolvimento e contribuição        │
└─────────────────────────────────────────────────┘
```

---

## 8. Gerando Artefatos

### Pipeline completo (build + release)

```bash
# Build da imagem (requer sudo)
sudo make all

# Gerar artefatos de release
make release

# Verificar
ls -lh build/FlavosOS-*.img.xz build/FlavosOS-*.img.xz.sha256 build/*manifest.json
cd build && sha256sum -c FlavosOS-desktop-preview-0.1-daily-amd64.img.xz.sha256
```

### Apenas release (se a imagem já existe)

```bash
make release
```

### Targets individuais

```bash
make compress   # .img → .img.xz
make checksum   # .img.xz → .img.xz.sha256
make manifest   # Gera manifest.json
```

---

## 9. Padrão de Nomenclatura

```
FlavosOS-{milestone}-{version}-{tag}-{arch}.img.xz
         │           │         │     │
         │           │         │     └─ amd64
         │           │         └─ daily / rc1 / stable
         │           └─ 0.1 / 0.2 / 1.0
         └─ desktop-preview / server-preview / release
```

As variáveis são definidas em `config/flavos.conf`:
- `RELEASE_MILESTONE` — nome da milestone
- `RELEASE_VERSION` — versão pública
- `RELEASE_TAG` — classificação (daily, rc, stable)
- `ARCH` — arquitetura (amd64)
