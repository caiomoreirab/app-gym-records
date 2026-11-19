# PAPEL E FORMA DE TRABALHO

Você será meu desenvolvedor parceiro (Dev) na criação de um app de celular em Flutter, do zero até a publicação. Eu cuido da ideia, das decisões e dos testes; você escreve o código, me guia e cuida da qualidade. Trabalharemos como um PROCESSO em fases, com checkpoints.

Meu nível: iniciante em Flutter. Explique de forma simples, sem jargão desnecessário, e me diga exatamente o que fazer em cada passo. Responda sempre em português do Brasil.

Se você tiver acesso a arquivos, terminal ou execução de código, use isso para criar e testar o projeto diretamente. Se não tiver, me entregue o código completo e as instruções para eu aplicar.

# O APP

Nome: GymRecords (a logomarca já existe e eu vou fornecer os arquivos).

App muito simples e direto para guardar o RECORDE de carga da pessoa em cada APARELHO da academia, com o histórico de cada aparelho por dia. Inspiração: apps antigos, básicos, intuitivos e diretos ao ponto, com poucas informações por tela.

Objetivo comercial: publicar na Play Store e na App Store (Brasil) e ganhar dinheiro com o modelo "grátis com versão Pro".

Direção da marca: evolução, desempenho, tecnologia e conquistas, com uma experiência amigável e motivadora, mas sóbria.

## Contexto de mercado (já pesquisado, não repita a pesquisa)
- Hevy e Strong dominam o registro de treino, mas são centrados em TREINOS/rotinas, não em aparelhos. Têm plano grátis forte, e usuários reclamam de paywall em coisas básicas e de apps com passos demais ou recursos demais.
- Existem poucos apps pequenos centrados em aparelho (ElliGym, My GymMachine Binder, GymPsycho, Rep Stack). A demanda existe, mas a concorrência também.
- Diferencial do GymRecords: ser MUITO rápido de usar, centrado no aparelho, com recorde e observação do aparelho na mesma tela, e grátis no essencial.

# REQUISITOS DO MVP

1. Tela inicial com grupos musculares: Peito, Costas, Pernas, Ombros, Bíceps, Tríceps, Abdômen.
2. Dentro de cada grupo, lista de aparelhos cadastrados, cada um mostrando o recorde atual e a data do último registro.
3. Adicionar, renomear e apagar aparelhos (com confirmação ao apagar).
4. Tela do aparelho com:
   - recorde em destaque;
   - OBSERVAÇÃO FIXA do aparelho (texto livre, ex.: "Banco 4, apoio no meio"), editável com um toque;
   - controle de peso: número grande no centro, botões − e + com incremento configurável (1, 2,5 ou 5), toque no número para digitar e slider como ajuste rápido. Tudo sincronizado. O campo já começa com o último peso usado;
   - repetições OPCIONAIS (pode salvar sem informar);
   - botão Salvar grande e fixo na parte de baixo;
   - histórico por dia, mais recente primeiro (ex.: "12/11 — 60 kg × 10").
5. Regra do recorde: maior peso já registrado no aparelho. Ao salvar um peso maior, destacar o novo recorde (mudança de cor para o verde de conquista, mensagem curta e vibração leve).
6. Dados locais, 100% offline, sem login e sem servidor.
7. Unidade padrão em kg (opção de lb nas configurações).
8. Configurações simples: unidade, incremento padrão, exportar e importar backup em arquivo.
9. Código preparado para uma versão Pro no futuro (ver Fase 11), sem implementar agora.

## Fora do escopo (NÃO implementar sem eu pedir)
Login/nuvem, rede social, treinos montados por IA, vídeos de exercício, timer de descanso, integração com relógio, observação por registro, gráficos, várias academias, tema claro. Pode sugerir como melhoria futura, mas não implemente.

# MODELO DE DADOS (proposta, confirme ou ajuste)
- Aparelho: id, nome, grupo muscular, observação, data de criação.
- Registro: id, id do aparelho, data/hora, peso, repetições (opcional).
- Recorde: calculado a partir dos registros (maior peso), não guardado separado.
- Configurações: unidade, incremento padrão.

# DECISÕES TÉCNICAS

- Flutter (Dart). Desenvolver e testar primeiro no ANDROID. Eu NÃO tenho Mac, então o iPhone entra numa fase final, com serviço de build na nuvem ou outra solução que você me orientar.
- Armazenamento local: banco SQL mantido ativamente, preferencialmente Drift (ou sqflite, se achar mais simples para iniciante; explique em poucas linhas e decida comigo). NÃO use Hive nem Isar (desenvolvimento parado ou sem manutenção).
- Gerenciamento de estado: o mais simples possível para um MVP (sugira Provider ou Riverpod e justifique em duas linhas).
- Pastas simples (models, data/repositories, screens, widgets, theme), sem exagero de arquitetura.
- Um ÚNICO arquivo de tema com todas as cores, fontes e tamanhos, para eu mudar o visual editando um só lugar. Nenhuma cor escrita direto nas telas.
- As fontes devem ficar EMBUTIDAS no app (pasta de assets), não baixadas da internet em tempo de execução, porque o app funciona offline.
- Antes de usar qualquer pacote, confira a versão atual e a documentação oficial. Não invente funções ou APIs; se não tiver certeza, diga que não tem.
- Código em inglês (nomes de classes, variáveis e arquivos); textos exibidos ao usuário em português do Brasil.

# IDENTIDADE VISUAL (SEGUIR EXATAMENTE)

Paleta oficial: Dark Navy + Electric Lime + Ice Blue. Tema ÚNICO escuro (dark mode).

| Cor | HEX | Uso |
| --- | --- | --- |
| Electric Lime | #C8F729 | Cor primária, botões e recordes |
| Deep Navy | #01102E | Fundo principal do aplicativo |
| Surface Navy | #051D40 | Cards e superfícies |
| Royal Blue | #3E67BE | Destaques secundários |
| Ice Blue | #AEC4F5 | Textos secundários |
| Polar White | #F1F6FB | Textos principais |
| Lime Light | #DBFA54 | Brilhos e realces |
| Lime Dark | #A0E423 | Variação da cor primária (ex.: botão pressionado) |
| Deep Blue | #163A7A | Bordas e detalhes |

Diretrizes de uso:
- Fundo das telas: #01102E. Cards e containers: #051D40.
- Botões principais: fundo #C8F729 com texto #01102E.
- Títulos e textos principais: #F1F6FB. Descrições e textos secundários: #AEC4F5.
- Ícones ativos: #C8F729. Ícones inativos: #AEC4F5.
- Bordas e divisórias: #163A7A.
- Conquistas e novos recordes: #C8F729.
- Gráficos (futuro, versão Pro): #C8F729, #3E67BE e #AEC4F5.

Regras de aplicação:
- O verde-limão é reservado para AÇÃO PRINCIPAL e RECORDES/CONQUISTAS. Não use como decoração, para não perder o significado.
- #3E67BE (Royal Blue) tem contraste baixo sobre #051D40: use só em elementos grandes, ícones e detalhes, nunca em texto pequeno.
- Respeite contraste legível em todos os textos; se algum par de cores ficar difícil de ler, me avise e proponha ajuste.
- Cada grupo muscular se diferencia por NOME e ÍCONE, não por cor própria.

Estilo: minimalista, moderno e esportivo. "Profundidade suave" é feita com sombras sutis em tons de azul e bordas finas em #163A7A. NÃO criar ilustrações 3D, nem usar efeitos pesados. A logomarca será fornecida por mim; use-a na tela de abertura e no ícone do app.

# REGRAS CONTRA O "VISUAL DE IA" (MUITO IMPORTANTE)

O app NÃO pode parecer feito por uma IA. Isso vale para interface, textos e código:

- PROIBIDO usar emojis em qualquer lugar do app (telas, botões, mensagens, notificações, loja).
- Ícones: use UM único conjunto consistente (ex.: Material Symbols ou Lucide, você sugere e justifica), sempre com a mesma espessura e estilo. Nada de mistura de estilos.
- Nada de gradientes decorativos, efeito de vidro (glassmorphism), brilhos exagerados, bordas neon ou confetes.
- Textos do app curtos, diretos e neutros, no tom de uma ferramenta bem feita. Sem exclamações em excesso, sem frases motivacionais genéricas, sem "Vamos lá!", "Oops!", "Bem-vindo(a)!". Exemplos bons: "Novo recorde", "Nenhum aparelho cadastrado", "Não foi possível salvar".
- Texto de estado vazio e de erro: uma frase objetiva e uma ação clara.
- Layout com hierarquia e alinhamentos consistentes: mesmo espaçamento, mesmos tamanhos e mesmos raios de borda em todas as telas, definidos no tema. Nada de elementos soltos ou de cada tela com um estilo.
- Nada de telas de exemplo, textos placeholder ("Lorem ipsum", "Item 1") ou o app de contador padrão do Flutter deixados no projeto.
- Animações curtas e discretas (transições simples), só quando ajudam. Nenhuma animação decorativa.
- Código limpo: comentários só onde a lógica não é óbvia, sem comentários explicando o que o código já diz. Nomes claros, sem código morto, sem arquivos ou funções de sobra.
- Textos de loja (Fase 10) em português natural, de pessoa real, sem exagero de marketing e sem lista de "recursos incríveis".

# DIRETRIZES DE USO (UX)

- Pensado para uso rápido na academia: mão suada, cansaço, olhar de relance entre séries.
- Botões grandes (área de toque mínima de 48 dp), ação principal na parte de baixo da tela, números grandes, alto contraste.
- Cartões grandes com cantos arredondados, pouca informação por tela, bastante espaço em branco.
- Uma única família de fonte principal com 2 ou 3 tamanhos fixos, mais (opcionalmente) uma fonte condensada só para os números grandes de peso. Sugira as fontes e justifique; precisam ter licença livre e ficar embutidas no app.
- Sem barra de navegação inferior (o fluxo é único: início, grupo, aparelho). Engrenagem de configurações no canto da tela inicial.
- Meta: registrar um peso em menos de 10 segundos.
- Textos em português do Brasil.

# O PROCESSO (FASES)

Conduza o projeto na ordem abaixo. REGRA PRINCIPAL: faça UMA fase por vez e PARE no fim dela, esperando eu dizer que funcionou antes de avançar.

- Fase 0 — Preparação: confirmar o plano, me fazer até 3 perguntas realmente necessárias (por exemplo: sistema operacional e se o Flutter já está instalado; formato dos arquivos da logo; qual será o identificador do app, como com.algo.gymrecords, que não pode mudar depois de publicado) e me ajudar a configurar o ambiente.
- Fase 1 — Esqueleto: criar o projeto GymRecords, estrutura de pastas, arquivo de tema com a paleta, fontes embutidas e navegação entre telas vazias.
- Fase 2 — Camada de dados: modelos, banco local, repositório e testes básicos de salvar e ler.
- Fase 3 — Tela inicial: grade de grupos musculares.
- Fase 4 — Lista de aparelhos: listar por grupo, adicionar, renomear e apagar.
- Fase 5 — Tela do aparelho: controle de peso (botões, digitação e slider sincronizados), repetições opcionais, salvar, regra e destaque de novo recorde.
- Fase 6 — Observação fixa e histórico por dia.
- Fase 7 — Configurações e backup: unidade, incremento, exportar e importar arquivo.
- Fase 8 — Acabamento: ícone do app e tela de abertura com a logo (me diga os formatos de arquivo necessários, incluindo o ícone adaptativo do Android), estados vazios, tratamento de erros, vibração e revisão geral de consistência visual contra as regras acima.
- Fase 9 — Testes: casos de borda (peso zero, nome vazio, muitos registros, apagar aparelho com histórico), desempenho e correção de bugs.
- Fase 10 — Publicação no Android: assinatura do app, política de privacidade, ficha da loja (textos e capturas de tela), conta de desenvolvedor, teste fechado e checklist de envio. Conta pessoal nova no Google Play exige teste fechado com 12 testers por 14 dias seguidos (confira a regra atual antes de me orientar).
- Fase 11 — Versão Pro: compra dentro do app (avaliar RevenueCat ou o pacote oficial), definir o que fica no Pro (ex.: backup em nuvem, gráficos, várias academias, mais exportações) mantendo o essencial grátis.
- Fase 12 — iPhone: build sem Mac, conta Apple, ficha da App Store e envio. Confira condições e taxas atuais antes de me orientar.

# COMO ENTREGAR CADA FASE

Em cada fase, entregue exatamente nesta estrutura:
1. Objetivo da fase, em 1 ou 2 frases.
2. Passo a passo do que fazer.
3. Código COMPLETO de cada arquivo (sem "..." nem trechos omitidos), com o caminho de onde colocá-lo.
4. Como testar e o que devo ver na tela quando estiver certo.
5. Checklist de aceite: itens que preciso marcar para a fase ser considerada concluída.
6. Estado do projeto: o que já está pronto, decisões tomadas e próxima fase.

Depois do item 6, PARE e espere minha resposta.

# REGRAS GERAIS

- Se eu colar uma mensagem de erro, ache a causa e me dê a correção completa, explicando em uma frase o que estava errado.
- Se uma decisão minha for ruim ou arriscada, diga com respeito e proponha alternativa, mas a decisão final é minha.
- Não adicione funcionalidades fora do escopo. Sugestões ficam numa lista de "Melhorias futuras", sem implementar.
- Se eu pedir uma mudança que quebre algo já feito, avise antes.
- Se a conversa ficar longa, comece sua resposta lembrando em 3 linhas onde estamos.
- Quando não souber algo ou não puder confirmar (versões, regras de loja, preços), diga claramente e me indique onde conferir.

# PRIMEIRA RESPOSTA

Comece assim: (1) confirme em poucas linhas que entendeu o app, a identidade visual e o processo; (2) aponte qualquer risco ou conflito que perceber no plano; (3) faça as perguntas da Fase 0, no máximo 3; (4) só comece a Fase 0 depois de eu responder.