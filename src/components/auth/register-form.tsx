'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { InputGroup, InputGroupAddon, InputGroupInput } from '@/components/ui/input-group'
import { Label } from '@/components/ui/label'
import { useRouter } from 'next/navigation'
import { Mail, User, Lock } from 'lucide-react'
import { ThemeSelect } from '@/components/auth/theme-select'

export function RegisterForm() {
  const [fullName, setFullName] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const router = useRouter()
  const supabase = createClient()

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError(null)

    const trimmedPassword = password.trim()

    if (trimmedPassword.length < 6) {
      setError('A senha deve ter pelo menos 6 caracteres')
      setLoading(false)
      return
    }

    try {
      console.log('Criando usuário:', {
        email: email.trim(),
        passwordLength: trimmedPassword.length,
        fullName: fullName.trim()
      })

      const { data, error } = await supabase.auth.signUp({
        email: email.trim(),
        password: trimmedPassword,
        options: {
          data: {
            full_name: fullName.trim(),
          },
        },
      })

      if (error) {
        console.error('Erro no cadastro:', error)
        setError(error.message)
        setLoading(false)
        return
      }

      console.log('Cadastro bem-sucedido:', data)

      // Criar perfil do usuário se não existir (fallback caso não haja trigger)
      if (data.user) {
        const profileData: Record<string, string | boolean> = {
          id: data.user.id,
          full_name: fullName.trim(),
          role: 'user',
          is_active: true,
        }

        const { error: profileError } = await supabase
          .from('user_profiles')
          // @ts-expect-error - Supabase type inference limitation
          .upsert(profileData)
          .select()

        if (profileError) {
          console.error('Erro ao criar perfil:', profileError)
          // Não falhar o cadastro se o perfil não for criado (pode ter trigger)
        }
      }

      // Usuário criado com sucesso
      router.push('/dashboard')
      router.refresh()
    } catch (err) {
      console.error('Erro inesperado no cadastro:', err)
      setError('Erro ao criar conta. Tente novamente.')
      setLoading(false)
    }
  }

  return (
    <form onSubmit={handleRegister} className="space-y-4">
      <div className="space-y-2">
        <Label htmlFor="fullName">Nome Completo</Label>
        <InputGroup>
          <InputGroupInput
            id="fullName"
            type="text"
            placeholder="Seu nome"
            value={fullName}
            onChange={(e) => setFullName(e.target.value)}
            required
            disabled={loading}
          />
          <InputGroupAddon align="inline-start" aria-hidden="true">
            <User className="h-4 w-4" />
          </InputGroupAddon>
        </InputGroup>
      </div>

      <div className="space-y-2">
        <Label htmlFor="email">Email</Label>
        <InputGroup>
          <InputGroupInput
            id="email"
            type="email"
            placeholder="Digite seu email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
            disabled={loading}
          />
          <InputGroupAddon align="inline-start" aria-hidden="true">
            <Mail className="h-4 w-4" />
          </InputGroupAddon>
        </InputGroup>
      </div>

      <div className="space-y-2">
        <Label htmlFor="password">Senha</Label>
        <InputGroup>
          <InputGroupInput
            id="password"
            type="password"
            placeholder="••••••••"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
            disabled={loading}
            minLength={6}
          />
          <InputGroupAddon align="inline-start" aria-hidden="true">
            <Lock className="h-4 w-4" />
          </InputGroupAddon>
        </InputGroup>
        <p className="text-xs text-muted-foreground">
          Mínimo de 6 caracteres
        </p>
      </div>

      {error && (
        <div className="text-sm text-red-500 bg-red-50 p-3 rounded-md">
          {error}
        </div>
      )}

      <Button type="submit" className="w-full" disabled={loading}>
        {loading ? 'Criando conta...' : 'Criar conta'}
      </Button>

      <ThemeSelect />
    </form>
  )
}
