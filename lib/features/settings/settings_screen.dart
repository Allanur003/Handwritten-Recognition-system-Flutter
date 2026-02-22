import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:handwritten_recognition/core/localization/app_localizations.dart';
import 'package:handwritten_recognition/core/theme/theme_provider.dart';
import 'package:handwritten_recognition/features/recognition/recognition_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _apiController;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    final provider = context.read<RecognitionProvider>();
    _apiController = TextEditingController(text: provider.apiKey);
  }

  @override
  void dispose() {
    _apiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final recProvider = context.watch<RecognitionProvider>();
    final theme = Theme.of(context);

    final appLanguages = [
      (const Locale('en'), '🇬🇧 English'),
      (const Locale('ru'), '🇷🇺 Русский'),
      (const Locale('tk'), '🇹🇲 Türkmençe'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.get('settings')),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Gemini API Key ──────────────────────────────
          _SectionHeader(title: loc.get('apiKeyTitle')),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: theme.colorScheme.secondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          loc.get('apiKeyInfo'),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.secondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _apiController,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      hintText: loc.get('apiKeyHint'),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                            _obscure ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      prefixIcon: const Icon(Icons.key),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        context
                            .read<RecognitionProvider>()
                            .setApiKey(_apiController.text);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ API Key saved!'),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.save),
                      label: Text(loc.get('apiKeySave')),
                    ),
                  ),
                  if (recProvider.hasApiKey)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green, size: 16),
                          const SizedBox(width: 6),
                          Text('API Key is set ✓',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Appearance ──────────────────────────────────
          _SectionHeader(title: 'Appearance'),
          Card(
            child: SwitchListTile(
              secondary: Icon(
                themeProvider.isDark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                color: theme.colorScheme.primary,
              ),
              title: Text(loc.get('darkMode')),
              value: themeProvider.isDark,
              onChanged: (_) => themeProvider.toggleTheme(),
            ),
          ),
          const SizedBox(height: 16),

          // ── App Language ────────────────────────────────
          _SectionHeader(title: loc.get('appLanguage')),
          Card(
            child: Column(
              children: appLanguages.map((item) {
                final (locale, label) = item;
                final isSelected =
                    localeProvider.locale.languageCode == locale.languageCode;
                return ListTile(
                  title: Text(label),
                  trailing: isSelected
                      ? Icon(Icons.check_rounded,
                          color: theme.colorScheme.primary)
                      : null,
                  onTap: () => localeProvider.setLocale(locale),
                  selected: isSelected,
                  selectedColor: theme.colorScheme.primary,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // ── About ───────────────────────────────────────
          _SectionHeader(title: 'About'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Handwriting Recognition v1.0',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Powered by Google Gemini Vision AI\n'
                    'Supports: English, Russian, Turkmen',
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
