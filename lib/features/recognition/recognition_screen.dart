import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/localization/app_localizations.dart';
import 'recognition_provider.dart';
import 'widgets/language_selector_widget.dart';
import 'widgets/image_area_widget.dart';
import 'widgets/result_card_widget.dart';
import '../history/history_provider.dart';

class RecognitionScreen extends StatelessWidget {
  const RecognitionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final provider = context.watch<RecognitionProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.get('appTitle'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: loc.get('history'),
            onPressed: () => Navigator.pushNamed(context, '/history'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: loc.get('settings'),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Language selector
            const LanguageSelectorWidget(),
            const SizedBox(height: 16),

            // Image area
            const ImageAreaWidget(),
            const SizedBox(height: 16),

            // Pick / Camera buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => provider.pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(loc.get('pickImage')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: theme.colorScheme.onSecondary,
                    ),
                    onPressed: () => provider.pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(loc.get('takePhoto')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Recognize button — only show if image selected
            if (provider.selectedImage != null) ...[
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.colorScheme.tertiary,
                  foregroundColor: theme.colorScheme.onTertiary,
                ),
                onPressed: provider.state == RecognitionState.processing
                    ? null
                    : () async {
                        await provider.recognizeText();
                        // Save to history if success
                        if (provider.state == RecognitionState.done &&
                            provider.recognizedText.isNotEmpty) {
                          context.read<HistoryProvider>().addEntry(
                                provider.recognizedText,
                                provider.language.name,
                              );
                        }
                      },
                icon: provider.state == RecognitionState.processing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.document_scanner_outlined),
                label: Text(
                  provider.state == RecognitionState.processing
                      ? loc.get('processing')
                      : loc.get('recognize'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ).animate().fadeIn().slideY(begin: 0.3),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: provider.reset,
                icon: const Icon(Icons.refresh),
                label: Text(loc.get('reset')),
              ),
            ],

            const SizedBox(height: 8),

            // Result
            if (provider.state == RecognitionState.done)
              ResultCardWidget(
                text: provider.recognizedText,
                onCopy: () {
                  Clipboard.setData(
                      ClipboardData(text: provider.recognizedText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(loc.get('copied')),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                onShare: () => Share.share(provider.recognizedText),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),

            // Error
            if (provider.state == RecognitionState.error)
              Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    provider.errorMessage,
                    style: TextStyle(
                        color: theme.colorScheme.onErrorContainer),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Tips card
            _TipsCard(),
          ],
        ),
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline,
                    color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(loc.get('tips'),
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            _tip(Icons.wb_sunny_outlined, loc.get('tip1'), theme),
            _tip(Icons.edit_outlined, loc.get('tip2'), theme),
            _tip(Icons.camera_outlined, loc.get('tip3'), theme),
          ],
        ),
      ),
    );
  }

  Widget _tip(IconData icon, String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.secondary),
          const SizedBox(width: 8),
          Expanded(
              child:
                  Text(text, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}
