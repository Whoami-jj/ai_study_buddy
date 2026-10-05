import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_utils.dart';
import '../models/flashcard.dart';
import '../models/study_deck.dart';
import '../repositories/deck_repository.dart';
import 'gemini_service.dart';
import 'local_storage_service.dart';
import 'ocr_service.dart';
import 'pdf_service.dart';

final localStorageProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

final ocrServiceProvider = Provider<OcrService>((ref) {
  final s = OcrService();
  ref.onDispose(s.dispose);
  return s;
});

final pdfServiceProvider = Provider<PdfService>((ref) {
  return PdfService();
});

final deckRepositoryProvider = Provider<DeckRepository>((ref) {
  return DeckRepository(
    ref.watch(localStorageProvider),
    ref.watch(geminiServiceProvider),
  );
});

// ── Settings ────────────────────────────────────────────────

class AppSettings {
  final ThemeMode themeMode;

  /// Cards the user aims to review each day.
  final int dailyGoal;

  const AppSettings({required this.themeMode, required this.dailyGoal});

  AppSettings copyWith({ThemeMode? themeMode, int? dailyGoal}) => AppSettings(
        themeMode: themeMode ?? this.themeMode,
        dailyGoal: dailyGoal ?? this.dailyGoal,
      );
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>(
  (ref) => SettingsNotifier(ref.watch(localStorageProvider)),
);

class SettingsNotifier extends StateNotifier<AppSettings> {
  final LocalStorageService _storage;

  SettingsNotifier(this._storage)
      : super(AppSettings(
          themeMode: _parseThemeMode(_storage.themeMode),
          dailyGoal: _storage.dailyGoal,
        ));

  static ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _storage.setThemeMode(mode.name);
  }

  Future<void> setDailyGoal(int goal) async {
    state = state.copyWith(dailyGoal: goal);
    await _storage.setDailyGoal(goal);
  }
}

// ── Study activity ──────────────────────────────────────────

class DayActivity {
  final DateTime day;
  final int reviews;
  const DayActivity(this.day, this.reviews);
}

class StudyStats {
  final int reviewedToday;

  /// Days in a row with at least one review.
  final int streak;

  /// The last seven days, oldest first, ending today.
  final List<DayActivity> week;

  const StudyStats({
    required this.reviewedToday,
    required this.streak,
    required this.week,
  });
}

final studyStatsProvider =
    StateNotifierProvider<StudyStatsNotifier, StudyStats>(
  (ref) => StudyStatsNotifier(ref.watch(localStorageProvider)),
);

class StudyStatsNotifier extends StateNotifier<StudyStats> {
  final LocalStorageService _storage;

  StudyStatsNotifier(this._storage) : super(_read(_storage));

  static StudyStats _read(LocalStorageService storage) {
    final today = AppDateUtils.dateOnly(DateTime.now());
    final week = [
      for (int i = 6; i >= 0; i--)
        DayActivity(
          today.subtract(Duration(days: i)),
          storage.reviewsOn(today.subtract(Duration(days: i))),
        ),
    ];
    return StudyStats(
      reviewedToday: storage.reviewsOn(today),
      streak: storage.currentStreak,
      week: week,
    );
  }

  void refresh() => state = _read(_storage);

  Future<void> clear() async {
    await _storage.clearActivity();
    refresh();
  }
}

// ── Decks ───────────────────────────────────────────────────

/// All decks — refreshed whenever one is saved.
final decksProvider = StateNotifierProvider<DecksNotifier, List<StudyDeck>>(
  (ref) => DecksNotifier(ref.watch(deckRepositoryProvider), ref),
);

class DecksNotifier extends StateNotifier<List<StudyDeck>> {
  final DeckRepository _repo;
  final Ref _ref;

  DecksNotifier(this._repo, this._ref) : super(_repo.getAllDecks());

  /// Read-only view of the current decks.
  List<StudyDeck> get decks => state;

  /// Safely fetch a single deck by ID.
  StudyDeck? deckById(String id) {
    try {
      return state.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  void refresh() => state = _repo.getAllDecks();

  Future<void> deleteDeck(String id) async {
    await _repo.deleteDeck(id);
    refresh();
  }

  Future<void> deleteAllDecks() async {
    await _repo.deleteAllDecks();
    refresh();
  }

  Future<void> renameDeck(StudyDeck deck, String title) async {
    await _repo.renameDeck(deck, title);
    refresh();
  }

  Future<void> addCard(StudyDeck deck, String question, String answer) async {
    await _repo.addCard(deck, question, answer);
    refresh();
  }

  Future<void> updateCard(
    StudyDeck deck,
    Flashcard card,
    String question,
    String answer,
  ) async {
    await _repo.updateCard(deck, card, question, answer);
    refresh();
  }

  Future<void> deleteCard(StudyDeck deck, Flashcard card) async {
    await _repo.deleteCard(deck, card);
    refresh();
  }

  Future<void> resetProgress(StudyDeck deck) async {
    await _repo.resetProgress(deck);
    refresh();
  }

  Future<void> reviewCard(StudyDeck deck, Flashcard card, int quality) async {
    await _repo.reviewCard(deck, card, quality);
    refresh();
    // Today's count and the streak changed too.
    _ref.read(studyStatsProvider.notifier).refresh();
  }
}
