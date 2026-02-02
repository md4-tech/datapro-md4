'use client'

import { createContext, useContext, useState, useEffect, ReactNode, useCallback } from 'react'
import { createClient } from '@/lib/supabase/client'
import type { Tenant, UserProfile } from '@/types'

interface TenantContextType {
  currentTenant: Tenant | null
  accessibleTenants: Tenant[]
  userProfile: UserProfile | null
  loading: boolean
  canSwitchTenants: boolean
  switchTenant: (tenantId: string) => Promise<void>
  refreshTenants: () => Promise<void>
}

const TenantContext = createContext<TenantContextType | undefined>(undefined)

const CURRENT_TENANT_KEY = 'bi_saas_current_tenant_id'

export function TenantProvider({ children }: { children: ReactNode }) {
  const [currentTenant, setCurrentTenant] = useState<Tenant | null>(null)
  const [accessibleTenants, setAccessibleTenants] = useState<Tenant[]>([])
  const [userProfile, setUserProfile] = useState<UserProfile | null>(null)
  const [loading, setLoading] = useState(true)
  const supabase = createClient()

  const loadTenants = useCallback(async () => {
    try {
      setLoading(true)

      // Get current user
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) {
        setLoading(false)
        return
      }

      // Get user profile
      const { data: profile, error: profileError } = await supabase
        .from('user_profiles')
        .select('*')
        .eq('id', user.id)
        .single() as { data: UserProfile | null; error: Error | null }

      if (profileError || !profile) {
        // Se o perfil não existe, fazer logout (pode ser email alterado ou RLS bloqueado)
        console.log('Perfil não encontrado ou acesso negado - fazendo logout')
        
        // Limpar completamente a sessão
        await supabase.auth.signOut()
        
        // Limpar localStorage
        localStorage.clear()
        
        // Forçar redirecionamento imediato
        setLoading(false)
        
        if (typeof window !== 'undefined' && !window.location.pathname.includes('/login')) {
          // Usar replace para evitar histórico
          window.location.replace('/login?error=Acesso negado. Faça login novamente.')
        }
        return
      }

      setUserProfile(profile)

      // If user is superadmin, get ALL active tenants
      if (profile.role === 'superadmin') {

        const { data: allTenants, error: tenantsError } = await supabase
          .from('tenants')
          .select('*')
          .eq('is_active', true)
          .order('name') as { data: Tenant[] | null; error: Error | null }

        if (tenantsError) {
          console.error('TenantContext: Erro ao buscar tenants:', tenantsError)
        } else if (allTenants) {
          setAccessibleTenants(allTenants)

          // Set current tenant from localStorage or first accessible tenant
          const savedTenantId = localStorage.getItem(CURRENT_TENANT_KEY)
          const savedTenant = allTenants.find(t => t.id === savedTenantId)

          if (savedTenant) {
            setCurrentTenant(savedTenant)
          } else if (allTenants.length > 0) {
            setCurrentTenant(allTenants[0])
            localStorage.setItem(CURRENT_TENANT_KEY, allTenants[0].id)
          }
        }
      } else {
        // Regular user/admin - get tenants from profile + user_tenant_access
        const tenantIds = new Set<string>()

        if (profile.tenant_id) {
          tenantIds.add(profile.tenant_id)
        }

        const { data: accessRows, error: accessError } = await supabase
          .from('user_tenant_access')
          .select('tenant_id')
          .eq('user_id', profile.id) as { data: { tenant_id: string }[] | null; error: Error | null }

        if (accessError) {
          console.error('TenantContext: Erro ao buscar acessos do usuário:', accessError)
        } else {
          accessRows?.forEach(row => tenantIds.add(row.tenant_id))
        }

        const tenantIdList = Array.from(tenantIds)
        if (tenantIdList.length === 0) {
          console.error('TenantContext: Usuário sem tenant acessível')
          setLoading(false)
          return
        }

        const { data: tenants, error: tenantError } = await supabase
          .from('tenants')
          .select('*')
          .in('id', tenantIdList)
          .eq('is_active', true)
          .order('name') as { data: Tenant[] | null; error: Error | null }

        if (tenantError) {
          console.error('TenantContext: Erro ao buscar tenants:', tenantError)
        } else if (tenants && tenants.length > 0) {
          setAccessibleTenants(tenants)

          const savedTenantId = localStorage.getItem(CURRENT_TENANT_KEY)
          const savedTenant = tenants.find(t => t.id === savedTenantId)

          if (savedTenant) {
            setCurrentTenant(savedTenant)
          } else {
            setCurrentTenant(tenants[0])
            localStorage.setItem(CURRENT_TENANT_KEY, tenants[0].id)
          }
        }
      }

      setLoading(false)
    } catch (error) {
      console.error('Error loading tenants:', error)
      setLoading(false)
    }
  }, [supabase])

  const switchTenant = async (tenantId: string) => {
    const tenant = accessibleTenants.find(t => t.id === tenantId)
    if (!tenant) {
      console.error('[TenantContext] Tenant não encontrado:', tenantId)
      return
    }
    
    console.log('[TenantContext] 🔄 Iniciando troca de tenant:', {
      de: currentTenant?.name,
      para: tenant.name,
      tenantId
    })
    
    try {
      // 1. Salvar novo tenant no localStorage IMEDIATAMENTE
      localStorage.setItem(CURRENT_TENANT_KEY, tenantId)
      console.log('[TenantContext] ✅ Tenant salvo no localStorage:', tenantId)
      
      // 2. Limpar sessionStorage completamente (pode ter dados cacheados)
      sessionStorage.clear()
      console.log('[TenantContext] ✅ SessionStorage limpo')
      
      // 3. Limpar dados específicos do localStorage (exceto auth)
      const itemsToKeep = ['bi_saas_current_tenant_id']
      const allKeys = Object.keys(localStorage)
      
      let removedCount = 0
      allKeys.forEach(key => {
        // Manter auth do Supabase e tenant_id
        if (key.includes('supabase') || itemsToKeep.includes(key)) {
          return
        }
        localStorage.removeItem(key)
        removedCount++
      })
      console.log('[TenantContext] 🗑️ Removidos', removedCount, 'itens do localStorage')
      
      // 4. Atualizar estado (para componentes que escutam)
      setCurrentTenant(tenant)
      console.log('[TenantContext] ✅ Estado atualizado')
      
      // 5. Forçar reload TOTAL da página
      console.log('[TenantContext] 🔄 RECARREGANDO PÁGINA em 50ms...')
      
      setTimeout(() => {
        // Usar reload(true) força bypass do cache do navegador
        window.location.reload()
      }, 50)
      
    } catch (error) {
      console.error('[TenantContext] ❌ Erro ao trocar tenant:', error)
    }
  }

  const refreshTenants = async () => {
    await loadTenants()
  }

  useEffect(() => {
    loadTenants()

    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange(() => {
      loadTenants()
    })

    return () => subscription.unsubscribe()
  }, [loadTenants, supabase.auth])

  const canSwitchTenants = accessibleTenants.length > 1

  return (
    <TenantContext.Provider
      value={{
        currentTenant,
        accessibleTenants,
        userProfile,
        loading,
        canSwitchTenants,
        switchTenant,
        refreshTenants,
      }}
    >
      {children}
    </TenantContext.Provider>
  )
}

export function useTenantContext() {
  const context = useContext(TenantContext)
  if (context === undefined) {
    throw new Error('useTenantContext must be used within a TenantProvider')
  }
  return context
}
