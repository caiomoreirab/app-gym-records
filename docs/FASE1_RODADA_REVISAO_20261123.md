# GymRecords — Rodada de revisão funcional (23/11/2026)

Base: visual clássico da v0.9.1, branch `feat/fase1-registro-confiavel-classico`.
A `main` não é alterada até a aprovação do produto.
Fonte da demanda: `Texto colado(20261123-002602).txt`.

| # | Tema | Status no código | Observação de aceite |
|---|---|---|---|
| 1 | Correspondência das imagens | Parcial, mitigação implementada | Exercícios sem pose segura recebem vetor neutro. Supinos livres não herdam chest press; oito abdominais com pose reutilizada também foram bloqueados. Criação/validação biomecânica de artes específicas ainda depende de revisão visual. |
| 2 | Português no onboarding | Implementado | Idioma automático ou escolha pt/en/es antes do cadastro. Verificar nos três dispositivos. |
| 3 | Regras por equipamento | Implementado | Serviço único distingue carga externa/peso corporal; duração e cardio usam seus campos; feedback no botão Salvar. |
| 4 | Editar/excluir séries | Implementado | Preserva ID, salva campos, permite cancelar, confirmação e desfazer. Confirmar em dispositivo após reiniciar. |
| 5 | Histórico/backup offline | Implementado | JSON v1/v2, preservação de extras, confirmação, importar arquivo, cópia e download. Testes cobrem JSON vazio/inválido/incompatível. |
| 6 | Fonte ampliada e primeira experiência | Implementado | Configuração disponível antes da conclusão do onboarding. Validar leitor de tela/teclado reais. |
| 7 | Repetir série | Implementado | Pré-preenche dados sem criar série nova; usuário revisa e toca Salvar. Validar tempo e ergonomia no celular. |
| 8 | Estados vazios dos gráficos | Implementado nas telas principais | Treinos insuficientes exibem instruções. Fazer inspeção manual em todos os filtros. |
| 9 | Próximo objetivo | Implementado | Linguagem exploratória, sem probabilidade numérica como previsão; exige dados mínimos. |
| 10 | Compartilhamento | Implementado parcialmente | Cartão PNG com compartilhar, download/cópia onde disponível. Compatibilidade iOS, Android e navegador precisa de testes manuais. |
| 11 | Resumo e calorias | Implementado | Peso opcional, MET 3.5, duração limitada e aviso de estimativa. Não informa números sem dados. |
| 12 | Filtros e unidades | Implementado no código | Converte kg/lb, km/mi e volume na apresentação; armazenamento físico em kg/km. CSV e PDF explicitam unidade canônica. Testar filtros com dados reais. |
| 13 | Variações de cartão | Parcial | Cartões de treino e recorde existem. Novas variações/opções de privacidade visual podem ser decididas depois. |
| 14 | Motivação para iniciantes | Adiado | Metas novas dependem de decisão de produto; não criar competição/rankings por padrão. |
| 15 | Plano para personal trainers | Fora do escopo pessoal | Se for priorizado, especificar produto e permissões à parte. |

## Critérios obrigatórios antes da versão oficial
- CI com análise, testes Flutter e build Web **verde no mesmo commit**.
- Verificação manual no iPhone e no Android: onboarding, fonte ampliada,
  séries com e sem carga, séries repetidas, edição, remoção, aquecimento e
  retorno ao histórico após reiniciar.
- Backup antes dos testes destrutivos, restauração de arquivo e confirmações.
- Compartilhamento real no navegador/iOS/Android, com caminho alternativo.
- Conferência visual das artes e dos textos em 320 px e aparelhos reais.
- Prévia Pro sempre declarada como **simulação**, sem assinatura real.

**Limitações:** testes automatizados não demonstram qualidade biomecânica de
todas as figuras nem funcionamento da folha de compartilhamento do sistema
operacional em aparelhos físicos. Esses pontos permanecem em homologação.

**Importante:** o armazenamento da rota Web /phase1/ usa chaves diferentes da
versão oficial. Guarde backups antes de qualquer migração entre versões.
