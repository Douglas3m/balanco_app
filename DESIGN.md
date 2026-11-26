# DESIGN SYSTEM: Balanço

## 1. Visão Geral & Identidade
- **Nome do Produto**: Balanço
- **Propósito**: Aplicativo mobile e desktop para catalogação de ativos patrimoniais, contagem de inventário e emissão de relatórios precisos A4 com fotos.
- **Estilo**: Moderno, limpo, confiável, corporativo e ergonômico para operação em campo e escritório. Uso de cartões com cantos arredondados (12px–16px) e sombras suaves (`BoxShadow`).
- **Logotipo / Ícone**: Balança estilizada com letra 'B' integrada (Fundo `#1E3A8A` com glifo branco).

## 2. Tipografia
- **Títulos e Destaques**: `Outfit`, sans-serif (pesos 600, 700)
- **Interface e Textos**: `Inter`, -apple-system, sans-serif (pesos 400, 500, 600)
- **Monospace (códigos/IDs/contadores)**: `JetBrains Mono`, monospace

## 3. Paleta de Cores (Design Tokens)
- **Primária (Azul Escuro / Deep Navy)**: `#1E3A8A` (Header, botões de ação principal, identidade visual)
- **Secundária (Azul / Cobalt Blue)**: `#3B82F6` (Foco, badges interativos, links, destaques)
- **Sucesso (Verde / Emerald)**: `#10B981` (Confirmação, status de sincronização, reconciliação)
- **Fundo Claro (Slate Light)**: `#F8FAFC` (Superfície geral suave)
- **Superfície de Cards (White)**: `#FFFFFF` (Cards elevados e seções)
- **Bordas & Linhas**: `#E2E8F0` (Bordas de cards, divisores e inputs)
- **Texto Principal**: `#1E293B` (Slate escuro para alto contraste e legibilidade)
- **Texto Secundário / Metadados**: `#64748B` (Subtítulos, datas, labels de apoio)
- **Alerta / Exclusão**: `#EF4444` (Avisos e remoções)
- **Container / Fundo Suave**: `#F1F5F9` (Badges de quantidade e fundos alternados)

## 4. Componentes Chave
- **Botões**: Arredondados (`RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))`), cor de fundo primária `#1E3A8A` e texto branco.
- **Cards**: `Card` com `elevation: 1` ou `2`, `shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))` e borda suave `#E2E8F0`.
- **Campos de Formulário**: `TextFormField` com `OutlineInputBorder`, bordas arredondadas (10px), fundo branco e label flutuante com foco em `#3B82F6`.
- **Cards de Catálogo**: Miniatura da foto em proporção fixa 1:1, tipografia hierarquizada (nome do bem em negrito, plaqueta #PAT, tags de setor e entidade, badge destacado para quantidade).
- **Barra de Navegação Inferior (Mobile)**: Dashboard (Início), Lançamentos (Itens), Novo (+ destacado em `#1E3A8A`), Cadastros (Entidades/Setores/Produtos) e Exportar.
- **Relatório PDF A4**: Margens auditáveis simétricas de 15mm, cabeçalho institucional com marca Balanço, dados da entidade, tabela zebrada de alta legibilidade, miniatura de foto 1:1 e rodapé auditável com paginação.
