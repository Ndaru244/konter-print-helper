import 'package:shared_preferences/shared_preferences.dart';

class OcrBlocklistStore {
  static const prefsKey = 'ocr_blocked_phrases';

  static String normalize(String phrase) => phrase.toLowerCase().trim();

  Future<Set<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(prefsKey) ?? const <String>[];
    return stored.map(normalize).where((e) => e.isNotEmpty).toSet();
  }

  Future<void> save(Set<String> phrases) async {
    final prefs = await SharedPreferences.getInstance();
    final cleaned = phrases.map(normalize).where((e) => e.isNotEmpty).toList()
      ..sort();
    await prefs.setStringList(prefsKey, cleaned);
  }
}
