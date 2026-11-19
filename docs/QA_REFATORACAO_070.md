# GymRecords 0.7.0 — relatório de revisão técnica

## Escopo

Este pacote mantém o fluxo existente de onboarding, home, grupos, exercícios, cardio, histórico e Pro.

### Visualização e assets

- Um componente único `TwoViewImagePager` substitui os dois pagers baseados em `PageView`. O gesto horizontal muda o modo após o fim do swipe e uma transição por opacidade, evitando a imagem paralisada com dois quadros lado a lado.
- Resolução de assets pelo perfil ativo (`masculine`, `feminine`, `neutral`), sem fallback para outra pasta de perfil.
- Arquivos de grupo com faixa superior embutida foram recortados.
- Card principal de Cardio recriado em três estilos anatômicos, sem borda embutida.
- Imagens secundárias de exercícios tratadas com fundo neutro e preservação de regiões azuis. Nas nove modalidades de Cardio, a segunda vista possui realce ilustrativo sobre a área corporal, em vez de luz borrada no fundo.
- Tela de recorde com confetes desenhados **depois** do cartão, sobrepostos e sem bloquear botões.

**Limitação de arte:** 124 exercícios e 3 perfis estão no catálogo, mas somente 32 arquivos-base de execução e 32 de músculos por perfil estão no acervo atual. Isso implica reutilização de família em exercícios sem arte individual. Além disso, algumas poses herdadas podem não representar exatamente o movimento nomeado. Não se deve descrever a revisão como ilustração exclusiva de cada exercício. A arte neutra do Cardio detalhado continua baseada em versões técnicas dessaturadas de poses existentes, enquanto o card de grupo novo usa um manequim anatômico próprio. A produção e conferência manual de imagens únicas continua necessária antes de publicar.

### Histórico e registros

- A tela de exercícios corporais aceita repetições isoladas, tempo isolado, ambos, e permite mostrar carga adicional opcional.
- Conquistas podem ter métrica de peso, repetição ou tempo, usando o indicador que de fato melhorou.
- Histórico e recordes exibem a métrica registrada; o cardio mantém distância, tempo, pace e velocidade.

### Pro e relatórios

- Hub Pro com navegação para PR Radar, relatórios, comparativo de grupos, Hall de Recordes e exportação.
- Relatórios com filtros por grupo, período e métrica. Totais e comparações calculados a partir do histórico em memória, sem percentuais ou quantidade de treinos hard-coded.
- Relatório de Cardio com filtro por modalidade, período e métrica.
- CSV copiável e geração/compartilhamento de PDF por `pdf`/`printing` (novas dependências).
- O PR Radar apresenta **índice exploratório**, não uma probabilidade validada cientificamente.
- Pro é uma **prévia funcional**: faturamento e sincronização reais seguem fora de escopo.

## Validação

Ferramentas de verificação incluídas:

```powershell
python tools/verify_visual_assets.py
.\tools\verify_flutter.ps1
```

A primeira é uma verificação estática de catálogo, arquivos e mapeamento explicitamente definido. A segunda executa `flutter pub get`, `flutter analyze`, `flutter test`, e `flutter build apk --debug` no computador com Flutter instalado.

**Este ambiente de edição não possui o Flutter SDK. Não foi possível compilar nem executar o APK no Pixel 8a aqui.** Os arquivos foram checados estruturalmente, mas testes de compilação e revisão visual no emulador são requisitos para aprovar a versão.

## Checklist manual no Pixel 8a

- [ ] Configurações mostram **Versão de validação 0.7.0 • Refactor**.
- [ ] Trocar entre feminino, masculino e neutro em Peito, Costas, Core e Cardio.
- [ ] Abrir tríceps na polia e alternar Execução ↔ Músculos por swipe e toque: nunca ver duas metades lado a lado.
- [ ] Verificar enquadramento, músculos azuis e ausência de linhas/bordas duplicadas.
- [ ] Registrar novo recorde de carga e observar confetes sobre a tela de conquista.
- [ ] Registrar apenas 12 repetições de abdominal; depois somente 45 s de prancha; depois reps + tempo.
- [ ] Abrir Radar, evolução por grupo e período, hall, relatório Cardio e exportação CSV/PDF.
- [ ] Executar `flutter analyze` e `flutter test` sem falhas.
