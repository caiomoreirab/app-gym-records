# GymRecords — auditoria visual e novo acompanhamento de treino
**Data:** 23/11/2026  
**Branch:** `feat/fase1-registro-confiavel-classico`  
**Base visual:** versão clássica da v0.9.1, com paleta azul/ciano.  
**Status:** candidata em testes; não aprovada para lançamento somente por esta auditoria.

## Visão geral

| Tipo de imagem de execução | Exercícios | Status |
|---|---:|---|
| Assets WebP explícitos existentes, não bloqueados | 31 | Mapeados; revisão biomecânica individual ainda recomendada |
| SVGs específicos novos (supino com barra, agachamento livre, terra) | 3 | 9 arquivos: 3 movimentos × 3 preferências visuais |
| Sem arte exclusiva validada | 90 | Fallback vetorial que identifica equipamento, sem fingir uma execução correta |
| **Total do catálogo** | **124** | |

Os 9 novos SVGs ficam em `assets/illustrations/movements/{masculine,feminine,neutral}/`. 
O visual utiliza `BoxFit.contain` para não esticar nem cortar ilustrações ao alterar o tamanho do cartão. 
Um visual genérico **não** deve ser divulgado como demonstração biomecânica.

**Importante:** os perfis de ilustração representam preferências de aparência, não a identidade do usuário. 
Os novos vetores são propositalmente esquemáticos; antes de tratá-los como orientação de execução, uma pessoa qualificada deve revisar posições articulares, equipamentos e amplitude.

## Requisitos do acompanhamento interativo

- Iniciar treino abre **Treino em andamento**.
- A tela mantém início, duração aproximada, progresso N/M, quantidade de séries e lista de exercícios.
- **Adicionar exercício** usa o catálogo atual, sem criar registros fictícios.
- **Registrar série** abre o formulário completo existente.
- **Série rápida / Repetir série** abre um formulário curto pré-preenchido que requer confirmação, validando carga, repetições e duração.
- Marcar/desmarcar **Concluído** modifica apenas o estado da sessão, não métricas ou recordes.
- Exercícios ainda não registrados podem sair do plano; exercícios com séries exigem a exclusão explícita dessas séries.
- Finalizar com exercícios pendentes ou zero séries solicita confirmação.
- Progresso e registros são serializados no JSON v2, compatível com backups v1/v2.

## Persistência e preparação de banco Android

`SqliteLocalDataStore` conserva o arquivo físico `gymrecords_v1.db` para evitar perda ao migrar. A versão **interna do SQLite** passa de 1 para 2. O payload JSON v2 permanece como representação canônica para backup/exportação; uma mesma transação persiste o payload e atualiza as tabelas:

- `workout_sessions`
- `session_exercises` (posição e estado concluído)
- `workout_sets` (carga, repetições, duração, RPE, aquecimento etc.)
- `cardio_entries`
- `user_state_previous` (snapshot anterior para recuperação explícita)

Existem índices por sessão, exercício e data, e constraints de chave estrangeira. A migração **não apaga o JSON anterior**. Gravações inválidas devem reverter a transação; a tela Dados e privacidade pode oferecer recuperação confirmada do snapshot anterior.

**Limite de arquitetura:** durante a fase de compatibilidade, as tabelas normalizadas são uma projeção do snapshot, reconstruída transacionalmente. Antes de uma escala maior, o próximo passo técnico é um repositório incremental com inserts/updates por série, evitando reindexar todo o histórico a cada alteração. Não adicionar nuvem ou autenticação à release offline.

## Fila de imagens restantes (90)

As entradas abaixo precisam de desenho específico, conferência do equipamento e revisão do movimento. A produção pode ser feita em lotes com aprovação visual antes de substituir o fallback neutro.

| ID de catálogo | Exercício | Grupo | Equipamento |
|---|---|---|---|
| `dumbbell_bench_press` | Supino reto com halteres | chest | dumbbell |
| `incline_barbell_press` | Supino inclinado com barra | chest | barbell |
| `incline_dumbbell_press` | Supino inclinado com halteres | chest | dumbbell |
| `smith_bench_press` | Supino reto no Smith | chest | smith |
| `push_up` | Flexão de braços | chest | bodyweight |
| `chest_dip` | Paralelas para peito | chest | bodyweight |
| `decline_barbell_press` | Supino declinado com barra | chest | barbell |
| `decline_dumbbell_press` | Supino declinado com halteres | chest | dumbbell |
| `dumbbell_fly` | Crucifixo com halteres | chest | dumbbell |
| `incline_dumbbell_fly` | Crucifixo inclinado com halteres | chest | dumbbell |
| `low_to_high_cable_fly` | Crossover baixo para cima | chest | cable |
| `high_to_low_cable_fly` | Crossover alto para baixo | chest | cable |
| `pull_up` | Barra fixa pronada | back | bodyweight |
| `chin_up` | Barra fixa supinada | back | bodyweight |
| `barbell_row` | Remada curvada com barra | back | barbell |
| `one_arm_dumbbell_row` | Remada unilateral com halter | back | dumbbell |
| `t_bar_row` | Remada T-bar | back | barbell |
| `straight_arm_pulldown` | Pulldown com braços estendidos | back | cable |
| `chest_supported_dumbbell_row` | Remada apoiada com halteres | back | dumbbell |
| `high_row_machine` | Remada alta articulada | back | machine |
| `single_arm_cable_row` | Remada unilateral na polia | back | cable |
| `barbell_shrug` | Encolhimento com barra | back | barbell |
| `dumbbell_shrug` | Encolhimento com halteres | back | dumbbell |
| `back_extension` | Extensão lombar | back | bodyweight |
| `barbell_overhead_press` | Desenvolvimento com barra | shoulders | barbell |
| `dumbbell_shoulder_press` | Desenvolvimento com halteres | shoulders | dumbbell |
| `arnold_press` | Desenvolvimento Arnold | shoulders | dumbbell |
| `dumbbell_lateral_raise` | Elevação lateral com halteres | shoulders | dumbbell |
| `cable_lateral_raise` | Elevação lateral na polia | shoulders | cable |
| `front_raise` | Elevação frontal | shoulders | dumbbell |
| `face_pull` | Face pull | shoulders | cable |
| `upright_row` | Remada alta | shoulders | barbell |
| `smith_shoulder_press` | Desenvolvimento no Smith | shoulders | smith |
| `cable_front_raise` | Elevação frontal na polia | shoulders | cable |
| `cable_reverse_fly` | Crucifixo inverso na polia | shoulders | cable |
| `landmine_press` | Landmine press | shoulders | barbell |
| `barbell_curl` | Rosca direta com barra | biceps | barbell |
| `ez_bar_curl` | Rosca direta com barra W | biceps | barbell |
| `dumbbell_curl` | Rosca alternada com halteres | biceps | dumbbell |
| `incline_dumbbell_curl` | Rosca inclinada com halteres | biceps | dumbbell |
| `hammer_curl` | Rosca martelo | biceps | dumbbell |
| `preacher_curl_free` | Rosca Scott livre | biceps | barbell |
| `concentration_curl` | Rosca concentrada | biceps | dumbbell |
| `spider_curl` | Rosca spider | biceps | dumbbell |
| `bayesian_curl` | Rosca Bayesian na polia | biceps | cable |
| `reverse_curl` | Rosca inversa | biceps | barbell |
| `zottman_curl` | Rosca Zottman | biceps | dumbbell |
| `rope_pushdown` | Tríceps corda | triceps | cable |
| `overhead_cable_extension` | Tríceps francês na polia | triceps | cable |
| `skull_crusher` | Tríceps testa com barra | triceps | barbell |
| `dumbbell_french_press` | Tríceps francês com halter | triceps | dumbbell |
| `close_grip_bench` | Supino fechado | triceps | barbell |
| `bench_dip` | Mergulho no banco | triceps | bodyweight |
| `dumbbell_kickback` | Coice de tríceps com halter | triceps | dumbbell |
| `cable_kickback_triceps` | Coice de tríceps na polia | triceps | cable |
| `jm_press` | JM press | triceps | barbell |
| `diamond_push_up` | Flexão diamante | triceps | bodyweight |
| `front_squat` | Agachamento frontal | legs | barbell |
| `smith_squat` | Agachamento no Smith | legs | smith |
| `goblet_squat` | Agachamento goblet | legs | dumbbell |
| `bulgarian_split_squat` | Agachamento búlgaro | legs | dumbbell |
| `walking_lunge` | Avanço / passada | legs | dumbbell |
| `romanian_deadlift` | Levantamento terra romeno | legs | barbell |
| `stiff_leg_deadlift` | Stiff | legs | barbell |
| `hip_thrust` | Hip thrust | legs | barbell |
| `glute_bridge` | Ponte de glúteos | legs | bodyweight |
| `cable_kickback` | Coice na polia | legs | cable |
| `standing_calf` | Panturrilha em pé | legs | machine |
| `horizontal_leg_press` | Leg press horizontal | legs | machine |
| `pendulum_squat` | Agachamento pêndulo | legs | machine |
| `single_leg_press` | Leg press unilateral | legs | machine |
| `sissy_squat` | Sissy squat | legs | bodyweight |
| `step_up` | Step-up no banco | legs | dumbbell |
| `good_morning` | Good morning | legs | barbell |
| `single_leg_curl` | Flexora unilateral | legs | machine |
| `nordic_curl` | Nordic curl | legs | bodyweight |
| `sumo_squat` | Agachamento sumô | legs | dumbbell |
| `smith_hip_thrust` | Hip thrust no Smith | legs | smith |
| `cable_hip_abduction` | Abdução de quadril na polia | legs | cable |
| `cable_hip_adduction` | Adução de quadril na polia | legs | cable |
| `smith_standing_calf` | Panturrilha em pé no Smith | legs | smith |
| `leg_press_calf` | Panturrilha no leg press | legs | machine |
| `captain_chair_raise` | Elevação de pernas na paralela | abs | bodyweight |
| `side_plank` | Prancha lateral | abs | bodyweight |
| `ab_wheel` | Roda abdominal | abs | other |
| `russian_twist` | Rotação russa | abs | bodyweight |
| `hanging_knee_raise` | Elevação de joelhos suspenso | abs | bodyweight |
| `dead_bug` | Dead bug | abs | bodyweight |
| `pallof_press` | Pallof press | abs | cable |
| `cable_woodchop` | Woodchop na polia | abs | cable |

## Critérios para homologação

1. `flutter analyze`, `flutter test` e verificador de assets verdes **no mesmo SHA**.
2. Confirmar em Android real que o arquivo SQLite v1 é atualizado para v2 sem perda do histórico; forçar parada, abrir de novo e registrar após migração.
3. Fazer backup JSON, restaurar v1 e v2, validar erro de arquivo inválido e recuperação da cópia anterior.
4. Testar série rápida com kg/lb, campos em branco, duração para prancha e toques repetidos.
5. Confirmar que o progresso sobrevive a reabertura e que marcar Concluído não cria séries.
6. Verificar 320 px, 375 px, fontes ampliadas e teclado em Android/iOS.
7. Revisar individualmente as ilustrações, especialmente exercícios não cobertos.
8. Garantir que `main` não seja modificada até a aprovação do produto.

## Próximo lote visual recomendado

1. Supino reto com halteres, inclinado com barra e inclinado com halteres.
2. Puxada alta, barra fixa, remada curvada e remada unilateral.
3. Terra romeno, stiff, agachamento frontal e afundo búlgaro.
4. Elevação lateral, rosca direta, tríceps testa.
5. Prancha lateral, dead bug, roda abdominal e elevação suspensa.

**Status final desta auditoria:** mapeamento, medidas e fluxo implementados; cobertura ilustrativa completa e homologação de loja **ainda pendentes**.
