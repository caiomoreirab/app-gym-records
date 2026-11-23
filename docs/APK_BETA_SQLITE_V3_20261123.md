# GymRecords Android Beta 0.10.1 (SQLite v3)

Data: 23/11/2026. Branch: feat/fase1-registro-confiavel-classico.
Build: APK debug assinado pela chave de depuração do GitHub Actions,
para teste em celular Android; não é o AAB assinado para a Play Store.
Package ID preservado: com.cmvis.gymrecords.
Min SDK 24: Android 7.0 ou superior.

## Conteúdo disponível offline

- Catálogo local de 124 exercícios, grupos musculares e imagens do pacote.
- Iniciar treino -> selecionar vários grupos ou pular -> escolher vários exercícios
  ou iniciar vazio -> acompanhar e registrar séries.
- Modificar grupos durante a sessão sem apagar séries e cardio já salvos.
- Séries, histórico, recordes, cardio, conclusão/compartilhamento e exportação.
- Preferências locais de nome, aparência, idioma, unidade e peso corporal.

## Atualização do banco real de produção

- SQLite do próprio app, nome original gymrecords_v1.db preservado.
- Nova versão de esquema 3. A migração cobre SQLite 1->3 e 2->3.
- JSON v1/v2 permanece fonte de verdade e é preservado integralmente
  durante a migração; índices são reconstruídos de forma transacional.
- Tabelas: workout_sessions, session_exercises, workout_sets, cardio_entries,
  session_groups e session_cardio, com índices de sessão.
- cardio_entries.session_id associa cardio gravado à sessão, quando houver.
- Snapshot anterior em user_state_previous, rollback de transação para
  dados inconsistentes, suporte a backups antigos e novos.
- Em Configurações > Dados e privacidade, usar Verificar banco local
  para rodar PRAGMA quick_check, foreign_key_check e comparação das
  contagens SQLite com o snapshot. Verificação somente leitura.
- Não há backend de sincronização. O banco não está dentro do APK como
  banco preenchido: ele é criado/evoluído no armazenamento privado do
  Android ao abrir o app e utilizado offline.

## Instalação segura no Android

1. Se já existe GymRecords, exportar primeiro Salvar arquivo JSON
   em Perfil/Configurações > Dados e privacidade. Guardar fora do aparelho.
2. Baixar o artefato GymRecords-APK-debug na execução
   GymRecords - Testes e APK Android da branch desta versão.
3. Extrair o ZIP: o instalador se chama app-debug.apk.
4. Instalar pelo gerenciador de arquivos Android; autorizar a fonte somente
   se o APK veio do repositório correto.
5. Preferir atualizar por cima sem desinstalar; preserva dados se o ID e a
   assinatura do APK forem compatíveis. Se assinaturas forem diferentes,
   não desinstalar antes de exportar backup; isso apaga SQLite do app.
6. Na primeira abertura a migração do banco antigo ocorre automaticamente.
   Conferir Perfil > Dados e privacidade > Verificar banco local: SQLite v3 íntegro.
7. Prévia web /phase1/ tem armazenamento separado do Android.

## Checklist no celular real

- [ ] Instalar e abrir sem travar; concluir onboarding.
- [ ] Criar treino Peito + Tríceps; escolher 2 exercícios; registrar 2+ séries.
- [ ] Criar outro treino usando Seguir sem escolher grupos.
- [ ] Alterar grupos durante sessão; preservar séries já registradas.
- [ ] Incluir cardio; registrar distância/tempo; conferir resumo.
- [ ] Fechar completamente e reabrir; verificar histórico e progresso.
- [ ] Alternar abas; conferir filtros e buscas.
- [ ] Exportar backup JSON; testar restauração em ambiente sem dados valiosos.
- [ ] Verificar banco local e contagens.
- [ ] Instalar nova versão por cima e confirmar que o histórico segue presente.

Testes automatizados validam formatos, transações e fluxos,
mas não substituem testes no aparelho físico.
Beta de avaliação: não afirmar ausência absoluta de bugs.
