# GymRecords — Auditoria de imagens (21/11/2026)

**Branch:** `fix/imagens-catalogo-auditoria-20261121` — `main` preservada.
**Estado:** auditoria automatizada implementada, correções de enquadramento e
primeiras substituições executadas. **Não aprovado integralmente para publicação.**

## Inventário fundamentado no catálogo
- **124 exercícios** no catálogo `buildExerciseCatalog()`.
- **3 perfis**: masculine, feminine e neutral.
- Originalmente, **32 arquivos-base de execução por perfil** (96 arquivos)
  eram compartilhados pelos 124 exercícios.
- **32 arquivos-base anatômicos por perfil** (96 arquivos).
- **7 imagens de grupo muscular por perfil**; 9 modalidades de cardio por
  perfil para execução e ativação, além das imagens gerais e onboarding.
- 39 exercícios tinham um `visualAssetId` declarado explicitamente.
- **Prancha de antebraços:** adicionadas três imagens específicas geradas
  para os três perfis; agora há **33 execuções por perfil**.
- Total de relações a verificar no catálogo:
  124 exercícios × 3 perfis × 2 visões = **744 relações**.

## Problemas confirmados
1. A miniatura do catálogo histórico utilizava um pager capaz de alternar
   para anatomia dentro da própria lista. Corrigido para execução fixa.
2. Listas compactas de 54×54 e 82×82, com recorte `cover`, ocultavam
   partes de imagens originalmente retangulares. Agora são usadas miniaturas
   maiores em **4:3**, `BoxFit.contain` e fundo neutro; no detalhe o
   enquadramento também foi ampliado e passou a `contain`.
3. `abs_plank` não representava uma prancha correta nos três perfis.
   `plank` passa a usar `abs_forearm_plank.webp`, criado para cada perfil.
   A imagem de anatomia não foi substituída pela execução.
4. As associações `barbell_squat → hack_squat`,
   `stiff_leg_deadlift → lying_leg_curl` e
   `barbell_bench_press → chest_0` representam equipamentos/movimentos
   diferentes. Não devem ser mostradas como imagens específicas.
5. Foram sinalizados **40 exercícios** cujas ilustrações compartilhadas
   induziriam a erro. Até que imagens específicas estejam prontas,
   o aplicativo mostra um marcador neutro em vez de ensinar um movimento
   incorreto. O registro de séries e o histórico permanecem inalterados.
6. A auditoria de arquivos detecta também imagens de ativação de
   `stair_climber` e `stationary_bike` com bytes repetidos em cada perfil,
   para inspeção visual/manual.

## O que é verificado automaticamente
- Todos os arquivos WEBP no banco: abertura, integridade, resolução e dimensões.
- Pares execução/anatomia da biblioteca; grupos musculares e cardio.
- Inventário CSV individual por exercício/perfil/visão e situação.
- Identificação de arquivos com bytes repetidos, resoluções atípicas e
  referências ausentes.
- Seis pranchas de contato (execução e músculos × três perfis).
- Testes Flutter: 4:3, ausência de carrossel/anatomia na lista,
  proteção contra imagem errada e manutenção do estilo selecionado.

Ferramenta: `python3 tools/audit_visual_assets.py`.
Workflow: `.github/workflows/visual-assets-audit.yml`.
Artefato do GitHub Actions: `GymRecords-imagens-auditoria`, contendo
`audit-summary.json`, `exercise-image-mapping.csv` e as seis pranchas.

## Ressalva de qualidade de conteúdo
**A existência do arquivo NÃO comprova que o movimento está anatomicamente
correto.** O catálogo possui ilustrações genéricas reaproveitadas e ainda
depende de validação humana dos 124 movimentos × três perfis. O relatório
torna essas lacunas visíveis em vez de contabilizá-las como imagens concluídas.

Para fechar o banco definitivamente, substituir os 40 desenhos sinalizados,
conferir as ilustrações compartilhadas restantes, validar músculos
primários/secundários com referência técnica e testar as imagens finais em
Android/iOS reais. Não se deve liberar a `main` até esse aceite.
