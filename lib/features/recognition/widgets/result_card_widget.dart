import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:handwritten_recognition/core/localization/app_localizations.dart';

class ResultCardWidget extends StatelessWidget {
  final String text;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  const ResultCardWidget({
    super.key,
    required this.text,
    required this.onCopy,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hasText = text.trim().isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.text_fields_rounded,
                    color: theme.colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  loc.get('result'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Spacer(),
                if (hasText) ...[
                  IconButton(
                    icon: const Icon(Icons.copy_rounded),
                    tooltip: loc.get('copy'),
                    onPressed: onCopy,
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_rounded),
                    tooltip: loc.get('share'),
                    onPressed: onShare,
                  ),
                ],
              ],
            ),
            const Divider(),
            const SizedBox(height: 4),
            if (hasText) ...[
              SelectableText(
                text,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.7),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(loc.get('copied')),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ));
                  },
                  icon: const Icon(Icons.select_all_rounded),
                  label: Text(loc.get('copyAll')),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ] else
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded,
                          size: 40, color: theme.colorScheme.outline),
                      const SizedBox(height: 8),
                      Text(
                        loc.get('noText'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.outline),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
