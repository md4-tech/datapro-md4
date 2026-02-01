# Rollback: Linha de Receita Bruta no DataTable DRE

**Data da Modificação**: 2025-01-12
**Solicitante**: Cliente
**Desenvolvedor**: Claude Code
**Status**: 🟡 Em implementação

---

## 📋 Resumo da Modificação

**Objetivo**: Adicionar uma linha de "RECEITA BRUTA" acima da linha "TOTAL DESPESAS" no DataTable do módulo DRE Gerencial.

**Impacto**:
- ✅ Apenas alterações no frontend (página DRE Gerencial)
- ✅ Nenhuma alteração em funções RPC do banco de dados
- ✅ Nenhuma alteração nas tabelas do banco
- ✅ Baixo risco de rollback

---

## 🔄 Arquivos Modificados

### 1. `/src/app/(dashboard)/dre-gerencial/page.tsx`

#### Modificações:
1. **Nova interface `ReceitaBrutaPorFilial`** (linhas ~65-68)
2. **Nova propriedade no estado** `receitaPorFilial` (linha ~113)
3. **Nova função `fetchReceitaBrutaPorFilial`** (linhas ~232-272)
4. **Modificação na função `handleFilter`** (adiciona chamada para buscar receita bruta)
5. **Modificação na função `transformToTableData`** (adiciona linha de Receita Bruta)

---

## 📦 Backup do Código Original

### Estado Original - Interfaces (linha 20-90)

```typescript
// BACKUP: Interfaces originais (ANTES DA MODIFICAÇÃO)
// Não havia interface ReceitaBrutaPorFilial

interface DespesaPorFilial {
  data_despesa: string
  descricao_despesa: string
  fornecedor_id: string | null
  numero_nota: number | null
  serie_nota: string | null
  observacao: string | null
  data_emissao: string | null
  valores_filiais: Record<number, number>
}

interface TipoPorFilial {
  tipo_id: number
  tipo_descricao: string
  valores_filiais: Record<number, number>
  despesas: DespesaPorFilial[]
}

interface DepartamentoPorFilial {
  dept_id: number
  dept_descricao: string
  valores_filiais: Record<number, number>
  tipos: TipoPorFilial[]
}

interface GraficoData {
  mes: string
  valor: number
}

interface ReportData {
  totalizador: {
    valorTotal: number
    qtdRegistros: number
    qtdDepartamentos: number
    qtdTipos: number
    mediaDepartamento: number
  }
  grafico: GraficoData[]
  departamentos: DepartamentoPorFilial[]
  filiais: number[]
}

interface IndicadoresData {
  receitaBruta: number
  lucroBruto: number
  cmv: number
  totalDespesas: number
  lucroLiquido: number
  margemLucroBruto: number
  margemLucroLiquido: number
}

interface DashboardData {
  total_vendas?: number
  total_lucro?: number
  margem_lucro?: number
}

interface ComparacaoIndicadores {
  current: IndicadoresData
  pam: {
    data: IndicadoresData
    ano: number
  }
  paa: {
    data: IndicadoresData
    ano: number
  }
}
```

### Estado Original - Estados do Componente (linha ~100-115)

```typescript
// BACKUP: Estados originais (ANTES DA MODIFICAÇÃO)
// Não havia estado receitaPorFilial

const [mes, setMes] = useState<number>(mesAnterior)
const [ano, setAno] = useState<number>(anoMesAnterior)
const [filiaisSelecionadas, setFiliaisSelecionadas] = useState<FilialOption[]>([])
const [data, setData] = useState<ReportData | null>(null)
const [dataPam, setDataPam] = useState<ReportData | null>(null)
const [dataPaa, setDataPaa] = useState<ReportData | null>(null)
const [loading, setLoading] = useState(false)
const [error, setError] = useState('')
const [indicadores, setIndicadores] = useState<ComparacaoIndicadores | null>(null)
const [loadingIndicadores, setLoadingIndicadores] = useState(false)
```

### Estado Original - transformToTableData (linha 517-597)

```typescript
// BACKUP: Função transformToTableData ORIGINAL (ANTES DA MODIFICAÇÃO)

const transformToTableData = (reportData: ReportData): DespesaRow[] => {
  const rows: DespesaRow[] = []

  // Linha de total
  const totalRow: DespesaRow = {
    id: 'total',
    tipo: 'total',
    descricao: 'TOTAL DESPESAS',
    total: reportData.totalizador.valorTotal,
    percentual: 100,
    valores_filiais: reportData.departamentos.reduce((acc, dept) => {
      reportData.filiais.forEach(filialId => {
        acc[filialId] = (acc[filialId] || 0) + (dept.valores_filiais[filialId] || 0)
      })
      return acc
    }, {} as Record<number, number>),
    filiais: reportData.filiais,
    subRows: []
  }

  // Departamentos
  reportData.departamentos.forEach((dept) => {
    const deptTotal = Object.values(dept.valores_filiais).reduce((sum, v) => sum + v, 0)

    const deptRow: DespesaRow = {
      id: `dept_${dept.dept_id}`,
      tipo: 'departamento',
      descricao: dept.dept_descricao,
      total: deptTotal,
      percentual: (deptTotal / reportData.totalizador.valorTotal) * 100,
      valores_filiais: dept.valores_filiais,
      filiais: reportData.filiais,
      subRows: []
    }

    // Tipos
    dept.tipos.forEach((tipo) => {
      const tipoTotal = Object.values(tipo.valores_filiais).reduce((sum, v) => sum + v, 0)

      const tipoRow: DespesaRow = {
        id: `tipo_${dept.dept_id}_${tipo.tipo_id}`,
        tipo: 'tipo',
        descricao: tipo.tipo_descricao,
        total: tipoTotal,
        percentual: (tipoTotal / reportData.totalizador.valorTotal) * 100,
        valores_filiais: tipo.valores_filiais,
        filiais: reportData.filiais,
        subRows: []
      }

      // Despesas
      tipo.despesas.forEach((desp, idx) => {
        const despTotal = Object.values(desp.valores_filiais).reduce((sum, v) => sum + v, 0)

        const despRow: DespesaRow = {
          id: `desp_${dept.dept_id}_${tipo.tipo_id}_${idx}`,
          tipo: 'despesa',
          descricao: desp.descricao_despesa || 'Sem descrição',
          data_despesa: desp.data_despesa,
          data_emissao: desp.data_emissao || undefined,
          numero_nota: desp.numero_nota,
          serie_nota: desp.serie_nota,
          observacao: desp.observacao,
          total: despTotal,
          percentual: (despTotal / reportData.totalizador.valorTotal) * 100,
          valores_filiais: desp.valores_filiais,
          filiais: reportData.filiais,
        }

        tipoRow.subRows!.push(despRow)
      })

      deptRow.subRows!.push(tipoRow)
    })

    totalRow.subRows!.push(deptRow)
  })

  rows.push(totalRow)
  return rows
}
```

---

## 🔙 Procedimento de Rollback

### Passo 1: Fazer backup do arquivo modificado

```bash
# 1. Navegar até o diretório do projeto
cd /Users/samueldutra/devinga-dash/datapro-md4

# 2. Criar backup da versão modificada (caso queira recuperar depois)
cp src/app/\(dashboard\)/dre-gerencial/page.tsx src/app/\(dashboard\)/dre-gerencial/page.tsx.backup-receita-bruta

# 3. Verificar que o backup foi criado
ls -la src/app/\(dashboard\)/dre-gerencial/
```

### Passo 2: Restaurar o arquivo original

**Opção A: Via Git (SE as mudanças foram commitadas)**

```bash
# 1. Verificar status do git
git status

# 2. Se foi commitado, reverter o commit
git log --oneline -5  # Ver últimos 5 commits
git revert <COMMIT_HASH_DA_MODIFICACAO>

# OU desfazer o commit (se for o último commit e não foi pushed)
git reset --hard HEAD~1
```

**Opção B: Substituição Manual (MAIS SEGURO)**

1. Abrir o arquivo: `/src/app/(dashboard)/dre-gerencial/page.tsx`

2. **Remover as linhas adicionadas**:
   - Nova interface `ReceitaBrutaPorFilial` (se foi adicionada)
   - Novo estado `receitaPorFilial`
   - Nova função `fetchReceitaBrutaPorFilial`
   - Chamada para `fetchReceitaBrutaPorFilial` dentro de `handleFilter`

3. **Restaurar a função `transformToTableData`** original (copiar do backup acima)

4. Salvar o arquivo

### Passo 3: Testar após rollback

```bash
# 1. Limpar cache do Next.js
npm run clean

# 2. Reiniciar servidor de desenvolvimento
npm run dev

# 3. Testar no navegador
# - Acessar /dre-gerencial
# - Verificar que a tabela voltou ao estado original (sem linha de Receita Bruta)
# - Verificar que não há erros no console
```

### Passo 4: Verificar integridade

**Checklist de Verificação Pós-Rollback:**

- [ ] Página `/dre-gerencial` carrega sem erros
- [ ] Filtros funcionam normalmente
- [ ] Cards de indicadores exibem valores corretos
- [ ] Tabela de despesas exibe hierarquia corretamente
- [ ] Não há linha de "RECEITA BRUTA" na tabela
- [ ] Primeira linha é "TOTAL DESPESAS"
- [ ] Console do navegador sem erros
- [ ] Comparações PAM/PAA funcionam

---

## 🚨 Problemas Comuns e Soluções

### Problema 1: Erro "Cannot read property 'valores_filiais' of undefined"

**Causa**: Estado `receitaPorFilial` ainda sendo referenciado no código

**Solução**:
```bash
# Buscar todas as referências no código
grep -n "receitaPorFilial" src/app/\(dashboard\)/dre-gerencial/page.tsx

# Remover todas as linhas que referenciam receitaPorFilial
```

### Problema 2: Tabela não renderiza após rollback

**Causa**: Erro de sintaxe ou função `transformToTableData` mal restaurada

**Solução**:
1. Verificar console do navegador para erros
2. Comparar função `transformToTableData` com o backup acima
3. Garantir que todas as chaves `{}` estão fechadas corretamente

### Problema 3: Build falha após rollback

**Causa**: Cache corrompido

**Solução**:
```bash
npm run clean:all
npm run dev
```

---

## 📊 Comparação: Antes vs Depois

### ANTES (Estado Original)
```
DataTable DRE Gerencial:
├── TOTAL DESPESAS (linha 1)
│   ├── DEPARTAMENTO 1
│   │   ├── Tipo 1
│   │   │   └── Despesa 1
│   │   └── Tipo 2
│   └── DEPARTAMENTO 2
```

### DEPOIS (Com Modificação)
```
DataTable DRE Gerencial:
├── RECEITA BRUTA (linha 1) ← NOVA LINHA
├── TOTAL DESPESAS (linha 2)
│   ├── DEPARTAMENTO 1
│   │   ├── Tipo 1
│   │   │   └── Despesa 1
│   │   └── Tipo 2
│   └── DEPARTAMENTO 2
```

---

## 🔍 Arquivos NÃO Modificados

Estes arquivos **NÃO foram alterados** nesta modificação:

- ✅ `/src/components/despesas/columns.tsx` (pode haver pequenas mudanças para suportar novo tipo de linha)
- ✅ `/src/components/despesas/data-table.tsx`
- ✅ `/src/components/despesas/filters.tsx`
- ✅ `/src/components/despesas/indicators-cards.tsx`
- ✅ `/src/app/api/dre-gerencial/hierarquia/route.ts`
- ✅ `/src/app/api/dashboard/route.ts`
- ✅ Nenhuma função RPC no banco de dados
- ✅ Nenhuma tabela no banco de dados

---

## 📝 Notas Importantes

1. **Sem alterações no banco**: Esta modificação é 100% frontend, sem necessidade de rollback de banco de dados
2. **Sem migrations**: Não há migrações SQL para reverter
3. **Sem mudanças em API**: As APIs continuam funcionando da mesma forma
4. **Rollback rápido**: Pode ser revertido em menos de 5 minutos
5. **Baixo risco**: Apenas uma página é afetada

---

## 📞 Suporte

Se encontrar problemas durante o rollback:

1. **Verificar este documento** primeiro
2. **Verificar logs do console** do navegador
3. **Verificar logs do servidor** Next.js
4. **Comparar código com backup** acima
5. **Usar git diff** se as mudanças foram commitadas

---

## ✅ Checklist Final de Rollback

Após executar o rollback, verificar:

- [ ] Arquivo `page.tsx` restaurado ao estado original
- [ ] Servidor Next.js reiniciado
- [ ] Cache limpo (`npm run clean`)
- [ ] Página `/dre-gerencial` acessível
- [ ] Nenhum erro no console do navegador
- [ ] Nenhum erro no terminal do servidor
- [ ] Tabela exibe dados corretamente
- [ ] Filtros funcionam
- [ ] Cards de indicadores funcionam
- [ ] Comparações PAM/PAA funcionam

---

**Data de Criação do Documento**: 2025-01-12
**Versão**: 1.0.0
**Status**: 📋 Pronto para uso
