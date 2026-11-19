# GymRecords — preparação para lançamento Android (v0.9)

Status: **pré-lançamento / validação**. O código está no GitHub, mas não representa uma publicação aprovada pela Google Play.

## 1. O que já existe

- Aplicativo Flutter Android; APK debug gerado por GitHub Actions.
- Banco SQLite local `gymrecords_v1.db` para histórico e exercícios personalizados.
- Prévia Flutter Web com armazenamento local do navegador (separado do celular).
- Backup manual completo dos registros por JSON (copiar e restaurar).
- Consentimento para estatísticas opcional e **desativado por padrão**.
- Integração Firebase opcional via variáveis de compilação, sem projeto configurado por padrão.
- Workflow manual `.github/workflows/android-release.yml` para AAB assinado.

## 2. Verificações obrigatórias antes de disponibilizar ao público

1. Confirmar jobs verdes em **Actions**: análise, testes, APK debug e Web.
2. Instalar o APK em aparelho Android real, registrar musculação e Cardio, forçar parada do app, reiniciar e confirmar que os registros persistiram.
3. Ativar modo avião e verificar navegação, registro, histórico, gráficos, configurações e exportação de PDF.
4. Criar exercício personalizado, renomear/anotar, fechar o app e confirmar que tudo permaneceu.
5. Gerar backup JSON, restaurar e testar se dados inválidos não substituem o histórico.
6. Conferir imagens por exercício e por perfil. **O catálogo de 124 exercícios ainda reutiliza 31 imagens-base de execução por perfil** — essa pendência visual não foi resolvida na v0.9.
7. Revisar privacidade e endereço público `https://caiomoreirab.github.io/app-gym-records/privacy.html`. Antes de publicar, disponibilizar um canal **privativo de contato** do desenvolvedor.
8. Revisar nome comercial, imagens da loja, ícone, screenshots, classificação indicativa, dados de segurança, público-alvo e requisitos atuais da Google Play.
9. Confirmar o ID `com.cmvis.gymrecords` e aumentar o `versionCode` a cada upload. Nunca reutilizar um código de versão na Play.
10. Gerar AAB **assinado com uma chave de upload própria**. Não publicar APK debug e nunca publicar uma chave privada no GitHub.

## 3. Assinatura de upload e Secrets no GitHub

Crie sua **própria** chave de upload em um computador de confiança, usando o `keytool` do Java, por exemplo:

```powershell
keytool -genkeypair -v -keystore "$env:USERPROFILE\gymrecords-upload.jks" -alias gymrecords-upload -keyalg RSA -keysize 4096 -validity 10000
```

Mantenha a senha, o alias e o arquivo `.jks` fora do repositório e faça cópia segura da chave.

Em **GitHub → Settings → Secrets and variables → Actions → Repository secrets**, configure:

- `GYM_UPLOAD_KEYSTORE_B64`: conteúdo Base64 **inteiro** do seu `.jks`.
- `GYM_UPLOAD_STORE_PASSWORD`: senha do arquivo.
- `GYM_UPLOAD_KEY_PASSWORD`: senha do alias.
- `GYM_UPLOAD_KEY_ALIAS`: `gymrecords-upload` (ou o alias escolhido).

Para transformar o arquivo em Base64 no Windows, **sem revelar o resultado no chat**:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("$env:USERPROFILE\gymrecords-upload.jks")) | Set-Clipboard
```

Depois vá para **Actions → GymRecords - AAB de publicação (assinado) → Run workflow**.

Baixe o artefato `GymRecords-release-signed-...` e envie o arquivo `app-release.aab` para uma faixa de testes da Play Console.

## 4. Métricas opcionais no Firebase

O app **não exige Firebase**. Sem variáveis configuradas, ele não inicializa Firebase nem envia eventos.

Quando decidir ativar Analytics, crie seu próprio projeto no Firebase e registre os aplicativos Android e Web. Em **Repository variables** configure:

- `GYM_FIREBASE_API_KEY`
- `GYM_FIREBASE_PROJECT_ID`
- `GYM_FIREBASE_SENDER_ID`
- `GYM_FIREBASE_ANDROID_APP_ID`
- `GYM_FIREBASE_WEB_APP_ID`
- `GYM_FIREBASE_WEB_MEASUREMENT_ID`

Os workflows passam essas configurações públicas ao Flutter por `--dart-define`; nenhuma senha administrativa de Firebase deve ser embutida no aplicativo. Confira que o projeto pertence a você. A coleta só é habilitada pelo consentimento nas configurações do GymRecords. É necessário também atualizar a política de privacidade e as declarações da Google Play antes de ativar a coleta.

Eventos definidos: `app_opened`, `onboarding_completed`, `exercise_opened`, `custom_exercise_created`, `strength_record_created` e `cardio_record_created`. Os parâmetros enviados são somente categorias e IDs de atividade, não nomes, anotações ou números de treino. No Firebase Analytics, registre dimensões personalizadas se quiser relatórios por categoria. Não há painel administrativo próprio nem sincronização dos treinos.

## 5. iOS

O projeto no repositório ainda **não contém a pasta iOS**. A publicação na App Store exigirá gerar essa plataforma no Flutter, testar num Mac, configurar assinatura Apple, revisar permissões e enviar via App Store Connect. O workflow de AAB é **somente Android**.

## 6. Dados dos usuários

O armazenamento é privado ao app. A atualização por APK/AAB **com a mesma assinatura** preserva os dados normalmente; desinstalação/limpeza pode apagá-los. Para migração entre aparelhos, use backup manual. A chave de debug usada nos APKs de CI não é a mesma chave de release — para testar uma build de loja, use instalação separada ou exporte dados antes de substituir um APK assinado de modo diferente.
