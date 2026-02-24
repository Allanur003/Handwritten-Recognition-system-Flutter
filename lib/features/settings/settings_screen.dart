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
  final TextEditingController _keyController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _keyController.dispose();
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

          // ── API Keys ─────────────────────────────────────
          _SectionHeader(title: loc.get('apiKeyTitle')),

          // Bilgi kartı
          Card(
            color: theme.colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16,
                          color: theme.colorScheme.onSecondaryContainer),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          loc.get('apiKeyInfo'),
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '💡 In kop 2 key gosup bilersin. '
                    'Biri dolsa aitomat beylekisine geçer.',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Mevcut key'ler
          ...recProvider.apiKeys.asMap().entries.map((entry) {
            final index = entry.key;
            final key = entry.value;
            final isActive = index == recProvider.currentKeyIndex;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      isActive ? Colors.green : theme.colorScheme.surfaceVariant,
                  radius: 16,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isActive
                          ? Colors.white
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                title: Text(
                  _maskKey(key),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontFamily: 'monospace'),
                ),
                subtitle: Text(
                  isActive ? '✅ Aktiw' : '⏳ Garasyn',
                  style: TextStyle(
                    color: isActive ? Colors.green : theme.colorScheme.outline,
                    fontWeight:
                        isActive ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: theme.colorScheme.error),
                  onPressed: () => _confirmDelete(context, recProvider, index),
                ),
              ),
            );
          }),

          // Yeni key ekleme — sadece 2'den az key varsa göster
          if (recProvider.canAddMoreKeys) ...[
            const SizedBox(height: 4),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recProvider.apiKeys.isEmpty
                          ? 'API Key Gosh (1/2)'
                          : 'İkinji API Key gosh (2/2)',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _keyController,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        hintText: loc.get('apiKeyHint'),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.key),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          final key = _keyController.text.trim();
                          if (key.isEmpty) return;
                          await recProvider.addApiKey(key);
                          _keyController.clear();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '✅ Key ${recProvider.apiKeys.length} db edildi!'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.save),
                        label: Text(loc.get('apiKeySave')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // 2 key doldu mesajı
            const SizedBox(height: 4),
            Card(
              color: theme.colorScheme.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'İki key hem gosuldy. Günde jemi 40 surat tanadyp bilersin.',
                      style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // ── Appearance ───────────────────────────────────
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

          // ── App Language ─────────────────────────────────
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

          // ── About ────────────────────────────────────────
          _SectionHeader(title: 'About'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.document_scanner,
                      color: theme.colorScheme.primary, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Handwriting Recognition v1.0',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'EN · RU · TK',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, RecognitionProvider provider, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Key\'i Poz'),
        content: const Text('Bu key\'i pozmak isleyarmin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Goybolsun'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () async {
              await provider.removeApiKey(index);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Poz'),
          ),
        ],
      ),
    );
  }

  String _maskKey(String key) {
    if (key.length <= 12) return '***';
    return '${key.substring(0, 8)}...${key.substring(key.length - 4)}';
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
