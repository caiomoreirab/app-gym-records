# GymRecords — Fase 1: revisão de mapeamentos visuais

**Base preservada:** v0.9.1 (visual clássico, iOS). **Status:** auditoria de
mapeamento do código, sem trocar imagens nem modificar assets.

## Escopo e limitação
O catálogo tem 124 exercícios e reutiliza um número muito menor de ilustrações.
As relações abaixo são verificáveis em
`lib/services/illustration_assets.dart`; é necessária validação visual e
biomecânica antes de substituir cada arte. Compartilhar um mesmo arquivo não
prova sozinho que duas execuções estão incorretas.

| Exercício(s) | Asset usado no código | Motivo para revisar |
|---|---|---|
| Supino reto com barra e variantes com halteres | família `chest_0` / fallback do peito | Pode confundir supino livre com máquina |
| Supino inclinado com barra e halteres | `chest_2` | Mesma pose para instrumentos distintos |
| Puxada alta, barra fixa e remada unilateral no cabo | `back_0` | Movimentos e trajetórias diferentes |
| Levantamento terra e extensão lombar | `back_4` | Movimentos diferentes compartilham figura |
| Rosca direta, martelo, Scott livre e Zottman | `biceps_0` | Pegadas e posições diferentes |
| Agachamento livre, frontal, avanço e afundo búlgaro | `hack_squat` | Movimento livre pode ser apresentado como máquina |
| Terra romeno, stiff, good morning e nórdico | `lying_leg_curl` | Movimentos livres associados à flexora deitada |
| Panturrilha em pé | `seated_calf` | Execuções em pé/sentado diferentes |
| Abdominal crunch, dead bug e russian twist | `abs_crunch` | Três movimentos distintos |
| Abdominal reverso e elevação de joelhos suspenso | `abs_reverse` | Distinção entre chão e suspensão |
| Elevação de pernas suspenso e na paralela | `abs_hanging` | Equipamentos e apoios diferentes |
| Prancha, prancha lateral e roda abdominal | `abs_plank` | Exercícios diferentes com a mesma pose-base |
| Pallof press, woodchop e crunch no cabo | `abs_cable` | Movimento antirrotação vs flexão/tronco |
| Elevação lateral e frontal com halteres/cabos | `shoulders_1` | Plano de movimento diferente |
| Tríceps testa, francês e supino fechado | `triceps_1` | Padrões de movimento diferentes |

## Proposta (aguarda aprovação)
1. Conferir execução e músculos alvo em três estilos para cada entrada.
2. Produzir uma lista de poses específicas necessárias e validar com referência
   biomecânica antes de trocar as imagens.
3. Manter fallback neutro quando não houver execução verificada.
4. Após aprovação do inventário, substituir assets em uma etapa própria, com
   testes de proporção e cobertura.

**Nenhum asset é substituído nesta Fase 1.**
