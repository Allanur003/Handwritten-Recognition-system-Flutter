import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }
}

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const Map<String, Map<String, String>> _strings = {
    'en': {
      'appTitle': 'Handwriting Recognition',
      'selectRecogLang': 'Recognition Language',
      'pickImage': 'Gallery',
      'takePhoto': 'Camera',
      'recognize': 'Recognize Text',
      'result': 'Recognized Text',
      'copy': 'Copy',
      'share': 'Share',
      'copied': 'Copied!',
      'noText': 'No text found. Try a clearer image.',
      'processing': 'Analyzing...',
      'history': 'History',
      'settings': 'Settings',
      'darkMode': 'Dark Mode',
      'appLanguage': 'App Language',
      'english': 'English',
      'russian': 'Russian',
      'turkmen': 'Turkmen',
      'tapToSelect': 'Tap to select an image',
      'clearHistory': 'Clear History',
      'noHistory': 'No history yet',
      'tips': 'Tips for better results',
      'tip1': 'Use good lighting',
      'tip2': 'Write clearly on white paper',
      'tip3': 'Keep camera steady',
      'reset': 'Reset',
      'apiKeyMissing': 'Gemini API key not set! Go to Settings.',
      'apiKeyHint': 'Enter your Gemini API Key',
      'apiKeySave': 'Save',
      'apiKeyTitle': 'Gemini API Key',
      'apiKeyInfo': 'Get your free key from aistudio.google.com',
      
    },
    'ru': {
      'appTitle': 'Распознавание почерка',
      'selectRecogLang': 'Язык распознавания',
      'pickImage': 'Галерея',
      'takePhoto': 'Камера',
      'recognize': 'Распознать',
      'result': 'Распознанный текст',
      'copy': 'Копировать',
      'share': 'Поделиться',
      'copied': 'Скопировано!',
      'noText': 'Текст не найден. Попробуйте более чёткое фото.',
      'processing': 'Анализируется...',
      'history': 'История',
      'settings': 'Настройки',
      'darkMode': 'Тёмная тема',
      'appLanguage': 'Язык приложения',
      'english': 'Английский',
      'russian': 'Русский',
      'turkmen': 'Туркменский',
      'tapToSelect': 'Нажмите для выбора фото',
      'clearHistory': 'Очистить историю',
      'noHistory': 'История пуста',
      'tips': 'Советы',
      'tip1': 'Используйте хорошее освещение',
      'tip2': 'Пишите чётко на белой бумаге',
      'tip3': 'Держите камеру ровно',
      'reset': 'Сброс',
      'apiKeyMissing': 'API ключ не задан! Перейдите в настройки.',
      'apiKeyHint': 'Введите Gemini API ключ',
      'apiKeySave': 'Сохранить',
      'apiKeyTitle': 'Gemini API Ключ',
      'apiKeyInfo': 'Бесплатный ключ: aistudio.google.com',
      
    },
    'tk': {
      'appTitle': 'El ýazgy tanamak',
      'selectRecogLang': 'Tanamak dili',
      'pickImage': 'Galereýa',
      'takePhoto': 'Kamera',
      'recognize': 'Teksti tanama',
      'result': 'Tanalanan tekst',
      'copy': 'Göçür',
      'share': 'Paýlaş',
      'copied': 'Göçürildi!',
      'noText': 'Tekst tapylmady. Has aýdyň surat synap görüň.',
      'processing': 'Derňelýär...',
      'history': 'Taryh',
      'settings': 'Sazlamalar',
      'darkMode': 'Garaňky tertip',
      'appLanguage': 'Programma dili',
      'english': 'Iňlisçe',
      'russian': 'Rusça',
      'turkmen': 'Türkmençe',
      'tapToSelect': 'Surat saýlamak üçin basyň',
      'clearHistory': 'Taryhy arassala',
      'noHistory': 'Taryh ýok',
      'tips': 'Maslahatlar',
      'tip1': 'Gowy yşyklandyrma ulanyň',
      'tip2': 'Ak kagyzda aýdyň ýazyň',
      'tip3': 'Kamerary durnukly saklaň',
      'reset': 'Täzele',
      'apiKeyMissing': 'API açary ýok! Sazlamalara geçiň.',
      'apiKeyHint': 'Gemini API açaryny giriziň',
      'apiKeySave': 'Sakla',
      'apiKeyTitle': 'Gemini API Açary',
      'apiKeyInfo': 'Mugt açar: aistudio.google.com',
      
    },
  };

  String get(String key) {
    return _strings[locale.languageCode]?[key] ?? _strings['en']![key] ?? key;
  }
}

class AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'ru', 'tk'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate old) => false;
}
