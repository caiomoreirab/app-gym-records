# GymRecords — aplicação da Tapa de UX (23/11/2026)

## Escopo e restrições

Avaliação baseada no código da branch `feat/fase1-registro-confiavel-classico`
e nas regras da skill [Tapa de UX](https://github.com/othiagopinheiro/tapa-de-ux)
de Thiago Pinheiro (CC BY 4.0). Mantida a identidade do GymRecords:
tema dark, azul-ciano `#10B7F4`, Barlow, mascote, cartões e ilustrações.
Nenhuma alteração foi feita na branch `main`.

## Plano executado

| Item | Estado | Mudança |
|---|---|---|
| Contraste do CTA | Implementado | Texto e ícones azul-escuro sobre azul-ciano |
| Área de toque do carrossel de imagens | Implementado | Toda a imagem aceita toque e possui descrição semântica |
| Histórico reabrível | Implementado | Cada sessão listada abre resumo de treino |
| Registrar série primeiro | Implementado | Formulário de registro acima das métricas históricas; imagem de 190 px sem distorção |
| Incluir somente com intenção | Implementado | Catálogo geral e busca não alteram treino ativo; picker adiciona |
| Preservar estado das abas | Implementado | `MainTabsShell` com `IndexedStack`; mantém busca, filtros e rolagem montados |
| Hierarquia dos CTAs | Implementado | Iniciar/acompanhar é principal; adicionar exercício é secundário na Home |
| Erros junto aos campos | Parcial | Editar série aponta erros por campo; registro rápido identifica números inválidos |
| Nome preciso da ação | Implementado | “Usar valores da última série” em vez de prometer gravação imediata |
| Conclusão sem série | Implementado | Pede confirmação e identifica estado sem inventar execuções |
| Feedback de descanso | Implementado | Estado “Descanso concluído” + retorno háptico |
| Terminologia e localização | Parcial | Ajustados CTAs principais; restam textos fixos em português |
| Feedback do toque | Implementado | Material ripple discreto azul, sem alterar a paleta |
| Régua de espaçamento | Parcial | Mantidas medidas da identidade; padronização extensiva pendente |

## Testes de regressão adicionados/ajustados

- `test/main_tab_state_test.dart`: trocas de abas preservam pesquisas.
- `test/ux_navigation_flow_test.dart`: contraste, catálogo sem inclusão oculta,
  abertura de histórico.
- `test/live_workout_progress_test.dart`: marcação vazia requer confirmação,
  sem forjar séries.

## Pendências para validação final

1. Testes reais de VoiceOver/TalkBack e tamanhos de fonte em iOS/Android;
   teste manual da transição do timer para descanso concluído.
2. Revisão da tradução integral das strings ainda fixas e padronização da régua
   de espaçamentos nas telas secundárias.
3. Ilustrações específicas dos demais 86 movimentos ainda com fallback genérico:
   manter o aviso honesto e validar biomecânica antes de substituir.
4. Validar a publicação via APK Android e prévia web; preparar AAB assinado
   apenas quando o produto estiver aprovado.

**Importante:** marcadores “Implementado” indicam código na branch de desenvolvimento,
não garantia de aprovação em dispositivos reais ou de loja.
