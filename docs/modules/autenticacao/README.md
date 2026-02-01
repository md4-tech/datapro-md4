# Módulo de Autenticação e Recuperação de Senha

> Status: ✅ Implementado

**Última Atualização:** 2025-01-14  
**Versão:** 1.0.0

## Visão Geral

O módulo de autenticação é responsável por gerenciar todo o ciclo de vida de autenticação de usuários no sistema BI SaaS, incluindo login, recuperação de senha, redefinição de senha e gestão de sessões. Utiliza Supabase Auth como backend de autenticação com suporte a multi-tenancy.

## Índice

- [Funcionalidades](#funcionalidades)
- [Componentes Principais](#componentes-principais)
- [Rotas](#rotas)
- [Arquivos de Documentação](#arquivos-de-documentação)
- [Permissões](#permissões)
- [Fluxos Principais](#fluxos-principais)

## Funcionalidades

### ✅ Implementadas

- **Login de Usuário**
  - Autenticação via email e senha
  - Validação de credenciais
  - Gestão de sessão
  - Exibição/ocultação de senha
  - Timeout de segurança (10s)
  - Mensagens de erro contextualizadas

- **Recuperação de Senha**
  - Envio de email de recuperação
  - Link com token seguro
  - Redirecionamento automático
  - Feedback visual de sucesso

- **Redefinição de Senha**
  - Interface de nova senha
  - Validação de força de senha
  - Confirmação de senha
  - Atualização segura via Supabase

- **Gestão de Sessão**
  - Middleware de autenticação
  - Proteção de rotas privadas
  - Refresh automático de tokens
  - Logout seguro

- **Tratamento de Erros**
  - Mensagens traduzidas (PT-BR)
  - Erros contextualizados por tipo
  - Rate limiting
  - Link expirado/inválido

## Componentes Principais

### Frontend

#### Páginas
- **Login**: [src/app/(auth)/login/page.tsx](../../../src/app/(auth)/login/page.tsx)
- **Esqueci Senha**: [src/app/(auth)/esqueci-senha/page.tsx](../../../src/app/(auth)/esqueci-senha/page.tsx)
- **Redefinir Senha**: [src/app/(auth)/redefinir-senha/page.tsx](../../../src/app/(auth)/redefinir-senha/page.tsx)

#### Componentes
- **LoginForm**: [src/components/auth/login-form.tsx](../../../src/components/auth/login-form.tsx)
  - Formulário de login
  - Validação de campos
  - Toggle de senha
  - Mensagens de URL

- **ForgotPasswordForm**: [src/components/auth/forgot-password-form.tsx](../../../src/components/auth/forgot-password-form.tsx)
  - Formulário de recuperação
  - Envio de email
  - Feedback de sucesso

- **ResetPasswordForm**: [src/components/auth/reset-password-form.tsx](../../../src/components/auth/reset-password-form.tsx)
  - Formulário de nova senha
  - Validação de confirmação
  - Atualização de senha

#### Componentes UI (shadcn/ui)
- **Button**: [src/components/ui/button.tsx](../../../src/components/ui/button.tsx)
- **Input**: [src/components/ui/input.tsx](../../../src/components/ui/input.tsx)
- **Card**: [src/components/ui/card.tsx](../../../src/components/ui/card.tsx)
- **Alert**: [src/components/ui/alert.tsx](../../../src/components/ui/alert.tsx)
- **Label**: [src/components/ui/label.tsx](../../../src/components/ui/label.tsx)

### Backend

#### Supabase Clients
- **Browser Client**: [src/lib/supabase/client.ts](../../../src/lib/supabase/client.ts)
  - Cliente para componentes client-side
  - Gerencia cookies de sessão
  - Usado em formulários

- **Server Client**: [src/lib/supabase/server.ts](../../../src/lib/supabase/server.ts)
  - Cliente para Server Components/API
  - Cache-control configurado
  - Cookies via Next.js

- **Middleware Client**: [src/lib/supabase/middleware.ts](../../../src/lib/supabase/middleware.ts)
  - Cliente específico para middleware
  - Atualização de sessão
  - Proteção de rotas

#### Middleware
- **Auth Middleware**: [src/middleware.ts](../../../src/middleware.ts)
  - Proteção de rotas privadas
  - Verificação de permissões
  - Redirecionamentos automáticos

#### API Routes
- **Auth Callback**: [src/app/api/auth/callback/route.ts](../../../src/app/api/auth/callback/route.ts)
  - Processa callbacks do Supabase
  - Troca código por sessão
  - Confirmação de email
  - Tratamento de erros

### Database

#### Tabelas Utilizadas
- `auth.users` (Supabase Auth)
  - Gerenciamento de usuários
  - Emails e senhas criptografadas
  - Metadata e confirmações

- `public.user_profiles`
  - Perfis de usuários
  - Roles (superadmin, admin, user)
  - Tenant association

- `public.tenants`
  - Informações de tenants
  - Schemas isolados

## Rotas

### Rotas Públicas (não requerem autenticação)

| Rota | Descrição | Componente |
|------|-----------|-----------|
| `/login` | Página de login | LoginPage |
| `/esqueci-senha` | Recuperação de senha | ForgotPasswordPage |
| `/redefinir-senha` | Redefinição de senha | ResetPasswordPage |
| `/cadastro` | Registro de novo usuário | RegisterPage |
| `/email-confirmacao` | Confirmação de email | EmailConfirmationPage |

### Rotas Protegidas

| Rota | Descrição | Requisito |
|------|-----------|-----------|
| `/dashboard` | Dashboard principal | Autenticado |
| `/dashboard/*` | Todas as páginas do dashboard | Autenticado |
| `/usuarios` | Gestão de usuários | Admin ou Superadmin |
| `/empresas` | Gestão de tenants | Superadmin |

### API Routes

| Rota | Método | Descrição |
|------|--------|-----------|
| `/api/auth/callback` | GET | Callback do Supabase Auth |

## Arquivos de Documentação

- [README.md](./README.md) - Este arquivo (visão geral)
- [BUSINESS_RULES.md](./BUSINESS_RULES.md) - Regras de negócio detalhadas
- [DATA_STRUCTURES.md](./DATA_STRUCTURES.md) - Estruturas de dados e tipos
- [INTEGRATION_FLOW.md](./INTEGRATION_FLOW.md) - Fluxos de integração completos
- [UI_PATTERNS.md](./UI_PATTERNS.md) - Padrões de design e UI
- [SECURITY.md](./SECURITY.md) - Aspectos de segurança
- [CHANGELOG.md](./CHANGELOG.md) - Histórico de alterações

## Permissões

| Funcionalidade | Público | User | Admin | Superadmin |
|---------------|---------|------|-------|------------|
| Login | ✅ | ✅ | ✅ | ✅ |
| Esqueci Senha | ✅ | ✅ | ✅ | ✅ |
| Redefinir Senha | ✅ | ✅ | ✅ | ✅ |
| Acessar Dashboard | ❌ | ✅ | ✅ | ✅ |
| Gerenciar Usuários | ❌ | ❌ | ✅ | ✅ |
| Gerenciar Tenants | ❌ | ❌ | ❌ | ✅ |

## Fluxos Principais

### 1. Login Bem-Sucedido
```
Usuário → Formulário Login → Supabase Auth → Sessão Criada → Redirect /dashboard
```

### 2. Recuperação de Senha
```
Usuário → Formulário Esqueci Senha → Supabase → Email Enviado → Link Mágico → Redefinir Senha
```

### 3. Proteção de Rota
```
Acesso /dashboard → Middleware → Verificar Sessão → Autorizado? → Página ou Redirect /login
```

### 4. Expiração de Sessão
```
Sessão Expirada → Middleware Detecta → Redirect /login?message=Sessão+expirada
```

## Tecnologias Utilizadas

- **Framework**: Next.js 15 (App Router)
- **Autenticação**: Supabase Auth
- **UI Components**: shadcn/ui
- **Styling**: Tailwind CSS
- **Icons**: Lucide React
- **TypeScript**: Tipagem estrita

## Variáveis de Ambiente

```env
# Supabase
NEXT_PUBLIC_SUPABASE_URL=https://seu-projeto.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=sua-chave-anonima

# App
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

## Links Úteis

- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Next.js App Router](https://nextjs.org/docs/app)
- [shadcn/ui Components](https://ui.shadcn.com/)

## Suporte

Para dúvidas ou problemas com autenticação:
- WhatsApp: +55 44 99722-3315
- Email: ajuda@md4tech.com.br

---

**Próximos Passos:**
- 🔄 Implementar autenticação OAuth (Google, Microsoft)
- 🔄 Adicionar autenticação de dois fatores (2FA)
- 🔄 Implementar login via código QR
- 🔄 Adicionar biometria para dispositivos móveis
