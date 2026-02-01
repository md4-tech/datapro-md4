/* eslint-disable @next/next/no-img-element */
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'

type AuthShellProps = {
  title: string
  description?: React.ReactNode
  children: React.ReactNode
  footer?: React.ReactNode
  logoSrc?: string
  logoAlt?: string
  logoClassName?: string
  sideImageSrc?: string
  sideImageDarkSrc?: string
  sideImageAlt?: string
  mobileLogoLightSrc?: string
  mobileLogoDarkSrc?: string
  mobileLogoAlt?: string
}

export function AuthShell({
  title,
  description,
  children,
  footer,
  logoSrc,
  logoAlt = 'Logo do produto',
  logoClassName = 'h-16 w-auto',
  sideImageSrc,
  sideImageDarkSrc,
  sideImageAlt = 'Imagem de apoio',
  mobileLogoLightSrc,
  mobileLogoDarkSrc,
  mobileLogoAlt = 'Logo do produto',
}: AuthShellProps) {
  return (
    <div className="bg-background flex min-h-svh flex-col items-center justify-center p-6 md:p-10">
      <div className="w-full max-w-sm md:max-w-4xl">
        {(mobileLogoLightSrc || mobileLogoDarkSrc) ? (
          <div className="mb-6 flex justify-center md:hidden">
            {mobileLogoLightSrc ? (
              <img
                src={mobileLogoLightSrc}
                alt={mobileLogoAlt}
                className={`h-20 w-auto ${mobileLogoDarkSrc ? 'block dark:hidden' : ''}`}
              />
            ) : null}
            {mobileLogoDarkSrc ? (
              <img
                src={mobileLogoDarkSrc}
                alt={mobileLogoAlt}
                className="hidden h-20 w-auto dark:block"
              />
            ) : null}
          </div>
        ) : null}
        <Card className="overflow-hidden p-0">
          <CardContent className="grid p-0 md:grid-cols-2">
            <div className="flex flex-col gap-6 p-6 md:p-8">
              <CardHeader className="space-y-2 p-0 text-center">
                {logoSrc ? (
                  <img src={logoSrc} alt={logoAlt} className={`mx-auto ${logoClassName}`} />
                ) : null}
                <CardTitle className="text-2xl">{title}</CardTitle>
                {description ? <CardDescription>{description}</CardDescription> : null}
              </CardHeader>
              {children}
            </div>
            {sideImageSrc ? (
              <div className="bg-muted relative hidden md:block">
                <img
                  src={sideImageSrc}
                  alt={sideImageAlt}
                  className={`absolute inset-0 h-full w-full object-cover ${sideImageDarkSrc ? 'block dark:hidden' : ''}`}
                />
                {sideImageDarkSrc ? (
                  <img
                    src={sideImageDarkSrc}
                    alt={sideImageAlt}
                    className="absolute inset-0 hidden h-full w-full object-cover dark:block"
                  />
                ) : null}
              </div>
            ) : null}
          </CardContent>
        </Card>
        {footer ? <div className="px-6 pt-6 text-center">{footer}</div> : null}
      </div>
    </div>
  )
}
