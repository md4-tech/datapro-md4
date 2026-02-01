import { ResetPasswordForm } from '@/components/auth/reset-password-form'
import { Suspense } from 'react'
import { Loader2 } from 'lucide-react'
import { AuthShell } from '@/components/auth/auth-shell'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'DataPro - Recuperar senha',
}

function ResetPasswordFormWrapper() {
  return (
    <Suspense fallback={
      <div className="flex flex-col items-center justify-center py-8 space-y-4">
        <Loader2 className="h-8 w-8 animate-spin text-emerald-500" />
        <p className="text-sm text-muted-foreground">Carregando...</p>
      </div>
    }>
      <ResetPasswordForm />
    </Suspense>
  )
}

export default function ResetPasswordPage() {
  return (
    <AuthShell
      title="Redefinir senha"
      description={(
        <p className="text-muted-foreground text-balance">
          Crie uma nova senha segura para sua conta.
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
      <ResetPasswordFormWrapper />
    </AuthShell>
  )
}
