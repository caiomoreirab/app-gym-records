# GymRecords — Branch de validação de UX (v0.10.0+20)

Esta branch **não é o lançamento** nem modifica a `main`. É uma versão de avaliação com dados reais armazenados localmente. Pull request: [#3](https://github.com/caiomoreirab/app-gym-records/pull/3).

## Como visualizar

- **Produção de demonstração (main):** https://caiomoreirab.github.io/app-gym-records/
- **Candidata para validar:** https://caiomoreirab.github.io/app-gym-records/preview/treinos-v1/
- Ambas são Flutter Web. Cada URL usa o armazenamento da origem; **o caminho /preview/ não garante isolamento de armazenamento no mesmo domínio**. Por segurança, exporte seu backup do app atual antes de testar. O esquema novo é compatível com backup v1, mas um downgrade posterior pode não ler o esquema v2.
- **APK de testes:** GitHub Actions → GymRecords - Testes e APK Android, escolha a execução verde da branch.
- **iPhone:** use o workflow IPA iOS, depois assine pelo Sideloadly. O IPA da branch ainda exige teste no iPhone físico.

## Implementado e funcional

- Cada gravação é uma **série** com carga, repetições, timestamp, sessão diária, aquecimento e RPE opcional.
- Repetições agora estão disponíveis em aparelhos de musculação classificados como máquina.
- Pré-preenchimento com última série, ação **Repetir última série**, registro de várias séries no mesmo dia.
- **Editar, excluir, desfazer**, histórico separado por dia e PRs (maior carga, faixa 8–12 e 1RM estimado Epley). Aquecimentos são excluídos dos PRs.
- Home com **Treino de hoje** e **Favoritos** persistentes. Resumo simples de sessão.
- **Exportação CSV/PDF** com série, carga e repetições; CSV inclui atributos completos. Exportação básica liberada na Free.
- Configuração de fonte ampliada (20%), Pro explicitamente em prévia sem cobrança e matriz simplificada Free × Pro.
- Dados persistem no SQLite (Android/iOS) e no armazenamento do navegador (Web). **Nenhum backend novo**.
- Backup JSON esquema **v2**, com importação compatível com backups v1 e preservação de registros legados.

## Em modo conceito — NÃO são funcionalidades de produção

Configurações → Laboratório: seleção ilustrativa de academias, foto do aparelho, importação Hevy/Strong, cartão para Stories, conquistas e nuvem. O **resumo semanal** usa dados locais e o **temporizador na tela** funciona; o restante abre descrições dos custos/riscos. Não existe sincronização, pagamento ou backend.

### Limites conhecidos

- Uma sessão é agrupada **por dia**; dois treinos independentes no mesmo dia ainda não se separam.
- O banco de dados continua armazenando snapshots JSON numa tabela SQLite. Normalização e sincronização serão uma evolução posterior.
- A Home atual preserva alguns layouts antigos; a substituição integral pelas 24 telas do HTML anterior ainda não foi concluída. O que está funcional foi priorizado em torno do registro.
- As ilustrações compartilhadas não foram refeitas nesta implementação.
- O pacote Web divide a mesma origem GitHub Pages entre `main` e `/preview/`; para testar sem risco de dados misturados, abra a prévia em um **perfil de navegador separado**. O armazenamento local usado pelo Flutter pode ser comum aos caminhos.
- O botão de exportação PDF depende do compartilhamento do navegador/sistema; conferir no aparelho.
- A rota /preview/ e o runner de GitHub Actions só devem ser considerados publicados quando o job de deployment estiver verde.

## Testes recomendados para validar

1. **Cenário 100 × 3:** abrir Supino reto com barra, registrar 100 kg e 3 repetições uma única vez; conferir hoje, histórico e CSV.
2. **Repetição:** abrir exercício e tocar Repetir última série; conferir uma única nova entrada, no máximo dois toques a partir de uma área de acesso rápido.
3. **Edição:** alterar a segunda série para 90 kg × 8; reabrir e verificar persistência.
4. **Desfazer:** excluir uma série, tocar DESFAZER e confirmar retorno.
5. **Aquecimento:** registrar 105 kg × 2 como aquecimento e verificar que não vira o maior PR.
6. **Sessão:** revisar volume e número de séries no Treino de hoje; abrir outro exercício e verificar agrupamento por dia.
7. **Backup:** fazer backup antes, importar uma cópia, reiniciar e conferir favoritos e séries.
8. **Free × Pro:** testar exportação básica no menu Configurações com Pro desligado; ler a explicação de preço como hipótese.
9. **Acessibilidade:** ativar Texto ampliado e usar com uma mão, inclusive no iPhone 12.
10. **Offline:** após primeira carga Web (cache não garantido) e no app nativo, desligar internet e validar fluxo.

## Critérios para merge

Análise Dart + testes + APK Android + compilação Web sem erros; teste de persistência em celular; aceitação do usuário. Nenhum merge automático.
