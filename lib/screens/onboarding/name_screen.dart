import 'package:material_ui/material_ui.dart';

import '../../l10n/app_strings.dart';
import '../../state/app_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_header.dart';
import '../../widgets/onboarding_progress.dart';
import '../../widgets/primary_bottom_bar.dart';
import 'illustration_style_screen.dart';

class NameScreen extends StatefulWidget {
  const NameScreen({super.key});

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  late final TextEditingController _nameController;
  late final FocusNode _focusNode;
  bool _seeded = false;

  String get _normalizedName => _nameController.text.trim();
  bool get _isValid => _normalizedName.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _focusNode = FocusNode();
    _nameController.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    _seeded = true;
    final savedName = AppScope.of(context).displayName;
    if (savedName.isNotEmpty) {
      _nameController.text = savedName;
      _nameController.selection = TextSelection.collapsed(
        offset: savedName.length,
      );
    }
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_refresh)
      ..dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_isValid) return;
    FocusScope.of(context).unfocus();
    AppScope.of(context).setDisplayName(_normalizedName);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const IllustrationStyleScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: bottomInset > 0
          ? null
          : PrimaryBottomBar(
              label: context.strings.continueLabel,
              onPressed: _isValid ? _continue : null,
            ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                28,
                18,
                28,
                28 + bottomInset,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 46,
                  maxWidth: AppTheme.maxContentWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const BrandHeader(),
                    const SizedBox(height: 18),
                    const _OnboardingPreferences(),
                    const SizedBox(height: 24),
                    const OnboardingProgress(step: 1),
                    const SizedBox(height: 56),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: context.strings.t('Como você quer ser ', 'What should we ', '¿Cómo quieres que te ')),
                          TextSpan(
                            text: context.strings.t('chamado?', 'call you?', 'llamemos?'),
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(color: AppTheme.electricLime),
                          ),
                        ],
                      ),
                      style: Theme.of(context)
                          .textTheme
                          .headlineLarge
                          ?.copyWith(fontSize: 38, height: 1.12),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.strings.nameSubtitle,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.iceBlue,
                            fontSize: 19,
                            height: 1.35,
                          ),
                    ),
                    const SizedBox(height: 34),
                    TextField(
                      key: const Key('displayNameField'),
                      controller: _nameController,
                      focusNode: _focusNode,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      maxLength: 28,
                      onSubmitted: (_) {
                        if (_isValid) _continue();
                      },
                      style: const TextStyle(
                        fontSize: 20,
                        color: AppTheme.polarWhite,
                      ),
                      decoration: InputDecoration(
                        hintText: context.strings.nameOrNickname,
                        counterText: '',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 14, right: 12),
                          child: Icon(Icons.person_outline_rounded, size: 30),
                        ),
                        prefixIconConstraints:
                            const BoxConstraints(minWidth: 58, minHeight: 58),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: AppTheme.royalBlue,
                            width: 1.6,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: AppTheme.electricLime,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceNavy,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppTheme.deepBlue),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: AppTheme.electricLime,
                            size: 30,
                          ),
                          const SizedBox(width: 14),
                          Container(
                            width: 1,
                            height: 38,
                            color: AppTheme.deepBlue,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              context.strings.t('Você pode usar seu nome ou apelido.', 'You can use your name or nickname.', 'Puedes usar tu nombre o apodo.'),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(color: AppTheme.iceBlue),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (bottomInset > 0) ...[
                      const SizedBox(height: 28),
                      FilledButton(
                        onPressed: _isValid ? _continue : null,
                        child: Text(context.strings.continueLabel),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OnboardingPreferences extends StatelessWidget {
  const _OnboardingPreferences();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final strings = context.strings;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceNavy,
        border: Border.all(color: AppTheme.deepBlue),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(children: [
        Row(children: [
          const Icon(Icons.language_rounded,
            color: AppTheme.electricLime, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(strings.t('Idioma do aplicativo',
            'App language', 'Idioma de la aplicación'),
            style: const TextStyle(fontSize: 13))),
          DropdownButton<String>(
            key: const Key('onboarding_language'),
            value: app.languageCode,
            underline: const SizedBox.shrink(),
            isDense: true,
            items: const [
              DropdownMenuItem(value: 'system', child: Text('Auto')),
              DropdownMenuItem(value: 'pt', child: Text('PT-BR')),
              DropdownMenuItem(value: 'en', child: Text('EN')),
              DropdownMenuItem(value: 'es', child: Text('ES')),
            ],
            onChanged: (value) {
              if (value != null) app.setLanguageCode(value);
            },
          ),
        ]),
        const Divider(height: 10, color: AppTheme.deepBlue),
        SwitchListTile(
          key: const Key('onboarding_large_text'),
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(strings.t('Fonte ampliada', 'Larger text',
            'Texto ampliado')),
          value: app.largeText,
          onChanged: app.setLargeText,
        ),
      ]),
    );
  }
}
