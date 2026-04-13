import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/localization/app_localizations.dart';
import 'core/theme/theme_provider.dart';
import 'features/recognition/recognition_provider.dart';
import 'features/recognition/recognition_screen.dart';
import 'features/signature/signature_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/history/history_provider.dart';
import 'features/history/history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final recProvider = RecognitionProvider();
  await recProvider.loadKeys();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider.value(value: recProvider),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();

    return MaterialApp(
      title: 'Handwriting Recognition',
      debugShowCheckedModeBanner: false,
      theme: ThemeProvider.lightTheme,
      darkTheme: ThemeProvider.darkTheme,
      themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
      locale: localeProvider.locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ru'),
        Locale('tk'),
      ],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const MainNavigation(),
      routes: {
        '/settings': (_) => const SettingsScreen(),
        '/history': (_) => const HistoryScreen(),
        '/signature': (_) => const SignatureScreen(),
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    final pages = [
      const RecognitionScreen(),
      const SignatureScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.text_fields_outlined),
            selectedIcon: const Icon(Icons.text_fields_rounded),
            label: loc.get('textTab'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.draw_outlined),
            selectedIcon: const Icon(Icons.draw_rounded),
            label: loc.get('signatureTab'),
          ),
        ],
      ),
    );
  }
}
