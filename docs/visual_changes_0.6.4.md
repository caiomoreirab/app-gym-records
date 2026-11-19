# GymRecords 0.6.4 — revisão visual e funcional

## Correções desta rodada

- Cardio: pager Execução ↔ Músculos com PageController próprio, swipe horizontal e toque no label/indicador.
- Cardio: overlays do hero não bloqueiam mais o gesto.
- Cardio: card principal usa imagem dedicada de cardio, e não a imagem de Pernas.
- Cardio: 9 execuções específicas por perfil (masculino, feminino e neutro técnico).
- Cardio: tela de novo recorde exibe explicitamente o mascote GymRecords.
- Anatomia: segunda página usa `BoxFit.contain` + centralização para evitar cortes/deslocamento, especialmente no perfil feminino.
- Core/Abdômen: seis famílias visuais distintas para máquina, cabo, crunch, reverso, suspensão e core livre.
- Exercícios de força: fallbacks redistribuídos por ID/equipamento/movimento, reduzindo repetições óbvias.
- Execução e anatomia: nunca usam o mesmo caminho de asset.

## Regra visual

1. Imagem 1 = execução do movimento.
2. Imagem 2 = anatomia/músculo ativado.
3. O estilo selecionado no onboarding controla os dois lados do componente.
4. Fallbacks são por família de movimento, não mais apenas por grupo muscular.
