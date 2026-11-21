# GymRecords — Fase 1: registro que merece confiança

**Base:** versão clássica v0.9.1 / branch `main` restaurada, commit `7f813c1`.
**Implementação isolada:** `feat/fase1-registro-confiavel-classico`.
**Regra:** não realizar merge sem validação do proprietário.

## Implementado

- `WorkoutRecord` com ID imutável, sessão, esforço opcional (RPE),
  tempo de descanso, observação e aquecimento.
- `WorkoutSession` com ID único, início, término e exercícios associados.
  Uma sessão ativa do dia pode ser concluída; dias diferentes não se misturam.
- `WorkoutSnapshotCodec` usa `schemaVersion: 2` e importa v1 e v2.
  Registros v1 recebem IDs determinísticos (sem deduplicar séries iguais).
  Quando não há identificador de sessão legado, os registros antigos são
  agrupados por **data local**, sem inventar sessões separadas não registradas.
  Campos extras experimentais (por exemplo, regulagens, fotos, local)
  continuam preservados no JSON de backup, sem serem habilitados na interface.
- Série individual editável ou excluível, com confirmação, salvamento local,
  desfazer e proteção contra toques duplicados.
- Tela clássica preservada; carga/repetições lado a lado no cartão de registro.
  Replicação em um toque, RPE/descanso/nota em seção recolhível.
- Histórico agrupado por sessão, numeração por exercício e sessão.
- Favoritos e treino atual na Home existente, com adicionar pela busca.
- Maior peso, peso entre 8 e 12 repetições e 1RM Epley. Aquecimentos são
  ignorados pelos recordes; 1RM apenas para 1–12 repetições.
- CSV com sessão, número da série, carga, repetições, RPE e outros campos.
  PDF com data, sessão, exercício, número de série, peso e repetições juntos.
- Feedback ao preparar PDF, fonte ampliada, melhorias de toque/semântica e
  estado vazio para gráficos sem histórico suficiente.
- Estrutura de métricas agregadas **locais**, sem novos envios de dados.

## Decisões que exigem validação do produto

1. **RPE:** somente RPE de 1–10 nesta fase; RIR permanece armazenável mas não
   exposto como controle duplicado.
2. **Sessão histórica:** registros v1 não guardavam sessão; são atribuídos a
   uma sessão de referência por data local. Dois treinos antigos no mesmo dia
   não podem ser separados de forma confiável.
3. **Aquecimento legado:** todos os registros antigos começam como não
   aquecimento, por falta dessa informação no backup.
4. **1RM:** fórmula de Epley e limite de 12 repetições, estimativa explicada.
5. **Ilustrações:** ver `docs/FASE1_AUDITORIA_ILUSTRACOES.md`; nenhum asset foi
   substituído sem aprovação.
6. **Free × Pro:** entitlements, preços e gating gratuitos ainda NÃO foram
   alterados. Dependem da aprovação desta fase.

## Procedimento de testes manuais (Web e aparelhos)

1. Salvar backup JSON dos dados existentes. Não apagar o banco.
2. Abrir supino com barra, definir 100 kg e 3 repetições e salvar uma vez.
   Conferir lista, backup JSON, CSV e PDF.
3. Salvar duas séries iguais e verificar IDs e numeração distintos.
4. Usar Repetir última série, editar, excluir, desfazer e reiniciar o app.
5. Marcar aquecimento e validar que ele não estabelece PR.
6. Encerrar treino A e iniciar B no mesmo dia, verificar histórico separado.
7. Criar favoritos, buscar exercício, adicionar ao treino de hoje.
8. Verificar fonte ampliada no dispositivo menor, teclado, rolagem e VoiceOver.
9. Alternar modo avião no iOS e Android, registrar, reabrir e restaurar backup.
10. Confirmar que o CSV e PDF mostram as repetições da mesma série da interface.

**Limitações de homologação:** os testes automatizados não substituem testes
reais em iPhone/Android. A versão oficial `main` ainda não foi atualizada.

**Cuidado de rollback:** backup v2 NÃO é compatível com o app clássico v0.9.1,
que só reconhece esquema v1. Conserve uma cópia do backup original antes de
testar o candidato; nunca substitua um backup único por um teste.
