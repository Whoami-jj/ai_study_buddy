import 'package:hive/hive.dart';

import '../../core/utils/date_utils.dart';
import '../models/study_deck.dart';

class LocalStorageService {
  static const _decksBox = 'decks';
  static const _settingsBox = 'settings';

  static const _themeModeKey = 'themeMode';
  static const _dailyGoalKey = 'dailyGoal';
  static const _reviewsPrefix = 'reviews_';

  Box<StudyDeck> get _decks => Hive.box<StudyDeck>(_decksBox);
  Box get _settings => Hive.box(_settingsBox);

  // ── Decks ────────────────────────────────────────────────
  List<StudyDeck> getAllDecks() {
    return _decks.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  StudyDeck? getDeck(String id) {
    try {
      return _decks.values.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveDeck(StudyDeck deck) async {
    await _decks.put(deck.id, deck);
  }

  Future<void> deleteDeck(String id) async {
    await _decks.delete(id);
  }

  Future<void> deleteAllDecks() async {
    await _decks.clear();
  }

  // ── Settings ────────────────────────────────────────────

  /// 'system', 'light' or 'dark'.
  ///
  /// Falls back to the older `isDarkMode` flag if it was ever set, so an
  /// existing choice is kept.
  String get themeMode {
    final stored = _settings.get(_themeModeKey);
    if (stored is String) return stored;
    final legacyDark = _settings.get('isDarkMode');
    if (legacyDark == true) return 'dark';
    return 'system';
  }

  Future<void> setThemeMode(String value) async {
    await _settings.put(_themeModeKey, value);
  }

  bool get isDarkMode => themeMode == 'dark';

  Future<void> setDarkMode(bool value) =>
      setThemeMode(value ? 'dark' : 'light');

  int get dailyGoal => _settings.get(_dailyGoalKey, defaultValue: 20) as int;

  Future<void> setDailyGoal(int value) async {
    await _settings.put(_dailyGoalKey, value);
  }

  // ── Study activity ──────────────────────────────────────
  // One counter per calendar day, kept in the settings box, so no change to
  // the saved deck format is needed.

  /// Cards reviewed on [day].
  int reviewsOn(DateTime day) {
    final value = _settings.get('$_reviewsPrefix${AppDateUtils.dayKey(day)}');
    return value is int ? value : 0;
  }

  /// Adds one review to today's count.
  Future<void> recordReview() async {
    final key = '$_reviewsPrefix${AppDateUtils.dayKey(DateTime.now())}';
    final current = _settings.get(key);
    await _settings.put(key, (current is int ? current : 0) + 1);
  }

  /// Days in a row with at least one review. A streak is still alive if
  /// today has no reviews yet but yesterday did.
  int get currentStreak {
    final today = AppDateUtils.dateOnly(DateTime.now());
    var day =
        reviewsOn(today) > 0 ? today : today.subtract(const Duration(days: 1));
    var streak = 0;
    while (reviewsOn(day) > 0) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Removes every saved daily review count.
  Future<void> clearActivity() async {
    final keys = _settings.keys
        .where((k) => k is String && k.startsWith(_reviewsPrefix))
        .toList();
    await _settings.deleteAll(keys);
  }
}
