import { NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'
import { safeErrorResponse } from '@/lib/api/error-handler'
import { hasTenantAccess } from '@/lib/security/tenant-access'

// GET - List tenant access for a user
export async function GET(request: Request) {
  try {
    const supabase = await createClient()
    const { searchParams } = new URL(request.url)
    const userId = searchParams.get('userId')

    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      return NextResponse.json({ error: 'Não autenticado' }, { status: 401 })
    }

    const { data: currentProfile } = await supabase
      .from('user_profiles')
      .select('role')
      .eq('id', user.id)
      .single() as { data: { role: string } | null }

    if (!currentProfile) {
      return NextResponse.json({ error: 'Perfil não encontrado' }, { status: 404 })
    }

    const targetUserId = userId || user.id

    if (targetUserId !== user.id && !['admin', 'superadmin'].includes(currentProfile.role)) {
      return NextResponse.json({ error: 'Sem permissão' }, { status: 403 })
    }

    const { data, error } = await supabase
      .from('user_tenant_access')
      .select('id, user_id, tenant_id, granted_at, granted_by, created_at')
      .eq('user_id', targetUserId)
      .order('created_at', { ascending: true })

    if (error) {
      return safeErrorResponse(error, 'tenant-access')
    }

    return NextResponse.json({ data })
  } catch (error) {
    console.error('Unexpected error:', error)
    return NextResponse.json({ error: 'Erro interno do servidor' }, { status: 500 })
  }
}

// POST - Add tenant access for a user
export async function POST(request: Request) {
  try {
    const supabase = await createClient()

    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      return NextResponse.json({ error: 'Não autenticado' }, { status: 401 })
    }

    const { data: currentProfile } = await supabase
      .from('user_profiles')
      .select('role')
      .eq('id', user.id)
      .single() as { data: { role: string } | null }

    if (!currentProfile || !['admin', 'superadmin'].includes(currentProfile.role)) {
      return NextResponse.json({ error: 'Sem permissão' }, { status: 403 })
    }

    const body = await request.json()
    const { userId, tenantId, tenantIds } = body as { userId?: string; tenantId?: string; tenantIds?: string[] }

    if (!userId || (!tenantId && (!tenantIds || tenantIds.length === 0))) {
      return NextResponse.json({ error: 'userId e tenantId(s) são obrigatórios' }, { status: 400 })
    }

    const idsToGrant = tenantIds && tenantIds.length > 0 ? tenantIds : [tenantId as string]

    if (currentProfile.role === 'admin') {
      for (const id of idsToGrant) {
        const allowed = await hasTenantAccess(supabase, user.id, id)
        if (!allowed) {
          return NextResponse.json({ error: 'Admin só pode conceder acesso a tenants que já acessa' }, { status: 403 })
        }
      }
    }

    const rows = idsToGrant.map(id => ({ user_id: userId, tenant_id: id }))

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const { data, error } = await (supabase as any)
      .from('user_tenant_access')
      .insert(rows)
      .select()

    if (error) {
      return safeErrorResponse(error, 'tenant-access')
    }

    return NextResponse.json({ data })
  } catch (error) {
    console.error('Unexpected error:', error)
    return NextResponse.json({ error: 'Erro interno do servidor' }, { status: 500 })
  }
}

// DELETE - Remove tenant access for a user
export async function DELETE(request: Request) {
  try {
    const supabase = await createClient()
    const { searchParams } = new URL(request.url)
    const userId = searchParams.get('userId')
    const tenantId = searchParams.get('tenantId')

    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      return NextResponse.json({ error: 'Não autenticado' }, { status: 401 })
    }

    const { data: currentProfile } = await supabase
      .from('user_profiles')
      .select('role')
      .eq('id', user.id)
      .single() as { data: { role: string } | null }

    if (!currentProfile || !['admin', 'superadmin'].includes(currentProfile.role)) {
      return NextResponse.json({ error: 'Sem permissão' }, { status: 403 })
    }

    if (!userId || !tenantId) {
      return NextResponse.json({ error: 'userId e tenantId são obrigatórios' }, { status: 400 })
    }

    if (currentProfile.role === 'admin') {
      const allowed = await hasTenantAccess(supabase, user.id, tenantId)
      if (!allowed) {
        return NextResponse.json({ error: 'Admin só pode remover acesso a tenants que já acessa' }, { status: 403 })
      }
    }

    const { error } = await supabase
      .from('user_tenant_access')
      .delete()
      .eq('user_id', userId)
      .eq('tenant_id', tenantId)

    if (error) {
      return safeErrorResponse(error, 'tenant-access')
    }

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('Unexpected error:', error)
    return NextResponse.json({ error: 'Erro interno do servidor' }, { status: 500 })
  }
}
