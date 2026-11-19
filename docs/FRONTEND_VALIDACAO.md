# Checklist de validação — Front-end 0.3.0

## Onboarding

- [ ] Splash exibe a identidade oficial do GymRecords e segue automaticamente.
- [ ] Primeira etapa solicita nome/apelido.
- [ ] Nome vazio ou apenas com espaços não habilita o botão.
- [ ] Teclado não causa overflow.
- [ ] Segunda etapa usa o nome no título.
- [ ] As três preferências são descritas como estilos de ilustração, não gênero do usuário.
- [ ] Apenas uma preferência pode ficar selecionada.
- [ ] A escolha persiste após fechar e abrir o app.
- [ ] Depois de concluído, o onboarding não reaparece.

## Home e catálogo

- [ ] Nome aparece no topo da Home.
- [ ] Imagens dos grupos mudam com a preferência visual.
- [ ] Busca de aparelho filtra corretamente a lista.
- [ ] Lista e catálogo usam a versão visual selecionada.
- [ ] Tela do aparelho também usa a mesma preferência.
- [ ] Assets ausentes têm fallback e não quebram a UI.

## Configurações

- [ ] Nome pode ser alterado.
- [ ] Preferência visual pode ser alterada.
- [ ] Mudança visual reflete imediatamente ao voltar às telas anteriores.
- [ ] Unidade e incremento continuam funcionais.

## Recordes

- [ ] Salvar carga maior abre a conquista.
- [ ] Mensagem usa o nome do usuário e menciona GymRecords.
- [ ] Copiar link/texto funciona como mock de compartilhamento.

## Comandos técnicos

```powershell
flutter analyze
flutter test
```
