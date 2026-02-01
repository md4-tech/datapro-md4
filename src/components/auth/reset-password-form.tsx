'use client'

import { useState, useEffect, useCallback } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { Field, FieldDescription, FieldGroup, FieldLabel } from '@/components/ui/field'
import { InputGroup, InputGroupAddon, InputGroupInput } from '@/components/ui/input-group'
import { ThemeSelect } from '@/components/auth/theme-select'
import { useRouter } from 'next/navigation'
import { Eye, EyeOff, CheckCircle2, XCircle, AlertTriangle, Loader2, ShieldCheck, Lock } from 'lucide-react'
import Link from 'next/link'

type FormStatus = 'validating' | 'ready' | 'submitting' | 'success' | 'error'

export function ResetPasswordForm() {
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [showConfirmPassword, setShowConfirmPassword] = useState(false)
  const [status, setStatus] = useState<FormStatus>('validating')
  const [error, setError] = useState<string | null>(null)
  const [countdown, setCountdown] = useState(3)

  const router = useRouter()
  const supabase = createClient()

  const passwordsMatch = password.trim() === confirmPassword.trim() && confirmPassword.length > 0

  // Check for active session on mount
  useEffect(() => {
    let isMounted = true

    const checkSession = async () => {
      console.log('[ResetPassword] Checking for active session...')

      await new Promise(resolve => setTimeout(resolve, 500))

      const { data: { session } } = await supabase.auth.getSession()

      if (!isMounted) return

      if (session) {
        console.log('[ResetPassword] Session found, ready for password update')
        setStatus('ready')
      } else {
        console.log('[ResetPassword] No session found')
        setError('Sessão não encontrada. Por favor, solicite um novo link de recuperação.')
        setStatus('error')
      }
    }

    const { data: { subscription } } = supabase.auth.onAuthStateChange((event, session) => {
      console.log('[ResetPassword] Auth state changed:', event, !!session)

      if (!isMounted) return

      if (event === 'PASSWORD_RECOVERY' || event === 'SIGNED_IN') {
        if (session) {
          setStatus('ready')
        }
      }
    })

    checkSession()

    return () => {
      isMounted = false
      subscription.unsubscribe()
    }
  }, [supabase.auth])

  // Countdown after success
  useEffect(() => {
    if (status === 'success' && countdown > 0) {
      const timer = setTimeout(() => setCountdown(countdown - 1), 1000)
      return () => clearTimeout(timer)
    } else if (status === 'success' && countdown === 0) {
      router.push('/dashboard')
      router.refresh()
    }
  }, [status, countdown, router])

  const handleSubmit = useCallback(async (e: React.FormEvent) => {
    e.preventDefault()
    setStatus('submitting')
    setError(null)

    const trimmedPassword = password.trim()

    if (trimmedPassword.length < 6) {
      setError('A senha deve ter pelo menos 6 caracteres')
      setStatus('ready')
      return
    }

    if (trimmedPassword !== confirmPassword.trim()) {
      setError('As senhas não coincidem')
      setStatus('ready')
      return
    }

    const { data: { session: currentSession } } = await supabase.auth.getSession()

    if (!currentSession) {
      setError('Sua sessão expirou. Por favor, solicite um novo link de recuperação.')
      setStatus('error')
      return
    }

    try {
      const { error: updateError } = await supabase.auth.updateUser({
        password: trimmedPassword,
      })

      if (updateError) {
        console.error('[ResetPassword] Error updating password:', updateError)

        if (updateError.message.includes('same')) {
          setError('A nova senha deve ser diferente da senha anterior')
        } else if (updateError.message.includes('session')) {
          setError('Sua sessão expirou. Por favor, solicite um novo link de recuperação.')
          setStatus('error')
          return
        } else {
          setError(updateError.message || 'Erro ao redefinir senha. Tente novamente.')
        }
        setStatus('ready')
        return
      }

      setStatus('success')
    } catch (err) {
      console.error('[ResetPassword] Unexpected error:', err)
      setError('Erro ao redefinir senha. Tente novamente.')
      setStatus('ready')
    }
  }, [password, confirmPassword, supabase.auth])

  // Loading state while validating
  if (status === 'validating') {
    return (
      <div className="flex flex-col items-center justify-center py-8 space-y-4">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
        <p className="text-sm text-muted-foreground">Verificando sessão...</p>
      </div>
    )
  }

  // Error state
  if (status === 'error') {
    return (
      <div className="flex flex-col gap-6">
        <Alert className="border-red-200 bg-red-50">
          <XCircle className="h-4 w-4 text-red-600" />
          <AlertDescription className="text-red-800">
            {error}
          </AlertDescription>
        </Alert>

        <div className="flex flex-col gap-3">
          <Link href="/esqueci-senha">
            <Button className="w-full">
              Solicitar novo link
            </Button>
          </Link>
          <Link href="/login">
            <Button variant="outline" className="w-full">
              Voltar para o login
            </Button>
          </Link>
        </div>
      </div>
    )
  }

  // Success state
  if (status === 'success') {
    return (
      <div className="flex flex-col gap-6 py-4">
        <div className="flex flex-col items-center text-center space-y-4">
          <div className="h-16 w-16 rounded-full bg-emerald-500/10 flex items-center justify-center">
            <ShieldCheck className="h-8 w-8 text-emerald-600" />
          </div>
          <div>
            <h3 className="text-lg font-semibold text-foreground">Senha redefinida com sucesso!</h3>
            <p className="text-sm text-muted-foreground mt-1">
              Sua nova senha foi configurada.
            </p>
          </div>
        </div>

        <Alert className="border-emerald-200 bg-emerald-50">
          <CheckCircle2 className="h-4 w-4 text-emerald-600" />
          <AlertDescription className="text-emerald-800">
            Redirecionando para o dashboard em {countdown} segundo{countdown !== 1 ? 's' : ''}...
          </AlertDescription>
        </Alert>

        <Button
          onClick={() => { router.push('/dashboard'); router.refresh() }}
          className="w-full"
        >
          Ir para o Dashboard agora
        </Button>
      </div>
    )
  }

  // Main form
  return (
    <div className="flex flex-col gap-6">
      {/* Form */}
      <form onSubmit={handleSubmit}>
        <FieldGroup>
          {/* Password Field */}
          <Field>
            <FieldLabel htmlFor="password">Nova senha</FieldLabel>
            <InputGroup>
              <InputGroupInput
                id="password"
                type={showPassword ? 'text' : 'password'}
                placeholder="Digite sua nova senha"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                disabled={status === 'submitting'}
                className="pr-10"
                autoFocus
              />
              <InputGroupAddon align="inline-start" aria-hidden="true">
                <Lock className="h-4 w-4" />
              </InputGroupAddon>
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground transition-colors"
                tabIndex={-1}
              >
                {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
              </button>
            </InputGroup>
            <FieldDescription>Mínimo de 6 caracteres</FieldDescription>
          </Field>

          {/* Confirm Password Field */}
          <Field>
            <FieldLabel htmlFor="confirmPassword">Confirmar nova senha</FieldLabel>
            <InputGroup>
              <InputGroupInput
                id="confirmPassword"
                type={showConfirmPassword ? 'text' : 'password'}
                placeholder="Digite novamente sua nova senha"
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                required
                disabled={status === 'submitting'}
                className={`pr-10 ${
                  confirmPassword && (passwordsMatch ? 'border-emerald-500 focus-visible:ring-emerald-500' : 'border-red-500 focus-visible:ring-red-500')
                }`}
              />
              <InputGroupAddon align="inline-start" aria-hidden="true">
                <Lock className="h-4 w-4" />
              </InputGroupAddon>
              <button
                type="button"
                onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground transition-colors"
                tabIndex={-1}
              >
                {showConfirmPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
              </button>
            </InputGroup>

            {/* Password Match Indicator */}
            {confirmPassword && (
              <div className={`flex items-center gap-1.5 text-xs ${
                passwordsMatch ? 'text-emerald-600' : 'text-red-500'
              }`}>
                {passwordsMatch ? (
                  <>
                    <CheckCircle2 className="h-3.5 w-3.5" />
                    Senhas coincidem
                  </>
                ) : (
                  <>
                    <AlertTriangle className="h-3.5 w-3.5" />
                    Senhas não coincidem
                  </>
                )}
              </div>
            )}
          </Field>

          {/* Error Alert */}
          {error && (
            <Alert className="border-red-200 bg-red-50">
              <XCircle className="h-4 w-4 text-red-600" />
              <AlertDescription className="text-red-800">
                {error}
              </AlertDescription>
            </Alert>
          )}

          {/* Submit Button */}
          <Field>
            <Button
              type="submit"
              className="w-full"
              disabled={status === 'submitting' || !passwordsMatch || password.length < 6}
            >
              {status === 'submitting' ? (
                <span className="flex items-center justify-center gap-2">
                  <Loader2 className="h-4 w-4 animate-spin" />
                  Redefinindo...
                </span>
              ) : (
                'Redefinir senha'
              )}
            </Button>
          </Field>
        </FieldGroup>
      </form>

      {/* WhatsApp Help Link */}
      <div className="flex items-center gap-4">
        <a
          href="https://wa.me/554499510755"
          target="_blank"
          rel="noopener noreferrer"
          className="inline-flex items-center gap-2 text-sm text-[color:var(--link)] hover:underline"
        >
          <svg className="h-4 w-4 text-[#25D366]" fill="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413Z"/>
          </svg>
          Precisa de ajuda?
        </a>
        <div className="ml-auto w-[180px]">
          <ThemeSelect />
        </div>
      </div>
    </div>
  )
}
