# Padrões de UI/UX - Autenticação e Recuperação de Senha

**Última Atualização:** 2025-01-14  
**Versão:** 1.0.0

## Índice

1. [Design System](#design-system)
2. [Componentes de UI](#componentes-de-ui)
3. [Padrões de Layout](#padrões-de-layout)
4. [Estados Visuais](#estados-visuais)
5. [Responsividade](#responsividade)
6. [Acessibilidade](#acessibilidade)
7. [Animações e Transições](#animações-e-transições)

---

## Design System

### Paleta de Cores

```typescript
// Cores principais (Tailwind CSS)
const colors = {
  // Primary (Emerald)
  primary: '#10b981',           // emerald-500
  primaryHover: '#059669',      // emerald-600
  
  // Feedback
  success: '#10b981',           // emerald-500/green-500
  successBg: '#f0fdf4',         // green-50
  successBorder: '#bbf7d0',     // green-200
  successText: '#166534',       // green-800
  
  error: '#ef4444',             // red-500
  errorBg: '#fef2f2',           // red-50
  errorBorder: '#fecaca',       // red-200
  errorText: '#991b1b',         // red-800
  
  info: '#3b82f6',              // blue-600
  infoBg: '#eff6ff',            // blue-50
  infoBorder: '#bfdbfe',        // blue-200
  infoText: '#1e40af',          // blue-800
  
  // Neutros
  background: '#ffffff',        // white
  foreground: '#1f1f1f',        // gray-900
  muted: '#6b7280',             // gray-500
  border: '#e5e7eb',            // gray-200
}
```

---

### Tipografia

```typescript
// Fonte padrão: Inter (via Tailwind)
const typography = {
  // Títulos
  h1: 'text-2xl font-bold text-gray-900',
  h2: 'text-xl font-semibold text-gray-900',
  h3: 'text-lg font-medium text-gray-900',
  
  // Corpo
  body: 'text-sm text-gray-900',
  bodyMuted: 'text-sm text-gray-600',
  bodySmall: 'text-xs text-gray-500',
  
  // Labels
  label: 'text-sm font-medium text-[#1F1F1F]',
  
  // Links
  link: 'text-sm text-blue-600 hover:underline',
}
```

---

### Espaçamento

```typescript
// Sistema de espaçamento (Tailwind)
const spacing = {
  xs: '0.25rem',    // 4px
  sm: '0.5rem',     // 8px
  md: '1rem',       // 16px
  lg: '1.5rem',     // 24px
  xl: '2rem',       // 32px
  '2xl': '3rem',    // 48px
}

// Aplicações comuns
const commonSpacing = {
  fieldGap: 'space-y-4',        // 16px entre campos
  cardPadding: 'p-6',           // 24px padding
  buttonPadding: 'px-4 py-2',   // 16px x 8px
}
```

---

### Bordas e Sombras

```typescript
// Raios de borda
const borderRadius = {
  input: 'rounded-md',      // 6px
  button: 'rounded-md',     // 6px
  card: 'rounded-xl',       // 12px
  alert: 'rounded-md',      // 6px
}

// Sombras
const shadows = {
  card: 'shadow-md',        // Drop shadow média
  input: 'shadow-sm',       // Drop shadow leve
  none: 'shadow-none',
}
```

---

## Componentes de UI

### Card (Login/Recuperação)

```tsx
/**
 * Estrutura padrão dos cards de autenticação
 */
<Card className="w-full shadow-md rounded-xl bg-white">
  <CardHeader className="flex flex-col items-center pt-8 pb-4">
    {/* Logo */}
    <Image 
      src="/logo_mobile.png" 
      alt="DevIngá" 
      width={120}
      height={40}
      className="h-10 w-auto"
      priority
    />
    
    {/* Título (opcional) */}
    <h1 className="text-2xl font-semibold text-gray-900 mt-4">
      {title}
    </h1>
    
    {/* Subtítulo (opcional) */}
    <p className="text-sm text-gray-600 text-center mt-2">
      {description}
    </p>
  </CardHeader>

  <CardContent>
    {children}
  </CardContent>

  <CardFooter className="flex flex-col gap-3 pb-6">
    {footer}
  </CardFooter>
</Card>
```

**Especificações**:
- Largura: `max-w-md` (448px)
- Padding Header: `pt-8 pb-4` (32px top, 16px bottom)
- Padding Content: `p-6` (24px all sides)
- Padding Footer: `pb-6` (24px bottom)
- Sombra: `shadow-md`
- Raio: `rounded-xl` (12px)

---

### Input Field

```tsx
/**
 * Campo de input padrão
 * @see src/components/ui/input.tsx
 */
<div className="space-y-2">
  <Label htmlFor="email" className="text-[#1F1F1F] font-medium">
    E-mail
  </Label>
  <Input
    id="email"
    type="email"
    placeholder="Informe seu e-mail de acesso"
    value={email}
    onChange={(e) => setEmail(e.target.value)}
    required
    disabled={loading}
    autoFocus
    className="mt-1.5"
  />
  <p className="text-xs text-gray-500 mt-1.5">
    {helperText}
  </p>
</div>
```

**Especificações**:
- Altura: `h-9` (36px)
- Padding: `px-3 py-1`
- Border: `border border-input`
- Raio: `rounded-md` (6px)
- Fonte: `text-sm md:text-sm`
- Focus: `focus-visible:ring-1 focus-visible:ring-ring`

---

### Password Field com Toggle

```tsx
/**
 * Campo de senha com botão de visualização
 * @see src/components/auth/login-form.tsx (linha 201-228)
 */
<div className="space-y-2">
  <Label htmlFor="password" className="text-[#1F1F1F] font-medium">
    Senha
  </Label>
  <div className="relative mt-1.5">
    <Input
      id="password"
      type={showPassword ? 'text' : 'password'}
      placeholder="Informe a senha"
      value={password}
      onChange={(e) => setPassword(e.target.value)}
      required
      disabled={loading}
      className="pr-10"
    />
    <Button
      type="button"
      variant="ghost"
      size="icon"
      className="absolute right-0 top-0 h-full px-3 hover:bg-transparent"
      onClick={toggleShowPassword}
      tabIndex={-1}
    >
      {showPassword ? (
        <EyeOff className="h-4 w-4 text-gray-400" />
      ) : (
        <Eye className="h-4 w-4 text-gray-400" />
      )}
    </Button>
  </div>
  <div className="text-right mt-1">
    <Link href="/esqueci-senha" className="text-sm text-blue-600 hover:underline">
      Esqueceu a senha?
    </Link>
  </div>
</div>
```

**Especificações**:
- Container: `relative`
- Input padding-right: `pr-10` (40px - espaço para botão)
- Botão: Position `absolute`, `right-0`, `top-0`
- Ícone: `h-4 w-4` (16px)
- Cor ícone: `text-gray-400`

---

### Button (Primary)

```tsx
/**
 * Botão primário de ação
 * @see src/components/ui/button.tsx
 */
<Button 
  type="submit" 
  className="bg-emerald-500 hover:bg-emerald-600 w-full transition-all duration-200" 
  disabled={loading}
>
  {loading ? (
    <span className="flex items-center justify-center gap-2">
      <svg className="animate-spin h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
        <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
        <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>
      {loadingText}
    </span>
  ) : (
    {buttonText}
  )}
</Button>
```

**Especificações**:
- Altura: `h-9` (36px)
- Largura: `w-full` (100%)
- Background: `bg-emerald-500`
- Hover: `hover:bg-emerald-600`
- Transição: `transition-all duration-200`
- Disabled: `disabled:opacity-50 disabled:pointer-events-none`

**Estados**:
- Normal: Verde emerald-500
- Hover: Verde emerald-600
- Loading: Spinner animado + texto
- Disabled: Opacidade 50%, sem interação

---

### Alert Messages

```tsx
/**
 * Alerta de sucesso
 */
<Alert className="border-green-200 bg-green-50">
  <CheckCircle2 className="h-4 w-4 text-green-600" />
  <AlertDescription className="text-green-800">
    {successMessage}
  </AlertDescription>
</Alert>

/**
 * Alerta de erro
 */
<Alert variant="destructive">
  <AlertCircle className="h-4 w-4" />
  <AlertDescription>
    {errorMessage}
  </AlertDescription>
</Alert>

/**
 * Alerta informativo
 */
<Alert className="bg-blue-50 border-blue-200 text-blue-800">
  <Info className="h-4 w-4" />
  <AlertDescription>
    {infoMessage}
  </AlertDescription>
</Alert>
```

**Especificações por Tipo**:

| Tipo | Background | Border | Text | Ícone |
|------|-----------|--------|------|-------|
| Success | `bg-green-50` | `border-green-200` | `text-green-800` | `CheckCircle2` |
| Error | `bg-red-50` | `border-red-200` | `text-red-800` | `AlertCircle` |
| Info | `bg-blue-50` | `border-blue-200` | `text-blue-800` | `Info` |

---

### Link de Suporte (WhatsApp)

```tsx
/**
 * Link de suporte padrão
 */
<a 
  href="https://wa.me/554499510755" 
  target="_blank" 
  rel="noopener noreferrer"
  className="flex items-center justify-center gap-2 text-sm text-blue-600 hover:underline transition-colors"
>
  <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
    {/* SVG do WhatsApp */}
  </svg>
  Precisa de ajuda?
</a>
```

**Especificações**:
- Layout: `flex items-center gap-2`
- Fonte: `text-sm` (14px)
- Cor: `text-blue-600`
- Hover: `hover:underline`
- Ícone: `w-4 h-4` (16px)

---

## Padrões de Layout

### Layout de Página de Autenticação

```tsx
/**
 * Estrutura padrão de páginas de auth
 * @see src/app/(auth)/login/page.tsx
 */
<div className="min-h-screen flex items-center justify-center bg-gray-50 px-4">
  <div className="w-full max-w-md">
    {/* Card principal */}
    <Card>
      {/* Conteúdo */}
    </Card>

    {/* Footer/Links adicionais */}
    <p className="text-center text-sm text-gray-600 mt-6">
      Não possui uma conta?{' '}
      <a href="/cadastro" className="text-blue-600 hover:underline">
        Solicite aqui.
      </a>
    </p>
  </div>
</div>
```

**Especificações**:
- Container: `min-h-screen flex items-center justify-center`
- Background: `bg-gray-50`
- Padding lateral: `px-4` (responsivo)
- Largura máxima: `max-w-md` (448px)
- Margem top footer: `mt-6` (24px)

---

### Formulário com Suspense

```tsx
/**
 * Wrapper com suspense para formulários
 * @see src/app/(auth)/login/page.tsx (linha 6-19)
 */
function LoginFormWrapper() {
  return (
    <Suspense fallback={
      <div className="space-y-4">
        <div className="animate-pulse space-y-4">
          <div className="h-10 bg-gray-200 rounded" />
          <div className="h-10 bg-gray-200 rounded" />
          <div className="h-11 bg-gray-200 rounded" />
        </div>
      </div>
    }>
      <LoginForm />
    </Suspense>
  )
}
```

**Skeleton Loading**:
- Containers: `space-y-4` (gap 16px)
- Animação: `animate-pulse`
- Altura inputs: `h-10` (40px)
- Altura botão: `h-11` (44px)
- Background: `bg-gray-200`

---

## Estados Visuais

### Estados de Input

#### 1. Normal (Default)
```css
border: 1px solid #e5e7eb (gray-200)
background: transparent
text: #1f1f1f
```

#### 2. Focus
```css
border: 1px solid #10b981 (emerald-500)
ring: 1px #10b981
outline: none
```

#### 3. Error
```css
border: 1px solid #ef4444 (red-500)
ring: 1px #ef4444/20
```

#### 4. Disabled
```css
background: #f3f4f6 (gray-100)
cursor: not-allowed
opacity: 0.5
```

#### 5. Filled
```css
/* Mantém estilo normal */
/* Apenas conteúdo preenchido */
```

---

### Estados de Button

#### 1. Normal
```tsx
<Button className="bg-emerald-500 text-white">
  Acessar
</Button>
```
**Visual**: Verde emerald-500, texto branco

#### 2. Hover
```tsx
<Button className="bg-emerald-500 hover:bg-emerald-600">
  Acessar
</Button>
```
**Visual**: Verde escurece para emerald-600

#### 3. Loading
```tsx
<Button disabled>
  <Spinner className="animate-spin" />
  Entrando...
</Button>
```
**Visual**: Spinner rotacionando + texto alterado

#### 4. Disabled
```tsx
<Button disabled>
  Acessar
</Button>
```
**Visual**: Opacidade 50%, sem hover, cursor not-allowed

---

### Estados de Formulário

#### 1. Inicial (Vazio)
- Todos os campos vazios
- Botão habilitado (validação HTML5)
- Sem mensagens de erro
- Focus no primeiro campo

#### 2. Preenchendo
- Campos sendo digitados
- Validação em tempo real (HTML5)
- Sem loading

#### 3. Enviando (Loading)
- Todos os campos disabled
- Botão com spinner
- Sem possibilidade de edição

#### 4. Erro
- Alert vermelho no topo
- Campos ainda preenchidos
- Botão habilitado para retry
- Focus permanece no formulário

#### 5. Sucesso
- Alert verde no topo
- Formulário pode ser substituído
- Ou redirect automático

---

## Responsividade

### Breakpoints

```typescript
// Tailwind CSS breakpoints
const breakpoints = {
  sm: '640px',   // Mobile landscape
  md: '768px',   // Tablet
  lg: '1024px',  // Desktop
  xl: '1280px',  // Large desktop
  '2xl': '1536px' // Extra large
}
```

---

### Layout Responsivo

#### Mobile (< 640px)
```tsx
<div className="min-h-screen flex items-center justify-center bg-gray-50 px-4">
  <div className="w-full max-w-md">
    {/* Card ocupa 100% da largura com padding de 16px */}
  </div>
</div>
```

**Características**:
- Padding lateral: 16px (`px-4`)
- Card: Largura máxima 448px (`max-w-md`)
- Fonte: 14px (`text-sm`)
- Campos: Altura 36px

#### Tablet (640px - 1024px)
```tsx
{/* Mantém mesmo layout do mobile */}
{/* Apenas fonte base aumenta ligeiramente */}
```

**Características**:
- Layout idêntico ao mobile
- Fonte pode ser `md:text-base` em alguns casos
- Card centralizado com mais espaço lateral

#### Desktop (> 1024px)
```tsx
{/* Mesmo layout, mais espaço lateral */}
```

**Características**:
- Card centralizado
- Mais "breathing room"
- Fonte base: 14px-16px

---

### Exemplos de Classes Responsivas

```tsx
// Texto responsivo
<p className="text-sm md:text-base">
  {text}
</p>

// Padding responsivo
<div className="px-4 md:px-6 lg:px-8">
  {content}
</div>

// Grid responsivo (não usado em auth, mas para referência)
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
  {items}
</div>
```

---

## Acessibilidade

### Navegação por Teclado

```tsx
/**
 * Ordem de foco (Tab)
 */
1. Campo Email (autoFocus)
   ↓
2. Campo Senha
   ↓
3. Botão Toggle Senha (tabIndex={-1} - skipado)
   ↓
4. Link "Esqueceu a senha?"
   ↓
5. Botão "Acessar"
   ↓
6. Link "Precisa de ajuda?"
```

**Implementação**:
```tsx
<Input
  id="email"
  autoFocus  // Primeiro campo recebe foco
  required
/>

<Button
  type="button"
  tabIndex={-1}  // Remove do fluxo de tabulação
  onClick={toggleShowPassword}
/>
```

---

### Labels e ARIA

```tsx
/**
 * Labels corretas para screen readers
 */
<Label htmlFor="email" className="text-[#1F1F1F] font-medium">
  E-mail
</Label>
<Input
  id="email"
  type="email"
  aria-label="Campo de email"
  aria-required="true"
  aria-invalid={error ? 'true' : 'false'}
/>

{error && (
  <p 
    className="text-red-500 text-xs mt-1"
    role="alert"
    aria-live="polite"
  >
    {error}
  </p>
)}
```

**ARIA Attributes Usados**:
- `aria-label`: Descrição do campo
- `aria-required`: Campo obrigatório
- `aria-invalid`: Campo com erro
- `role="alert"`: Mensagem de erro
- `aria-live="polite"`: Atualização dinâmica

---

### Contraste de Cores

**WCAG AA Compliance** (4.5:1):

| Elemento | Foreground | Background | Contraste |
|----------|-----------|-----------|-----------|
| Texto normal | #1f1f1f | #ffffff | 16.1:1 ✅ |
| Texto muted | #6b7280 | #ffffff | 4.6:1 ✅ |
| Link | #2563eb | #ffffff | 7.5:1 ✅ |
| Erro | #991b1b | #fef2f2 | 13.2:1 ✅ |
| Sucesso | #166534 | #f0fdf4 | 11.8:1 ✅ |
| Info | #1e40af | #eff6ff | 9.3:1 ✅ |

---

### Focus Visible

```tsx
/**
 * Indicador de foco personalizado
 */
<Input className="
  focus-visible:outline-none 
  focus-visible:ring-1 
  focus-visible:ring-ring
" />

<Button className="
  focus-visible:ring-2 
  focus-visible:ring-emerald-500 
  focus-visible:ring-offset-2
" />
```

**Especificações**:
- Ring: 1px-2px
- Cor: Emerald-500 ou Ring (variável CSS)
- Offset: 2px (espaçamento)
- Apenas no `:focus-visible` (não no click)

---

## Animações e Transições

### Spinner de Loading

```tsx
/**
 * Spinner SVG animado
 */
<svg 
  className="animate-spin h-4 w-4" 
  xmlns="http://www.w3.org/2000/svg" 
  fill="none" 
  viewBox="0 0 24 24"
>
  <circle 
    className="opacity-25" 
    cx="12" 
    cy="12" 
    r="10" 
    stroke="currentColor" 
    strokeWidth="4"
  />
  <path 
    className="opacity-75" 
    fill="currentColor" 
    d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
  />
</svg>
```

**Animação**:
```css
@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}

.animate-spin {
  animation: spin 1s linear infinite;
}
```

---

### Skeleton Loading

```tsx
/**
 * Skeleton com pulse
 */
<div className="animate-pulse space-y-4">
  <div className="h-10 bg-gray-200 rounded" />
  <div className="h-10 bg-gray-200 rounded" />
  <div className="h-11 bg-gray-200 rounded" />
</div>
```

**Animação**:
```css
@keyframes pulse {
  0%, 100% {
    opacity: 1;
  }
  50% {
    opacity: 0.5;
  }
}

.animate-pulse {
  animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}
```

---

### Transições de Botão

```tsx
/**
 * Transição suave em hover/focus
 */
<Button className="
  bg-emerald-500 
  hover:bg-emerald-600 
  transition-all 
  duration-200
">
  Acessar
</Button>
```

**CSS Gerado**:
```css
.transition-all {
  transition-property: all;
  transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
  transition-duration: 200ms;
}
```

---

### Fade In de Alertas

```tsx
/**
 * Alert com fade in suave
 */
<Alert className="animate-in fade-in duration-300">
  {message}
</Alert>
```

**Implementação** (via Tailwind plugin):
```css
@keyframes fade-in {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}

.fade-in {
  animation: fade-in 300ms ease-out;
}
```

---

## Iconografia

### Ícones Utilizados (Lucide React)

```tsx
import { 
  Eye,          // Mostrar senha
  EyeOff,       // Ocultar senha
  CheckCircle2, // Sucesso
  AlertCircle,  // Erro
  Info,         // Informação
  ArrowLeft,    // Voltar
  Loader2,      // Loading alternativo
} from 'lucide-react'
```

**Tamanhos Padrão**:
- Normal: `h-4 w-4` (16px)
- Pequeno: `h-3 w-3` (12px)
- Grande: `h-5 w-5` (20px)

---

## Referências

### Documentação Relacionada
- [BUSINESS_RULES.md](./BUSINESS_RULES.md) - Regras de negócio
- [DATA_STRUCTURES.md](./DATA_STRUCTURES.md) - Estruturas de dados
- [INTEGRATION_FLOW.md](./INTEGRATION_FLOW.md) - Fluxos de integração

### Design System
- [Tailwind CSS](https://tailwindcss.com/)
- [shadcn/ui](https://ui.shadcn.com/)
- [Lucide Icons](https://lucide.dev/)
- [Radix UI](https://www.radix-ui.com/)

### Acessibilidade
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [WAI-ARIA Practices](https://www.w3.org/WAI/ARIA/apg/)

---

**Última Revisão:** 2025-01-14  
**Próxima Revisão:** 2025-04-14
