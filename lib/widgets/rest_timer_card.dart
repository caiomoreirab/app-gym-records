import 'dart:async';
import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import 'section_card.dart';

/// Foreground-only optional rest timer. No background notification is promised.
class RestTimerCard extends StatefulWidget {
  const RestTimerCard({super.key});

  @override
  State<RestTimerCard> createState() => _RestTimerCardState();
}

class _RestTimerCardState extends State<RestTimerCard> {
  Timer? _ticker;
  int _remaining = 0;
  int _duration = 90;

  void _stop() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _start(int seconds) {
    _stop();
    setState(() {
      _duration = seconds;
      _remaining = seconds;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_remaining > 0) _remaining--;
        if (_remaining == 0) _stop();
      });
    });
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = _remaining > 0;
    final minutes = (_remaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remaining % 60).toString().padLeft(2, '0');
    return SectionCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.timer_outlined, color: AppTheme.electricLime),
          const SizedBox(width: 8),
          Expanded(child: Text('Descanso entre séries',
              style: Theme.of(context).textTheme.titleMedium)),
          Text(active ? '$minutes:$seconds' : 'Opcional',
              style: const TextStyle(color: AppTheme.iceBlue)),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final option in [60, 90, 120])
            OutlinedButton(
              onPressed: () => _start(option),
              child: Text('${option}s'),
            ),
          if (active)
            TextButton.icon(
              onPressed: () {
                _stop();
                setState(() => _remaining = 0);
              },
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('Parar'),
            ),
        ]),
        const SizedBox(height: 4),
        Text('Contagem na tela; pode pausar ao sair do aplicativo. '
             'Última seleção: ${_duration}s.',
          style: const TextStyle(color: AppTheme.iceBlue, fontSize: 12)),
      ]),
    );
  }
}
