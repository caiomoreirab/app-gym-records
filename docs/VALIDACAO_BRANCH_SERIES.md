# GymRecords — validação da branch de funcionalidades

Branch: `feat/registro-sessoes-validacao`. **Não mesclar na main antes dos testes.**

## O que está implementado nesta candidata
- Registro por série, agrupamento por dia, repetição da última série, edição, exclusão/desfazer.
- Aquecimento separado dos recordes, maior peso, faixa 8–12 e 1RM estimado.
- Favoritos e lista de exercícios registrados hoje.
- CSV básico acessível sem ativar a prévia Pro; PDF completo continua demonstrativo Pro.
- Ficha estruturada do aparelho: banco, encosto, pegada e outra regulagem, salva no backup local.
- Resumo semanal offline: dias ativos, exercícios e séries de trabalho.
- Temporizador de descanso na tela (60, 90, 120 s), sem notificação em segundo plano.

## Roteiro de validação manual
1. Com perfil novo, registrar supino 80 kg × 3; fechar e reabrir; confirmar histórico e CSV.
2. Registrar 80 kg × 10; verificar duas séries distintas e cálculo de recorde por faixa.
3. Marcar 120 kg × 5 como aquecimento; verificar que não altera o recorde de trabalho.
4. Editar a primeira série, excluir a segunda e usar Desfazer; reabrir e verificar persistência.
5. Favoritar o exercício, conferir atalho na Home; registrar e conferir 'Treino de hoje'.
6. Anotar banco posição 4, encosto 2 e pegada; reabrir e conferir ficha.
7. Gerar backup JSON, restaurar e verificar séries, favoritos e regulagens.
8. Confirmar resumo semanal de dias distintos e séries sem aquecimento.
9. Iniciar temporizador de 60s, parar e iniciar 90s; verificar comportamento ao navegar.
10. Desativar a prévia Pro; conferir que copiar CSV segue disponível, e PDF completo aparece bloqueado.
11. Testar com texto ampliado do sistema, leitor de tela e toque com uma mão no celular.
12. Testar dados antigos v1 e verificar que nenhuma entrada histórica desapareceu.

## Pendências antes de considerar o briefing inteiro implementado
- Sessões de treino iniciadas/encerradas explicitamente (hoje são agrupadas por dia).
- Fotos de aparelho; múltiplas academias; importação CSV/Hevy/Strong.
- Gamificação completa, compartilhamento de imagem, detecção de platô, acessibilidade auditada.
- Política de assinatura real, sincronização e contas (fora do lançamento offline acordado).
- Revisão visual de TODAS as ilustrações e testes em Android/iOS reais.
- Confirmar resultado da compilação Flutter, testes automatizados e deploy GitHub Pages.

## Deploy esperado
Workflow: `.github/workflows/feature-web-preview.yml`.
Endereço pretendido: https://caiomoreirab.github.io/app-gym-records/review/

**A existência desta configuração não confirma deploy bem-sucedido.**
