'use client'

import { createClient } from '@/lib/supabase/client'
import { useEffect, useState } from 'react'
import type { Tenant } from '@/types'

/**
 * Hook para obter os tenants acessíveis por um usuário
 * - Superadmins: retorna TODOS os tenants ativos
 * - Outros usuários: retorna apenas o tenant do usuário
 */
export function useAccessibleTenants() {
  const [tenants, setTenants] = useState<Tenant[]>([])
  const [loading, setLoading] = useState(true)
  const supabase = createClient()

  useEffect(() => {
    const fetchAccessibleTenants = async () => {
      try {
        const { data: { user } } = await supabase.auth.getUser()

        if (!user) {
          console.log('useAccessibleTenants: Nenhum usuário autenticado')
          setLoading(false)
          return
        }

        // Buscar perfil do usuário para verificar role
        const { data: profile } = await supabase
          .from('user_profiles')
          .select('role, tenant_id')
          .eq('id', user.id)
          .single() as { data: { role: string; tenant_id: string | null } | null; error: Error | null }

        if (!profile) {
          console.error('useAccessibleTenants: Perfil não encontrado')
          setLoading(false)
          return
        }

        // Se for superadmin, buscar todos os tenants
        if (profile.role === 'superadmin') {
          console.log('useAccessibleTenants: Buscando todos os tenants (superadmin)')

          const { data: allTenants, error } = await supabase
            .from('tenants')
            .select('*')
            .eq('is_active', true)
            .order('name') as { data: Tenant[] | null; error: Error | null }

          if (error) {
            console.error('useAccessibleTenants: Erro ao buscar tenants:', error)
          } else {
            console.log(`✅ useAccessibleTenants: ${allTenants?.length || 0} tenants encontrados`)
            setTenants(allTenants || [])
          }
        } else {
          // Se não for superadmin, buscar tenants do perfil + user_tenant_access
          console.log('useAccessibleTenants: Buscando tenants do usuário')

          const tenantIds = new Set<string>()

          if (profile.tenant_id) {
            tenantIds.add(profile.tenant_id)
          }

          const { data: accessRows, error: accessError } = await supabase
            .from('user_tenant_access')
            .select('tenant_id')
            .eq('user_id', user.id) as { data: { tenant_id: string }[] | null; error: Error | null }

          if (accessError) {
            console.error('useAccessibleTenants: Erro ao buscar acessos:', accessError)
          } else {
            accessRows?.forEach(row => tenantIds.add(row.tenant_id))
          }

          const tenantIdList = Array.from(tenantIds)
          if (tenantIdList.length > 0) {
            const { data: accessibleTenants, error } = await supabase
              .from('tenants')
              .select('*')
              .in('id', tenantIdList)
              .eq('is_active', true)
              .order('name') as { data: Tenant[] | null; error: Error | null }

            if (error) {
              console.error('useAccessibleTenants: Erro ao buscar tenants:', error)
            } else {
              console.log(`✅ useAccessibleTenants: ${accessibleTenants?.length || 0} tenants encontrados`)
              setTenants(accessibleTenants || [])
            }
          }
        }

        setLoading(false)
      } catch (err) {
        console.error('useAccessibleTenants: Erro inesperado:', err)
        setLoading(false)
      }
    }

    fetchAccessibleTenants()
  }, [supabase])

  return { tenants, loading }
}
