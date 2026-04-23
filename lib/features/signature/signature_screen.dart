import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

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

  static const String _ownerName = 'Hudaýgulyýew Şirli';

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

    setState(() => _signatureState = SignatureState.processing);

    try {
      final apiKey = recProvider.apiKeys[recProvider.currentKeyIndex];
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );

      final imageBytes = await _selectedImage!.readAsBytes();
      final ext = _selectedImage!.path.split('.').last.toLowerCase();
      final mimeType = (ext == 'png') ? 'image/png' : 'image/jpeg';

      const prompt = '''You are a signature verification expert.

Your task: Determine if the image contains a valid personal signature that matches this specific signature style:

The reference signature has these distinctive features:
1. Starts with a large "H" — two tall parallel vertical strokes connected by a horizontal crossbar in the middle, with a small dot above the left stroke
2. Followed by 3 flowing "u"-shaped humps (like "uuu") in cursive style going to the right
3. Ends with a long descending tail that curves down and forms a closed loop/spiral at the bottom

A signature MATCHES if:
- There is a large "H" shape at the start (two vertical lines with a crossbar)
- Followed by wave/hump strokes in cursive
- Has a long descending tail or loop at the end
- Overall looks like a personal cursive signature with these structural elements

It does NOT MATCH if:
- The image is blank or has no writing
- The writing is clearly printed/typed text (not a signature)
- There is no recognizable "H" shape at the beginning
- The signature style is completely different with no similar elements

Respond with ONLY one word:
- "MATCH" if it looks like a valid personal signature matching this style
- "NO_MATCH" if no matching signature is visible

Your answer:''';

      final response = await model.generateContent([
        Content.multi([
          DataPart(mimeType, imageBytes),
          TextPart(prompt),
        ])
      ]);

      final result = (response.text ?? '').trim().toUpperCase();

      setState(() {
        if (result.contains('MATCH') && !result.contains('NO_MATCH')) {
          _signatureState = SignatureState.matched;
        } else {
          _signatureState = SignatureState.noMatch;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _signatureState = SignatureState.error;
      });
    }
  }

  void _reset() {
    setState(() {
      _selectedImage = null;
      _signatureState = SignatureState.idle;
      _errorMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.get('signatureTitle'),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Reference card
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
                        Text(
                          loc.get('signatureReferenceLabel'),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                theme.colorScheme.outline.withOpacity(0.3)),
                      ),
                      child: Center(
                        child: CustomPaint(
                          size: const Size(280, 80),
                          painter: _SignaturePainter(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        _ownerName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color:
                              theme.colorScheme.onSurface.withOpacity(0.65),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Upload area
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
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
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

            // Buttons row
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

            // Verify button
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

            // Result cards
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
              Card(
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
                          _errorMessage == 'API_KEY_MISSING'
                              ? loc.get('apiKeyMissing')
                              : _errorMessage,
                          style: TextStyle(
                              color: theme.colorScheme.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

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
}

class _SignaturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A237E)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final w = size.width;
    final h = size.height;

    // --- Big "H" ---
    // Left vertical stroke of H (tall, slight curve at top)
    path.moveTo(w * 0.08, h * 0.75);
    path.cubicTo(w * 0.07, h * 0.55, w * 0.08, h * 0.30, w * 0.09, h * 0.18);

    // Right vertical stroke of H (parallel, same height)
    path.moveTo(w * 0.20, h * 0.18);
    path.cubicTo(w * 0.20, h * 0.30, w * 0.20, h * 0.55, w * 0.19, h * 0.75);

    // Horizontal crossbar of H (connecting at mid-height)
    path.moveTo(w * 0.09, h * 0.47);
    path.cubicTo(w * 0.12, h * 0.44, w * 0.17, h * 0.44, w * 0.20, h * 0.47);

    // --- "uuu" waves flowing right from H ---
    // Three humps: each is a small arch going up then back down
    path.moveTo(w * 0.20, h * 0.62);

    // hump 1
    path.cubicTo(w * 0.24, h * 0.38, w * 0.29, h * 0.38, w * 0.32, h * 0.62);
    // hump 2
    path.cubicTo(w * 0.36, h * 0.38, w * 0.41, h * 0.38, w * 0.44, h * 0.62);
    // hump 3
    path.cubicTo(w * 0.48, h * 0.38, w * 0.53, h * 0.38, w * 0.56, h * 0.62);

    // --- Long descending tail with loop at bottom ---
    // Flows down-right from the last hump, then curves into a loop
    path.cubicTo(w * 0.60, h * 0.75, w * 0.65, h * 0.85, w * 0.68, h * 0.95);
    path.cubicTo(w * 0.70, h * 1.05, w * 0.62, h * 1.08, w * 0.57, h * 1.00);
    path.cubicTo(w * 0.52, h * 0.92, w * 0.56, h * 0.82, w * 0.62, h * 0.82);

    canvas.drawPath(path, paint);

    // Dot above the "H" (like a tittle — matches the dot visible in the image)
    final dotPaint = Paint()
      ..color = const Color(0xFF1A237E)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.085, h * 0.10), 2.8, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
