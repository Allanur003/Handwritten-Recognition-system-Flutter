import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

enum RecognitionLanguage { english, turkish, russian, turkmen }

enum RecognitionState { idle, processing, done, error }

class RecognitionProvider extends ChangeNotifier {
  RecognitionState _state = RecognitionState.idle;
  RecognitionLanguage _language = RecognitionLanguage.english;
  File? _selectedImage;
  String _recognizedText = '';
  String _errorMessage = '';

  RecognitionState get state => _state;
  RecognitionLanguage get language => _language;
  File? get selectedImage => _selectedImage;
  String get recognizedText => _recognizedText;
  String get errorMessage => _errorMessage;

  final ImagePicker _picker = ImagePicker();

  void setLanguage(RecognitionLanguage lang) {
    _language = lang;
    // If we already have a result, reset it so user re-recognizes with new lang
    if (_state == RecognitionState.done) {
      _state = RecognitionState.idle;
      _recognizedText = '';
    }
    notifyListeners();
  }

  TextRecognizer _buildRecognizer() {
    switch (_language) {
      case RecognitionLanguage.russian:
        return TextRecognizer(script: TextRecognitionScript.cyrillic);
      case RecognitionLanguage.english:
      case RecognitionLanguage.turkish:
      case RecognitionLanguage.turkmen:
        return TextRecognizer(script: TextRecognitionScript.latin);
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

    _state = RecognitionState.processing;
    _recognizedText = '';
    notifyListeners();

    final recognizer = _buildRecognizer();
    try {
      final inputImage = InputImage.fromFile(_selectedImage!);
      final RecognizedText result = await recognizer.processImage(inputImage);

      // Sort blocks top-to-bottom for natural reading order
      final blocks = result.blocks.toList()
        ..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

      _recognizedText = blocks
          .map((block) => block.lines
              .map((line) => line.elements.map((e) => e.text).join(' '))
              .join('\n'))
          .join('\n\n')
          .trim();

      _state = RecognitionState.done;
    } catch (e) {
      _errorMessage = 'Recognition error: $e';
      _state = RecognitionState.error;
    } finally {
      await recognizer.close();
    }
    notifyListeners();
  }

  void reset() {
    _selectedImage = null;
    _recognizedText = '';
    _errorMessage = '';
    _state = RecognitionState.idle;
    notifyListeners();
  }
}
