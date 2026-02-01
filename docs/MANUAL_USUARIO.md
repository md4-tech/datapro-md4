# Manual do Usuário - BI SaaS Dashboard

**Versão:** 1.0.0
**Data:** Novembro 2024
**Sistema:** Business Intelligence SaaS - Plataforma Multi-Tenant

---

## 📑 Índice

1. [Introdução](#1-introdução)
2. [Primeiros Passos](#2-primeiros-passos)
3. [Papéis e Permissões](#3-papéis-e-permissões)
4. [Navegação do Sistema](#4-navegação-do-sistema)
5. [Módulo Dashboard](#5-módulo-dashboard)
6. [Módulo Relatórios](#6-módulo-relatórios)
7. [Módulo Metas](#7-módulo-metas)
8. [Módulo DRE Gerencial](#8-módulo-dre-gerencial)
9. [Módulo Descontos de Venda](#9-módulo-descontos-de-venda)
10. [Módulo Despesas](#10-módulo-despesas)
11. [Módulo Configurações](#11-módulo-configurações)
12. [Gestão de Usuários](#12-gestão-de-usuários)
13. [Gestão de Empresas](#13-gestão-de-empresas)
14. [Perfil do Usuário](#14-perfil-do-usuário)
15. [Perguntas Frequentes](#15-perguntas-frequentes)
16. [Solução de Problemas](#16-solução-de-problemas)

---

## 1. Introdução

### 1.1 O que é o BI SaaS Dashboard?

O BI SaaS Dashboard é uma plataforma completa de Business Intelligence desenvolvida para empresas multi-filiais que precisam:

- **Acompanhar vendas e lucros** em tempo real
- **Gerenciar metas** mensais e por setor
- **Analisar desempenho** por produto, departamento e filial
- **Controlar despesas** e gerar DRE Gerencial
- **Tomar decisões** baseadas em dados consolidados

### 1.2 Principais Características

✅ **Multi-Tenant**: Cada empresa tem seus dados isolados e protegidos
✅ **Multi-Filial**: Consolide ou analise dados de múltiplas filiais
✅ **Permissões Granulares**: 4 níveis de acesso (Super Admin, Admin, Gestor, Visualizador)
✅ **Análise ABC**: Classificação de produtos por curva de vendas e lucro
✅ **Gestão de Metas**: Acompanhamento de metas mensais e por setor
✅ **DRE Gerencial**: Demonstração de resultado completa com comparativos
✅ **Exportação PDF**: Todos os relatórios podem ser exportados

### 1.3 Requisitos do Sistema

- **Navegador**: Chrome, Firefox, Safari ou Edge (versões recentes)
- **Conexão**: Internet estável
- **Resolução**: Mínima de 1280x720 (responsivo para mobile)
- **JavaScript**: Habilitado no navegador

---

## 2. Primeiros Passos

### 2.1 Acessando o Sistema

1. Abra seu navegador e acesse a URL fornecida pela sua empresa
2. Você verá a tela de login do BI SaaS

### 2.2 Login

**Se você já tem uma conta:**

1. Digite seu **e-mail** no campo "Email"
2. Digite sua **senha** no campo "Senha"
3. Clique em **"Entrar"**

**Se esqueceu sua senha:**

1. Clique em **"Esqueceu sua senha?"**
2. Digite seu e-mail cadastrado
3. Clique em **"Enviar link de recuperação"**
4. Verifique seu e-mail e siga as instruções

### 2.3 Primeiro Acesso

Ao fazer login pela primeira vez:

1. Você será redirecionado para o **Dashboard**
2. Familiarize-se com o menu lateral
3. Explore os módulos disponíveis de acordo com suas permissões

### 2.4 Interface do Sistema

A interface é dividida em 3 áreas principais:

```
┌─────────────────────────────────────────────┐
│  [Logo]    BI SaaS Dashboard    [Usuário]   │ ← Cabeçalho
├──────────┬──────────────────────────────────┤
│          │                                  │
│  Menu    │     Área de Conteúdo             │
│  Lateral │     (Dashboard, Relatórios, etc) │
│          │                                  │
│          │                                  │
└──────────┴──────────────────────────────────┘
```

**Cabeçalho Superior:**
- Logo do sistema
- Nome da empresa/tenant atual
- Botão de perfil do usuário

**Menu Lateral (Sidebar):**
- Dashboard
- Relatórios
- Metas
- DRE Gerencial
- Descontos de Venda
- Despesas (em desenvolvimento)
- Configurações
- Usuários
- Empresas (somente Super Admin)

**Área de Conteúdo:**
- Exibe o módulo selecionado
- Breadcrumb de navegação
- Filtros e controles

---

## 3. Papéis e Permissões

O sistema possui 4 níveis de acesso com permissões diferentes:

### 3.1 Super Administrador

**Identificação:** Badge "Super Administrador"

**Permissões:**
- ✅ Acesso a **todas as empresas** (pode alternar entre tenants)
- ✅ Criar, editar e excluir **empresas**
- ✅ Criar, editar e excluir **usuários de qualquer empresa**
- ✅ Visualizar e editar **todos os dados financeiros**
- ✅ Acessar **todos os módulos**
- ✅ Gerenciar **configurações globais**

**Uso Recomendado:** Equipe técnica ou gerência executiva

### 3.2 Administrador

**Identificação:** Badge "Administrador"

**Permissões:**
- ✅ Acesso à **própria empresa** apenas
- ✅ Criar, editar e excluir **usuários da própria empresa**
- ✅ Visualizar e editar **dados financeiros**
- ✅ Acessar **todos os módulos** (exceto gestão de empresas)
- ✅ Gerenciar **setores e configurações**
- ✅ Definir **metas**

**Uso Recomendado:** Gerentes e coordenadores

### 3.3 Gestor

**Identificação:** Badge "Gestor"

**Permissões:**
- ✅ Acesso à **própria empresa** apenas
- ✅ Visualizar **dados financeiros**
- ❌ **Não pode editar** dados financeiros
- ❌ **Não pode gerenciar** usuários
- ✅ Acessar **relatórios e dashboards**
- ✅ Exportar **relatórios em PDF**

**Uso Recomendado:** Supervisores e analistas

### 3.4 Visualizador

**Identificação:** Badge "Visualizador"

**Permissões:**
- ✅ Acesso à **própria empresa** apenas
- ✅ **Visualizar** dados financeiros
- ❌ **Não pode editar** nenhum dado
- ❌ **Não pode gerenciar** usuários
- ✅ Acessar **relatórios e dashboards**
- ✅ Exportar **relatórios em PDF**

**Uso Recomendado:** Consultores, auditores ou parceiros externos

### 3.5 Matriz de Permissões

| Permissão | Super Admin | Admin | Gestor | Visualizador |
|-----------|:-----------:|:-----:|:------:|:------------:|
| Gerenciar Empresas | ✅ | ❌ | ❌ | ❌ |
| Gerenciar Usuários | ✅ | ✅ | ❌ | ❌ |
| Alternar entre Empresas | ✅ | ❌ | ❌ | ❌ |
| Visualizar Dados Financeiros | ✅ | ✅ | ✅ | ✅ |
| Editar Dados Financeiros | ✅ | ✅ | ❌ | ❌ |
| Definir Metas | ✅ | ✅ | ❌ | ❌ |
| Gerenciar Setores | ✅ | ✅ | ❌ | ❌ |
| Exportar Relatórios | ✅ | ✅ | ✅ | ✅ |

### 3.6 Restrições por Filial

Além do papel (role), usuários podem ter **restrições de filial**:

- **Sem restrição**: Acessa dados de todas as filiais da empresa
- **Com restrição**: Acessa apenas filiais autorizadas

**Exemplo:**
- João (Gestor) tem acesso apenas à Filial 1
- Maria (Admin) tem acesso a todas as filiais

Isso é configurado na **Gestão de Usuários** pelo Administrador.

---

## 4. Navegação do Sistema

### 4.1 Menu Lateral

O menu lateral é o principal meio de navegação. Clique nos itens para acessar os módulos:

**📊 Dashboard** - Visão geral de indicadores
**📈 Relatórios** - Submenu com:
  - Ruptura ABCD
  - Venda por Curva ABC
  - Ruptura Venda 60 Dias

**🎯 Metas** - Submenu com:
  - Metas Mensais
  - Metas por Setor

**💰 DRE Gerencial** - Demonstração de Resultado do Exercício
**💳 Descontos de Venda** - Análise de descontos aplicados
**📋 Despesas** - Gestão de despesas (em desenvolvimento)
**⚙️ Configurações** - Setores e configurações gerais
**👥 Usuários** - Gestão de usuários (Admin+)
**🏢 Empresas** - Gestão de empresas (somente Super Admin)

### 4.2 Breadcrumb

No topo de cada página, você verá o caminho de navegação:

```
Dashboard / Relatórios / Venda por Curva
```

Clique em qualquer item do breadcrumb para voltar à página anterior.

### 4.3 Perfil do Usuário

Clique no **ícone do usuário** no canto superior direito para:

- 👤 **Meu Perfil** - Ver e editar dados pessoais
- 🚪 **Sair** - Fazer logout do sistema

### 4.4 Seletor de Empresa (Super Admin)

Se você é **Super Administrador**, verá um seletor de empresa no cabeçalho:

1. Clique no nome da empresa atual
2. Selecione a empresa que deseja acessar
3. O sistema recarregará com os dados da empresa selecionada

---

## 5. Módulo Dashboard

### 5.1 Visão Geral

O Dashboard é a **página inicial** do sistema e oferece uma visão consolidada dos principais indicadores de desempenho.

**Acesso:** Menu Lateral → Dashboard

### 5.2 Indicadores Principais

O Dashboard exibe cards com métricas importantes:

#### 📊 Total de Vendas
- Valor total de vendas no período selecionado
- Comparação com período anterior (%)
- Indicador visual de crescimento (verde ↑) ou queda (vermelho ↓)

#### 💰 Total de Lucro
- Lucro bruto total no período
- Comparação percentual com período anterior
- Margem de lucro calculada automaticamente

#### 📈 Margem de Lucro
- Percentual de lucro sobre vendas
- Comparação com período anterior
- Meta vs Realizado (se metas estiverem configuradas)

#### 🎯 Atingimento de Meta
- Percentual de meta atingida
- Valor realizado vs Meta definida
- Status visual (verde se atingiu, vermelho se não)

### 5.3 Gráficos e Visualizações

#### Gráfico de Vendas por Filial
- **Tipo:** Gráfico de barras
- **Dados:** Comparação de vendas entre filiais
- **Período:** Configurável pelos filtros
- **Interatividade:** Hover para ver valores exatos

#### Gráfico de Evolução Temporal
- **Tipo:** Gráfico de linha
- **Dados:** Tendência de vendas e lucro ao longo do tempo
- **Períodos:** Diário, Semanal ou Mensal
- **Comparação:** Ano atual vs ano anterior

#### Top Produtos
- **Lista:** 10 produtos mais vendidos
- **Informações:** Código, descrição, quantidade, valor
- **Classificação:** Por valor de vendas (maior para menor)

### 5.4 Filtros do Dashboard

**Período:**
- MTD (Month to Date) - Do início do mês até hoje
- YTD (Year to Date) - Do início do ano até hoje
- Personalizado - Selecione data início e fim

**Filial:**
- Todas as Filiais - Consolida dados de todas
- Filial Específica - Selecione uma filial

**Como aplicar filtros:**
1. Selecione o período desejado
2. Escolha a(s) filial(is)
3. Clique em **"Aplicar Filtros"**
4. Os dados serão atualizados automaticamente

### 5.5 Atualização de Dados

- **Automática:** Os dados são atualizados ao aplicar filtros
- **Manual:** Clique em "Atualizar" se necessário
- **Frequência:** Dados do banco são em tempo real

---

## 6. Módulo Relatórios

### 6.1 Visão Geral

O módulo de Relatórios oferece análises detalhadas sobre produtos, vendas e rupturas de estoque.

**Acesso:** Menu Lateral → Relatórios

### 6.2 Ruptura ABCD

**O que é:** Relatório de produtos sem estoque, classificados por departamento e curva ABC.

#### Como usar:

1. Acesse **Relatórios → Ruptura ABCD**
2. Configure os filtros:
   - **Filial:** Selecione uma ou mais filiais
   - **Mês:** Escolha o mês de análise
   - **Ano:** Escolha o ano
3. Clique em **"Aplicar"**

#### Informações exibidas:

**Hierarquia de Departamentos:**
- **Setor** (Nível 3) → **Grupo** (Nível 2) → **Subgrupo** (Nível 1)
- Clique nas setas (▶) para expandir/recolher níveis

**Para cada produto:**
- Código do produto
- Descrição
- Filial
- Quantidade em ruptura
- Valor estimado de perda
- Curva ABC de vendas
- Curva ABC de lucro

#### Filtro de Produto:
- Digite código ou nome do produto (mínimo 3 caracteres)
- A busca é feita em tempo real
- Produtos correspondentes são destacados em azul claro

#### Curvas ABC:

- **A** (Verde): Produtos de alta importância (20% que representam 80% vendas)
- **B** (Azul): Produtos de média importância
- **C** (Amarelo): Produtos de baixa importância
- **D** (Vermelho): Produtos de importância mínima

#### Exportar PDF:
1. Configure os filtros desejados
2. Clique no botão **"Exportar PDF"** (ícone 📄)
3. O arquivo será baixado automaticamente
4. Contém todos os dados filtrados (até 10.000 registros)

### 6.3 Venda por Curva ABC

**O que é:** Análise de vendas e lucro por produto, classificados em curvas ABC.

#### Como usar:

1. Acesse **Relatórios → Venda por Curva**
2. Configure os filtros:
   - **Filiais:** Selecione uma ou múltiplas filiais
   - **Mês:** Escolha o mês
   - **Ano:** Escolha o ano
   - **Filtrar Produto:** Digite para buscar produto específico
3. Clique em **"Aplicar"** (aplicação automática ao mudar filtros)

#### Informações exibidas:

**Estrutura Hierárquica:**
```
📂 Setor (Dept Nível 3)
  ├─ 📂 Grupo (Dept Nível 2)
  │   └─ 📂 Subgrupo (Dept Nível 1)
  │       └─ 📄 Produtos
```

**Para cada nível:**
- **Total de Vendas:** Soma das vendas
- **Total de Lucro:** Soma do lucro
- **Margem:** Percentual de lucro sobre vendas

**Para cada produto:**
| Campo | Descrição |
|-------|-----------|
| Filial | ID da filial |
| Código | Código do produto |
| Descrição | Nome do produto |
| Qtde | Quantidade vendida |
| Valor Vendas | Receita total |
| Curva Venda | Classificação ABC por vendas |
| Valor Lucro | Lucro total |
| % Lucro | Margem de lucro |
| Curva Lucro | Classificação ABC por lucro |

#### Funcionalidades Especiais:

**Filtro de Produto com Debounce:**
- Digite no campo "Filtrar Produto"
- Sistema aguarda 300ms após parar de digitar
- Filtra automaticamente produtos correspondentes
- Expande automaticamente departamentos com produtos encontrados
- Mínimo 3 caracteres para ativar busca

**Paginação:**
- 50 departamentos por página
- Use os controles no rodapé para navegar
- Números de página: 1, 2, 3...
- Botões: ← Anterior | Próximo →

**Exportar PDF:**
- Botão no topo da página
- Exporta **todos** os dados (não apenas a página atual)
- Mantém estrutura hierárquica
- Inclui totais por departamento
- Até 10.000 registros

### 6.4 Ruptura Venda 60 Dias

**O que é:** Lista produtos que não tiveram vendas nos últimos 60 dias.

#### Como usar:

1. Acesse **Relatórios → Ruptura Venda 60D**
2. Configure os filtros:
   - **Filial:** Selecione uma filial
   - **Período:** Últimos 60 dias (fixo)
3. Clique em **"Aplicar"**

#### Informações exibidas:

Para cada produto sem venda:
- Código do produto
- Descrição
- Departamento
- Última data de venda
- Dias sem venda
- Estoque atual
- Valor do estoque parado

#### Ações Recomendadas:

📌 **Produtos com 60+ dias sem venda:**
- Considere promoções
- Avalie descontinuação
- Verifique precificação
- Analise sazonalidade

---

## 7. Módulo Metas

### 7.1 Visão Geral

O módulo de Metas permite definir, acompanhar e analisar o cumprimento de objetivos comerciais.

**Acesso:** Menu Lateral → Metas

### 7.2 Metas Mensais

**O que é:** Definição e acompanhamento de metas mensais por filial.

#### Como criar metas:

1. Acesse **Metas → Metas Mensais**
2. Selecione **Mês** e **Ano**
3. Clique em **"Gerar Metas"**
4. O sistema cria metas para todas as filiais automaticamente
5. Valores iniciais são zerados

#### Como definir valores de meta:

**Método 1: Edição Individual**
1. Localize a filial desejada
2. Clique no campo "Meta Vendas" ou "Meta Lucro"
3. Digite o valor desejado
4. Pressione Enter ou clique fora para salvar

**Método 2: Cópia do Mês Anterior**
1. Clique em **"Copiar Mês Anterior"**
2. Sistema copia valores do mês anterior
3. Ajuste valores individualmente se necessário

#### Informações da tabela:

| Coluna | Descrição |
|--------|-----------|
| Filial | Nome da filial |
| Meta Vendas | Valor esperado de vendas |
| Vendas Realizadas | Valor atual de vendas |
| % Vendas | Percentual atingido |
| Meta Lucro | Valor esperado de lucro |
| Lucro Realizado | Valor atual de lucro |
| % Lucro | Percentual atingido |
| Status | Indicador visual (🟢 atingiu, 🔴 não atingiu) |

#### Consolidado (Todas as Filiais):

Quando seleciona **"Todas as Filiais"**:
- Mostra apenas totais consolidados
- Soma de todas as metas
- Soma de todos os realizados
- Percentual médio de atingimento

#### Atualização Automática:

- Valores realizados são atualizados **automaticamente**
- Sincronização com dados de vendas em tempo real
- Atualização ocorre a cada mudança nos filtros

### 7.3 Metas por Setor

**O que é:** Metas detalhadas por setor de negócio, com divisão por departamentos.

#### Como funciona:

**Estrutura de Setores:**
```
🏢 Setor de Negócio
  └─ 📂 Departamentos Associados
      └─ Produtos relacionados
```

Exemplo:
```
🏢 Mercearia
  ├─ Bebidas
  ├─ Alimentos Básicos
  └─ Limpeza
```

#### Como criar metas por setor:

1. Acesse **Metas → Metas por Setor**
2. Selecione **Mês** e **Ano**
3. Selecione **Filiais** (uma ou múltiplas)
4. Clique em **"Gerar Metas"**
5. Sistema cria metas para todos os setores

#### Como definir valores:

1. Localize o setor desejado
2. Digite valores em:
   - **Meta Vendas**
   - **Meta Lucro**
   - **Meta Margem** (%)
3. Valores salvam automaticamente

#### Visualização Consolidada:

Quando seleciona **múltiplas filiais**:
- Exibe totais consolidados por setor
- Soma vendas realizadas de todas filiais
- Calcula média de margem
- Status geral de atingimento

#### Associação de Departamentos:

**Como funciona:**
- Cada setor agrupa vários departamentos
- Vendas do setor = soma vendas dos departamentos associados
- Configure em **Configurações → Setores**

**Exemplo de associação:**
```
Setor: MERCEARIA
├─ Dept3: MERCEARIA DOCE
│   └─ Dept2: BISCOITOS
│       └─ Dept1: BISCOITOS RECHEADOS
└─ Dept3: MERCEARIA SALGADA
    └─ Dept2: MASSAS
        └─ Dept1: MASSAS GRANO DURO
```

#### Indicadores de Performance:

**Status por Setor:**
- 🟢 **Verde**: Meta atingida (≥100%)
- 🟡 **Amarelo**: Parcialmente atingida (80-99%)
- 🔴 **Vermelho**: Não atingida (<80%)

**Percentuais exibidos:**
- % Vendas: Realizado/Meta Vendas
- % Lucro: Realizado/Meta Lucro
- Margem Real vs Meta Margem

---

## 8. Módulo DRE Gerencial

### 8.1 Visão Geral

O DRE (Demonstração do Resultado do Exercício) Gerencial é um relatório financeiro completo que mostra receitas, custos, despesas e lucros da empresa.

**Acesso:** Menu Lateral → DRE Gerencial

### 8.2 Estrutura do DRE

O DRE segue a estrutura contábil padrão:

```
(+) RECEITA BRUTA
(-) Descontos sobre Vendas
(=) RECEITA LÍQUIDA

(-) CMV (Custo das Mercadorias Vendidas)
(=) LUCRO BRUTO

(-) DESPESAS OPERACIONAIS
    ├─ Despesas Administrativas
    ├─ Despesas com Pessoal
    ├─ Despesas Comerciais
    └─ Outras Despesas
(=) LUCRO OPERACIONAL

(-) Despesas Financeiras
(+) Receitas Financeiras
(=) LUCRO LÍQUIDO
```

### 8.3 Como usar o DRE

#### Filtros disponíveis:

**Filiais:**
- Selecione uma ou múltiplas filiais
- Opção "Todas as Filiais" para consolidação
- Sistema consolida automaticamente se múltiplas selecionadas

**Período:**
- **Mês:** Selecione o mês de análise
- **Ano:** Selecione o ano
- Sistema calcula automaticamente:
  - **PAM** (Período Anterior Mês) - Mês anterior
  - **PAA** (Período Anterior Ano) - Mesmo mês do ano anterior

**Como aplicar:**
1. Selecione filiais desejadas
2. Escolha mês e ano
3. Clique em **"Aplicar Filtros"**
4. DRE é atualizado automaticamente

### 8.4 Colunas do Relatório

O DRE exibe 4 colunas principais:

| Coluna | Descrição | Uso |
|--------|-----------|-----|
| **Atual** | Período selecionado | Valores do mês/ano escolhido |
| **PAM** | Período Anterior Mês | Mês anterior para comparação |
| **PAA** | Período Anterior Ano | Mesmo mês do ano anterior |
| **AH** | Análise Horizontal | Variação % vs PAA |

**Exemplo:**
```
Selecionado: Novembro/2024
- Atual: Novembro/2024
- PAM: Outubro/2024
- PAA: Novembro/2023
- AH: Variação de Nov/2024 vs Nov/2023
```

### 8.5 Hierarquia de Despesas

As despesas são organizadas em até **6 níveis** hierárquicos:

```
Nível 1: DESPESAS OPERACIONAIS
  └─ Nível 2: Despesas Administrativas
      └─ Nível 3: Utilities
          └─ Nível 4: Energia
              └─ Nível 5: Energia Elétrica
                  └─ Nível 6: Conta de Luz - Matriz
```

**Como navegar:**
- Clique na **seta ▶** para expandir
- Clique na **seta ▼** para recolher
- Níveis estão identificados por indentação
- Cada nível mostra:
  - Valor no período atual
  - Valor PAM
  - Valor PAA
  - Variação % (AH)

### 8.6 Indicadores Financeiros

**Cards no topo:**

**Receita Líquida:**
- Valor total de vendas após descontos
- Variação % vs PAA
- Indicador visual de crescimento

**CMV (Custo):**
- Custo das mercadorias vendidas
- Inclui ajuste de desconto_custo
- Variação % vs PAA

**Lucro Bruto:**
- Receita Líquida - CMV
- Principal indicador de rentabilidade
- Variação % vs PAA

**Margem Bruta:**
- % Lucro Bruto sobre Receita Líquida
- Indicador de eficiência
- Comparação com períodos anteriores

### 8.7 Análise Horizontal (AH)

A coluna **AH** mostra a variação percentual:

**Interpretação:**
- **Valores Positivos (+)**: Crescimento vs PAA
  - Exemplo: +15% = cresceu 15%
- **Valores Negativos (-)**: Redução vs PAA
  - Exemplo: -8% = reduziu 8%

**Cores:**
- 🟢 **Verde**: Crescimento em receitas/lucros
- 🔴 **Vermelho**: Redução em receitas/lucros
- 🟢 **Verde**: Redução em despesas/custos
- 🔴 **Vermelho**: Crescimento em despesas/custos

### 8.8 Correção de Desconto Custo

**Importante:** O sistema aplica correção automática no CMV:

```
CMV Correto = CMV Original - desconto_custo
Lucro Bruto = Receita Líquida - CMV Correto
```

Isso garante que:
- Descontos sobre vendas reduzem a receita
- Descontos sobre custo reduzem o CMV
- Lucro bruto reflete corretamente as margens

**Referência:** Ver documentação `CORRECAO_DESCONTO_CUSTO.md`

### 8.9 Exportar DRE para PDF

1. Configure os filtros desejados
2. Clique em **"Exportar PDF"** (ícone 📄)
3. O PDF inclui:
   - Todas as colunas (Atual, PAM, PAA, AH)
   - Hierarquia completa de despesas
   - Totalizadores e indicadores
   - Cabeçalho com filtros aplicados
   - Data de geração

### 8.10 Consolidação Multi-Filial

Quando seleciona **múltiplas filiais** ou **"Todas as Filiais"**:

**Sistema consolida:**
- ✅ Soma receitas de todas as filiais
- ✅ Soma CMV de todas as filiais
- ✅ Soma despesas de todas as filiais
- ✅ Calcula lucro consolidado
- ✅ Recalcula margens consolidadas

**Exemplo:**
```
Filial 1: Receita R$ 100.000 | Lucro R$ 20.000 (20%)
Filial 2: Receita R$ 150.000 | Lucro R$ 36.000 (24%)
────────────────────────────────────────────────────────
TOTAL:    Receita R$ 250.000 | Lucro R$ 56.000 (22,4%)
```

---

## 9. Módulo Descontos de Venda

### 9.1 Visão Geral

O módulo de Descontos de Venda permite registrar e analisar descontos comerciais aplicados sobre vendas e custos.

**Acesso:** Menu Lateral → Descontos de Venda

### 9.2 Conceitos Importantes

**Dois tipos de desconto:**

**valor_desconto:**
- Desconto dado ao cliente
- **Reduz a receita bruta**
- Impacta negativamente o lucro
- Exemplo: Promoção, desconto comercial

**desconto_custo:**
- Desconto obtido do fornecedor
- **Reduz o CMV** (custo)
- Impacta positivamente o lucro
- Exemplo: Bonificação, negociação com fornecedor

### 9.3 Como funciona

**Fórmula do Lucro:**
```
Receita Líquida = Receita Bruta - valor_desconto
CMV Ajustado = CMV Original - desconto_custo
Lucro Bruto = Receita Líquida - CMV Ajustado
```

**Exemplo prático:**
```
Vendas Brutas:      R$ 10.000
valor_desconto:     R$  1.000 (desconto ao cliente)
Receita Líquida:    R$  9.000

CMV Original:       R$  6.000
desconto_custo:     R$    600 (bonificação do fornecedor)
CMV Ajustado:       R$  5.400

Lucro Bruto:        R$  3.600 (9.000 - 5.400)
Margem:             40%
```

### 9.4 Cadastrar Desconto

#### Dados necessários:

1. **Filial**: Selecione a filial
2. **Data**: Data do desconto
3. **Valor Desconto**: Desconto sobre vendas (opcional)
4. **Desconto Custo**: Desconto sobre custo (opcional)
5. **Observação**: Justificativa ou descrição

#### Passos:

1. Clique em **"Novo Desconto"**
2. Preencha o formulário
3. Clique em **"Salvar"**
4. Desconto será aplicado automaticamente nos cálculos

### 9.5 Visualizar Descontos

**Filtros:**
- **Período**: Data início e fim
- **Filial**: Filtrar por filial específica
- **Tipo**: valor_desconto, desconto_custo ou ambos

**Tabela exibe:**
- Data do desconto
- Filial
- Valor desconto (sobre vendas)
- Desconto custo (sobre CMV)
- Observação
- Ações (Editar, Excluir)

### 9.6 Editar/Excluir Desconto

**Editar:**
1. Clique no ícone ✏️ (lápis)
2. Modifique os campos necessários
3. Clique em **"Salvar"**

**Excluir:**
1. Clique no ícone 🗑️ (lixeira)
2. Confirme a exclusão
3. Desconto será removido

⚠️ **Atenção:** Ao editar/excluir, os cálculos de lucro e CMV serão recalculados automaticamente.

### 9.7 Análise de Descontos

**Totalizadores exibidos:**
- Total de valor_desconto no período
- Total de desconto_custo no período
- Impacto no lucro bruto
- Percentual sobre vendas

**Gráficos:**
- Evolução de descontos ao longo do tempo
- Descontos por filial
- Comparação desconto vendas vs desconto custo

### 9.8 Impacto nos Outros Módulos

**Dashboard:**
- Lucro exibido já considera os descontos
- Margem calculada com descontos aplicados

**DRE Gerencial:**
- Receita Líquida: já deduzido valor_desconto
- CMV: já deduzido desconto_custo
- Lucro Bruto: reflete ambos os descontos

**Metas:**
- Valores realizados incluem descontos
- Comparação meta vs realizado considera descontos

---

## 10. Módulo Despesas

### 10.1 Visão Geral

**Status:** Em desenvolvimento

O módulo de Despesas permitirá:
- Cadastrar despesas operacionais
- Classificar por categoria e centro de custo
- Anexar comprovantes
- Aprovar/reprovar despesas
- Gerar relatórios de despesas

**Acesso:** Menu Lateral → Despesas

### 10.2 Funcionalidades Planejadas

- Cadastro de despesas com anexos
- Workflow de aprovação
- Categorias personalizáveis
- Rateio por filial/departamento
- Integração com DRE Gerencial
- Relatórios de despesas por categoria

**Previsão:** Em breve

---

## 11. Módulo Configurações

### 11.1 Visão Geral

O módulo de Configurações permite gerenciar setores de negócio e suas associações com departamentos.

**Acesso:** Menu Lateral → Configurações

**Permissão:** Admin ou Super Admin

### 11.2 Configurações de Setores

**O que são Setores?**

Setores são agrupamentos de departamentos para fins de análise e metas.

**Exemplo:**
```
Setor: MERCEARIA
├─ Dept Nível 3: MERCEARIA DOCE
│   ├─ Dept Nível 2: BISCOITOS
│   └─ Dept Nível 2: CHOCOLATES
└─ Dept Nível 3: MERCEARIA SALGADA
    ├─ Dept Nível 2: MASSAS
    └─ Dept Nível 2: ENLATADOS
```

### 11.3 Criar Novo Setor

1. Acesse **Configurações → Setores**
2. Clique em **"Novo Setor"**
3. Preencha:
   - **Nome do Setor**: Nome descritivo
   - **Descrição**: Opcional
   - **Status**: Ativo/Inativo
4. Clique em **"Salvar"**

### 11.4 Associar Departamentos ao Setor

**O que é associação?**

Vincular departamentos (da hierarquia de 6 níveis) ao setor para consolidação de dados.

**Como associar:**

1. Localize o setor na lista
2. Clique em **"Associar Departamentos"**
3. Selecione o **nível** do departamento (1 a 6)
4. Selecione os **departamentos** desejados
5. Clique em **"Adicionar"**

**Exemplo de associação:**

```
Setor: BEBIDAS
└─ Associar Dept Nível 3:
    ├─ BEBIDAS ALCOOLICAS
    ├─ BEBIDAS NÃO ALCOOLICAS
    └─ SUCOS E REFRESCOS
```

Quando associa um departamento de nível 3, **todos os departamentos filhos** (níveis 2, 1) são automaticamente incluídos.

### 11.5 Hierarquia de Departamentos

O sistema usa uma estrutura de **6 níveis**:

```
Nível 6 (Mais genérico)
  └─ Nível 5
      └─ Nível 4
          └─ Nível 3 (Setor/Categoria)
              └─ Nível 2 (Grupo)
                  └─ Nível 1 (Subgrupo/Mais específico)
```

**Uso recomendado:**
- **Níveis 6-4**: Macro categorias
- **Nível 3**: Setores principais (use para metas por setor)
- **Níveis 2-1**: Classificações detalhadas

### 11.6 Visualizar Associações

Na tela de setores, você vê:
- Nome do setor
- Quantidade de departamentos associados
- Lista de departamentos vinculados
- Botão para editar associações

### 11.7 Editar Setor

1. Clique no ícone ✏️ (lápis) do setor
2. Modifique:
   - Nome
   - Descrição
   - Status
   - Departamentos associados
3. Clique em **"Salvar"**

### 11.8 Desativar Setor

⚠️ **Não é possível excluir setores com dados associados**

Para desativar:
1. Edite o setor
2. Altere **Status** para "Inativo"
3. Salve

Setores inativos:
- Não aparecem em filtros
- Não podem receber novas metas
- Mantêm histórico de dados

### 11.9 Impacto das Configurações

**Metas por Setor:**
- Usa setores configurados aqui
- Consolida vendas dos departamentos associados
- Calcula atingimento baseado nas associações

**Relatórios:**
- Permite filtrar por setor
- Agrupa dados conforme associações
- Facilita análise por categoria de negócio

---

## 12. Gestão de Usuários

### 12.1 Visão Geral

O módulo de Gestão de Usuários permite criar, editar e gerenciar contas de acesso ao sistema.

**Acesso:** Menu Lateral → Usuários

**Permissão:** Admin ou Super Admin

### 12.2 Listar Usuários

**Visualização:**
- Lista todos os usuários da empresa
- Super Admins veem usuários de todas as empresas

**Informações exibidas:**
- Nome completo
- E-mail
- Papel (Role)
- Status (Ativo/Inativo)
- Filiais autorizadas
- Data de criação
- Ações (Editar, Desativar)

**Filtros:**
- **Busca**: Pesquisar por nome ou e-mail
- **Papel**: Filtrar por role (Admin, Gestor, Visualizador)
- **Status**: Ativos, Inativos ou Todos

### 12.3 Criar Novo Usuário

#### Passos:

1. Clique em **"Novo Usuário"**
2. Preencha o formulário:

**Dados Pessoais:**
- **Nome Completo**: Nome do usuário
- **E-mail**: E-mail de login (único no sistema)

**Dados de Acesso:**
- **Papel**: Selecione o nível de acesso
  - Super Administrador (somente Super Admin pode criar)
  - Administrador
  - Gestor
  - Visualizador

**Restrições de Acesso:**
- **Filiais Autorizadas**:
  - Deixe vazio = acesso a todas as filiais
  - Selecione filiais = acesso restrito apenas às selecionadas

3. Clique em **"Criar Usuário"**

#### O que acontece após criação:

1. Usuário recebe e-mail de confirmação
2. E-mail contém link para definir senha
3. Usuário deve clicar no link em até 24h
4. Após definir senha, pode fazer login

### 12.4 Editar Usuário

1. Clique no ícone ✏️ (lápis) do usuário
2. Modifique os campos necessários:
   - Nome completo
   - Papel
   - Filiais autorizadas
   - Status

⚠️ **Não é possível alterar o e-mail** após criação

3. Clique em **"Salvar"**

### 12.5 Alterar E-mail do Usuário

**Processo especial** para alterar e-mail:

1. Edite o usuário
2. Clique em **"Alterar E-mail"**
3. Digite o novo e-mail
4. Clique em **"Confirmar"**
5. Sistema enviará e-mail de confirmação para o **novo** endereço
6. Usuário deve confirmar o novo e-mail

⚠️ Até confirmar o novo e-mail, o usuário continua usando o e-mail antigo.

### 12.6 Redefinir Senha

**Se usuário esqueceu a senha:**

1. Edite o usuário
2. Clique em **"Enviar E-mail de Recuperação"**
3. Usuário receberá link para redefinir senha
4. Link válido por 24 horas

**Senha temporária:**

Administradores podem definir senha temporária:
1. Edite o usuário
2. Digite uma senha temporária
3. Marque **"Exigir troca na próxima entrada"**
4. Usuário deverá alterar senha no primeiro login

### 12.7 Desativar Usuário

**Para desativar acesso:**

1. Edite o usuário
2. Altere **Status** para "Inativo"
3. Salve

**Usuário inativo:**
- ❌ Não consegue fazer login
- ✅ Dados históricos são mantidos
- ✅ Pode ser reativado a qualquer momento

**Para reativar:**
1. Edite o usuário inativo
2. Altere **Status** para "Ativo"
3. Salve

⚠️ **Não é possível excluir usuários** (apenas desativar)

### 12.8 Filiais Autorizadas

**Como funciona:**

Administradores podem restringir acesso de usuários a filiais específicas.

**Cenários:**

**Sem restrição (padrão):**
```
Usuário: João
Filiais Autorizadas: (vazio)
Acesso: TODAS as filiais da empresa
```

**Com restrição:**
```
Usuário: Maria
Filiais Autorizadas: Filial 1, Filial 3
Acesso: SOMENTE Filiais 1 e 3
```

**Como configurar:**

1. Edite o usuário
2. Na seção "Filiais Autorizadas"
3. Selecione as filiais permitidas
4. Salve

**Impacto:**
- Usuário só verá dados das filiais autorizadas em:
  - Dashboard
  - Relatórios
  - Metas
  - DRE Gerencial
- Filtros mostrarão apenas filiais autorizadas

### 12.9 Audoria de Acessos

**Registro automático:**

O sistema registra automaticamente:
- Data/hora de login
- Módulos acessados
- Ações realizadas (criar, editar, excluir)
- Tentativas de acesso não autorizado

**Visualizar logs:**

Super Admins podem acessar logs de auditoria:
- Menu → Auditoria (em desenvolvimento)
- Filtrar por usuário, data, ação
- Exportar relatório de acessos

---

## 13. Gestão de Empresas

### 13.1 Visão Geral

O módulo de Gestão de Empresas permite criar e gerenciar múltiplas empresas (tenants) no sistema.

**Acesso:** Menu Lateral → Empresas

**Permissão:** Somente Super Admin

### 13.2 Conceito de Tenant

**O que é um Tenant?**

Um tenant (inquilino) é uma empresa independente no sistema com:
- ✅ Dados completamente isolados
- ✅ Schema próprio no banco de dados
- ✅ Usuários próprios
- ✅ Configurações independentes

**Exemplo:**
```
Tenant: Supermercado ABC Ltda
  ├─ Schema: abc_supermercado
  ├─ Filiais: 5
  ├─ Usuários: 15
  └─ Dados: Isolados de outros tenants
```

### 13.3 Listar Empresas

**Visualização:**

Lista todas as empresas cadastradas no sistema.

**Informações exibidas:**
- Nome da empresa
- Schema do banco de dados
- Tipo (Empresa, Filial)
- Status (Ativo/Inativo)
- Quantidade de filiais
- Data de criação
- Ações (Ver, Editar, Desativar)

### 13.4 Criar Nova Empresa

#### Passos:

1. Clique em **"Nova Empresa"**
2. Preencha os dados:

**Informações Básicas:**
- **Nome**: Nome da empresa
- **CNPJ**: CNPJ (opcional)
- **Tipo**: Empresa ou Filial

**Configuração Técnica:**
- **Schema**: Nome do schema no banco de dados
  - Apenas letras minúsculas e underline
  - Exemplo: `supermercado_abc`
  - ⚠️ Deve ser único no sistema

**Configurações:**
- **Status**: Ativo/Inativo
- **Limite de Usuários**: Opcional
- **Limite de Filiais**: Opcional

3. Clique em **"Criar Empresa"**

#### O que acontece após criação:

⚠️ **IMPORTANTE:** A criação da empresa **NÃO cria automaticamente** o schema no banco de dados.

**Passos necessários após criação:**

1. **Criar schema no PostgreSQL:**
   ```sql
   CREATE SCHEMA nome_schema;
   ```

2. **Executar migrações:**
   - Criar tabelas (vendas, produtos, etc)
   - Criar funções RPC
   - Configurar permissões

3. **Adicionar ao "Exposed schemas":**
   - Supabase Dashboard → Settings → API
   - Adicionar schema à lista de "Exposed schemas"
   - Exemplo: `public, okilao, saoluiz, novo_schema`

4. **Importar dados iniciais:**
   - Filiais
   - Departamentos
   - Produtos (se aplicável)

**Referência:** Ver `docs/SUPABASE_SCHEMA_CONFIGURATION.md` e migrations em `supabase/migrations/`

### 13.5 Editar Empresa

1. Clique no ícone ✏️ (lápis) da empresa
2. Modifique:
   - Nome
   - CNPJ
   - Status
   - Limites
3. Salve

⚠️ **Não é possível alterar o schema** após criação

### 13.6 Visualizar Detalhes da Empresa

1. Clique no nome da empresa ou ícone 👁️ (olho)
2. Visualize:
   - Informações completas
   - Lista de filiais
   - Lista de usuários
   - Estatísticas de uso

### 13.7 Desativar Empresa

**Para desativar:**

1. Edite a empresa
2. Altere **Status** para "Inativo"
3. Salve

**Empresa inativa:**
- ❌ Usuários não conseguem fazer login
- ❌ Não aparece no seletor de empresas
- ✅ Dados são mantidos no banco
- ✅ Pode ser reativada

**Para reativar:**
1. Edite a empresa
2. Altere **Status** para "Ativo"
3. Salve

### 13.8 Alternar entre Empresas (Super Admin)

Como Super Admin, você pode acessar dados de qualquer empresa:

1. Clique no **nome da empresa** no cabeçalho
2. Selecione a empresa desejada na lista
3. Sistema recarrega com dados da nova empresa

**Indicador visual:**
- Nome da empresa atual sempre visível no cabeçalho
- Badge "Super Administrador" indica acesso multi-tenant

### 13.9 Filiais da Empresa

Cada empresa pode ter múltiplas filiais.

**Gerenciar filiais:**

1. Acesse detalhes da empresa
2. Clique em **"Filiais"**
3. Adicione, edite ou remova filiais

**Informações de filial:**
- Nome da filial
- Código/ID
- Endereço
- Responsável
- Status

---

## 14. Perfil do Usuário

### 14.1 Acessar Perfil

1. Clique no **ícone de usuário** no canto superior direito
2. Selecione **"Meu Perfil"**

### 14.2 Visualizar Informações

**Dados exibidos:**
- Nome completo
- E-mail
- Papel (role)
- Empresa vinculada
- Filiais autorizadas
- Data de criação da conta
- Último acesso

### 14.3 Editar Perfil

**Campos editáveis:**
- Nome completo
- Foto de perfil (em desenvolvimento)

**Campos não editáveis:**
- E-mail (solicite ao administrador)
- Papel (solicite ao administrador)
- Empresa (solicite ao Super Admin)

**Como editar:**
1. Clique em **"Editar Perfil"**
2. Modifique os campos permitidos
3. Clique em **"Salvar"**

### 14.4 Alterar Senha

1. No perfil, clique em **"Alterar Senha"**
2. Digite:
   - **Senha Atual**
   - **Nova Senha**
   - **Confirmar Nova Senha**
3. Clique em **"Alterar"**

**Requisitos de senha:**
- Mínimo 8 caracteres
- Pelo menos 1 letra maiúscula
- Pelo menos 1 número
- Pelo menos 1 caractere especial

### 14.5 Notificações

**Configurar preferências de notificação:**
- E-mail para novos relatórios
- Alertas de metas
- Notificações de aprovações

(Em desenvolvimento)

### 14.6 Sair do Sistema

1. Clique no ícone de usuário
2. Selecione **"Sair"**
3. Você será redirecionado para a tela de login

---

## 15. Perguntas Frequentes

### 15.1 Login e Acesso

**P: Esqueci minha senha. O que faço?**

R: Na tela de login, clique em "Esqueceu sua senha?", digite seu e-mail e siga as instruções enviadas por e-mail.

**P: Não recebi o e-mail de recuperação de senha.**

R:
1. Verifique a caixa de spam/lixo eletrônico
2. Aguarde alguns minutos (pode haver atraso)
3. Certifique-se de digitar o e-mail correto
4. Contate o administrador se persistir

**P: Posso usar o sistema no celular?**

R: Sim! O sistema é responsivo e funciona em smartphones e tablets. Recomendamos usar na horizontal para melhor visualização de relatórios.

### 15.2 Dados e Relatórios

**P: Os dados são atualizados em tempo real?**

R: Sim. Os dados de vendas, lucro e metas são atualizados automaticamente conforme novas transações são registradas no sistema.

**P: Por que não vejo dados de algumas filiais?**

R: Sua conta pode ter **restrição de filiais**. Contate seu administrador para liberar acesso.

**P: Como exportar dados para Excel?**

R: Atualmente, o sistema oferece exportação em **PDF**. A exportação para Excel está em desenvolvimento.

**P: Posso criar relatórios personalizados?**

R: No momento, os relatórios são padrão. Estamos trabalhando em uma funcionalidade de relatórios customizáveis.

### 15.3 Metas

**P: Como são calculados os percentuais de meta atingida?**

R:
```
% Atingida = (Valor Realizado / Meta Definida) × 100
```
Exemplo: Meta R$ 10.000, Realizado R$ 8.500 = 85% atingido

**P: Posso copiar metas de um mês para outro?**

R: Sim! Em **Metas Mensais**, use o botão "Copiar Mês Anterior" para duplicar os valores.

**P: Por que minhas metas não estão atualizando automaticamente?**

R: Certifique-se de que:
1. As metas foram salvas corretamente
2. Os filtros estão aplicados (mês/ano corretos)
3. Há dados de vendas no período selecionado

### 15.4 DRE Gerencial

**P: O que significa PAM e PAA?**

R:
- **PAM**: Período Anterior Mês (mês anterior)
- **PAA**: Período Anterior Ano (mesmo mês do ano anterior)

**P: Por que o CMV parece diferente do esperado?**

R: O sistema aplica a **Correção de Desconto Custo** automaticamente:
```
CMV Correto = CMV Original - desconto_custo
```
Isso garante que descontos de fornecedores reduzam o custo.

**P: Como adicionar novas categorias de despesa?**

R: Contate o administrador ou Super Admin para configurar novas categorias na hierarquia de despesas.

### 15.5 Configurações e Permissões

**P: Como solicitar acesso a mais filiais?**

R: Entre em contato com seu **Administrador** para que ele edite suas permissões de filiais autorizadas.

**P: Posso criar usuários?**

R: Somente **Administradores** e **Super Admins** podem criar e gerenciar usuários.

**P: Como mudar meu papel de Visualizador para Gestor?**

R: Apenas o **Administrador** pode alterar papéis. Solicite a mudança ao responsável.

### 15.6 Problemas Técnicos

**P: A página está carregando lentamente. O que faço?**

R:
1. Verifique sua conexão com a internet
2. Limpe o cache do navegador (Ctrl+Shift+Del)
3. Tente usar outro navegador
4. Se persistir, contate o suporte

**P: Recebi erro "Schema not found" ou "Permission denied".**

R: Esse é um erro de configuração do banco de dados. Contate o **Super Admin** ou suporte técnico.

**P: Não consigo exportar PDF.**

R:
1. Verifique se há dados para exportar (filtros aplicados)
2. Desabilite bloqueadores de pop-up
3. Tente em modo anônimo do navegador
4. Se persistir, contate o suporte

**P: Meus filtros não estão funcionando.**

R:
1. Certifique-se de clicar em "Aplicar" ou "Buscar"
2. Verifique se selecionou valores válidos
3. Atualize a página (F5)
4. Limpe cache do navegador

---

## 16. Solução de Problemas

### 16.1 Erros Comuns

#### Erro: "Não autorizado" ou "403 Forbidden"

**Causa:** Tentativa de acessar recurso sem permissão.

**Solução:**
1. Verifique seu papel (role)
2. Contate administrador para solicitar permissão
3. Faça logout e login novamente

#### Erro: "Schema must be one of the following"

**Causa:** Schema não está configurado como "Exposed" no Supabase.

**Solução (Super Admin apenas):**
1. Acesse Supabase Dashboard → Settings → API
2. Adicione o schema em "Exposed schemas"
3. Aguarde 1-2 minutos
4. Tente novamente

**Referência:** `docs/SUPABASE_SCHEMA_CONFIGURATION.md`

#### Erro: "Falha ao carregar dados"

**Causas possíveis:**
- Conexão com internet instável
- Servidor temporariamente indisponível
- Filtros inválidos

**Solução:**
1. Verifique conexão com internet
2. Aguarde alguns segundos e tente novamente
3. Recarregue a página (F5)
4. Se persistir, contate suporte

#### Erro: "E-mail já cadastrado"

**Causa:** Tentativa de criar usuário com e-mail existente.

**Solução:**
1. Use outro e-mail
2. Ou edite o usuário existente se for o mesmo

#### Página em branco ou travada

**Solução:**
1. Recarregue a página (F5)
2. Limpe cache: Ctrl+Shift+Delete → Limpar dados
3. Tente em modo anônimo
4. Use outro navegador
5. Desabilite extensões do navegador

### 16.2 Problemas de Performance

#### Filtros demoram muito para aplicar

**Causas:**
- Grande volume de dados
- Conexão lenta
- Muitas filiais selecionadas

**Soluções:**
1. Selecione períodos menores
2. Filtre por filiais específicas (não "Todas")
3. Use filtros de produto quando disponível
4. Aguarde carregamento completo

#### Exportação de PDF falha ou trava

**Causas:**
- Muitos registros (>10.000)
- Pop-ups bloqueados
- Memória insuficiente

**Soluções:**
1. Reduza o período ou filiais
2. Permita pop-ups do site
3. Feche outras abas do navegador
4. Use Chrome ou Firefox atualizado

### 16.3 Dúvidas sobre Dados

#### Valores não conferem com sistema legado

**Verificar:**
1. **Período selecionado:** Mesmo mês/ano?
2. **Filiais:** Mesmas filiais comparadas?
3. **Descontos:** Sistema aplica descontos automaticamente
4. **Metas vs Realizado:** Certifique-se de comparar campos corretos

**Contate:**
- Administrador para verificação
- Suporte técnico se discrepância persistir

#### Produtos não aparecem no relatório

**Verificar:**
1. **Filtros:** Produto está no período selecionado?
2. **Filial:** Produto está na filial selecionada?
3. **Filtro de Produto:** Mínimo 3 caracteres
4. **Departamento:** Produto está em departamento associado?

#### Metas não atualizam valores realizados

**Verificar:**
1. Há vendas no período da meta?
2. Filiais corretas selecionadas?
3. Metas foram salvas?
4. Recarregue a página (F5)

### 16.4 Contatos e Suporte

**Suporte Nível 1 - Usuários:**
- Contate seu **Administrador** local
- Verifique este manual primeiro

**Suporte Nível 2 - Administradores:**
- Contate o **Super Admin** da empresa
- Consulte documentação técnica em `/docs`

**Suporte Nível 3 - Técnico:**
- E-mail: suporte@bisaas.com.br
- Inclua:
  - Descrição do problema
  - Passos para reproduzir
  - Screenshot (se aplicável)
  - Navegador e versão
  - Nome de usuário (não senha!)

**Documentação Técnica:**
- GitHub: `/docs` folder
- `CLAUDE.md` - Visão geral técnica
- `FILTER_PATTERN_STANDARD.md` - Padrões de filtros
- `SUPABASE_SCHEMA_CONFIGURATION.md` - Configuração de schemas
- `DRE_GERENCIAL_INTEGRATION.md` - DRE técnico

### 16.5 Atualizações e Changelog

**Verificar versão:**
- Rodapé do sistema mostra versão atual
- Changelog disponível em `/docs/CHANGELOG.md`

**Novas funcionalidades:**
- Sistema é atualizado regularmente
- Novas features são anunciadas via e-mail
- Verificar notas de lançamento no login

---

## 📞 Contato e Informações

**Sistema:** BI SaaS Dashboard
**Versão:** 1.0.0
**Data:** Novembro 2024

**Desenvolvido por:** Equipe BI SaaS
**Suporte:** suporte@bisaas.com.br
**Documentação:** [github.com/datapro-md4/docs](https://github.com)

---

**© 2024 BI SaaS. Todos os direitos reservados.**

Este manual está sujeito a atualizações. Última revisão: Novembro/2024.
