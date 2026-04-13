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
      'copyAll': 'Copy All',
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
      'signatureTitle': 'Signature Recognition',
      'signatureTab': 'Signature',
      'textTab': 'Text',
      'signatureInstruction': 'Upload a photo of your signature',
      'signatureVerify': 'Verify Signature',
      'signatureMatch': 'Signature Verified ✓',
      'signatureMatchMsg': 'Hudaýgulyýew Şirli',
      'signatureNoMatch': 'Signature Not Recognized',
      'signatureNoMatchMsg': 'This signature does not match or is unreadable. Please try a clearer photo.',
      'signatureAnalyzing': 'Analyzing signature...',
      'signatureHint': 'Place your signature clearly on white paper',
      'signatureReferenceLabel': 'Reference Signature',
      'appearance': 'Appearance',
      'about': 'About',
      'keyDelete': 'Delete Key',
      'keyDeleteConfirm': 'Are you sure you want to delete this key?',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'keyActive': 'Active',
      'keyWaiting': 'Waiting',
      'keyAddFirst': 'Add API Key (1/2)',
      'keyAddSecond': 'Add Second API Key (2/2)',
      'keyBothAdded': 'Both keys added. You can recognize up to 40 images per day.',
      'keyInfoTip': 'You can add up to 2 keys. If one is exhausted, it switches to the other automatically.',
    },
    'ru': {
      'appTitle': 'Распознавание почерка',
      'selectRecogLang': 'Язык распознавания',
      'pickImage': 'Галерея',
      'takePhoto': 'Камера',
      'recognize': 'Распознать',
      'result': 'Распознанный текст',
      'copy': 'Копировать',
      'copyAll': 'Копировать всё',
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
      'signatureTitle': 'Распознавание подписи',
      'signatureTab': 'Подпись',
      'textTab': 'Текст',
      'signatureInstruction': 'Загрузите фото вашей подписи',
      'signatureVerify': 'Проверить подпись',
      'signatureMatch': 'Подпись подтверждена ✓',
      'signatureMatchMsg': 'Hudaýgulyýew Şirli',
      'signatureNoMatch': 'Подпись не распознана',
      'signatureNoMatchMsg': 'Эта подпись не совпадает или нечёткая. Попробуйте более чёткое фото.',
      'signatureAnalyzing': 'Анализ подписи...',
      'signatureHint': 'Положите подпись на белую бумагу чётко',
      'signatureReferenceLabel': 'Эталонная подпись',
      'appearance': 'Внешний вид',
      'about': 'О приложении',
      'keyDelete': 'Удалить ключ',
      'keyDeleteConfirm': 'Вы уверены, что хотите удалить этот ключ?',
      'cancel': 'Отмена',
      'delete': 'Удалить',
      'keyActive': '✅ Активен',
      'keyWaiting': '⏳ Ожидает',
      'keyAddFirst': 'Добавить API ключ (1/2)',
      'keyAddSecond': 'Добавить второй API ключ (2/2)',
      'keyBothAdded': 'Оба ключа добавлены. Можно распознавать до 40 изображений в день.',
      'keyInfoTip': 'Можно добавить до 2 ключей. Если один исчерпан, автоматически переключится на другой.',
    },
    'tk': {
      'appTitle': 'El ýazgy tanamak',
      'selectRecogLang': 'Tanamak dili',
      'pickImage': 'Galereýa',
      'takePhoto': 'Kamera',
      'recognize': 'Teksti tanama',
      'result': 'Tanalanan tekst',
      'copy': 'Göçür',
      'copyAll': 'Hemmesini göçür',
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
      'signatureTitle': 'Gol tanamak',
      'signatureTab': 'Gol',
      'textTab': 'Tekst',
      'signatureInstruction': 'Golyňyzyň suratyny ýükläň',
      'signatureVerify': 'Goly barla',
      'signatureMatch': 'Gol tassyklandy ✓',
      'signatureMatchMsg': 'Hudaýgulyýew Şirli',
      'signatureNoMatch': 'Gol tanalmady',
      'signatureNoMatchMsg': 'Bu gol gabat gelmeýär ýa-da okalmaýar. Has aýdyň surat synap görüň.',
      'signatureAnalyzing': 'Gol derňelýär...',
      'signatureHint': 'Golyňyzy ak kagyzda aýdyň çekiň',
      'signatureReferenceLabel': 'Nusgalyk gol',
      'appearance': 'Görnüş',
      'about': 'Programma barada',
      'keyDelete': 'Açary poz',
      'keyDeleteConfirm': 'Bu açary pozmak isleýärsiňizmi?',
      'cancel': 'Goýbolsun',
      'delete': 'Poz',
      'keyActive': '✅ Işjeň',
      'keyWaiting': '⏳ Garaşýar',
      'keyAddFirst': 'API açary goş (1/2)',
      'keyAddSecond': 'Ikinji API açary goş (2/2)',
      'keyBothAdded': 'Iki açar hem goşuldy. Günde jemi 40 surat tanadyp bilersiň.',
      'keyInfoTip': 'Iň köp 2 açar goşup bilersiň. Biri dolsa awtomatik beýlekisine geçer.',
    },
  };

  String get(String key) {
    if (_strings[locale.languageCode]?.containsKey(key) ?? false) {
      return _strings[locale.languageCode]![key]!;
    }
    if (_strings['en']!.containsKey(key)) {
      return _strings['en']![key]!;
    }
    return key;
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
