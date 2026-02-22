import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:handwritten_recognition/core/localization/app_localizations.dart';
import 'package:handwritten_recognition/features/recognition/recognition_provider.dart';
import 'package:handwritten_recognition/features/recognition/widgets/language_selector_widget.dart';
import 'package:handwritten_recognition/features/recognition/widgets/image_area_widget.dart';
import 'package:handwritten_recognition/features/recognition/widgets/result_card_widget.dart';
import 'package:handwritten_recognition/features/history/history_provider.dart';

class RecognitionScreen extends StatelessWidget {
  const RecognitionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final provider = context.watch<RecognitionProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.get('appTitle'),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.pushNamed(context, '/history'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // API Key warning banner
            if (!provider.hasApiKey)
              _ApiKeyBanner().animate().fadeIn().slideY(begin: -0.2),

            // Gemini badge
            if (provider.hasApiKey)
              _GeminiBadge(loc: loc),

            const SizedBox(height: 12),

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

            // Recognize button
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
                        if (provider.state == RecognitionState.done &&
                            provider.recognizedText.isNotEmpty) {
                          // ignore: use_build_context_synchronously
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
                    : const Icon(Icons.auto_awesome),
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
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(loc.get('copied')),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ));
                },
                onShare: () => Share.share(provider.recognizedText),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),

            // Error
            if (provider.state == RecognitionState.error)
              _ErrorCard(message: provider.errorMessage, loc: loc),

            const SizedBox(height: 24),
            _TipsCard(),
          ],
        ),
      ),
    );
  }
}

class _GeminiBadge extends StatelessWidget {
  final AppLocalizations loc;
  const _GeminiBadge({required this.loc});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 16),
          const SizedBox(width: 6),
          Text(loc.get('geminiPowered'),
              style: theme.textTheme.labelMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ApiKeyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/settings'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.key_off, color: theme.colorScheme.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppLocalizations.of(context).get('apiKeyMissing'),
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: theme.colorScheme.onErrorContainer),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final AppLocalizations loc;
  const _ErrorCard({required this.message, required this.loc});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayMsg = message == 'API_KEY_MISSING'
        ? loc.get('apiKeyMissing')
        : message;
    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline,
                color: theme.colorScheme.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(displayMsg,
                  style:
                      TextStyle(color: theme.colorScheme.onErrorContainer)),
            ),
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
          Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}
