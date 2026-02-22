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
      'copied': 'Copied to clipboard!',
      'noText': 'No text found. Try a clearer image.',
      'processing': 'Processing...',
      'history': 'History',
      'settings': 'Settings',
      'darkMode': 'Dark Mode',
      'appLanguage': 'App Language',
      'recognitionLang': 'Recognition Language',
      'english': 'English',
      'turkish': 'Turkish',
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
      'selectImage': 'Please select an image first',
    },
    'tr': {
      'appTitle': 'El Yazısı Tanıma',
      'selectRecogLang': 'Tanıma Dili',
      'pickImage': 'Galeri',
      'takePhoto': 'Kamera',
      'recognize': 'Metni Tanı',
      'result': 'Tanınan Metin',
      'copy': 'Kopyala',
      'share': 'Paylaş',
      'copied': 'Panoya kopyalandı!',
      'noText': 'Metin bulunamadı. Daha net bir resim deneyin.',
      'processing': 'İşleniyor...',
      'history': 'Geçmiş',
      'settings': 'Ayarlar',
      'darkMode': 'Karanlık Mod',
      'appLanguage': 'Uygulama Dili',
      'recognitionLang': 'Tanıma Dili',
      'english': 'İngilizce',
      'turkish': 'Türkçe',
      'russian': 'Rusça',
      'turkmen': 'Türkmence',
      'tapToSelect': 'Resim seçmek için dokun',
      'clearHistory': 'Geçmişi Temizle',
      'noHistory': 'Henüz geçmiş yok',
      'tips': 'Daha iyi sonuç için ipuçları',
      'tip1': 'İyi aydınlatma kullanın',
      'tip2': 'Beyaz kağıtta düzgün yazın',
      'tip3': 'Kamerayı sabit tutun',
      'reset': 'Sıfırla',
      'selectImage': 'Lütfen önce bir resim seçin',
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
      'processing': 'Обработка...',
      'history': 'История',
      'settings': 'Настройки',
      'darkMode': 'Тёмная тема',
      'appLanguage': 'Язык приложения',
      'recognitionLang': 'Язык распознавания',
      'english': 'Английский',
      'turkish': 'Турецкий',
      'russian': 'Русский',
      'turkmen': 'Туркменский',
      'tapToSelect': 'Нажмите для выбора фото',
      'clearHistory': 'Очистить историю',
      'noHistory': 'История пуста',
      'tips': 'Советы для лучшего результата',
      'tip1': 'Используйте хорошее освещение',
      'tip2': 'Пишите чётко на белой бумаге',
      'tip3': 'Держите камеру ровно',
      'reset': 'Сброс',
      'selectImage': 'Сначала выберите изображение',
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
      ['en', 'tr', 'ru'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate old) => false;
}
