import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../models/user_profile.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_header.dart';
import '../widgets/illustration_style_card.dart';
import '../widgets/page_body.dart';
import '../widgets/pro_widgets.dart';
import '../widgets/section_card.dart';
import 'evolution_screen.dart';
import 'data_privacy_screen.dart';
import 'pro_overview_screen.dart';
import 'pro_export_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);

    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(context.strings.settings),
      ),
      body: PageBody(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 30),
          children: [
            BrandHeader(compact: true, showPro: app.isPro),
            const SizedBox(height: 20),
            SectionCard(
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlueSoft,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.deepBlue),
                    ),
                    child: const Icon(Icons.person_outline_rounded),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.strings.t('Como você quer ser chamado', 'What should we call you'),
                          style: TextStyle(color: AppTheme.iceBlue, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          app.displayName.isEmpty ? context.strings.user : app.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: context.strings.t('Editar nome', 'Edit name'),
                    onPressed: () => _editName(context, app),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.text_increase_rounded,
                  color: AppTheme.electricLime),
                title: const Text('Fonte ampliada'),
                subtitle: const Text(
                  'Aumenta os textos sem alterar o visual do aplicativo.'),
                value: app.largeText,
                onChanged: app.setLargeText,
              ),
            ),
            const SizedBox(height: 16),
            _ProSettingsCard(app: app),
            const SizedBox(height: 16),
            SectionCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.storage_rounded, color: AppTheme.electricLime),
                title: const Text('Dados e privacidade'),
                subtitle: const Text('Histórico offline, backup e consentimento'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const DataPrivacyScreen()),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.strings.t('Estilo das ilustrações', 'Illustration style'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.strings.t('Altere como os exercícios são apresentados no app.', 'Change how exercises are illustrated in the app.'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  for (final style in IllustrationStyle.values) ...[
                    IllustrationStyleCard(
                      style: style,
                      compact: true,
                      selected: app.effectiveIllustrationStyle == style,
                      onTap: () => app.setIllustrationStyle(style),
                    ),
                    if (style != IllustrationStyle.values.last)
                      const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.strings.language, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 6),
                  Text(
                    context.strings.t('O app pode seguir o idioma do sistema ou usar uma preferência fixa.', 'The app can follow the system language or use a fixed preference.'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  _LanguageRow(
                    flag: '🌐',
                    label: context.strings.systemLanguage,
                    selected: app.languageCode == 'system',
                    onTap: () => app.setLanguageCode('system'),
                  ),
                  const SizedBox(height: 8),
                  _LanguageRow(
                    flag: '🇧🇷',
                    label: context.strings.portuguese,
                    selected: app.languageCode == 'pt',
                    onTap: () => app.setLanguageCode('pt'),
                  ),
                  const SizedBox(height: 8),
                  _LanguageRow(
                    flag: '🇺🇸',
                    label: context.strings.english,
                    selected: app.languageCode == 'en',
                    onTap: () => app.setLanguageCode('en'),
                  ),
                  const SizedBox(height: 8),
                  _LanguageRow(
                    flag: '🇪🇸',
                    label: context.strings.spanish,
                    selected: app.languageCode == 'es',
                    onTap: () => app.setLanguageCode('es'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.strings.t('Unidade de peso', 'Weight unit'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _OptionButton(
                          label: 'kg',
                          selected: app.unit == 'kg',
                          onTap: () => app.setUnit('kg'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _OptionButton(
                          label: 'lb',
                          selected: app.unit == 'lb',
                          onTap: () => app.setUnit('lb'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.strings.t('Unidade de distância', 'Distance unit'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _OptionButton(
                          label: 'km',
                          selected: app.distanceUnit == 'km',
                          onTap: () => app.setDistanceUnit('km'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _OptionButton(
                          label: 'mi',
                          selected: app.distanceUnit == 'mi',
                          onTap: () => app.setDistanceUnit('mi'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.strings.t('Incremento padrão', 'Default increment'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      for (final value in const [1.0, 2.5, 5.0]) ...[
                        Expanded(
                          child: _OptionButton(
                            label: value == 2.5
                                ? '2,5'
                                : value.toStringAsFixed(0),
                            selected: app.increment == value,
                            onTap: () => app.setIncrement(value),
                          ),
                        ),
                        if (value != 5.0) const SizedBox(width: 10),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        context.strings.t('Dados e exportação', 'Data & export'),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Spacer(),
                      const ProPill(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.strings.t('CSV copiável e relatório PDF compartilhável usando os registros disponíveis.', 'Copyable CSV and shareable PDF generated from available logs.', 'CSV y PDF generados con los registros disponibles.'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  _ActionRow(
                    icon: Icons.table_chart_outlined,
                    title: context.strings.t('Exportar CSV', 'Export CSV'),
                    subtitle: context.strings.t('Planilha com seu histórico de registros', 'Spreadsheet with your workout history'),
                    locked: !app.isPro,
                    onTap: () => _handleExport(context, app, 'CSV'),
                  ),
                  const Divider(height: 1),
                  _ActionRow(
                    icon: Icons.picture_as_pdf_outlined,
                    title: context.strings.t('Exportar PDF', 'Export PDF'),
                    subtitle: context.strings.t('Relatório organizado de exercícios e recordes', 'Organized report of exercises and records'),
                    locked: !app.isPro,
                    onTap: () => _handleExport(context, app, 'PDF'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),
            Center(
              child: Text(
                context.strings.t('Versão de validação 0.9.1 • Dados locais', 'Validation build 0.9.1 • Local data', 'Versión de prueba 0.9.1 • Datos locales'),
                style: const TextStyle(color: AppTheme.iceBlue),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  static Future<void> _editName(BuildContext context, AppController app) async {
    final controller = TextEditingController(text: app.displayName);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.strings.t('Editar nome', 'Edit name')),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            maxLength: 28,
            decoration: InputDecoration(
              hintText: context.strings.nameOrNickname,
              counterText: '',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.strings.t('Cancelar', 'Cancel')),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isEmpty) return;
                Navigator.of(dialogContext).pop(value);
              },
              child: Text(context.strings.t('Salvar', 'Save')),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (result != null) app.setDisplayName(result);
  }

  static void _handleExport(BuildContext context, AppController app, String format) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => app.isPro ? const ProExportScreen() : const ProOverviewScreen(),
    ));
  }

}

class _ProSettingsCard extends StatelessWidget {
  const _ProSettingsCard({required this.app});

  final AppController app;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardElevated,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.electricLime.withValues(alpha: .65)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Image.asset(
                'assets/branding/pro_mascot.webp',
                width: 68,
                height: 62,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('GymRecords Pro', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(width: 7),
                        ProPill(label: app.isPro ? 'ATIVO' : 'PRO'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      app.isPro
                          ? context.strings.t('PR Radar, IQ, mapa muscular e recordes avançados ativos.', 'PR Radar, IQ, muscle map and advanced records are active.')
                          : context.strings.t('Veja como ficará a experiência premium.', 'Preview the premium experience.'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.25),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => app.isPro
                          ? const EvolutionScreen()
                          : const ProOverviewScreen(),
                    ),
                  ),
                  child: Text(app.isPro ? context.strings.t('Ver evolução', 'View progress') : context.strings.t('Conhecer Pro', 'Explore Pro')),
                ),
              ),
              const SizedBox(width: 10),
              Switch(
                value: app.isPro,
                activeTrackColor: AppTheme.electricLime,
                onChanged: app.setProPreview,
              ),
            ],
          ),
          Text(
            context.strings.t('Chave de prévia para validação do front. Não representa assinatura real.', 'Preview toggle for front-end validation. This is not a real subscription.'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}


class _LanguageRow extends StatelessWidget {
  const _LanguageRow({required this.flag, required this.label, required this.selected, required this.onTap});
  final String flag;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: selected ? AppTheme.accentBlueSoft : AppTheme.mutedSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? AppTheme.electricLime : AppTheme.deepBlue),
          ),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
              if (selected) const Icon(Icons.check_circle_rounded, color: AppTheme.electricLime),
            ],
          ),
        ),
      );
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppTheme.accentBlueSoft : AppTheme.mutedSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.electricLime : AppTheme.deepBlue,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: selected ? AppTheme.electricLime : AppTheme.polarWhite,
              ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.locked = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.accentBlueSoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: AppTheme.electricLime),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (locked) const Icon(Icons.lock_outline_rounded, size: 18),
            const SizedBox(width: 5),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
