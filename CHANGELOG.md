# Changelog

Todas as mudanças relevantes do GlassFrame serão documentadas neste arquivo.

O formato segue o [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/) e o projeto utiliza [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [2.0.0] - 2026-06-27

### Adicionado

- Slideshow de imagens a partir de uma pasta.
- Reprodução aleatória sem repetição e ordenação por nome.
- Controles rápidos para imagem anterior, pausar, avançar, alterar layout e abrir configurações.
- Histórico de navegação para retornar ao conjunto anterior.
- Cinco layouts: imagem única, duas colunas, três colunas, grade 2×2 e recorte circular.
- Estado vazio clicável quando nenhuma imagem válida é encontrada.
- Indexador PowerShell para criar um catálogo UTF-8 de imagens.
- Configurações bilíngues em português e inglês, com detecção inicial do idioma do Windows.
- Persistência de pasta, imagens, intervalo, ordem, pausa, idioma, layout, escala, cor e transparência.
- Opacidade configurável de aproximadamente `2%` a `100%`.
- Botão para restaurar as configurações padrão.

### Alterado

- `Layout.lua` tornou-se a única fonte da lógica de layout, slideshow e visibilidade dos slots.
- A interface recebeu um visual glass mais discreto, com bordas suaves e melhor contraste.
- A barra de controles agora aparece sobre a parte inferior das imagens apenas durante o hover.
- Os controles numéricos foram substituídos por representações visuais dos layouts.
- A janela de configurações foi reorganizada em Fonte, Slideshow, Aparência e Idioma.
- O botão **Aplicar e fechar** salva as alterações, encerra a janela e atualiza a skin.
- A escala pode ser ajustada entre `0.4×` e `3.0×` e permanece salva após reiniciar o Rainmeter.
- Scripts e arquivos de configuração passaram a utilizar gravação atômica e codificação UTF-8.
- README reescrito em português e inglês para refletir o funcionamento da versão 2.0.

### Corrigido

- Layout Lua legado que referenciava meters inexistentes.
- Painel de controles ocupando espaço permanente abaixo das imagens.
- Alterações da janela de configurações sendo gravadas antes da confirmação.
- Caracteres acentuados e ícones exibidos com codificação incorreta.
- Abertura da janela de configurações quando executada pelo plugin RunCommand.
- Atualização da skin após salvar as configurações.
- Tratamento de pastas vazias, inacessíveis e arquivos removidos.
- Comportamento do histórico após um novo embaralhamento.
- Atualizações periódicas e refreshes completos desnecessários.

### Removido

- `SelectImage.ps1`, substituído pela seleção integrada à janela de configurações.
- Sistema duplicado de layouts baseado em expressões extensas no arquivo INI.
- Dependência de glifos Unicode pouco confiáveis para os controles principais.
