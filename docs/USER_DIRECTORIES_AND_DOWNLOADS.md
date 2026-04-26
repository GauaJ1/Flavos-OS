# Flavos OS: User Directories & Download Flow

## Objetivo
Este documento define a estrutura padrão dos diretórios do usuário (XDG User Dirs) no Flavos OS, as razões para o idioma escolhido, e as políticas de segurança aplicadas aos arquivos baixados da internet.

## Estrutura Inicial da Home (`~`)
No primeiro boot, o usuário `flavos` (ou qualquer outro usuário criado) receberá uma estrutura predefinida e consistente via `/etc/skel`.

As pastas garantidas pelo sistema são:
```text
~/Desktop
~/Downloads
~/Documents
~/Pictures
~/Music
~/Videos
~/Templates
~/Public
```

### Por que pastas em inglês?
Embora o público alvo inicial do Flavos OS utilize pt-BR (sendo o idioma da UI), optou-se tecnicamente por manter as pastas físicas no padrão inglês (Opção A) por motivos de previsibilidade e suporte:
- **Ausência de caracteres especiais:** Nomes como "Música" (acento) e "Área de Trabalho" (espaços) frequentemente quebram scripts mal formatados, demandam escapes constantes no terminal (`cd ~/Área\ de\ Trabalho`) e causam bugs em softwares empacotados de forma rígida.
- **Camadas de compatibilidade (Wine/Proton):** Jogos e aplicações Windows rodam com maior estabilidade quando mapeiam "Documents" nativamente, reduzindo pastas duplicadas ou erros de permissão.
- **Suporte unificado:** Guias de documentação técnica ("Salve o arquivo em ~/Downloads") funcionam universalmente para qualquer idioma em que o sistema for instalado no futuro.

A integração é feita instalando o pacote `xdg-user-dirs` e predefinindo a lista rígida em `/etc/xdg/user-dirs.defaults` e `/etc/skel/.config/user-dirs.dirs`, propositalmente omitindo o `xdg-user-dirs-gtk` para barrar traduções automáticas não-intencionais.

## Integração com o Desktop (Nemo e Firefox)
A arquitetura garante que o ecossistema gráfico entenda essas pastas como oficiais:
- **Nemo (Gerenciador de Arquivos):** Lê a estrutura XDG e injeta automaticamente os "Bookmarks" (favoritos) na barra lateral sob o menu "Computador", com os ícones especiais corretos (ícone de música, foto, etc.).
- **Firefox:** Herda as propriedades GLib/GTK e aponta nativamente o destino de arquivos para `~/Downloads` (variável `XDG_DOWNLOAD_DIR`).

*Nota: Isso retroage e integra perfeitamente com a Etapa 13A (Archive & Compression). O Firefox baixa o `.zip` no `Downloads`, e o usuário usa o menu de contexto do Nemo ("Extrair Aqui") de forma fluida.*

## Segurança e a Zona de Risco (Downloads)
O diretório `~/Downloads` atua como a zona de entrada para dados externos. Devido à sua natureza, políticas de contenção são aplicadas para evitar infecções "one-click" ou execuções inadvertidas.

O Flavos OS segue o princípio de que **nenhum conteúdo externo roda sem ação explícita e consciente do usuário**.

### Executáveis, Scripts e Binários
- **Políticas de Arquivo:** O Flavos OS não deve marcar arquivos baixados como executáveis automaticamente nem executar conteúdo externo (como atalhos `.desktop` baixados) sem ação explícita do usuário.
- **Proteção do Nemo:** O esquema do Nemo (`org.nemo.preferences > executable-text-activation`) está fixado em `ask` (perguntar). Caso o usuário manualmente torne um arquivo executável (`chmod +x`), dar duplo-clique forçará o Nemo a exibir um prompt de confirmação ("Você deseja rodar este arquivo ou abrir o seu conteúdo em um editor de texto?"), evitando rodar `.sh` acidentalmente.

### Formatos Externos (.AppImage, .deb, .zip)
- **AppImages:** Baixam sem permissão de execução. Requerem `chmod +x` ou mudança na aba Permissões (Nemo) antes de rodar.
- **Arquivos Compactados (.zip, .tar):** Abertos via *Flavos Archives* (Etapa 13A). A extração preserva as flags de execução se o arquivo contiver binários Linux genuínos, mas a execução ainda assim invocará o prompt de confirmação do Nemo se forem scripts.
- **Arquivos deb:** Devem ser instalados via terminal ou instalador dedicado, garantindo a avaliação do administrador do sistema (`sudo apt install ./pacote.deb`).
