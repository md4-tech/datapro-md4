# Guia de Responsividade - Datapro-MD4 Dashboard

## Visão Geral

Este documento define os padrões de responsividade para o sistema Datapro-MD4 Dashboard, garantindo uma experiência consistente em todos os dispositivos.

## Breakpoints do Tailwind CSS

```css
/* Mobile First Approach */
Base (0-639px):    Layout mobile, 1 coluna, stack vertical
sm (640px+):       2 colunas para cards, filtros começam inline
md (768px+):       Sidebar visível, tabelas completas
lg (1024px+):      Layout completo desktop, 4 colunas
xl (1280px+):      Larguras maiores, mais espaçamento
```

---

## Padrões Obrigatórios

### 1. Filtros (PADRÃO OFICIAL)

**✅ Use este padrão em TODAS as telas:**

```tsx
<div className="flex flex-col gap-4 lg:flex-row lg:items-end lg:gap-4">
  {/* Filial - SEMPRE primeiro */}
  <div className="flex flex-col gap-2 w-full sm:w-auto">
    <Label>Filial</Label>
    <div className="h-10">
      <Select className="w-full sm:w-[200px] h-10">
        {/* ... */}
      </Select>
    </div>
  </div>

  {/* Mês - SEMPRE segundo */}
  <div className="flex flex-col gap-2 w-full sm:w-auto">
    <Label>Mês</Label>
    <div className="h-10">
      <Select className="w-full sm:w-[160px] h-10">
        {/* ... */}
      </Select>
    </div>
  </div>

  {/* Ano - SEMPRE terceiro */}
  <div className="flex flex-col gap-2 w-full sm:w-auto">
    <Label>Ano</Label>
    <div className="h-10">
      <Select className="w-full sm:w-[120px] h-10">
        {/* ... */}
      </Select>
    </div>
  </div>

  {/* Filtros específicos aqui */}

  {/* Botão - SEMPRE último */}
  <div className="flex justify-end lg:justify-start w-full lg:w-auto">
    <div className="h-10">
      <Button className="w-full sm:w-auto min-w-[120px] h-10">
        Aplicar
      </Button>
    </div>
  </div>
</div>
```

**Características:**
- ✅ Altura fixa `h-10` (40px) em TODOS os inputs e botões
- ✅ Ordem padronizada: Filial → Mês → Ano → Específicos → Botão
- ✅ Larguras responsivas: full width mobile, largura fixa desktop
- ✅ Wrapper `<div className="h-10">` para altura consistente
- ✅ `flex-col` mobile, `flex-row lg:` desktop
- ✅ `items-end` APENAS em desktop (`lg:items-end`)

**❌ NÃO FAÇA:**
```tsx
{/* ❌ ERRADO: items-end sem prefixo lg: */}
<div className="flex flex-col lg:flex-row gap-4 items-end">

{/* ❌ ERRADO: flex-1 causa larguras desproporcionais */}
<div className="space-y-2 flex-1">

{/* ❌ ERRADO: space-y-2 (use gap-2) */}
<div className="space-y-2">

{/* ❌ ERRADO: sem wrapper h-10 */}
<Label>Campo</Label>
<Select className="w-full h-10">
```

---

### 2. Headers com Ações

```tsx
<div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
  <div>
    <h1 className="text-2xl sm:text-3xl font-bold tracking-tight">Título</h1>
    <p className="text-sm text-muted-foreground">Descrição</p>
  </div>

  <Button
    onClick={handleAction}
    variant="outline"
    className="w-full sm:w-auto gap-2"
  >
    <FileDown className="h-4 w-4" />
    <span>Exportar PDF</span>
  </Button>
</div>
```

**Características:**
- Stack vertical mobile, horizontal desktop
- Botões full-width mobile
- Tamanhos de fonte responsivos
- `gap-4` para espaçamento adequado

---

### 3. Grid de Cards de Métricas

```tsx
<div className="grid gap-4 grid-cols-1 sm:grid-cols-2 lg:grid-cols-4">
  <CardMetric title="Métrica 1" value={value1} />
  <CardMetric title="Métrica 2" value={value2} />
  <CardMetric title="Métrica 3" value={value3} />
  <CardMetric title="Métrica 4" value={value4} />
</div>
```

**Breakpoints:**
- Mobile (< 640px): 1 coluna
- Tablet (640px+): 2 colunas
- Desktop (1024px+): 4 colunas

**❌ NÃO FAÇA:**
```tsx
{/* ❌ ERRADO: pula de 1 para 4 colunas */}
<div className="grid gap-4 md:grid-cols-1 lg:grid-cols-4">
```

---

### 4. Tabelas Complexas

Para tabelas com muitas colunas (> 4 colunas), use **scroll horizontal simples** em todos os breakpoints:

```tsx
<CardContent className="p-0">
  <div className="overflow-x-auto">
    <table className="w-full text-left text-sm">
      <thead className="bg-muted/50">
        <tr>
          <th className="p-3 border-b font-medium whitespace-nowrap">
            Coluna 1
          </th>
          <th className="p-3 border-b font-medium text-right whitespace-nowrap">
            Coluna 2
          </th>
          {/* Mais colunas... */}
        </tr>
      </thead>
      <tbody>
        {data.map((row) => (
          <tr key={row.id} className="hover:bg-muted/20">
            <td className="p-3 border-b whitespace-nowrap">
              {row.value1}
            </td>
            <td className="p-3 border-b text-right whitespace-nowrap">
              {row.value2}
            </td>
            {/* Mais células... */}
          </tr>
        ))}
      </tbody>
    </table>
  </div>
</CardContent>
```

**Características:**
- ✅ Scroll horizontal simples com `overflow-x-auto`
- ✅ `whitespace-nowrap` em todas as células para evitar quebra de linha
- ✅ Sem sticky columns (evita problemas de z-index e transparência)
- ✅ Funciona em todos os tamanhos de tela (mobile, tablet, desktop, 4K)
- ✅ Fácil de manter e debugar

**❌ NÃO FAÇA:**
```tsx
{/* ❌ EVITE: Sticky columns causam problemas de z-index e overflow */}
<th className="sticky left-0 z-10 bg-muted">...</th>

{/* ❌ EVITE: Layout alternativo mobile/desktop é muito complexo */}
<div className="block md:hidden">Card Layout</div>
<div className="hidden md:block">Table Layout</div>

{/* ❌ EVITE: Responsividade com larguras fixas */}
<th className="w-[300px] md:w-[400px]">...</th>
```

**Para tabelas simples (≤ 4 colunas), mesmo padrão:**

```tsx
<div className="rounded-md border overflow-x-auto">
  <Table>
    {/* Tabela com whitespace-nowrap nas células */}
  </Table>
</div>
```

---

### 5. Dialogs/Modals

```tsx
<DialogContent className="max-w-[95vw] sm:max-w-md md:max-w-lg max-h-[90vh] overflow-y-auto">
  <DialogHeader>
    <DialogTitle>Título do Modal</DialogTitle>
    <DialogDescription>Descrição</DialogDescription>
  </DialogHeader>

  <div className="space-y-4 py-4">
    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
      {/* Campos do formulário */}
    </div>
  </div>

  <DialogFooter className="flex-col sm:flex-row gap-2">
    <Button variant="outline" className="w-full sm:w-auto">Cancelar</Button>
    <Button className="w-full sm:w-auto">Confirmar</Button>
  </DialogFooter>
</DialogContent>
```

**Características:**
- `max-w-[95vw]` evita ultrapassar viewport mobile
- `max-h-[90vh] overflow-y-auto` permite scroll em modais longos
- Botões full-width mobile, auto desktop
- Grid de formulários 1 coluna mobile, 2 colunas desktop

---

### 6. Collapsibles com Métricas

```tsx
<CollapsibleTrigger className="flex w-full flex-col sm:flex-row sm:items-center sm:justify-between p-4 hover:bg-accent/50 gap-3">
  <div className="flex items-center gap-2 min-w-0">
    {expanded ? (
      <ChevronDown className="h-4 w-4 flex-shrink-0" />
    ) : (
      <ChevronRight className="h-4 w-4 flex-shrink-0" />
    )}
    <span className="font-bold text-base truncate">
      {title}
    </span>
  </div>

  <div className="grid grid-cols-3 gap-2 sm:flex sm:items-center sm:gap-6 text-xs sm:text-sm">
    <div className="text-left sm:text-right">
      <div className="text-xs text-muted-foreground">Vendas</div>
      <div className="font-semibold text-sm">{vendas}</div>
    </div>
    <div className="text-left sm:text-right">
      <div className="text-xs text-muted-foreground">Lucro</div>
      <div className="font-semibold text-sm">{lucro}</div>
    </div>
    <div className="text-left sm:text-right">
      <div className="text-xs text-muted-foreground">Margem</div>
      <div className="font-semibold text-sm">{margem}%</div>
    </div>
  </div>
</CollapsibleTrigger>
```

**Características:**
- Stack vertical mobile para evitar compressão
- Grid 3 colunas para métricas em mobile
- `truncate` em títulos longos
- `flex-shrink-0` em ícones para evitar redimensionamento

---

## Correções Implementadas

### ✅ Relatório Ruptura ABCD
**Arquivo:** `src/app/(dashboard)/relatorios/ruptura-abcd/page.tsx`

**Antes:**
```tsx
<div className="flex flex-col lg:flex-row gap-4 items-end">
  <div className="space-y-2 flex-1">
```

**Depois:**
```tsx
<div className="flex flex-col gap-4 lg:flex-row lg:items-end lg:gap-4">
  <div className="flex flex-col gap-2 w-full sm:w-auto">
```

**Melhorias:**
- ✅ `items-end` aplicado apenas em desktop
- ✅ Larguras responsivas (full → 200px)
- ✅ Padrão de gap consistente
- ✅ Header do card responsivo

### ✅ Dashboard Principal
**Arquivo:** `src/app/(dashboard)/dashboard/page.tsx`

**Antes:**
```tsx
<div className="grid gap-4 md:grid-cols-1 lg:grid-cols-4">
```

**Depois:**
```tsx
<div className="grid gap-4 grid-cols-1 sm:grid-cols-2 lg:grid-cols-4">
```

**Melhorias:**
- ✅ Grid responsivo: 1 col → 2 cols → 4 cols
- ✅ Melhor aproveitamento de espaço em tablets

### ✅ Tela de Despesas
**Arquivo:** `src/app/(dashboard)/despesas/page.tsx`

**Status:**
- ✅ Filtros padronizados
- ✅ Header responsivo
- ✅ Seletor de filiais com scroll
- ✅ **Tabela complexa com scroll horizontal simples**
- ✅ Funciona em todos os breakpoints (mobile, tablet, desktop, Full HD, 2K, 4K)

---

## Checklist de Responsividade

Use este checklist ao criar ou revisar componentes:

### Filtros
- [ ] Usa padrão oficial com `flex-col lg:flex-row lg:items-end`
- [ ] Todos os inputs têm `h-10` (40px)
- [ ] Wrapper `<div className="h-10">` em selects
- [ ] Larguras responsivas: `w-full sm:w-[Xpx]`
- [ ] Botão full-width mobile (`w-full sm:w-auto`)

### Tabelas
- [ ] Wrapper com `overflow-x-auto`
- [ ] Se > 4 colunas, tem layout Card alternativo para mobile
- [ ] Células sem `whitespace-nowrap` excessivo
- [ ] Sticky columns (se houver) têm z-index correto

### Cards e Grids
- [ ] Grid responsivo: `grid-cols-1 sm:grid-cols-2 lg:grid-cols-4`
- [ ] Gap consistente: `gap-4`
- [ ] Textos com tamanhos responsivos quando apropriado

### Headers
- [ ] Stack vertical em mobile: `flex-col sm:flex-row`
- [ ] Botões full-width mobile: `w-full sm:w-auto`
- [ ] Tamanhos de fonte responsivos: `text-2xl sm:text-3xl`

### Modals/Dialogs
- [ ] `max-w-[95vw]` para mobile
- [ ] `max-h-[90vh] overflow-y-auto` para scroll
- [ ] Formulários com grid: `grid-cols-1 sm:grid-cols-2`
- [ ] Botões de footer full-width mobile

### Geral
- [ ] Testado em 375px (iPhone SE)
- [ ] Testado em 768px (iPad)
- [ ] Testado em 1024px+ (Desktop)
- [ ] Sem scroll horizontal indesejado
- [ ] Textos longos com `truncate` ou `break-words`

---

## Ferramentas de Teste

### DevTools Chrome/Firefox
```
1. Abrir DevTools (F12)
2. Toggle Device Toolbar (Ctrl+Shift+M)
3. Testar em:
   - iPhone SE (375px)
   - iPhone 12/13 (390px)
   - iPad (768px)
   - Desktop (1024px, 1440px)
```

### Breakpoints de Teste
```
- 375px  - iPhone SE (viewport mais estreito)
- 390px  - iPhone 12/13
- 640px  - Breakpoint sm (Tailwind)
- 768px  - iPad / Breakpoint md (Tailwind)
- 1024px - Breakpoint lg (Tailwind)
- 1280px - Breakpoint xl (Tailwind)
```

---

## Problemas Comuns e Soluções

### 1. Scroll Horizontal Indesejado

**Problema:**
```tsx
<div className="flex gap-4">
  <div className="min-w-[400px]">...</div>
</div>
```

**Solução:**
```tsx
<div className="flex flex-col sm:flex-row gap-4">
  <div className="w-full sm:min-w-[400px]">...</div>
</div>
```

### 2. Botões Cortados em Mobile

**Problema:**
```tsx
<Button>Exportar Relatório Completo</Button>
```

**Solução:**
```tsx
<Button className="w-full sm:w-auto">
  <FileDown className="h-4 w-4" />
  <span className="truncate">Exportar Relatório Completo</span>
</Button>
```

### 3. Modais Ultrapassando Viewport

**Problema:**
```tsx
<DialogContent>
```

**Solução:**
```tsx
<DialogContent className="max-w-[95vw] sm:max-w-md max-h-[90vh] overflow-y-auto">
```

### 4. Tabelas Transbordando Viewport (Full HD, 2K, 4K)

**Problema:**
```tsx
{/* Sticky columns causam overflow e problemas de z-index */}
<th className="sticky left-0 w-[400px] z-10">...</th>
```

**Solução:**
```tsx
{/* Scroll horizontal simples, sem sticky columns */}
<div className="overflow-x-auto">
  <table className="w-full">
    <th className="whitespace-nowrap">...</th>
  </table>
</div>
```

**Motivo:**
- Sticky columns adicionam complexidade (z-index, larguras fixas, transparência)
- Scroll horizontal simples funciona em TODOS os tamanhos de tela
- Mais fácil de manter e debugar
- Comportamento consistente e previsível

---

## Próximas Implementações

### Pendente
1. **Tabela Dashboard Vendas**
   - Aplicar padrão de scroll horizontal simples
   - Remover complexidade se existir sticky columns

2. **Collapsibles de Venda Curva** (mobile)
   - Stack vertical em triggers
   - Grid de métricas

3. **Todas as telas de Metas** (mobile)
   - Dialogs responsivos
   - Tabelas com padrão de scroll horizontal simples

---

## Referências

- [Tailwind CSS - Responsive Design](https://tailwindcss.com/docs/responsive-design)
- [shadcn/ui - Components](https://ui.shadcn.com/)
- [Material Design - Layout](https://m3.material.io/foundations/layout/understanding-layout/overview)
- `docs/FILTER_PATTERN_STANDARD.md` - Padrão de filtros oficial do projeto

---

## Contato

Para dúvidas sobre responsividade, consulte este documento ou o padrão oficial de filtros em `docs/FILTER_PATTERN_STANDARD.md`.

**Última atualização:** 2025-10-26
