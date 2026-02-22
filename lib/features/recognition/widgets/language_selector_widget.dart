import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:handwritten_recognition/core/localization/app_localizations.dart';
import 'package:handwritten_recognition/features/recognition/recognition_provider.dart';

class LanguageSelectorWidget extends StatelessWidget {
  const LanguageSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecognitionProvider>();
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // Only 3 languages: EN, RU, TK
    final langs = [
      (RecognitionLanguage.english, '🇬🇧', loc.get('english')),
      (RecognitionLanguage.russian, '🇷🇺', loc.get('russian')),
      (RecognitionLanguage.turkmen, '🇹🇲', loc.get('turkmen')),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.get('selectRecogLang'),
              style: theme.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: langs.map((item) {
                final (lang, flag, label) = item;
                final isSelected = provider.language == lang;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      avatar: Text(flag, style: const TextStyle(fontSize: 16)),
                      label: Text(label, style: const TextStyle(fontSize: 12)),
                      selected: isSelected,
                      onSelected: (_) => provider.setLanguage(lang),
                      selectedColor: theme.colorScheme.primaryContainer,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
