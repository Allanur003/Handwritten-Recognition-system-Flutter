import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';

enum RecognitionLanguage { english, russian, turkmen }

enum RecognitionState { idle, processing, done, error }

class RecognitionProvider extends ChangeNotifier {
  RecognitionState _state = RecognitionState.idle;
  RecognitionLanguage _language = RecognitionLanguage.english;
  File? _selectedImage;
  String _recognizedText = '';
  String _errorMessage = '';
  String _apiKey = '';

  RecognitionState get state => _state;
  RecognitionLanguage get language => _language;
  File? get selectedImage => _selectedImage;
  String get recognizedText => _recognizedText;
  String get errorMessage => _errorMessage;
  String get apiKey => _apiKey;
  bool get hasApiKey => _apiKey.trim().isNotEmpty;

  final ImagePicker _picker = ImagePicker();

  void setApiKey(String key) {
    _apiKey = key.trim();
    notifyListeners();
  }

  void setLanguage(RecognitionLanguage lang) {
    _language = lang;
    if (_state == RecognitionState.done) {
      _state = RecognitionState.idle;
      _recognizedText = '';
    }
    notifyListeners();
  }

  String _buildPrompt() {
    final langName = switch (_language) {
      RecognitionLanguage.english => 'English',
      RecognitionLanguage.russian => 'Russian',
      RecognitionLanguage.turkmen => 'Turkmen',
    };

    return '''You are an expert handwriting recognition AI.
Your task: Extract ALL handwritten text from this image exactly as written.

Rules:
1. Output ONLY the recognized text — no explanations, no comments.
2. Preserve line breaks as they appear in the image.
3. The text is written in $langName. Use this to resolve ambiguous characters.
4. Include numbers, punctuation, and special characters as-is.
5. If you cannot read a word clearly, make your best guess based on context.
6. If there is NO text in the image, output only: [no text found]

Output the recognized text now:''';
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 100,
        maxWidth: 4096,
        maxHeight: 4096,
      );
      if (file != null) {
        _selectedImage = File(file.path);
        _recognizedText = '';
        _errorMessage = '';
        _state = RecognitionState.idle;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      _state = RecognitionState.error;
      notifyListeners();
    }
  }

  Future<void> recognizeText() async {
    if (_selectedImage == null) return;
    if (!hasApiKey) {
      _errorMessage = 'API_KEY_MISSING';
      _state = RecognitionState.error;
      notifyListeners();
      return;
    }

    _state = RecognitionState.processing;
    _recognizedText = '';
    notifyListeners();

    try {
      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: _apiKey,
      );

      // Read image bytes
      final imageBytes = await _selectedImage!.readAsBytes();
      final mimeType = _getMimeType(_selectedImage!.path);

      final prompt = _buildPrompt();

      final response = await model.generateContent([
        Content.multi([
          DataPart(mimeType, imageBytes),
          TextPart(prompt),
        ])
      ]);

      final text = response.text ?? '';

      if (text.trim().isEmpty || text.contains('[no text found]')) {
        _recognizedText = '';
      } else {
        _recognizedText = text.trim();
      }

      _state = RecognitionState.done;
    } on GenerativeAIException catch (e) {
      _errorMessage = 'Gemini error: ${e.message}';
      _state = RecognitionState.error;
    } catch (e) {
      _errorMessage = 'Error: $e';
      _state = RecognitionState.error;
    }

    notifyListeners();
  }

  String _getMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      _ => 'image/jpeg',
    };
  }

  void reset() {
    _selectedImage = null;
    _recognizedText = '';
    _errorMessage = '';
    _state = RecognitionState.idle;
    notifyListeners();
  }
}
