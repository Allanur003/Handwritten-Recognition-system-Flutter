import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final theme = Theme.of(context);

    final appLanguages = [
      (const Locale('en'), '🇬🇧 English'),
      (const Locale('tr'), '🇹🇷 Türkçe'),
      (const Locale('ru'), '🇷🇺 Русский'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.get('settings')),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance section
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

          // Language section
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

          // About
          _SectionHeader(title: 'About'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Handwriting Recognition',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Powered by Google ML Kit (on-device, offline)\n'
                    'Supports: English, Turkish, Russian, Turkmen\n'
                    'Version: 1.0.0',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(height: 1.6),
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
