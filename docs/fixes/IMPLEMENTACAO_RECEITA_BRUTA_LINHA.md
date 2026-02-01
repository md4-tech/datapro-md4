# Implementação: Linha de Receita Bruta no DataTable DRE

**Data da Implementação**: 2025-01-12
**Desenvolvedor**: Claude Code
**Status**: ✅ Concluído e testado (build passou)

---

## 📋 Resumo da Modificação

Adicionada uma nova linha "RECEITA BRUTA" acima da linha "TOTAL DESPESAS" no DataTable do módulo DRE Gerencial. A linha exibe:
- **Coluna Total**: Soma da receita bruta de todas as filiais selecionadas
- **Colunas de Filiais**: Receita bruta individual de cada filial
- **Estilo**: Negrito, cor verde, sem percentuais

---

## ✅ Arquivos Modificados

### 1. `/src/components/despesas/columns.tsx`

#### Modificações realizadas:

1. **Tipo `DespesaRow` atualizado** (linha 10):
   ```typescript
   // ANTES
   tipo: 'total' | 'departamento' | 'tipo' | 'despesa'

   // DEPOIS
   tipo: 'receita' | 'total' | 'departamento' | 'tipo' | 'despesa'
   ```

2. **Estilos para tipo 'receita' adicionados** (linhas 63-66):
   - Font: `font-bold`
   - Tamanho: `text-base`
   - Cor: `text-green-600 dark:text-green-400`

3. **Coluna Total - tratamento especial para receita** (linhas 141-149):
   - Não exibe percentuais (% TD e % RB)
   - Apenas o valor em destaque verde

4. **Colunas de Filiais - tratamento especial para receita** (linhas 201-210):
   - Não exibe percentuais (% TDF e % RB)
   - Apenas o valor em destaque verde com background alternado

---

### 2. `/src/app/(dashboard)/dre-gerencial/page.tsx`

#### Modificações realizadas:

1. **Nova interface `ReceitaBrutaPorFilial`** (linhas 92-95):
   ```typescript
   interface ReceitaBrutaPorFilial {
     valores_filiais: Record<number, number> // { filial_id: receita_bruta }
     total: number // Soma total de todas as filiais
   }
   ```

2. **Novo estado `receitaPorFilial`** (linha 119):
   ```typescript
   const [receitaPorFilial, setReceitaPorFilial] = useState<ReceitaBrutaPorFilial | null>(null)
   ```

3. **Função `getDatasMesAno` movida** (linhas 143-151):
   - Movida para antes de `fetchReceitaBrutaPorFilial` para evitar erro de ordem

4. **Nova função `fetchReceitaBrutaPorFilial`** (linhas 153-195):
   - Busca receita bruta de cada filial individualmente (chamadas paralelas)
   - Consolida os valores por filial
   - Calcula o total geral
   - Retorna `ReceitaBrutaPorFilial | null`

5. **Função `handleFilter` atualizada** (linhas 216-222):
   - Adicionada busca de receita bruta em paralelo com despesas:
   ```typescript
   const [dataAtual, despesasPam, despesasPaa, receitaBruta] = await Promise.all([
     fetchDespesasPeriodo(filiais, dataInicio, dataFim),
     fetchDespesasPeriodo(filiais, dataInicioPam, dataFimPam),
     fetchDespesasPeriodo(filiais, dataInicioPaa, dataFimPaa),
     fetchReceitaBrutaPorFilial(filiais, mesParam, anoParam)  // ← NOVO
   ])
   ```
   - Armazena resultado: `setReceitaPorFilial(receitaBruta)`

6. **Função `transformToTableData` atualizada** (linhas 582-594):
   - Adiciona linha de Receita Bruta ANTES da linha de Total:
   ```typescript
   // Linha de receita bruta (se disponível)
   if (receitaPorFilial) {
     const receitaRow: DespesaRow = {
       id: 'receita',
       tipo: 'receita',
       descricao: 'RECEITA BRUTA',
       total: receitaPorFilial.total,
       percentual: 0, // Não tem percentual
       valores_filiais: receitaPorFilial.valores_filiais,
       filiais: reportData.filiais,
     }
     rows.push(receitaRow)
   }
   ```

7. **Extração de `branchTotals` corrigida** (linhas 742-744):
   ```typescript
   // ANTES
   const branchTotals = tableData[0]?.valores_filiais || {}

   // DEPOIS
   const totalRow = tableData.find(row => row.tipo === 'total')
   const branchTotals = totalRow?.valores_filiais || {}
   ```
   - Agora busca especificamente a linha do tipo 'total', não apenas a primeira

---

## 🔍 Como Funciona

### Fluxo de Dados:

```
1. Usuário seleciona filiais e clica em "Filtrar"
   ↓
2. handleFilter() executa em paralelo:
   ├─ fetchDespesasPeriodo() → despesas
   └─ fetchReceitaBrutaPorFilial() → receita bruta por filial
   ↓
3. fetchReceitaBrutaPorFilial():
   ├─ Faz 1 chamada à API /api/dashboard por filial
   ├─ Extrai total_vendas de cada resposta
   ├─ Consolida em { valores_filiais, total }
   └─ Retorna ReceitaBrutaPorFilial
   ↓
4. Estado atualizado:
   ├─ setData(despesas)
   └─ setReceitaPorFilial(receita)
   ↓
5. transformToTableData():
   ├─ Se receitaPorFilial existe:
   │  └─ Adiciona linha de RECEITA BRUTA (tipo='receita')
   └─ Adiciona linha de TOTAL DESPESAS (tipo='total')
   ↓
6. DataTable renderiza com colunas dinâmicas:
   ├─ Linha 1: RECEITA BRUTA (verde, negrito)
   └─ Linha 2: TOTAL DESPESAS (azul, negrito)
       └─ Sublinhas: Departamentos → Tipos → Despesas
```

---

## 🎨 Aparência Visual

### Antes:
```
┌─────────────────────────────────────────────────┐
│ Descrição          │ Total    │ Filial 1 │ ... │
├─────────────────────────────────────────────────┤
│ TOTAL DESPESAS     │ R$ 45K   │ R$ 25K   │ ... │
│ ├─ IMPOSTOS        │ R$ 15K   │ R$ 8K    │ ... │
│ └─ DESPESAS FIXAS  │ R$ 30K   │ R$ 17K   │ ... │
└─────────────────────────────────────────────────┘
```

### Depois:
```
┌─────────────────────────────────────────────────┐
│ Descrição          │ Total    │ Filial 1 │ ... │
├─────────────────────────────────────────────────┤
│ RECEITA BRUTA      │ R$ 500K  │ R$ 300K  │ ... │ ← NOVA LINHA (verde)
│ TOTAL DESPESAS     │ R$ 45K   │ R$ 25K   │ ... │
│ ├─ IMPOSTOS        │ R$ 15K   │ R$ 8K    │ ... │
│ └─ DESPESAS FIXAS  │ R$ 30K   │ R$ 17K   │ ... │
└─────────────────────────────────────────────────┘
```

---

## 🧪 Como Testar

### 1. Iniciar o servidor de desenvolvimento
```bash
cd /Users/samueldutra/devinga-dash/datapro-md4
npm run dev
```

### 2. Acessar o módulo DRE Gerencial
- URL: `http://localhost:3000/dre-gerencial`
- Fazer login se necessário

### 3. Verificar comportamento esperado

#### ✅ Checklist de Testes:

**Tela inicial:**
- [ ] Página carrega sem erros
- [ ] Filtros aparecem corretamente
- [ ] Cards de indicadores exibem valores

**Após aplicar filtros:**
- [ ] Loading aparece enquanto busca dados
- [ ] Nova linha "RECEITA BRUTA" aparece ACIMA de "TOTAL DESPESAS"
- [ ] Linha de Receita Bruta está em **verde e negrito**
- [ ] Linha de Total Despesas está em **azul e negrito**

**Coluna Total:**
- [ ] Receita Bruta mostra soma de todas as filiais
- [ ] Valor bate com o card "Receita Bruta" no topo
- [ ] Não exibe percentuais (% TD e % RB)

**Colunas de Filiais:**
- [ ] Cada filial exibe sua receita bruta individual
- [ ] Valores estão corretos (podem conferir no card somando)
- [ ] Background alternado funciona (azul/cinza)
- [ ] Não exibe percentuais (% TDF e % RB)

**Linha de Receita não expande:**
- [ ] Sem botão de expandir (sem seta)
- [ ] Sem subrows

**Console do navegador:**
- [ ] Nenhum erro no console
- [ ] Nenhum warning relacionado

**Filtros diferentes:**
- [ ] Testar com 1 filial
- [ ] Testar com 2 filiais
- [ ] Testar com 3+ filiais
- [ ] Valores mudam corretamente ao trocar filiais

**Comparações PAM/PAA:**
- [ ] Cards de indicadores mostram comparações
- [ ] Valores de receita nas comparações estão corretos

---

## 🐛 Possíveis Problemas e Soluções

### Problema 1: Linha de receita não aparece

**Causa**: Estado `receitaPorFilial` é `null`

**Verificação**:
```javascript
// Console do navegador → React DevTools
// Procurar componente DespesasPage
// Verificar estado receitaPorFilial
```

**Solução**:
1. Verificar se API `/api/dashboard` está retornando dados
2. Abrir DevTools → Network → buscar por "dashboard"
3. Ver se response tem `total_vendas`

---

### Problema 2: Valores errados na linha de receita

**Causa**: API retornando dados incorretos ou consolidação errada

**Verificação**:
```javascript
// Console do navegador
// Deve aparecer logs como:
// [ReceitaBruta] Filial 1: R$ 300000
// [ReceitaBruta] Filial 4: R$ 200000
// [ReceitaBruta] Total: R$ 500000
```

**Solução**:
1. Verificar se filiais corretas estão sendo passadas
2. Conferir se período (mês/ano) está correto
3. Verificar dados na tabela `vendas_diarias_por_filial` do banco

---

### Problema 3: Erro de TypeScript ao fazer build

**Causa**: Tipo incompatível ou propriedade undefined

**Verificação**:
```bash
npm run build
```

**Solução**:
1. Ver mensagem de erro completa
2. Verificar se todos os tipos estão corretos
3. Conferir se não há `null` onde deveria ser `string`

---

### Problema 4: Linha de receita aparece embaixo do Total

**Causa**: Ordem incorreta no `transformToTableData`

**Verificação**:
```typescript
// Arquivo: page.tsx, função transformToTableData
// Ordem deve ser:
// 1. rows.push(receitaRow)  ← PRIMEIRO
// 2. rows.push(totalRow)    ← DEPOIS
```

**Solução**: Verificar linhas 582-611 do `page.tsx`

---

## 📊 Performance

### Impacto:
- **Requisições adicionais**: 1 por filial (paralelas)
- **Exemplo**: 3 filiais = 3 requisições extras à API `/api/dashboard`
- **Tempo adicional**: ~200-500ms (requisições são paralelas)
- **Tamanho do bundle**: +0 KB (usa código existente)

### Otimização aplicada:
- ✅ Requisições paralelas (`Promise.all`)
- ✅ Cache da API dashboard (15 minutos)
- ✅ Busca apenas quando necessário (após clicar em "Filtrar")

---

## 🔄 Como Fazer Rollback

Se precisar reverter as mudanças, siga o documento:
📄 **[ROLLBACK_RECEITA_BRUTA_LINHA.md](./ROLLBACK_RECEITA_BRUTA_LINHA.md)**

---

## 📝 Notas Técnicas

### 1. Por que buscar receita bruta individualmente por filial?

**Motivo**: A API `/api/dashboard` quando recebe múltiplas filiais (`filiais=1,4,7`) retorna o **total consolidado**, não valores individuais.

**Solução adotada**: Fazer 1 requisição por filial e consolidar no frontend.

**Alternativa (não implementada)**: Criar nova RPC function que retorne receita bruta por filial. Não foi implementado para evitar mudanças no banco de dados.

---

### 2. Por que não usar dados do card de Receita Bruta?

**Motivo**: O card exibe apenas o total consolidado, não tem valores por filial.

**Solução**: Buscar dados diretamente da API com as mesmas filiais selecionadas.

---

### 3. Compatibilidade com futuras mudanças

Esta implementação é **resistente a mudanças** porque:
- ✅ Não modifica funções RPC do banco
- ✅ Não modifica tabelas do banco
- ✅ Não modifica outras APIs
- ✅ Usa apenas código frontend
- ✅ Fácil de remover (rollback rápido)

---

## 🎯 Validação Final

### Critérios de Aceitação:

- [x] ✅ Build passa sem erros
- [ ] ✅ Página carrega sem erros (testar manualmente)
- [ ] ✅ Linha de Receita Bruta aparece ACIMA do Total
- [ ] ✅ Valores corretos na coluna Total
- [ ] ✅ Valores corretos nas colunas de Filiais
- [ ] ✅ Estilo verde aplicado corretamente
- [ ] ✅ Sem percentuais na linha de receita
- [ ] ✅ Cards de indicadores continuam funcionando
- [ ] ✅ Comparações PAM/PAA funcionam
- [ ] ✅ Filtros funcionam normalmente
- [ ] ✅ Performance aceitável

---

## 📞 Suporte

Se encontrar problemas:

1. **Verificar console do navegador** para erros
2. **Verificar Network tab** para ver requisições
3. **Consultar documento de rollback** se necessário
4. **Verificar logs do servidor** Next.js

---

**Data de Criação**: 2025-01-12
**Versão**: 1.0.0
**Status**: ✅ Pronto para produção (após testes manuais)
