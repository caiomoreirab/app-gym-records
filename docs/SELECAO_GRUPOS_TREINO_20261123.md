# GymRecords — Seleção de grupos musculares por treino

## Objetivo

Na ação “Iniciar treino”, a pessoa passa por duas etapas opcionais:
1. Selecionar um ou vários grupos musculares, com os cartões e imagens atuais,
   incluindo Cardio. “Seguir sem escolher grupos” abre o catálogo inteiro.
2. Selecionar exercícios (múltiplos) e, quando relevante, atividades de cardio.
   “Começar sem exercícios” inicia a sessão vazia, para montar durante o treino.

A sessão só nasce após confirmar a segunda etapa. Voltar ou cancelar não gera
treinos vazios involuntariamente. Os filtros sugerem; nunca adicionam todos
os exercícios de um grupo automaticamente.

## Durante o treino

- “Grupos do treino” > “Alterar” reabre a seleção com os grupos pré-marcados.
- A edição só troca sugestões. Exercícios, séries e cardio já registrados
  permanecem intactos, mesmo que um grupo deixe de estar selecionado.
- O atalho “Adicionar exercício” usa os grupos escolhidos, com opção “Todos”.
- Atividades de cardio planejadas aparecem com acesso ao respectivo registro.
- Cardio registrado durante treino carrega `sessionId` e mantém seus dados.

## Persistência e retrocompatibilidade

`WorkoutSession.selectedGroupIds` e `plannedCardioIds` são opcionais.
`CardioRecord.sessionId` também é opcional. Os três campos são registrados
no snapshot e no backup existente, sem mudança do esquema SQLite: dados
antigos assumem seleções vazias e cardio sem vínculo. Grupos inválidos
no backup são rejeitados antes de alterar a memória atual.

Acompanhamento de progresso baseado em séries de musculação continua
separado da conclusão de cardio. Nenhuma série fictícia é produzida.

## Identidade visual

Conservados Barlow, cores escuras e azul-ciano, imagens de cada grupo,
o mascote, os cartões e os ícones do GymRecords. Sem imagens novas,
sem alteração de imagens anteriores ou da branch `main`.

## Aceitação

- Vários grupos e nenhum grupo.
- Seleção múltipla de exercícios filtrados.
- Alternância temporária para todos os grupos.
- Cardio junto a grupos de musculação.
- Edição sem perda de registros ou de exercícios existentes.
- Backup antigo funciona, backup inválido não altera dados.
- Testes para tela de 320 px, catálogo e persistência offline.
