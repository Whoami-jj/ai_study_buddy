import 'package:uuid/uuid.dart';

import '../../domain/srs/sm2_algorithm.dart';
import '../models/flashcard.dart';
import '../models/study_deck.dart';
import '../services/gemini_service.dart';
import '../services/local_storage_service.dart';

class DeckRepository {
  final LocalStorageService _storage;
  final GeminiService _gemini;
  final _uuid = const Uuid();

  DeckRepository(this._storage, this._gemini);

  List<StudyDeck> getAllDecks() => _storage.getAllDecks();

  StudyDeck? getDeck(String id) => _storage.getDeck(id);

  Future<StudyDeck> createDeckFromText({
    required String title,
    required String sourceText,
    int flashcardCount = 10,
    int quizCount = 5,
  }) async {
    final result = await _gemini.generateStudyMaterial(
      sourceText,
      deckTitle: title,
      flashcardCount: flashcardCount,
      quizCount: quizCount,
    );

    final deck = StudyDeck(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      flashcards: result.flashcards,
      quizQuestions: result.quiz,
      createdAt: DateTime.now(),
    );

    await _storage.saveDeck(deck);
    return deck;
  }

  Future<void> updateDeck(StudyDeck deck) => _storage.saveDeck(deck);

  Future<void> deleteDeck(String id) => _storage.deleteDeck(id);

  Future<void> deleteAllDecks() => _storage.deleteAllDecks();

  Future<void> renameDeck(StudyDeck deck, String title) async {
    deck.title = title;
    await _storage.saveDeck(deck);
  }

  // The card list is replaced with a new list on every change. A deck's
  // list can be unmodifiable (the model's default is a const list), so it
  // is never edited in place.

  Future<void> addCard(StudyDeck deck, String question, String answer) async {
    deck.flashcards = [
      ...deck.flashcards,
      Flashcard(id: _uuid.v4(), question: question, answer: answer),
    ];
    await _storage.saveDeck(deck);
  }

  Future<void> updateCard(
    StudyDeck deck,
    Flashcard card,
    String question,
    String answer,
  ) async {
    card.question = question;
    card.answer = answer;
    await _storage.saveDeck(deck);
  }

  Future<void> deleteCard(StudyDeck deck, Flashcard card) async {
    deck.flashcards = deck.flashcards.where((c) => c.id != card.id).toList();
    await _storage.saveDeck(deck);
  }

  /// Puts every card back to "new" and clears the deck's review totals.
  Future<void> resetProgress(StudyDeck deck) async {
    for (final card in deck.flashcards) {
      card.repetitions = 0;
      card.easeFactor = 2.5;
      card.intervalDays = 0;
      card.dueDate = DateTime.now();
      card.lastQuality = 0;
    }
    deck.totalReviews = 0;
    deck.correctAnswers = 0;
    await _storage.saveDeck(deck);
  }

  /// Schedules a single flashcard after a review.
  Future<void> reviewCard(StudyDeck deck, Flashcard card, int quality) async {
    SM2Algorithm.schedule(card, quality);
    deck.totalReviews += 1;
    if (quality >= 3) deck.correctAnswers += 1;
    deck.lastReviewedAt = DateTime.now();
    await _storage.saveDeck(deck);
    await _storage.recordReview();
  }
}
