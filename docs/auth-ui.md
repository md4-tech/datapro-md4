# Auth UI (Login / Esqueci senha / Redefinir)

Este documento define o padrão visual e estrutural das telas de autenticação.
O estilo base deve seguir o template shadcn/ui `login-04`.

## Escopo
- Login
- Esqueci senha
- Redefinir senha

## Layout Base
Criar um shell reutilizável que seja usado nas três telas:
- Logo no topo (novo asset pendente).
- Título e subtítulo.
- Card central com formulário.
- Links auxiliares (ex: "Voltar para o login", "Precisa de ajuda?").

## Estrutura Recomendada
1. Container de página (background, padding, centralização).
2. Branding (logo + nome do produto).
3. Card com título e descrição.
4. Form com inputs e CTAs.
5. Links auxiliares abaixo do card.

## Direção Visual (login-04)
- Card com borda suave, sombra discreta.
- Botão primário ocupando 100% da largura.
- Espaçamentos generosos entre campos.
- Tipografia clara (títulos 18-24px).

## Estados
Padronizar states com Alert:
- Erro (destructive)
- Sucesso (success)
- Info (info)
- Loading (spinner discreto)

## CTA e Links (pendente de revisão)
Lista atual para revisar/substituir:
- Link de WhatsApp: `https://wa.me/554499510755`
- Link "Solicite aqui" (WhatsApp)
- Link "Precisa de ajuda?" (WhatsApp)
- Link "Voltar para o login" (`/login`)
- Link "Esqueceu a senha?" (`/esqueci-senha`)

## Formulários
### Login
- Campos: email, senha
- Ações: mostrar/ocultar senha, erro inline
- CTA principal: "Acessar"

### Esqueci senha
- Campo: email
- CTA: "Enviar link de recuperação"
- Sucesso: aviso com instruções de email

### Redefinir senha
- Campos: nova senha, confirmar nova senha
- Indicador de match de senha
- CTA: "Redefinir senha"

## Checklist de Implementação
- [ ] Criar `auth-shell` reutilizável.
- [ ] Migrar Login para o shell + Card padrão.
- [ ] Migrar Esqueci senha para o shell + Card padrão.
- [ ] Migrar Redefinir senha para o shell + Card padrão.
- [ ] Padronizar alerts, botões e inputs.
- [ ] Revisar CTA/links e substituir pelos aprovados.
- [ ] Ajustar logo nova em todas as telas.

