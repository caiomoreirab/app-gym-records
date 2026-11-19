# GymRecords Front-end 0.5.0 — visual azul + experiência Pro

Esta versão mantém o fluxo funcional da 0.4.0 e aplica uma atualização visual global inspirada no protótipo azul/charcoal aprovado.

## Fluxo preservado

Splash → Nome → Preferência visual → Home → Grupo/Busca → Exercício → Registro/Histórico.

A busca global, filtros, acesso rápido, grupos musculares, catálogo, criação de aparelho e configurações continuam no mesmo lugar.

## Atualização visual

- Fundo quase preto `#030507`.
- Cards charcoal `#101417`.
- Destaque primário azul elétrico `#10B7F4`.
- Bordas `#26343E` e superfícies selecionadas azul-escuro.
- Botões principais, estados selecionados, recordes e indicadores atualizados para azul.
- Mascote normal permanece como identidade do app, com tratamento de matiz azul na interface.
- Novo asset `assets/branding/pro_mascot.webp` usado somente em áreas Pro.

## Pro implementado no front

1. PR Radar.
2. Próximo alvo sugerido.
3. Detector de possível platô (só aparece quando a regra identifica estagnação).
4. GymRecords IQ.
5. Mapa/evolução por grupo muscular.
6. Hall de recordes avançado: carga, repetições, 1RM estimado e maior volume.
7. Resumo semanal.
8. Exercícios prontos para PR.
9. Gráfico avançado de evolução.
10. Exportação CSV/PDF em Configurações (fluxo visual; arquivo real depende do banco local).

Não foram adicionados: passaporte de máquinas, cards premium de compartilhamento, análises selecionáveis por período e backup em nuvem.

## Encaixe do Pro

- Home: um único card discreto entre Acesso rápido e Grupos musculares.
- Exercício: um único card GymRecords IQ ao final do histórico, abrindo a análise completa do exercício.
- Evolução: única área geral nova, aberta pelo card Pro da Home.
- Configurações: status Pro, chave de prévia para validação e exportação CSV/PDF.

A chave de Pro é apenas uma simulação de front-end. A cobrança real não foi implementada.
