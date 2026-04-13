import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

enum RecognitionLanguage { english, russian, turkmen }
enum RecognitionState { idle, processing, done, error }

class RecognitionProvider extends ChangeNotifier {
  RecognitionState _state = RecognitionState.idle;
  RecognitionLanguage _language = RecognitionLanguage.english;
  File? _selectedImage;
  String _recognizedText = '';
  String _errorMessage = '';

  static const int maxKeys = 2;
  List<String> _apiKeys = [];
  int _currentKeyIndex = 0;

  // Kalıcı referans imza
  File? _referenceSignature;
  File? get referenceSignature => _referenceSignature;
  bool get hasReferenceSignature =>
      _referenceSignature != null && _referenceSignature!.existsSync();

  // Text için tek model (2.5-flash çalışıyor)
  static const String _textModel = 'gemini-2.5-flash';

  // Signature için fallback listesi — 2.5-flash 503 verebilir, en sona bırakıldı
  static const List<String> _signatureModels = [
    'gemini-2.0-flash',
    'gemini-1.5-flash',
    'gemini-2.5-flash',
  ];

  RecognitionState get state => _state;
  RecognitionLanguage get language => _language;
  File? get selectedImage => _selectedImage;
  String get recognizedText => _recognizedText;
  String get errorMessage => _errorMessage;
  List<String> get apiKeys => List.unmodifiable(_apiKeys);
  bool get hasApiKey => _apiKeys.isNotEmpty;
  bool get canAddMoreKeys => _apiKeys.length < maxKeys;
  int get currentKeyIndex => _currentKeyIndex;
  List<String> get signatureModels => List.unmodifiable(_signatureModels);

  final ImagePicker _picker = ImagePicker();

  Future<void> loadKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final key1 = prefs.getString('api_key_0') ?? '';
    final key2 = prefs.getString('api_key_1') ?? '';
    _apiKeys = [];
    if (key1.isNotEmpty) _apiKeys.add(key1);
    if (key2.isNotEmpty) _apiKeys.add(key2);
    _currentKeyIndex = 0;
    await _loadReferenceSignature();
    notifyListeners();
  }

  Future<void> _loadReferenceSignature() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final refFile = File('${dir.path}/reference_signature.png');
      if (refFile.existsSync()) {
        _referenceSignature = refFile;
      }
    } catch (_) {}
  }

  Future<void> saveReferenceSignature(File imageFile) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final refPath = '${dir.path}/reference_signature.png';
      await imageFile.copy(refPath);
      _referenceSignature = File(refPath);
      notifyListeners();
    } catch (e) {
      debugPrint('Referans imza kaydedilemedi: $e');
    }
  }

  Future<void> removeReferenceSignature() async {
    try {
      if (_referenceSignature != null && _referenceSignature!.existsSync()) {
        await _referenceSignature!.delete();
      }
      _referenceSignature = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Referans imza silinemedi: $e');
    }
  }

  Future<void> addApiKey(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) return;
    if (_apiKeys.contains(trimmed)) return;
    if (_apiKeys.length >= maxKeys) return;
    _apiKeys.add(trimmed);
    final prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < _apiKeys.length; i++) {
      await prefs.setString('api_key_$i', _apiKeys[i]);
    }
    notifyListeners();
  }

  Future<void> removeApiKey(int index) async {
    _apiKeys.removeAt(index);
    if (_currentKeyIndex >= _apiKeys.length) _currentKeyIndex = 0;
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
    final model = GenerativeModel(model: _textModel, apiKey: apiKey);
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

  // ── İmza karşılaştırma — model fallback ile ────────────────────────────────
  Future<String> callSignatureApi(
      String apiKey, String modelName, File testImage) async {
    if (_referenceSignature == null || !_referenceSignature!.existsSync()) {
      throw Exception('NO_REFERENCE');
    }

    final model = GenerativeModel(model: modelName, apiKey: apiKey);

    final refBytes = await _referenceSignature!.readAsBytes();
    final refMime = _getMimeType(_referenceSignature!.path);
    final testBytes = await testImage.readAsBytes();
    final testMime = _getMimeType(testImage.path);

    const prompt =
        '''You are an expert forensic signature verification specialist.

You are given TWO images:
- Image 1: The REFERENCE signature (the authentic, known signature)
- Image 2: The TEST signature (the signature to verify)

Your task: Compare both signatures and determine if they belong to the same person.

Analyze these characteristics:
1. Overall shape and flow of the signature
2. Stroke patterns, pressure points, and line thickness
3. Letter formations and connecting strokes
4. Angles and slant consistency
5. Starting and ending points
6. Unique personal flourishes or decorative elements
7. Proportions and spacing between elements

IMPORTANT: Real signatures from the same person will have slight natural variations but maintain consistent core characteristics. Do NOT require pixel-perfect matching.

Respond with ONLY one word:
- "MATCH" if the signatures appear to be from the same person (similar core characteristics)
- "NO_MATCH" if the signatures appear to be from different people or test image has no valid signature

Your answer:''';

    final response = await model.generateContent([
      Content.multi([
        DataPart(refMime, refBytes),
        DataPart(testMime, testBytes),
        TextPart(prompt),
      ])
    ]);

    return (response.text ?? '').trim().toUpperCase();
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
    if (msg.contains('503') || msg.contains('unavailable')) return 'server_busy';
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
