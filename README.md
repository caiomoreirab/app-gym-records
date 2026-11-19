# GymRecords — v0.8.0+16 | Refatoração da base visual (entrega incremental)

Aplicativo Flutter de validação do GymRecords. Esta versão parte do build `0.7.0+15`, mantendo onboarding, registros, métricas de peso/repetições/tempo e as telas Pro existentes.

## O que foi implementado nesta entrega

- **Execução / Músculos:** os 32 arquivos de vista muscular de cada perfil foram substituídos por renders anatômicos exclusivos da vista de execução (96 arquivos no total). As vistas musculares agora mostram o corpo de frente e de costas com destaques por região e não uma foto de exercício com filtro azul.
- **Cardio:** substituição dos 9 arquivos de ativação muscular de cada perfil (27 imagens) por vistas anatômicas independentes. O perfil neutro usa manequim sem rosto nessas vistas.
- **Grupo Cardio:** novos cards com corredores de aparência masculina, feminina e neutra, sem moldura interna.
- **Grupos musculares:** recorte do contorno/faixa superior embutidos nas 21 imagens de categoria, mantendo a borda real do Flutter.
- **Confetes:** dispersão elevada para a parte superior do card de conquista nas modalidades de musculação e Cardio.
- **Fallback Cardio:** se faltar uma imagem de músculos, mostra estado de revisão, jamais a própria imagem de execução disfarçada de ativação.
- **Qualidade:** scripts de auditoria, CSV por exercício/perfil e testes adicionais de regressão visual.

### Pendências importantes (não confundir com bugs resolvidos)

**Ilustrações específicas de execução ainda NÃO foram concluídas.** O catálogo possui 124 exercícios, mas apenas **31 imagens-base de execução realmente referenciadas por perfil** e **120 exercícios compartilham a imagem de execução com algum outro**. Os casos `goblet_squat`, `barbell_squat`, `front_squat` etc. ainda usam a arte da máquina `hack_squat`, portanto **ainda precisam de renders individuais da pose/equipamento correto**. Não inserimos desenhos provisórios de baixa qualidade como se fossem fotografias 3D finalizadas.

A execução de algumas atividades de Cardio no perfil neutro ainda usa a arte do acervo antigo, enquanto a vista anatômica e o card de grupo foram adequados para manequim neutro. A auditoria não afirma validação biomecânica individual dos 124 exercícios. A ativação muscular é esquemática e não uma medição fisiológica.

Não foi possível compilar `flutter analyze`, `flutter test` nem gerar APK nesta máquina de geração (Flutter SDK ausente). Os scripts de verificação de arquivos e o ZIP foram conferidos; **confirme o build no seu emulador**.

## Como rodar no Windows

Dentro da pasta `gymrecords`, com o emulador `emulator-5554` aberto:

```powershell
$androidSdkPath = "$env:LOCALAPPDATA\Android\Sdk"
$env:ANDROID_SDK_ROOT = $androidSdkPath
$env:ANDROID_HOME = $androidSdkPath
& "$androidSdkPath\platform-tools\adb.exe" devices
flutter clean
flutter pub get
flutter analyze
flutter test
flutter run -d emulator-5554
```

A versão em Configurações deve exibir `0.8.0 • Base visual`.

## Auditoria reproduzível

`python tools/audit_visuals.py` gera `tools/visual_audit.csv` (372 linhas, 124 exercícios × 3 perfis), e `tools/visual_audit_summary.json`. `python tools/build_anatomical_assets.py` regenera as 123 artes anatômicas a partir de `tools/anatomy_atlas_source.png` (usa Pillow, NumPy e OpenCV em computador de desenvolvimento; não é executado pelo app).

Esta v0.8.0 é uma **etapa entregue da refatoração**, não uma declaração de conclusão do catálogo visual.
