# GymRecords no iPhone 12 (Windows + Sideloadly)

A v0.9.1 do GymRecords usa Flutter. Para testar o aplicativo **nativo** no iPhone 12, o GitHub Actions executa uma compilação em macOS e disponibiliza um **IPA sem assinatura**. Você **não** precisa possuir um Mac; porém, **precisa assinar o IPA com sua própria Conta Apple** antes de instalá-lo no iPhone usando o Sideloadly para Windows.

## Compilar no GitHub

1. Acesse [Actions](https://github.com/caiomoreirab/app-gym-records/actions/workflows/ios-unsigned.yml).
2. Clique em **Run workflow**, selecione a branch `main` e execute.
3. Abra a execução concluída com o símbolo verde.
4. Em **Artifacts**, baixe **GymRecords-iOS-IPA-unsigned-…**. O download é um ZIP do GitHub que contém o arquivo **GymRecords-unsigned.ipa**.
5. Extraia o ZIP. Não tente abrir o arquivo IPA no Android Studio nem instalá-lo diretamente no iPhone.

O identificador iOS usado nesta compilação é **com.cmvis.gymrecords**. A versão para Android permanece independente; não há sincronização entre Android, iPhone e Web.

## Instalar pelo Windows

1. Instale [Sideloadly](https://sideloadly.io/) **somente** do site oficial.
2. Conecte o iPhone 12 ao Windows com um cabo USB funcional; desbloqueie e toque em **Confiar neste computador** se solicitado.
3. Abra o Sideloadly. Verifique se ele reconhece o iPhone; se não reconhecer, consulte o FAQ oficial sobre os componentes Apple Mobile Device Support / iTunes.
4. Arraste **GymRecords-unsigned.ipa** para a janela do Sideloadly, ou selecione o arquivo manualmente.
5. Informe **sua própria Conta Apple diretamente no Sideloadly**, escolha a opção Apple ID Sideload e inicie a instalação. **Nunca compartilhe senha ou código de verificação no GitHub ou no ChatGPT**.
6. Se o iPhone solicitar, habilite **Modo de Desenvolvedor** em Ajustes → Privacidade e Segurança (iOS 16+) e reinicie o dispositivo.
7. Se aparecer aviso de desenvolvedor não confiável, consulte Ajustes → Geral → VPN e Gerenciamento de Dispositivo e autorize o perfil relacionado à sua Conta Apple.
8. Abra o GymRecords na Tela de Início e teste cadastro, musculação, Cardio, histórico e backup offline.

### Restrições

- Uma Conta Apple gratuita geralmente permite executar o app assinado por **até 7 dias** antes de renovar a assinatura.
- **O IPA não vem assinado**: não pode ser instalado simplesmente tocando no arquivo no Safari ou Arquivos.
- O build iOS depende dos plugins Flutter e do Xcode no macOS. A compilação verde valida a geração do IPA, **não a instalação real no seu iPhone**; a assinatura e a execução no hardware precisam ser validadas por você.
- As compilações do GitHub usam minutos de runners macOS, por isso o job de IPA é executado manualmente após o merge.
- Dados locais ficam no próprio iPhone (SQLite). A instalação de outra versão assinada com identidade diferente pode exigir remover a anterior, apagando os dados. **Faça backup antes de reinstalar**.
- O arquivo gerado é para desenvolvimento e avaliação, não é um artefato assinado para App Store/TestFlight.

## Repetir o teste

Após alterar o código Flutter, inicie manualmente outro workflow, baixe o novo IPA, e assine/instale novamente via Sideloadly. Para continuar os testes sem interrupções, renove a assinatura no prazo exigido pela Conta Apple. Eventuais problemas de instalação devem ser investigados com o log do Sideloadly.

Consulte também [Release Android](RELEASE_ANDROID.md) e [Auditoria v0.9.1](AUDITORIA_V091.md).
