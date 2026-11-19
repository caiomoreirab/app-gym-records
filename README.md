# GymRecords — Flutter (v0.9.0+18)

Aplicativo de acompanhamento de recordes de musculação e Cardio. **A versão principal funciona offline**, com dados privados no dispositivo e sem necessidade de criar uma conta.

## Recursos disponíveis

- Onboarding com nome e escolha de perfil visual.
- Catálogo de 124 exercícios de musculação, nove atividades de Cardio e imagens por perfil.
- Registro de peso, repetições e duração; recordes pessoais e relatórios Pro de prévia.
- **Persistência de dados local:** SQLite no Android/iOS e preferências locais do navegador na prévia Web. Os dados são independentes por aparelho.
- Criação, edição e notas de exercícios personalizados.
- Central de **Dados e privacidade** nas configurações: backup JSON, restauração e consentimento para métricas.
- Eventos anônimos instrumentados e adaptador de Firebase opcional, sem coleta remota até configurar um projeto e o usuário autorizar.
- GitHub Actions: testes, APK Android, prévia Web e geração manual de AAB assinado com Secrets.

## Repositório e builds

- [Testes e APK Android](https://github.com/caiomoreirab/app-gym-records/actions/workflows/android-ci.yml)
- [Prévia Web](https://caiomoreirab.github.io/app-gym-records/)
- [Workflow de AAB assinado](https://github.com/caiomoreirab/app-gym-records/actions/workflows/android-release.yml)
- [Política de privacidade](https://caiomoreirab.github.io/app-gym-records/privacy.html)
- **[Checklist de publicação Android](docs/RELEASE_ANDROID.md)**

O fluxo de publicação não instala automaticamente o app na loja. Para o AAB, é necessário configurar uma **chave de upload própria** e validar os requisitos da Play Console.

## Arquitetura de dados

- `lib/services/local_data_store.dart`: repositório offline; SQLite móvel e fallback de navegador.
- `lib/services/workout_snapshot_codec.dart`: formato versionado para persistência e backup.
- `lib/state/app_controller.dart`: estado de telas, filas de escrita sequenciais e restauração.
- `lib/services/usage_events.dart` e `firebase_usage_sink.dart`: eventos de uso após consentimento.

Na versão de produção, novos usuários começam com histórico vazio. O catálogo de exercícios fica embutido no pacote, de modo que registrar treinos não dependa de servidor.

## Limitações ainda abertas

- **Imagens de execução:** apesar de 124 exercícios, apenas 31 artes-base de execução são referenciadas por perfil; muitas poses ainda precisam de ilustrações específicas.
- **Firebase:** coleta remota somente se o projeto e seus identificadores forem configurados. O painel de métricas é o Firebase Console, não um painel próprio dentro do app.
- **Backup:** JSON manual via área de transferência. Não há sincronização, conta ou recuperação automática após desinstalar.
- **iOS:** a pasta iOS não está versionada. O foco de publicação inicial é Android.
- **Assinatura:** APK debug não substitui AAB de loja assinado e não é apropriado para publicação.

## Desenvolvimento

Com Flutter 3.50.0 e Android SDK:

```powershell
flutter pub get
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter run -d emulator-5554
```

O GitHub Actions usa Flutter 3.50.0. Veja os resultados atuais dos jobs para confirmar a versão.
