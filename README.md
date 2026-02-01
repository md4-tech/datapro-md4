# 📊 BI SaaS Dashboard

Sistema de Business Intelligence SaaS multi-tenant com dashboard moderno, autenticação completa, e visualização de dados interativa.

![Status](https://img.shields.io/badge/status-active-success)
![Next.js](https://img.shields.io/badge/Next.js-15.5.4-black)
![React](https://img.shields.io/badge/React-19.1.0-blue)
![TypeScript](https://img.shields.io/badge/TypeScript-5.x-blue)
![Supabase](https://img.shields.io/badge/Supabase-Auth%20%26%20DB-green)

---

## 🚀 Stack Tecnológica

- **Framework:** Next.js 15 (App Router + Turbopack)
- **UI:** React 19
- **Linguagem:** TypeScript
- **Estilo:** Tailwind CSS v4
- **Componentes:** shadcn/ui (17+ components)
- **Backend:** Supabase (Auth + PostgreSQL)
- **Gráficos:** Chart.js v4 + react-chartjs-2
- **Ícones:** lucide-react

---

## ✨ Funcionalidades

### 🔐 Autenticação Completa
- Login com email/senha
- Cadastro de usuários
- Recuperação de senha via email
- Redefinição de senha com token
- Logout seguro
- Proteção de rotas via middleware

### 🏢 Multi-Tenancy
- Isolamento por tenant no banco de dados
- Roles: admin, user, viewer
- User profiles vinculados a organizações
- RLS (Row Level Security) configurado

### 📊 Dashboard Interativo
- 4 cards de métricas com trends
- Gráficos interativos (Receita vs Despesas)
- Lista de atividades recentes
- Ações rápidas
- Status do sistema em tempo real

### 👤 Perfil do Usuário
- Edição de nome
- Alteração de senha com validação
- Visualização de informações da conta
- Avatar com iniciais

### 📈 Visualização de Dados
- Chart.js totalmente integrado
- Componentes: AreaChart, LineChart, BarChart
- Cores do design system
- Formatadores (moeda, número, percentual)
- Totalmente responsivo

### 🎨 UI/UX Moderna
- Sidebar collapsible
- Menu com submenus expansíveis
- Dark mode support
- Design system completo
- Mobile-first responsive

---

## 📦 Instalação

### Pré-requisitos
- Node.js 18+ ou 20+
- npm 9+ ou 10+
- Conta no Supabase

### Setup

1. **Clone o repositório**
```bash
git clone <repo-url>
cd datapro-md4
```

2. **Instale as dependências**
```bash
npm install
```

3. **Configure as variáveis de ambiente**

Crie um arquivo `.env.local` na raiz do projeto:

```env
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

4. **Configure o Supabase**

Execute as migrations SQL no Supabase Dashboard:
- Criar tabelas: `tenants`, `user_profiles`
- Configurar RLS policies
- (Ver documentação completa em `CLAUDE.md`)

5. **Inicie o servidor de desenvolvimento**
```bash
npm run dev
```

Acesse: [http://localhost:3000](http://localhost:3000)

---

## 🛠️ Scripts Disponíveis

### Desenvolvimento
```bash
npm run dev       # Inicia servidor dev (Turbopack)
```

### Build & Produção
```bash
npm run build     # Build de produção
npm start         # Inicia servidor de produção
```

### Manutenção
```bash
npm run lint      # Verifica código
npm run clean     # Limpa cache do Next.js
npm run clean:all # Reset completo (node_modules + cache)
```

### Limpeza de Cache
```bash
# Rápido (apenas cache)
npm run clean

# Completo (reinstala tudo)
npm run clean:all

# Ou use o script:
./scripts/clean-cache.sh
```

---

## 📁 Estrutura do Projeto

```
datapro-md4/
├── src/
│   ├── app/
│   │   ├── (auth)/              # Páginas de autenticação
│   │   ├── (dashboard)/         # Páginas do dashboard
│   │   ├── api/                 # API routes
│   │   └── globals.css          # Estilos globais + tema
│   ├── components/
│   │   ├── auth/                # Componentes de auth
│   │   ├── charts/              # Wrappers Chart.js ⭐
│   │   ├── dashboard/           # Componentes dashboard
│   │   ├── profile/             # Componentes de perfil
│   │   └── ui/                  # shadcn/ui components
│   ├── hooks/
│   │   ├── use-user.ts          # Hook de autenticação
│   │   ├── use-tenant.ts        # Hook de tenant
│   │   └── use-mobile.ts        # Detecção mobile
│   ├── lib/
│   │   ├── supabase/            # Clients Supabase
│   │   ├── chart-config.ts      # Config Chart.js ⭐
│   │   └── utils.ts             # Utilities
│   ├── types/
│   │   ├── database.types.ts    # Tipos Supabase
│   │   └── index.ts             # Tipos de domínio
│   └── middleware.ts            # Proteção de rotas
├── scripts/
│   └── clean-cache.sh           # Script de limpeza
├── .env.local                   # Variáveis de ambiente
├── components.json              # Config shadcn/ui
├── CLAUDE.md                    # 📖 Guia para IA
├── CHARTS_GUIDE.md              # 📊 Guia Chart.js
├── TROUBLESHOOTING.md           # 🔧 Resolução de problemas
├── PROJECT_STATUS.md            # 📋 Status do projeto
└── README.md                    # Este arquivo
```

---

## 📚 Documentação

### Para Desenvolvedores
- **[CHARTS_GUIDE.md](CHARTS_GUIDE.md)** - Guia completo de Chart.js
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Resolução de problemas
- **[PROJECT_STATUS.md](PROJECT_STATUS.md)** - Status atual do projeto
- **[docs/N8N_QUERIES.md](docs/N8N_QUERIES.md)** - Queries SQL para integração N8N

### Para IA (Claude)
- **[CLAUDE.md](CLAUDE.md)** - Guia principal do projeto
  - Architecture
  - Authentication flow
  - Multi-tenancy model
  - UI components
  - Charts & Data Visualization

### Para Integrações
- **[docs/](docs/)** - Documentação de integrações e automações
  - Queries N8N para WhatsApp
  - APIs e webhooks
  - Exemplos de uso

---

## 🎨 Design System

### Tema
- **Primary:** Blue `hsl(221.2, 83.2%, 53.3%)`
- **Dark Mode:** Totalmente suportado
- **Font:** Inter (system default)

### Componentes shadcn/ui (17)
Alert, Avatar, Badge, Button, Card, Collapsible, Dropdown Menu, Input, Label, Progress, Select, Separator, Sheet, Sidebar, Skeleton, Tabs, Tooltip

### Responsividade
- Mobile: < 768px
- Tablet: 768px - 1024px
- Desktop: > 1024px

---

## 📊 Criando Gráficos

### Quick Start

```typescript
import { AreaChart } from '@/components/charts/area-chart'
import { createAreaDataset, chartColorsRGBA } from '@/lib/chart-config'

const chartData = {
  labels: ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun'],
  datasets: [
    createAreaDataset(
      'Receita',
      [45000, 52000, 48000, 61000, 59000, 72000],
      chartColorsRGBA.primary,
      chartColorsRGBA.primaryLight
    ),
  ],
}

<AreaChart data={chartData} height={350} />
```

**Ver guia completo:** [CHARTS_GUIDE.md](CHARTS_GUIDE.md)

---

## 🐛 Troubleshooting

### Erro: ENOENT no `.next`
```bash
npm run clean
npm run dev
```

### Porta 3000 em uso
O Next.js automaticamente usará a próxima porta disponível (ex: 3002).

### Mais problemas?
Ver: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## 🔒 Segurança

- ✅ Row Level Security (RLS) configurado
- ✅ Autenticação via Supabase Auth
- ✅ Proteção de rotas via middleware
- ✅ Variáveis de ambiente não commitadas
- ✅ TypeScript para type safety

---

## 🚀 Deploy

### Vercel (Recomendado)

1. Conecte seu repositório no [Vercel](https://vercel.com)
2. Configure as variáveis de ambiente
3. Deploy automático!

### Outras Plataformas

Funciona em qualquer plataforma que suporte Next.js 15:
- Netlify
- AWS Amplify
- Railway
- Render

**Importante:** Configure as variáveis de ambiente em produção.

---

## 🎯 Próximos Passos

- [ ] Conectar gráficos com dados reais do Supabase
- [ ] Implementar página de relatórios
- [ ] Adicionar mais tipos de gráficos (Pie, Doughnut)
- [ ] Gerenciamento de usuários (admin)
- [ ] Filtros de período
- [ ] Export de dados (CSV, PDF)

Ver plano completo em: [PROJECT_STATUS.md](PROJECT_STATUS.md)

---

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma branch (`git checkout -b feature/nova-feature`)
3. Commit suas mudanças (`git commit -m 'Add: nova feature'`)
4. Push para a branch (`git push origin feature/nova-feature`)
5. Abra um Pull Request

---

## 📄 Licença

Este projeto está sob a licença MIT.

---

## 👤 Autor

**Samuel Dutra**

---

## 🙏 Agradecimentos

- [Next.js](https://nextjs.org)
- [Supabase](https://supabase.com)
- [shadcn/ui](https://ui.shadcn.com)
- [Chart.js](https://www.chartjs.org)
- [Tailwind CSS](https://tailwindcss.com)

---

**🎉 Projeto pronto para desenvolvimento!**

**Ver demo:** `npm run dev` → [http://localhost:3000](http://localhost:3000)
