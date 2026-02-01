# Design System (Base)

Este documento define os tokens e regras gerais de UI para o projeto.
Ele serve como base para qualquer refactory de design.

## Objetivo
- Unificar cores, tipografia, espaçamentos e estados de interação.
- Evitar estilos inline isolados e decisões ad-hoc.
- Preparar terreno para padronização com shadcn/ui.

## Tokens (a definir)
Preencher com valores finais assim que a direção visual estiver aprovada.

### Cores
- `--background`:
- `--foreground`:
- `--primary`:
- `--primary-foreground`:
- `--secondary`:
- `--secondary-foreground`:
- `--muted`:
- `--muted-foreground`:
- `--accent`:
- `--accent-foreground`:
- `--destructive`:
- `--destructive-foreground`:
- `--border`:
- `--input`:
- `--ring`:

### Tipografia
- Fonte principal:
- Fonte de destaque:
- Tamanhos base (ex: 12/14/16/18/20/24/32):
- Altura de linha base:

### Raios
- `--radius`:

### Sombras
- Elevation 1:
- Elevation 2:
- Elevation 3:

### Espaçamentos
- Escala (ex: 4/8/12/16/24/32/40/48/64):

## Componentes Base (shadcn/ui)
Componentes que devem ser priorizados antes de criar variações próprias:
- Button
- Input
- Label
- Card
- Alert
- Form

## Regras Gerais
- Evitar cores hex diretas em componentes (usar tokens).
- Variantes de botão devem mapear `default/secondary/outline/destructive/ghost`.
- Estados de foco devem usar `ring` consistente.
- Mensagens de erro e sucesso devem usar Alert padronizado.

## Responsividade
- Mobile-first.
- Largura máxima de conteúdo para Auth: 360-420px.
- Padding lateral em mobile: 16-24px.

## Acessibilidade
- Contraste mínimo AA.
- Sempre expor `label` para inputs.
- Evitar placeholder como única forma de indicação.

