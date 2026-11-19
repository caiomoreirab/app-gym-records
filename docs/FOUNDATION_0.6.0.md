# GymRecords Foundation 0.6.0

## Escopo implementado

### Musculação

- 124 exercícios canônicos.
- 7 grupos visuais da Home preservados: Peito, Costas, Pernas, Ombros, Bíceps, Tríceps e Abdômen/Core.
- Tipos de equipamento: máquina, barra, halteres, cabo/polia, Smith, peso corporal, kettlebell, elástico e outro.
- Pernas e outros grupos podem usar subgrupos para filtrar sem criar novos cards na Home.
- Busca considera nome localizado, grupo, equipamento e aliases.
- Exercício personalizado preservado.

### Cardio

Atividades iniciais:

1. Corrida ao ar livre
2. Esteira
3. Caminhada
4. Ciclismo
5. Bicicleta ergométrica
6. Elíptico
7. Escada / simulador de escada
8. Remo ergométrico
9. Corda

Campos comuns:
- tempo;
- distância quando aplicável;
- pace ou velocidade média calculados;
- frequência cardíaca opcional;
- calorias opcionais;
- observações.

Campos específicos:
- inclinação na esteira;
- resistência/nível em bike, elíptico, escada e remo;
- remo usa pace por 500 m.

### Idiomas

- `pt-BR`
- `en-US`
- opção de seguir o idioma do sistema

Os IDs persistentes são neutros ao idioma. Nome do exercício, grupo e equipamento são resolvidos na camada de apresentação.

### Branding

- novo launcher icon Android;
- adaptive icon Android;
- splash nativa navy;
- GIF fornecido pelo usuário em `assets/branding/splash_intro.gif`;
- animação de texto leve feita em Flutter após o GIF começar.

## Assets de exercícios

Os 26 exercícios que já possuíam ilustrações dedicadas continuam usando suas versões masculina/feminina/neutra.

Novas variações do catálogo não recebem imagens incorretas de outro equipamento: quando não há asset dedicado, o app usa fallback visual por grupo muscular para exercícios livres ou fallback genérico para equipamentos. Isso evita imagem quebrada ou equipamento falso. Uma futura etapa pode gerar ilustrações dedicadas para os itens mais utilizados com base em telemetria/beta.

## Próximo marco recomendado

Banco local/repositórios para persistir `StrengthRecord` e `CardioRecord`, mantendo IDs canônicos desta Foundation.
