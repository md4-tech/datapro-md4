'use client'

import { useEffect, useState, Suspense } from 'react'
import { useSearchParams, useRouter } from 'next/navigation'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { CheckCircle2, AlertCircle, Loader2, Mail } from 'lucide-react'
import Link from 'next/link'
import Image from 'next/image'

function EmailConfirmacaoContent() {
  const searchParams = useSearchParams()
  const router = useRouter()
  const [status, setStatus] = useState<'loading' | 'success' | 'error' | 'info'>('loading')
  const [message, setMessage] = useState('')

  useEffect(() => {
    const urlMessage = searchParams.get('message')
    const error = searchParams.get('error')
    const type = searchParams.get('type')

    // Processar diferentes tipos de mensagens
    if (error) {
      setStatus('error')
      setMessage(processErrorMessage(error))
    } else if (urlMessage) {
      const processedMessage = processConfirmationMessage(urlMessage)
      setStatus(processedMessage.type as 'success' | 'info')
      setMessage(processedMessage.text)
    } else if (type === 'email_change') {
      setStatus('info')
      setMessage('Confirmação de alteração de email em andamento...')
    } else {
      setStatus('success')
      setMessage('Email confirmado com sucesso!')
    }

    // Se não houver parâmetros, redirecionar após 3 segundos
    if (!urlMessage && !error && !type) {
      setTimeout(() => {
        router.push('/login')
      }, 3000)
    }
  }, [searchParams, router])

  const processConfirmationMessage = (message: string): { type: string; text: string } => {
    const msg = message.toLowerCase()

    if (msg.includes('confirmation link accepted')) {
      return {
        type: 'info',
        text: 'Link de confirmação aceito! Verifique sua nova caixa de entrada para concluir a alteração de email.'
      }
    }

    if (msg.includes('email confirmed') || msg.includes('email change confirmed')) {
      return {
        type: 'success',
        text: 'Email confirmado com sucesso! Você já pode fazer login com seu novo email.'
      }
    }

    return {
      type: 'info',
      text: message
    }
  }

  const processErrorMessage = (error: string): string => {
    const err = error.toLowerCase()

    if (err.includes('expired')) {
      return 'Link de confirmação expirado. Por favor, solicite um novo link.'
    }
    if (err.includes('invalid')) {
      return 'Link inválido. Verifique se você clicou no link correto ou solicite um novo.'
    }
    if (err.includes('already confirmed')) {
      return 'Este email já foi confirmado anteriormente.'
    }

    return error
  }

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center gap-3">
          {status === 'loading' && <Loader2 className="h-6 w-6 animate-spin text-blue-600" />}
          {status === 'success' && <CheckCircle2 className="h-6 w-6 text-green-600" />}
          {status === 'error' && <AlertCircle className="h-6 w-6 text-red-600" />}
          {status === 'info' && <Mail className="h-6 w-6 text-blue-600" />}
          <div>
            <CardTitle>
              {status === 'loading' && 'Processando...'}
              {status === 'success' && 'Confirmação Concluída'}
              {status === 'error' && 'Erro na Confirmação'}
              {status === 'info' && 'Confirmação de Email'}
            </CardTitle>
            <CardDescription>
              {status === 'loading' && 'Aguarde enquanto processamos sua confirmação'}
              {status === 'success' && 'Seu email foi confirmado com sucesso'}
              {status === 'error' && 'Houve um problema ao confirmar seu email'}
              {status === 'info' && 'Ação necessária'}
            </CardDescription>
          </div>
        </div>
      </CardHeader>
      <CardContent className="space-y-4">
        <Alert
          variant={status === 'error' ? 'destructive' : 'default'}
          className={
            status === 'success'
              ? 'bg-green-50 border-green-200 text-green-800'
              : status === 'info'
              ? 'bg-blue-50 border-blue-200 text-blue-800'
              : ''
          }
        >
          {status === 'success' && <CheckCircle2 className="h-4 w-4" />}
          {status === 'error' && <AlertCircle className="h-4 w-4" />}
          {status === 'info' && <Mail className="h-4 w-4" />}
          <AlertDescription>{message}</AlertDescription>
        </Alert>

        {/* Instruções adicionais para alteração de email */}
        {status === 'info' && message.includes('nova caixa de entrada') && (
          <div className="bg-blue-50 border border-blue-200 rounded-md p-4 text-sm text-blue-800">
            <p className="font-medium mb-2">Próximos passos:</p>
            <ol className="list-decimal list-inside space-y-1">
              <li>Acesse sua nova caixa de email</li>
              <li>Procure pelo email de confirmação da MD4 Tech</li>
              <li>Clique no link de confirmação</li>
              <li>Após confirmar, faça login com o novo email</li>
            </ol>
          </div>
        )}

        {/* Botões de ação */}
        <div className="flex gap-2">
          {status === 'success' && (
            <Button asChild className="w-full bg-[#1cca5b] hover:bg-[#1cca5b]/90 text-black">
              <Link href="/login">Fazer Login</Link>
            </Button>
          )}

          {status === 'error' && (
            <>
              <Button asChild variant="outline" className="w-full">
                <Link href="/esqueci-senha">Solicitar Novo Link</Link>
              </Button>
              <Button asChild className="w-full bg-[#1cca5b] hover:bg-[#1cca5b]/90 text-black">
                <Link href="/login">Voltar ao Login</Link>
              </Button>
            </>
          )}

          {status === 'info' && (
            <Button asChild className="w-full bg-[#1cca5b] hover:bg-[#1cca5b]/90 text-black">
              <Link href="/login">Ir para Login</Link>
            </Button>
          )}

          {status === 'loading' && (
            <Button disabled className="w-full">
              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              Processando...
            </Button>
          )}
        </div>

        {/* Link adicional */}
        <div className="text-center text-sm text-gray-600">
          <p>
            Precisa de ajuda?{' '}
            <Link href="/login" className="text-[#1cca5b] hover:text-[#1cca5b]/80">
              Entre em contato
            </Link>
          </p>
        </div>
      </CardContent>
    </Card>
  )
}

export default function EmailConfirmacaoPage() {
  return (
    <div className="min-h-screen flex items-center justify-center p-4 bg-gray-100">
      <div className="w-full max-w-md">
        {/* Logo */}
        <div className="mb-8 text-center">
          <Image
            src="/logo_mobile.png"
            alt="MD4 Tech Logo"
            width={150}
            height={60}
            className="h-15 w-auto mx-auto"
          />
        </div>

        <Suspense fallback={
          <Card>
            <CardContent className="p-6">
              <div className="flex items-center justify-center">
                <Loader2 className="h-8 w-8 animate-spin text-blue-600" />
              </div>
            </CardContent>
          </Card>
        }>
          <EmailConfirmacaoContent />
        </Suspense>
      </div>
    </div>
  )
}
