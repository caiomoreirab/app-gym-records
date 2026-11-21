# GymRecords — roteiro de validação da branch Neon

**Branch:** `feat/registro-sessoes-validacao`. **A `main` permanece intocada.**
**Referência visual:** as quatro pranchas PNG aprovadas no chat, especialmente
`Mockup GymRecords em Quatro Telas`. O HTML anterior serve apenas de referência funcional.

## Implementado no código (ainda sujeito à compilação e teste visual)
- Home nova com mascote, azul-ciano, treino ativo, favoritos, recentes e grupos via catálogo.
- Sessões com IDs únicos, início, plano de exercícios e conclusão, com suporte a dois
  treinos no mesmo dia; dados antigos mantidos pelo formato de backup v1.
- Registro de séries com carga e repetições lado a lado, RPE, observação,
  aquecimento, repetição da última série, edição, exclusão e desfazer do salvamento.
- Abas Registrar, Séries, Histórico e Recordes no detalhe do exercício.
- Recordes por maior carga, faixa 8–12 e 1RM estimado pela fórmula Epley.
- Metas locais por exercício, resumo semanal e descanso opcional de 60/90/120 s.
- Perfis de academia, ID de academia em cada série e fotografia de equipamento
  selecionada da galeria, armazenada no backup local com limite de tamanho.
- CSV e PDF básicos gratuitos. Importação CSV por texto/área de transferência,
  com prévia, reconhecimento de cabeçalhos e prevenção de reimportação do mesmo CSV.
- Preferências de texto ampliado e alto contraste; visual escuro/ciano.
- Sem login, sem sincronização obrigatória. SQLite em Android/iOS.

## Roteiro manual de aceite
1. Onboarding com nome e visual, Home Neon e catálogo de exercícios.
2. Iniciar Treino A, adicionar supino, registrar 80 kg × 3 e 80 kg × 10.
3. Editar, excluir e desfazer; conferir que o reinício não perde as séries.
4. Concluir treino e iniciar Treino B no mesmo dia; conferir sessões distintas.
5. Marcar 120 kg × 5 como aquecimento e conferir que não vira PR.
6. Conferir carga mais alta, 8–12 reps e 1RM estimado.
7. Criar meta de supino, verificar progresso e o resumo da semana.
8. Criar academia B, selecioná-la, registrar uma série e conferir o campo gym_id no CSV.
9. Salvar uma foto do aparelho e reabrir; confirmar persistência sem internet.
10. Fazer backup, restaurar e conferir sessões, metas, academia e foto.
11. Copiar CSV, gerar PDF e tentar importar o mesmo CSV duas vezes; não duplicar.
12. Ligar texto ampliado e alto contraste; testar dispositivo pequeno e leitor de tela.
13. Validar com as cinco personas e comparar prints com as quatro pranchas.

## O que ainda NÃO está validado / não foi entregue integralmente
- Compatibilidade integral com todos os CSVs Hevy/Strong: depende de arquivos reais
  e correspondência de exercícios entre catálogos.
- Compartilhamento de recorde como **imagem** e integração com redes sociais.
- Detecção de platô de 4 semanas, gamificação completa, sequência semanal e conquistas
  por níveis além das metas e celebrações de PR.
- Modelo Pro real (cobrança, lojas, assinatura), nuvem, contas, multi-aluno e smartwatch.
- Mapeamento visual correto de todas as ilustrações por exercício; QA de acessibilidade.
- Verificação em iPhone/Android reais, compilação final e resultado do GitHub Pages.

## Observações de segurança e integridade
- Fotos são inseridas como cópias comprimidas no JSON local; há limites de tamanho.
- Antes de uma importação CSV real, exporte um backup JSON.
- O importador ignora exercícios sem correspondência, explicitando quantas linhas
  não foram importadas; formatos externos podem ter colunas diferentes.
- Dados da prévia web permanecem no armazenamento local do navegador e podem ser
  perdidos ao apagar os dados do site. Não usar como armazenamento definitivo.

## Link da prévia, sujeito ao sucesso do workflow
https://caiomoreirab.github.io/app-gym-records/review/

Workflow: `.github/workflows/feature-web-preview.yml`.
A presença deste endereço **não comprova** que o último deploy foi concluído.
