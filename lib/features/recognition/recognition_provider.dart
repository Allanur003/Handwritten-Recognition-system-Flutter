import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum RecognitionLanguage { english, russian, turkmen }
enum RecognitionState { idle, processing, done, error }

class RecognitionProvider extends ChangeNotifier {
  RecognitionState _state = RecognitionState.idle;
  RecognitionLanguage _language = RecognitionLanguage.english;
  File? _selectedImage;
  String _recognizedText = '';
  String _errorMessage = '';

  // Max 2 key
  static const int maxKeys = 2;
  List<String> _apiKeys = [];
  int _currentKeyIndex = 0;

  RecognitionState get state => _state;
  RecognitionLanguage get language => _language;
  File? get selectedImage => _selectedImage;
  String get recognizedText => _recognizedText;
  String get errorMessage => _errorMessage;
  List<String> get apiKeys => List.unmodifiable(_apiKeys);
  bool get hasApiKey => _apiKeys.isNotEmpty;
  bool get canAddMoreKeys => _apiKeys.length < maxKeys;
  int get currentKeyIndex => _currentKeyIndex;

  final ImagePicker _picker = ImagePicker();

  // Uygulama başlayınca key'leri yükle
  Future<void> loadKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final key1 = prefs.getString('api_key_0') ?? '';
    final key2 = prefs.getString('api_key_1') ?? '';
    _apiKeys = [];
    if (key1.isNotEmpty) _apiKeys.add(key1);
    if (key2.isNotEmpty) _apiKeys.add(key2);
    _currentKeyIndex = 0;
    notifyListeners();
  }

  // Key kaydet (kalıcı)
  Future<void> addApiKey(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) return;
    if (_apiKeys.contains(trimmed)) return;
    if (_apiKeys.length >= maxKeys) return;

    _apiKeys.add(trimmed);

    // SharedPreferences'a kaydet
    final prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < _apiKeys.length; i++) {
      await prefs.setString('api_key_$i', _apiKeys[i]);
    }
    notifyListeners();
  }

  // Key sil (kalıcı)
  Future<void> removeApiKey(int index) async {
    _apiKeys.removeAt(index);
    if (_currentKeyIndex >= _apiKeys.length) {
      _currentKeyIndex = 0;
    }

    // SharedPreferences'ı güncelle
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('api_key_0');
    await prefs.remove('api_key_1');
    for (int i = 0; i < _apiKeys.length; i++) {
      await prefs.setString('api_key_$i', _apiKeys[i]);
    }
    notifyListeners();
  }

  bool _switchToNextKey() {
    if (_apiKeys.length <= 1) return false;
    _currentKeyIndex = (_currentKeyIndex + 1) % _apiKeys.length;
    notifyListeners();
    return true;
  }

  String get _activeKey => _apiKeys[_currentKeyIndex];

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
    return '''You are an expert handwriting recognition system.
Extract ALL handwritten text from this image exactly as written.

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

    int attempts = 0;
    while (attempts < _apiKeys.length) {
      try {
        final result = await _callApi(_activeKey);
        _recognizedText = result;
        _state = RecognitionState.done;
        notifyListeners();
        return;
      } on GenerativeAIException catch (e) {
        final msg = e.message.toLowerCase();
        final isRateLimit = msg.contains('429') ||
            msg.contains('rate') ||
            msg.contains('quota') ||
            msg.contains('limit') ||
            msg.contains('resource exhausted');

        if (isRateLimit && _switchToNextKey()) {
          attempts++;
          continue;
        } else {
          _errorMessage = _friendlyError(e.message);
          _state = RecognitionState.error;
          notifyListeners();
          return;
        }
      } catch (e) {
        _errorMessage = 'Error: $e';
        _state = RecognitionState.error;
        notifyListeners();
        return;
      }
    }

    _errorMessage = 'all_keys_exhausted';
    _state = RecognitionState.error;
    notifyListeners();
  }

  Future<String> _callApi(String apiKey) async {
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
    );
    final imageBytes = await _selectedImage!.readAsBytes();
    final mimeType = _getMimeType(_selectedImage!.path);
    final response = await model.generateContent([
      Content.multi([
        DataPart(mimeType, imageBytes),
        TextPart(_buildPrompt()),
      ])
    ]);
    final text = response.text ?? '';
    if (text.trim().isEmpty || text.contains('[no text found]')) return '';
    return text.trim();
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

  String _friendlyError(String msg) {
    if (msg.contains('API_KEY') || msg.contains('invalid')) return 'invalid_key';
    if (msg.contains('not found') || msg.contains('404')) return 'model_not_found';
    return msg;
  }

  void reset() {
    _selectedImage = null;
    _recognizedText = '';
    _errorMessage = '';
    _state = RecognitionState.idle;
    notifyListeners();
  }
}
