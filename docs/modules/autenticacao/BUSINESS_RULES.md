# Regras de Negócio - Autenticação e Recuperação de Senha

**Última Atualização:** 2025-01-14  
**Versão:** 1.0.0

## Índice

1. [Regras de Login](#regras-de-login)
2. [Regras de Recuperação de Senha](#regras-de-recuperação-de-senha)
3. [Regras de Redefinição de Senha](#regras-de-redefinição-de-senha)
4. [Regras de Sessão](#regras-de-sessão)
5. [Regras de Segurança](#regras-de-segurança)
6. [Regras de Middleware](#regras-de-middleware)
7. [Regras de Mensagens](#regras-de-mensagens)

---

## Regras de Login

### RN-LOGIN-001: Validação de Email
**Descrição**: O email deve ser válido e estar no formato correto.

**Implementação**: `login-form.tsx` (linha 190)
```typescript
<Input
  id="email"
  type="email"
  required
/>
```

**Validação**:
- Campo obrigatório
- Formato de email válido (validação HTML5)
- Trim automático de espaços

---

### RN-LOGIN-002: Validação de Senha
**Descrição**: A senha é obrigatória e deve ser fornecida para login.

**Implementação**: `login-form.tsx` (linha 204-213)
```typescript
<Input
  id="password"
  type={showPassword ? 'text' : 'password'}
  required
/>
```

**Características**:
- Campo obrigatório
- Toggle para exibir/ocultar senha
- Trim automático de espaços

---

### RN-LOGIN-003: Timeout de Segurança
**Descrição**: O processo de login deve ter um timeout de 10 segundos para evitar travamentos.

**Implementação**: `login-form.tsx` (linha 127-130)
```typescript
const timeoutId = setTimeout(() => {
  setLoading(false)
  setError('Tempo de login excedido. Tente novamente.')
}, 10000) // 10 segundos
```

**Comportamento**:
- Se login não completar em 10s → timeout
- Loading state é resetado
- Mensagem de erro exibida
- Usuário pode tentar novamente

---

### RN-LOGIN-004: Tratamento de Erros Contextualizados
**Descrição**: Erros de login devem ser traduzidos e contextualizados em PT-BR.

**Implementação**: `login-form.tsx` (linha 82-119)

**Tipos de Erro**:

| Erro Original | Mensagem PT-BR | Código |
|--------------|----------------|--------|
| `invalid login credentials` | "Login ou senha estão incorretos." | RN-LOGIN-004a |
| `email not confirmed` | "Email não confirmado. Verifique sua caixa de entrada." | RN-LOGIN-004b |
| `user not found` | "Usuário não encontrado. Verifique seu email." | RN-LOGIN-004c |
| `user is disabled` | "Esta conta foi desabilitada. Entre em contato com o administrador." | RN-LOGIN-004d |
| `too many requests` | "Muitas tentativas de login. Aguarde alguns minutos e tente novamente." | RN-LOGIN-004e |
| `invalid email` | "Email inválido. Verifique o formato do email." | RN-LOGIN-004f |

---

### RN-LOGIN-005: Redirecionamento Pós-Login
**Descrição**: Após login bem-sucedido, usuário deve ser redirecionado para o dashboard.

**Implementação**: `login-form.tsx` (linha 145-147)
```typescript
router.push('/dashboard')
router.refresh()
```

**Comportamento**:
- Redirect para `/dashboard`
- Refresh da página para carregar dados do usuário
- Loading state mantido até carregamento completo

---

### RN-LOGIN-006: Processamento de Mensagens da URL
**Descrição**: O sistema deve processar e exibir mensagens passadas via URL query params.

**Implementação**: `login-form.tsx` (linha 27-41)

**Tipos de Mensagem**:

1. **Sessão Expirada**
   - Trigger: `?message=Sessão+expirada`
   - Exibição: Alert informativo azul

2. **Email Confirmado**
   - Trigger: `?message=Email+confirmed`
   - Exibição: Alert de sucesso verde

3. **Erro de Autenticação**
   - Trigger: `?error=access_denied`
   - Exibição: Alert de erro vermelho

---

### RN-LOGIN-007: Link Esqueci Senha
**Descrição**: Link "Esqueceu a senha?" deve estar visível e redirecionar para `/esqueci-senha`.

**Implementação**: `login-form.tsx` (linha 230-232)
```typescript
<Link href="/esqueci-senha" className="text-sm text-blue-600 hover:underline">
  Esqueceu a senha?
</Link>
```

---

## Regras de Recuperação de Senha

### RN-RECOVERY-001: Validação de Email
**Descrição**: Email deve ser válido e existir no sistema.

**Implementação**: `forgot-password-form.tsx` (linha 66-76)
```typescript
<Input
  id="email"
  type="email"
  placeholder="Informe seu e-mail de acesso"
  value={email}
  required
/>
```

**Validação**:
- Campo obrigatório
- Formato válido
- Trim automático

---

### RN-RECOVERY-002: Envio de Email de Recuperação
**Descrição**: Sistema deve enviar email com link seguro de recuperação via Supabase.

**Implementação**: `forgot-password-form.tsx` (linha 26-28)
```typescript
const { error } = await supabase.auth.resetPasswordForEmail(email.trim(), {
  redirectTo: `${window.location.origin}/redefinir-senha`,
})
```

**Configuração**:
- Método: `resetPasswordForEmail()`
- Redirect: `/redefinir-senha`
- Token: Gerenciado pelo Supabase (24h de validade)

---

### RN-RECOVERY-003: Feedback de Sucesso
**Descrição**: Após envio bem-sucedido, exibir mensagem de confirmação sem permitir reenvio imediato.

**Implementação**: `forgot-password-form.tsx` (linha 46-58)
```typescript
if (success) {
  return (
    <Alert className="border-green-200 bg-green-50">
      <CheckCircle2 className="h-4 w-4 text-green-600" />
      <AlertDescription className="text-green-800">
        Email enviado com sucesso! Verifique sua caixa de entrada...
      </AlertDescription>
    </Alert>
  )
}
```

**Comportamento**:
- Formulário substituído por mensagem de sucesso
- Impede múltiplos envios acidentais
- Usuário deve voltar manualmente para tentar outro email

---

### RN-RECOVERY-004: Tratamento de Erros
**Descrição**: Erros no envio de email devem ser tratados e exibidos.

**Implementação**: `forgot-password-form.tsx` (linha 30-34)
```typescript
if (error) {
  console.error('Erro ao enviar email:', error)
  setError('Erro ao enviar email. Verifique o endereço e tente novamente.')
  setLoading(false)
  return
}
```

---

### RN-RECOVERY-005: Link de Ajuda
**Descrição**: Disponibilizar link de suporte via WhatsApp para casos de problemas.

**Implementação**: `forgot-password-form.tsx` (linha 107-118)
```typescript
<a 
  href="https://wa.me/554499510755" 
  target="_blank" 
  rel="noopener noreferrer"
  className="flex items-center justify-center gap-2 text-sm text-blue-600 hover:underline"
>
  Precisa de ajuda?
</a>
```

---

## Regras de Redefinição de Senha

### RN-RESET-001: Validação de Senha Mínima
**Descrição**: Nova senha deve ter no mínimo 6 caracteres.

**Implementação**: `reset-password-form.tsx` (linha 26-30)
```typescript
if (trimmedPassword.length < 6) {
  setError('A senha deve ter pelo menos 6 caracteres')
  setLoading(false)
  return
}
```

**Requisitos**:
- Mínimo: 6 caracteres
- Sem limite máximo
- Todos os caracteres permitidos

---

### RN-RESET-002: Confirmação de Senha
**Descrição**: Senha e confirmação devem ser idênticas.

**Implementação**: `reset-password-form.tsx` (linha 32-36)
```typescript
if (trimmedPassword !== confirmPassword.trim()) {
  setError('As senhas não coincidem')
  setLoading(false)
  return
}
```

---

### RN-RESET-003: Atualização Segura
**Descrição**: Atualização de senha deve ser feita via método seguro do Supabase.

**Implementação**: `reset-password-form.tsx` (linha 41-43)
```typescript
const { error } = await supabase.auth.updateUser({
  password: trimmedPassword,
})
```

**Processo**:
1. Usuário deve ter token válido (do email)
2. Supabase valida token automaticamente
3. Senha é criptografada antes de salvar
4. Sessão é criada automaticamente

---

### RN-RESET-004: Redirecionamento Pós-Redefinição
**Descrição**: Após redefinição bem-sucedida, usuário deve ser redirecionado ao dashboard.

**Implementação**: `reset-password-form.tsx` (linha 54-56)
```typescript
router.push('/dashboard')
router.refresh()
```

**Comportamento**:
- Sessão já está ativa (criada pelo Supabase)
- Redirect imediato para `/dashboard`
- Não precisa fazer login novamente

---

### RN-RESET-005: Validação de Interface
**Descrição**: Campos de senha devem ter validação HTML5.

**Implementação**: `reset-password-form.tsx` (linha 68-77, 84-93)
```typescript
<Input
  id="password"
  type="password"
  required
  minLength={6}
/>
```

---

## Regras de Sessão

### RN-SESSION-001: Gestão de Cookies
**Descrição**: Sessão deve ser gerenciada via cookies HTTP-only seguros.

**Implementação**: `lib/supabase/middleware.ts` (linha 13-28)
```typescript
cookies: {
  getAll() {
    return request.cookies.getAll()
  },
  setAll(cookiesToSet) {
    cookiesToSet.forEach(({ name, value, options }) =>
      supabaseResponse.cookies.set(name, value, options)
    )
  },
}
```

**Características**:
- HTTP-only cookies
- Secure flag em produção
- SameSite=Lax
- Gerenciados automaticamente pelo Supabase

---

### RN-SESSION-002: Verificação de Usuário
**Descrição**: Middleware deve verificar usuário autenticado em cada requisição.

**Implementação**: `lib/supabase/middleware.ts` (linha 32-34)
```typescript
const {
  data: { user },
} = await supabase.auth.getUser()
```

---

### RN-SESSION-003: Refresh Automático
**Descrição**: Token de sessão deve ser renovado automaticamente.

**Implementação**: Gerenciado automaticamente pelo Supabase SDK
- Refresh token válido por 30 dias
- Access token válido por 1 hora
- Renovação automática antes da expiração

---

### RN-SESSION-004: Cache Control
**Descrição**: Respostas de autenticação não devem ser cacheadas.

**Implementação**: `lib/supabase/server.ts` (linha 26-31)
```typescript
global: {
  headers: {
    'Cache-Control': 'no-cache, no-store, must-revalidate',
    'Pragma': 'no-cache',
    'Expires': '0'
  }
}
```

---

## Regras de Segurança

### RN-SEC-001: Proteção de Rotas Privadas
**Descrição**: Rotas privadas devem redirecionar usuários não autenticados.

**Implementação**: `middleware.ts` (linha 58-62)
```typescript
if (!user && !isPublicRoute) {
  const url = request.nextUrl.clone()
  url.pathname = '/login'
  return NextResponse.redirect(url)
}
```

**Rotas Públicas**:
- `/login`
- `/cadastro`
- `/esqueci-senha`
- `/redefinir-senha`

---

### RN-SEC-002: Verificação de Permissões
**Descrição**: Rotas administrativas devem verificar role do usuário.

**Implementação**: `lib/supabase/middleware.ts` (linha 65-78)

**Níveis de Permissão**:

| Rota | Role Mínimo | Verificação |
|------|-------------|-------------|
| `/empresas` | superadmin | RN-SEC-002a |
| `/usuarios` | admin | RN-SEC-002b |
| `/dashboard` | user | RN-SEC-002c |

---

### RN-SEC-003: Sanitização de Inputs
**Descrição**: Todos os inputs devem ser sanitizados (trim).

**Implementação**: Em todos os formulários
```typescript
email: email.trim()
password: password.trim()
```

---

### RN-SEC-004: Rate Limiting
**Descrição**: Supabase aplica rate limiting automático.

**Configuração** (Supabase):
- Login: 60 requisições/hora por IP
- Recovery: 30 emails/hora por IP
- Reset: 10 tentativas/hora por token

---

### RN-SEC-005: Validação de Token
**Descrição**: Tokens de recuperação devem ser validados pelo Supabase.

**Comportamento**:
- Token válido por 24 horas
- Uso único (invalidado após uso)
- Validação automática pelo SDK

---

## Regras de Middleware

### RN-MIDDLEWARE-001: Ordem de Verificação
**Descrição**: Middleware deve verificar autenticação e permissões na ordem correta.

**Implementação**: `lib/supabase/middleware.ts`

**Ordem**:
1. Verificar se usuário está autenticado (linha 58)
2. Verificar se rota é pública (linha 36-40)
3. Verificar permissões de superadmin (linha 65-78)
4. Verificar permissões de admin (linha 81-94)
5. Verificar módulos habilitados (linha 97-152)

---

### RN-MIDDLEWARE-002: Redirecionamento de Usuários Autenticados
**Descrição**: Usuários autenticados não devem acessar rotas públicas (exceto reset password).

**Implementação**: `lib/supabase/middleware.ts` (linha 155-159)
```typescript
if (user && isPublicRoute && !isResetPasswordRoute) {
  const url = request.nextUrl.clone()
  url.pathname = '/dashboard'
  return NextResponse.redirect(url)
}
```

---

### RN-MIDDLEWARE-003: Verificação de Módulos
**Descrição**: Módulos opcionais devem verificar flag de habilitação no tenant.

**Implementação**: `lib/supabase/middleware.ts` (linha 97-152)

**Exemplo**: Módulo "Descontos Venda"
```typescript
const { data: parameter } = await supabase
  .from('tenant_parameters')
  .select('parameter_value')
  .eq('tenant_id', currentTenantId)
  .eq('parameter_key', 'enable_descontos_venda')
  .maybeSingle()
```

---

## Regras de Mensagens

### RN-MSG-001: Mensagens de URL
**Descrição**: Mensagens de sistema devem ser passadas via URL query params.

**Formato**:
- Sucesso: `?message=Texto+da+mensagem`
- Erro: `?error=Texto+do+erro`
- Descrição: `?error_description=Detalhes`

---

### RN-MSG-002: Processamento de Mensagens
**Descrição**: Componentes devem processar e exibir mensagens da URL.

**Implementação**: `login-form.tsx` (linha 43-61)

**Tipos de Processamento**:
- Substituição de `+` por espaços
- Tradução de mensagens do Supabase
- Detecção de tipo (info, error, success)

---

### RN-MSG-003: Estilo de Alertas
**Descrição**: Alertas devem usar cores semânticas.

**Cores**:
- Info: Azul (`bg-blue-50`, `border-blue-200`, `text-blue-800`)
- Success: Verde (`bg-green-50`, `border-green-200`, `text-green-800`)
- Error: Vermelho (`variant="destructive"`)

---

### RN-MSG-004: Ícones de Mensagens
**Descrição**: Mensagens devem ter ícones apropriados.

**Mapeamento**:
- Success: `<CheckCircle2 />`
- Error: `<AlertCircle />`
- Info: `<Info />`

---

## Referências de Implementação

### Arquivos Principais
- Login: `src/components/auth/login-form.tsx`
- Recuperação: `src/components/auth/forgot-password-form.tsx`
- Redefinição: `src/components/auth/reset-password-form.tsx`
- Middleware: `src/lib/supabase/middleware.ts`
- Callback: `src/app/api/auth/callback/route.ts`

### Documentação Relacionada
- [DATA_STRUCTURES.md](./DATA_STRUCTURES.md) - Estruturas de dados
- [INTEGRATION_FLOW.md](./INTEGRATION_FLOW.md) - Fluxos de integração
- [SECURITY.md](./SECURITY.md) - Aspectos de segurança detalhados

---

**Última Revisão:** 2025-01-14  
**Próxima Revisão:** 2025-04-14
