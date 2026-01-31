# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a multi-tenant Business Intelligence SaaS platform built with Next.js 15 (App Router), React 19, TypeScript, and Supabase. The application implements database-level isolation using PostgreSQL schemas, with each tenant having its own schema for data separation.

## Development Commands

```bash
# Development
npm run dev          # Start dev server with Turbopack
npm run build        # Build for production with Turbopack
npm start            # Start production server

# Maintenance
npm run lint         # Check code with ESLint
npm run clean        # Clear Next.js cache
npm run clean:all    # Full reset (removes node_modules, reinstalls)
```

## Architecture

### Multi-Tenant Model (Critical)

**Schema-based Isolation:**
- Each tenant has its own PostgreSQL schema (e.g., `okilao`, `saoluiz`, `paraiso`, `lucia`)
- The `public` schema contains only configuration tables (`tenants`, `user_profiles`, `user_tenant_access`, `branches`, `tenant_parameters`)
- Each tenant's data (sales, products, goals, etc.) lives in their own schema

**Critical Configuration:**
- New schemas MUST be added to "Exposed schemas" in Supabase Dashboard (Settings → API)
- Error `PGRST106` indicates a schema is not exposed
- Documentation: `docs/SUPABASE_SCHEMA_CONFIGURATION.md`

**Tenant Table:**
- Location: `public.tenants`
- Critical field: `supabase_schema` - the actual PostgreSQL schema name
- RPC functions always use `p_schema` parameter to target the correct tenant schema

### Authentication Architecture

**Three Supabase Client Instances:**
1. `@/lib/supabase/client.ts` - Browser/client components
2. `@/lib/supabase/server.ts` - Server components and API routes
3. `@/lib/supabase/middleware.ts` - Middleware (route protection)
4. `@/lib/supabase/admin.ts` - Admin operations (bypasses RLS)

**Middleware Protection** (`src/middleware.ts`):
- Protects all dashboard routes
- Enforces role-based access (superadmin-only, admin+)
- Checks tenant parameters for feature flags (e.g., `enable_descontos_venda`)
- Redirects unauthenticated users to `/login`

**Context Providers:**
- `TenantProvider` (`src/contexts/tenant-context.tsx`) - Manages current tenant, tenant switching for superadmins
- `ThemeProvider` (`src/contexts/theme-context.tsx`) - Theme management

### Permission System

**User Roles** (defined in `src/types/index.ts`):
- `superadmin` - Full access, can switch tenants, manage companies
- `admin` - Manage users, full data access within tenant
- `user` (Gestor) - View and use features, limited editing
- `viewer` - Read-only access

**Permission Hooks:**
```typescript
// Use these hooks in components
const { canManageUsers, canViewFinancialData } = usePermissions()
const isAdmin = useIsAdminOrAbove()
const { currentTenant, accessibleTenants } = useTenantContext()
const { branches } = useBranches({ tenantId: currentTenant?.id })
```

### Route Structure

**Route Groups:**
- `(auth)` - Public authentication pages (login, cadastro, esqueci-senha, redefinir-senha)
- `(dashboard)` - Protected dashboard pages, wrapped in `<DashboardShell>`

**Key Dashboard Routes:**
- `/dashboard` - Main dashboard with metrics
- `/metas/mensal` - Monthly goals by branch
- `/metas/setor` - Goals by department/sector (3-level hierarchy)
- `/dre-gerencial` - Management income statement (DRE)
- `/descontos-venda` - Sales discounts (requires `enable_descontos_venda` parameter)
- `/usuarios` - User management (admin+)
- `/empresas` - Company management (superadmin only)
- `/configuracoes` - Settings (includes sectors management)

### Report Architecture

**RPC Functions Pattern:**
All reports use Supabase RPC functions with schema parameter:
```typescript
const { data } = await supabase.rpc('get_report_name', {
  p_schema: currentTenant.supabase_schema,  // ALWAYS required
  p_filial_id: filters.filialId,
  p_mes: filters.mes,
  p_ano: filters.ano,
  p_page: filters.page,
  p_page_size: filters.pageSize  // Max: 10,000
})
```

**Report Functions Available:**
- `get_venda_curva_report` - Sales by product curve (ABC analysis)
- `get_ruptura_abcd_report` - Stock rupture by ABC classification
- `generate_metas_mensais` - Generate monthly goals
- `update_meta_mensal` - Update monthly goal values
- `get_metas_setor_report` - Goals by sector with realizations

**Filter Pattern** (documented in `docs/FILTER_PATTERN_STANDARD.md`):
All report pages must follow this UI pattern:
- Order: Filial → Mês → Ano → Specific Filters → Apply Button
- Fixed height: `h-10` (40px) on all fields and button
- Responsive: `flex-col` on mobile, `flex-row` on desktop
- Standard widths: Filial (200px), Mês (160px), Ano (120px)

**PDF Export Pattern:**
- Uses dynamic import: `const jsPDF = (await import('jspdf')).default`
- Fetches all data with `page_size: 10000`
- Implementation reference: `docs/PDF_EXPORT_VENDA_CURVA.md`

### Chart.js Integration

**Configuration** (`src/lib/chart-config.ts`):
- Auto-registers Chart.js components on module import
- Provides helpers: `createAreaDataset()`, `createLineDataset()`, `createBarDataset()`
- Theme: Dark mode with green neon accent (`#1EC56A`)
- Formatters: `formatCurrency()`, `formatNumber()`, `formatPercentage()`, `formatValueShort()`

**Chart Components** (`src/components/charts/`):
```typescript
import { AreaChart } from '@/components/charts/area-chart'
import { createAreaDataset, chartColorsRGBA } from '@/lib/chart-config'

// Use in components
<AreaChart data={chartData} height={350} />
```

### Database Patterns

**Critical Multi-Tenant Rules:**
1. ALWAYS include `tenant_id` filter in queries (except superadmin global views)
2. ALWAYS use `p_schema` parameter when calling RPC functions
3. NEVER query tenant-specific data without tenant context
4. Row Level Security (RLS) is enabled on `public` schema tables

**Type Generation:**
- Database types: `src/types/database.types.ts` (auto-generated from Supabase)
- Domain types: `src/types/index.ts` (extends database types with relationships)

### Feature Flags (Tenant Parameters)

Located in `public.tenant_parameters` table:
- `enable_descontos_venda` - Enable sales discounts module
- Checked in middleware for route access control
- Documentation: `docs/PARAMETROS_TENANT.md`

### Key Modules

**Metas (Goals) System:**
- Monthly goals: Generate goals for each branch for a month, track progress vs actual sales
- Sector goals: 3-level department hierarchy, track by sector with discount application
- Inline editing: Edit goal values directly in tables
- Documents: `docs/MODULO_METAS_OVERVIEW.md`, `docs/FEATURE_INLINE_EDIT_METAS.md`

**User Authorized Branches:**
- Users can have access limited to specific branches
- Hook: `useAuthorizedBranches()`
- API: `/api/users/authorized-branches`
- Documentation: `docs/USER_AUTHORIZED_BRANCHES.md`

### Important Conventions

**Server vs Client Components:**
- Mark client components with `'use client'` directive
- Hooks (useState, useEffect, context) only in client components
- Use `@/lib/supabase/server` in server components/API routes
- Use `@/lib/supabase/client` in client components

**Path Aliases:**
- `@/*` maps to `src/*` (configured in `tsconfig.json`)

**Styling:**
- Tailwind CSS v4 with design system
- shadcn/ui components in `src/components/ui/`
- Dark theme by default with green neon accent

### Environment Variables

Required in `.env.local`:
```env
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

### New Tenant Setup Checklist

When adding a new tenant:
1. Create schema: `CREATE SCHEMA tenant_name;`
2. Run migrations in new schema
3. Create all required tables in tenant schema
4. Create RPC functions in tenant schema
5. Insert record in `public.tenants` with `supabase_schema` field
6. **⚠️ CRITICAL:** Add schema to "Exposed schemas" in Supabase Dashboard
7. Grant necessary permissions
8. Import initial data
9. Create user profiles with `tenant_id`

### Common Issues

**Error PGRST106:**
- Schema not in "Exposed schemas" list
- Fix: Settings → API → Add schema name
- See: `docs/SUPABASE_SCHEMA_CONFIGURATION.md`

**PDF Export Errors:**
- Verify `page_size` limit (max 10,000)
- Use dynamic import for jsPDF
- See: `docs/FIX_PDF_EXPORT_ERROR.md`

**Filter Appearance Issues:**
- Follow standard pattern in `docs/FILTER_PATTERN_STANDARD.md`
- All fields must have `h-10` height

### Performance Notes

- Page size maximum: 10,000 records (report APIs)
- PDF export uses dynamic imports to reduce bundle size
- Chart.js uses tree-shaking (only registered components are bundled)
- Next.js automatically caches static pages
- RPC functions have 30-second timeout

### Testing

- Manual testing in dev environment
- Use superadmin account to test tenant switching
- Test with different roles to verify permissions
- Verify RLS policies are working (users can't access other tenant data)

### Additional Documentation

See `docs/` directory for detailed feature documentation:
- `FILTER_PATTERN_STANDARD.md` - UI filter pattern
- `SUPABASE_SCHEMA_CONFIGURATION.md` - Schema setup
- `PDF_EXPORT_VENDA_CURVA.md` - PDF export implementation
- `MODULO_METAS_OVERVIEW.md` - Goals system overview
- `USER_AUTHORIZED_BRANCHES.md` - Branch authorization
- `N8N_QUERIES.md` - Integration queries for N8N
