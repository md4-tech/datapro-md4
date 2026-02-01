import { ForgotPasswordForm } from '@/components/auth/forgot-password-form'
import { Suspense } from 'react'
import { Loader2 } from 'lucide-react'
import { AuthShell } from '@/components/auth/auth-shell'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'DataPro - Esqueceu a senha?',
}

function ForgotPasswordFormWrapper() {
  return (
    <Suspense fallback={
      <div className="flex flex-col items-center justify-center py-8 space-y-4">
        <Loader2 className="h-8 w-8 animate-spin text-emerald-500" />
        <p className="text-sm text-muted-foreground">Carregando...</p>
      </div>
    }>
      <ForgotPasswordForm />
    </Suspense>
  )
}

export default function ForgotPasswordPage() {
  return (
    <AuthShell
      title="Recuperar senha"
      description={(
        <p className="text-muted-foreground text-balance">
          Informe seu email para receber as instruções.
        </p>
      )}
      logoAlt="DataPro by MD4Tech - Inteligência analítica para negócios"
      sideImageSrc="/login.svg"
      sideImageDarkSrc="/dark-login.svg"
      sideImageAlt="Ilustração de login"
      mobileLogoLightSrc="/light-logo.svg"
      mobileLogoDarkSrc="/dark-logo.svg"
      mobileLogoAlt="DataPro by MD4Tech - Inteligência analítica para negócios"
      footer={undefined}
    >
      <ForgotPasswordFormWrapper />
    </AuthShell>
  )
}
