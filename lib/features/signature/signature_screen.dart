import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:handwritten_recognition/core/localization/app_localizations.dart';
import 'package:handwritten_recognition/features/recognition/recognition_provider.dart';

enum SignatureState { idle, processing, matched, noMatch, error }

class SignatureScreen extends StatefulWidget {
  const SignatureScreen({super.key});

  @override
  State<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  File? _selectedImage;
  SignatureState _signatureState = SignatureState.idle;
  String _errorMessage = '';
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 100,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (file != null) {
        setState(() {
          _selectedImage = File(file.path);
          _signatureState = SignatureState.idle;
          _errorMessage = '';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _signatureState = SignatureState.error;
      });
    }
  }

  Future<void> _pickReferenceSignature(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 100,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (file != null && mounted) {
        final recProvider = context.read<RecognitionProvider>();
        await recProvider.saveReferenceSignature(File(file.path));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).get('refSigSaved')),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Model fallback ile imza doğrula:
  /// gemini-2.0-flash → gemini-1.5-flash → gemini-2.5-flash
  /// 503 (server busy) veya 404 (model not found) hatalarında sonraki modele geç.
  Future<void> _verifySignature() async {
    if (_selectedImage == null) return;
    final recProvider = context.read<RecognitionProvider>();

    if (!recProvider.hasApiKey) {
      setState(() {
        _errorMessage = 'API_KEY_MISSING';
        _signatureState = SignatureState.error;
      });
      return;
    }

    if (!recProvider.hasReferenceSignature) {
      setState(() {
        _errorMessage = 'NO_REFERENCE';
        _signatureState = SignatureState.error;
      });
      return;
    }

    setState(() => _signatureState = SignatureState.processing);

    final models = recProvider.signatureModels;

    for (int keyAttempt = 0; keyAttempt < recProvider.apiKeys.length; keyAttempt++) {
      final apiKey = recProvider.apiKeys[recProvider.currentKeyIndex];

      for (final modelName in models) {
        try {
          final result = await recProvider.callSignatureApi(
            apiKey,
            modelName,
            _selectedImage!,
          );

          if (!mounted) return;

          setState(() {
            if (result.contains('MATCH') && !result.contains('NO_MATCH')) {
              _signatureState = SignatureState.matched;
            } else {
              _signatureState = SignatureState.noMatch;
            }
          });
          return;

        } catch (e) {
          final msg = e.toString().toLowerCase();
          final isModelError = msg.contains('404') || msg.contains('not found');
          final isUnavailable =
              msg.contains('503') || msg.contains('unavailable') || msg.contains('overloaded');
          final isRateLimit =
              msg.contains('429') || msg.contains('quota') || msg.contains('resource exhausted');

          // Model yok veya sunucu meşgul → sonraki modeli dene
          if (isModelError || isUnavailable) continue;

          // Rate limit → sonraki key'e geç (iç döngüyü kır)
          if (isRateLimit) break;

          // Başka hata → ekrana yansıt
          if (!mounted) return;
          setState(() {
            _errorMessage = e.toString();
            _signatureState = SignatureState.error;
          });
          return;
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _errorMessage = 'all_keys_exhausted';
      _signatureState = SignatureState.error;
    });
  }

  void _reset() {
    setState(() {
      _selectedImage = null;
      _signatureState = SignatureState.idle;
      _errorMessage = '';
    });
  }

  void _showRefPickerDialog() {
    final loc = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loc.get('refSigUploadTitle'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.photo_library)),
                title: Text(loc.get('pickImage')),
                subtitle: Text(loc.get('refSigFromGallery')),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickReferenceSignature(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.camera_alt)),
                title: Text(loc.get('takePhoto')),
                subtitle: Text(loc.get('refSigFromCamera')),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickReferenceSignature(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final recProvider = context.watch<RecognitionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.get('signatureTitle'),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
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
            // ── Referans İmza Kartı ────────────────────────────────────────
            Card(
              color: theme.colorScheme.primaryContainer.withOpacity(0.4),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.draw_rounded,
                            color: theme.colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            loc.get('signatureReferenceLabel'),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _showRefPickerDialog,
                          icon: Icon(
                            recProvider.hasReferenceSignature
                                ? Icons.swap_horiz
                                : Icons.upload_file,
                            size: 18,
                          ),
                          label: Text(
                            recProvider.hasReferenceSignature
                                ? loc.get('refSigChange')
                                : loc.get('refSigUpload'),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                theme.colorScheme.outline.withOpacity(0.3)),
                      ),
                      child: recProvider.hasReferenceSignature
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Image.file(
                                recProvider.referenceSignature!,
                                fit: BoxFit.contain,
                                width: double.infinity,
                              ),
                            )
                          : InkWell(
                              onTap: _showRefPickerDialog,
                              borderRadius: BorderRadius.circular(12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined,
                                      size: 40,
                                      color: theme.colorScheme.outline),
                                  const SizedBox(height: 8),
                                  Text(
                                    loc.get('refSigTapToUpload'),
                                    style: TextStyle(
                                      color: theme.colorScheme.outline,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    if (recProvider.hasReferenceSignature) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle,
                              size: 14, color: Colors.green.shade700),
                          const SizedBox(width: 4),
                          Text(
                            loc.get('refSigStored'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Referans yoksa uyarı ───────────────────────────────────────
            if (!recProvider.hasReferenceSignature)
              Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: theme.colorScheme.onErrorContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          loc.get('refSigMissing'),
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn().slideY(begin: -0.2),

            if (!recProvider.hasReferenceSignature) const SizedBox(height: 16),

            // ── Test İmza Yükleme ──────────────────────────────────────────
            GestureDetector(
              onTap: () => _pickImage(ImageSource.gallery),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedImage != null
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withOpacity(0.4),
                    width: 2,
                  ),
                  color: theme.colorScheme.surfaceContainerHighest
                      .withOpacity(0.3),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.contain,
                          width: double.infinity,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.gesture_rounded,
                              size: 64, color: theme.colorScheme.outline),
                          const SizedBox(height: 12),
                          Text(
                            loc.get('signatureInstruction'),
                            style: TextStyle(
                                color: theme.colorScheme.outline,
                                fontSize: 14),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // Butonlar
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
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
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(loc.get('takePhoto')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Doğrula butonu
            if (_selectedImage != null) ...[
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.colorScheme.tertiary,
                  foregroundColor: theme.colorScheme.onTertiary,
                ),
                onPressed: _signatureState == SignatureState.processing
                    ? null
                    : _verifySignature,
                icon: _signatureState == SignatureState.processing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.fingerprint_rounded),
                label: Text(
                  _signatureState == SignatureState.processing
                      ? loc.get('signatureAnalyzing')
                      : loc.get('signatureVerify'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ).animate().fadeIn().slideY(begin: 0.3),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.refresh),
                label: Text(loc.get('reset')),
              ),
            ],

            const SizedBox(height: 8),

            // ── Sonuç Kartları ─────────────────────────────────────────────
            if (_signatureState == SignatureState.matched)
              Card(
                color: Colors.green.withOpacity(0.15),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.verified_rounded,
                          size: 56, color: Colors.green),
                      const SizedBox(height: 12),
                      Text(
                        loc.get('signatureMatch'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        loc.get('signatureMatchMsg'),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),

            if (_signatureState == SignatureState.noMatch)
              Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.gpp_bad_rounded,
                          size: 56,
                          color: theme.colorScheme.onErrorContainer),
                      const SizedBox(height: 12),
                      Text(
                        loc.get('signatureNoMatch'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        loc.get('signatureNoMatchMsg'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),

            if (_signatureState == SignatureState.error)
              _buildErrorCard(theme, loc),

            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        loc.get('signatureHint'),
                        style: theme.textTheme.bodySmall,
                      ),
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

  Widget _buildErrorCard(ThemeData theme, AppLocalizations loc) {
    String displayMsg;
    if (_errorMessage == 'API_KEY_MISSING') {
      displayMsg = loc.get('apiKeyMissing');
    } else if (_errorMessage == 'NO_REFERENCE') {
      displayMsg = loc.get('refSigMissing');
    } else if (_errorMessage == 'all_keys_exhausted') {
      displayMsg = loc.get('allKeysExhausted');
    } else if (_errorMessage.contains('503') ||
        _errorMessage.toLowerCase().contains('unavailable')) {
      displayMsg = loc.get('serverBusy');
    } else {
      displayMsg = _errorMessage;
    }

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
              child: Text(
                displayMsg,
                style:
                    TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
