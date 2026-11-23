import 'package:material_ui/material_ui.dart';

import '../../l10n/app_strings.dart';
import '../../models/user_profile.dart';
import '../../state/app_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_header.dart';
import '../../widgets/illustration_style_card.dart';
import '../../widgets/onboarding_progress.dart';
import '../../widgets/primary_bottom_bar.dart';
import '../home_screen.dart';

class IllustrationStyleScreen extends StatefulWidget {
  const IllustrationStyleScreen({super.key});

  @override
  State<IllustrationStyleScreen> createState() =>
      _IllustrationStyleScreenState();
}

class _IllustrationStyleScreenState extends State<IllustrationStyleScreen> {
  IllustrationStyle? _selected;

  String _titleName(String raw) {
    final name = raw.trim().split(RegExp(r'\s+')).firstOrNull ?? '';
    if (name.length <= 14) return name;
    return '${name.substring(0, 13)}…';
  }

  void _continue() {
    final style = _selected;
    if (style == null) return;
    final app = AppScope.of(context);
    app.setIllustrationStyle(style);
    app.completeOnboarding();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final name = _titleName(app.displayName);
    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      bottomNavigationBar: PrimaryBottomBar(
        label: context.strings.continueLabel,
        onPressed: _selected == null ? null : _continue,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(28, 18, 28, 22),
              children: [
                const BrandHeader(),
                const SizedBox(height: 38),
                const OnboardingProgress(step: 2),
                const SizedBox(height: 42),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: name.isEmpty ? '' : '$name, '),
                      TextSpan(text: context.strings.t('como você prefere visualizar os ', 'how do you prefer to view ', '¿cómo prefieres ver los ')),
                      TextSpan(
                        text: context.strings.t('exercícios?', 'exercises?', 'ejercicios?'),
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(color: AppTheme.electricLime),
                      ),
                    ],
                  ),
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: name.length > 10 ? 31 : 35,
                        height: 1.08,
                      ),
                ),
                const SizedBox(height: 14),
                Text(
                  context.strings.illustrationSubtitle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.iceBlue,
                        fontSize: 17,
                        height: 1.3,
                      ),
                ),
                const SizedBox(height: 26),
                for (final style in IllustrationStyle.values) ...[
                  IllustrationStyleCard(
                    key: Key('style_${style.name}'),
                    style: style,
                    selected: _selected == style,
                    onTap: () => setState(() => _selected = style),
                  ),
                  if (style != IllustrationStyle.values.last)
                    const SizedBox(height: 14),
                ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceNavy,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.deepBlue),
                  ),
                  child: Row(children: [
                    const Icon(Icons.fitness_center_rounded,
                      color: AppTheme.electricLime, size: 24),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.strings.t(
                            'Exemplo de registro', 'Sample workout entry',
                            'Ejemplo de registro'),
                          style: const TextStyle(color: AppTheme.iceBlue,
                            fontSize: 12),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          context.strings.t(
                            'Supino reto · 40 kg × 10 repetições',
                            'Bench press · 40 kg × 10 reps',
                            'Press de banca · 40 kg × 10 repeticiones'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    )),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
