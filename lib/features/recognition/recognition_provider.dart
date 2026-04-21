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
  switch (_language) {
    case RecognitionLanguage.turkmen:
      return '''You are an expert in Turkmen language handwriting recognition.

CRITICAL: The text in this image is written in TURKMEN LANGUAGE (Türkmen dili).
- This is NOT Turkish, NOT Uzbek, NOT Azerbaijani, NOT any other language.
- This is specifically TURKMEN written in the LATIN script.

Turkmen Latin alphabet (all possible letters):
A, B, Ç, D, E, Ä, F, G, H, I, J, Ž, K, L, M, N, Ň, O, Ö, P, R, S, Ş, T, U, Ü, W, Y, Ý, Z
(lowercase: a, b, ç, d, e, ä, f, g, h, i, j, ž, k, l, m, n, ň, o, ö, p, r, s, ş, t, u, ü, w, y, ý, z)

Key Turkmen-specific characters to watch for:
- Ä/ä (not A/a) — open front vowel
- Ň/ň (not N/n) — nasal sound
- Ö/ö (not O/o) — front rounded vowel  
- Ş/ş (not S/s) — like English "sh"
- Ü/ü (not U/u) — front rounded vowel
- W/w (not V/v) — Turkmen uses W not V
- Ý/ý (not Y/y) — used in specific positions
- Ž/ž (not Z/z) — like French "j"
- Ç/ç (not C/c) — like English "ch"

Common Turkmen words for reference: 
salam, türkmen, döwlet, mekdep, okuw, kitap, adam, aýal, çaga

Rules:
1. Output ONLY the recognized Turkmen text — no explanations.
2. Preserve line breaks exactly as in the image.
3. Never substitute Turkmen letters with similar-looking letters from other languages.
4. If unsure between two letters, choose the one that makes sense in Turkmen.
5. If NO text visible: output [no text found]

Output the Turkmen text now:''';

    case RecognitionLanguage.russian:
      return '''You are an expert in Russian language handwriting recognition.

CRITICAL: The text in this image is written in RUSSIAN LANGUAGE using the CYRILLIC script.
- This is NOT Bulgarian, NOT Ukrainian, NOT Serbian — this is specifically RUSSIAN.
- Do NOT convert Cyrillic to Latin characters under any circumstances.

Russian Cyrillic alphabet:
А, Б, В, Г, Д, Е, Ё, Ж, З, И, Й, К, Л, М, Н, О, П, Р, С, Т, У, Ф, Х, Ц, Ч, Ш, Щ, Ъ, Ы, Ь, Э, Ю, Я

Common handwriting confusions to watch for:
- Т/т can look like Latin "T/t" — always use Cyrillic
- Р/р can look like Latin "P/p" — always use Cyrillic  
- С/с can look like Latin "C/c" — always use Cyrillic
- Н/н can look like Latin "H/h" — always use Cyrillic
- В/в can look like Latin "B/b" — always use Cyrillic

Rules:
1. Output ONLY the recognized Russian text in Cyrillic — no explanations.
2. Preserve line breaks exactly as in the image.
3. Never mix Latin and Cyrillic characters.
4. If NO text visible: output [no text found]

Output the Russian text now:''';

    case RecognitionLanguage.english:
      return '''You are an expert handwriting recognition system.

The text in this image is written in ENGLISH.

Rules:
1. Output ONLY the recognized English text — no explanations, no comments.
2. Preserve line breaks exactly as in the image.
3. Include numbers, punctuation, and special characters as-is.
4. If you cannot read a word clearly, make your best guess based on context.
5. If NO text visible: output [no text found]

Output the English text now:''';
  }
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
