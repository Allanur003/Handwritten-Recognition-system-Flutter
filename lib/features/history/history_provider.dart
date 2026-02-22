import 'package:flutter/material.dart';

class HistoryEntry {
  final String text;
  final String language;
  final DateTime createdAt;

  HistoryEntry({
    required this.text,
    required this.language,
    required this.createdAt,
  });
}

class HistoryProvider extends ChangeNotifier {
  final List<HistoryEntry> _entries = [];

  List<HistoryEntry> get entries => List.unmodifiable(_entries.reversed.toList());

  void addEntry(String text, String language) {
    _entries.add(HistoryEntry(
      text: text,
      language: language,
      createdAt: DateTime.now(),
    ));
    notifyListeners();
  }

  void removeAt(int index) {
    // index is from reversed list
    final realIndex = _entries.length - 1 - index;
    _entries.removeAt(realIndex);
    notifyListeners();
  }

  void clearAll() {
    _entries.clear();
    notifyListeners();
  }
}
