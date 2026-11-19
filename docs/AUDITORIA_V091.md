# Auditoria técnica — GymRecords v0.9.1+19

**Escopo:** revisão corretiva da v0.9 interrompida, realizada a partir do commit estável `44f5eba`. Nenhuma alteração de catálogo, ilustrações ou design foi pretendida.

## 1. O que foi verificado

- Permissão de escrita no repositório GitHub e histórico de builds.
- Build Android (APK debug), análise Dart e testes automatizados na `main`.
- Build e deploy da prévia Flutter Web pelo GitHub Actions.
- Estado e persistência do `AppController`.
- Serialização do histórico de musculação, Cardio e exercícios personalizados.
- Falhas de leitura e escrita do banco SQLite.
- Exportação e restauração de backups JSON.
- Consentimento de uso e integração Firebase opcional.
- Fluxos de edição e registro de exercícios e Cardio.
- Estratégia de assinatura do Android e configuração de release.

## 2. Correções desta auditoria

1. **GitHub Pages:** removido o workflow Jekyll concorrente. Somente o workflow Flutter Web deve publicar o site.
2. **Banco ilegível:** bloqueio de sobrescrita automática após falha de leitura, para não salvar um histórico vazio em cima de um banco potencialmente recuperável.
3. **Erro temporário de escrita:** novas tentativas de salvar habilitadas e botão de recuperação em Dados e privacidade.
4. **Confirmação de registros:** telas de musculação e Cardio aguardam conclusão da fila de gravação antes de informar sucesso ou apresentar um novo recorde.
5. **Cliques duplicados:** botão de registrar desabilitado enquanto uma gravação está em curso.
6. **Compatibilidade futura:** exercícios retirados de um catálogo podem ser recuperados como registros personalizados, preservando as séries anteriores; modalidades de Cardio legadas ficam retidas em backups e gravações futuras.
7. **Backups inválidos:** valores numéricos negativos ou dados com formato inválido são rejeitados antes de substituir o estado existente.
8. **Compatibilidade de plataformas:** SQLite restrito às plataformas Android/iOS; a Web e desktops usam armazenamento próprio do dispositivo.
9. **Versionamento:** `0.9.1+19` para diferenciar a compilação auditada.

## 3. Como testar o funcionamento offline

- **Android, instalação nova:** concluir onboarding; registrar 2 exercícios e 2 sessões de Cardio.
- **Persistência:** forçar parada do app (não apenas minimizar), reabri-lo e confirmar que todos os registros, notas e exercícios personalizados continuam presentes.
- **Sem internet:** ativar modo avião e repetir registro, cálculo de PR, gráficos, histórico, configurações e exportação.
- **Backup:** copiar o JSON em Dados e privacidade, guardar fora do app e restaurar; conferir contagem e valores. Nunca publicar o backup no GitHub.
- **Proteção contra corrupção:** os testes automatizados simulam banco ilegível, armazenamento sem espaço e backup com valores inválidos.
- **Android atualizado:** ao instalar outro APK com a **mesma assinatura**, verificar que os dados anteriores permanecem; trocar de assinatura exige desinstalação, que apaga os dados locais.
- **Web:** testar no navegador e lembrar que os dados da prévia são diferentes dos dados do aplicativo Android.

## 4. CI / aprovação

- `.github/workflows/android-ci.yml`: análise Dart, testes de unidade/widget e APK debug, incluindo testes de armazenamento.
- `.github/workflows/web-preview.yml`: gera e publica a prévia Flutter Web no GitHub Pages.
- `.github/workflows/android-release.yml`: gera AAB **somente** após o desenvolvedor configurar uma chave privada nos GitHub Actions Secrets.

A aprovação desses jobs prova compilação e execução dos testes existentes, **não** substitui o ensaio em aparelho Android real nem a revisão da Play Console.

## 5. Pendências para publicação comercial

- Criar e proteger a chave de upload própria; configurar Secrets de assinatura e testar o AAB na Play Console.
- Fornecer um contato privativo válido e revisar a política de privacidade conforme a configuração real de Analytics.
- Verificar formulário de segurança de dados, imagens de loja, classificações etárias, target SDK e requisitos vigentes.
- Firebase só poderá coletar dados se o projeto for cadastrado, identificadores forem disponibilizados na build e houver consentimento do usuário. Sem isso, a coleta permanece desligada.
- Ainda não existe faturamento Pro real; o botão Pro continua sendo uma **prévia de funcionalidades**.
- A plataforma iOS ainda não está adicionada e não foi compilada.
- O catálogo de 124 exercícios ainda reutiliza referências de execução. A auditoria visual original apontou aproximadamente 31 imagens-base por perfil; a correção de todas as poses exige novas artes específicas.

## 6. Decisão

Esta revisão busca tornar a v0.9 estável e protegida contra perda de dados. **Não declaramos a versão pronta para a Play Store** antes dos testes no aparelho, da assinatura de upload, da conferência de privacidade e do preenchimento da Play Console.
