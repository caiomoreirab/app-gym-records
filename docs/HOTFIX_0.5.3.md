# Hotfix 0.5.3 — scroll/compositing azul

Correção para o artefato visual observado no Android Emulator em que o canvas ficava azul elétrico durante a rolagem com o mouse e voltava ao normal ao arrastar no sentido oposto.

Alterações:
- removidos todos os `ColorFiltered(... BlendMode.hue)` em runtime;
- criado `assets/branding/icon_blue.png`, com o azul já incorporado no arquivo;
- header, splash, card de recorde e sheet de conquista passam a usar o asset estático;
- adicionado `GymRecordsScrollBehavior`, sem overscroll/stretch visual e com `ClampingScrollPhysics`;
- nenhum fluxo, dado mockado ou recurso Pro foi alterado.
