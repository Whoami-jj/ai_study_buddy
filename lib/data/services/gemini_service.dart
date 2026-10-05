import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:uuid/uuid.dart';

import '../models/flashcard.dart';
import '../models/quiz_question.dart';

/// Thrown when the Gemini API key is missing, so the UI can show a clear
/// message instead of a generic failure.
class MissingApiKeyException implements Exception {
  @override
  String toString() =>
      'Gemini API key is missing. Add GEMINI_API_KEY to your .env file.';
}

class GeminiService {
  GenerativeModel? _cachedModel;
  final _uuid = const Uuid();

  /// The model is created the first time it is needed, not when the app
  /// starts. A missing API key then only affects deck generation, and the
  /// rest of the app (saved decks, reviews) keeps working.
  GenerativeModel get _model {
    final existing = _cachedModel;
    if (existing != null) return existing;

    String? apiKey;
    try {
      apiKey = dotenv.env['GEMINI_API_KEY'];
    } catch (_) {
      // dotenv was never loaded (no .env file).
      apiKey = null;
    }
    if (apiKey == null || apiKey.isEmpty) {
      throw MissingApiKeyException();
    }

    final model = GenerativeModel(
      model: 'gemini-3.8-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 8192,
        responseMimeType: 'application/json',
      ),
    );
    _cachedModel = model;
    return model;
  }

  /// Generates flashcards and quiz questions from raw study material.
  Future<({List<Flashcard> flashcards, List<QuizQuestion> quiz})>
      generateStudyMaterial(
    String sourceText, {
    String? deckTitle,
    int flashcardCount = 10,
    int quizCount = 5,
  }) async {
    final truncated = _truncate(sourceText, 15000);

    final prompt = '''
You are an expert tutor. Based on the study material below, generate:
1. $flashcardCount high-quality flashcards (question/answer pairs)
2. $quizCount multiple-choice quiz questions with 4 options each

Return ONLY valid JSON (no markdown, no explanation) in this exact shape:

{
  "flashcards": [
    { "question": "…", "answer": "…" }
  ],
  "quiz": [
    {
      "question": "…",
      "options": ["A", "B", "C", "D"],
      "correctIndex": 0,
      "explanation": "…"
    }
  ]
}

Study material:
"""
$truncated
"""
''';

    final response = await _model.generateContent([Content.text(prompt)]);
    final text = response.text;

    if (text == null || text.trim().isEmpty) {
      throw Exception('Empty response from Gemini');
    }

    final cleaned = _stripCodeFences(text);
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to parse AI response: $e');
    }

    final flashcards = ((json['flashcards'] as List?) ?? const [])
        .map((f) => Flashcard(
              id: _uuid.v4(),
              question: (f['question'] ?? '').toString(),
              answer: (f['answer'] ?? '').toString(),
            ))
        .where((f) => f.question.isNotEmpty && f.answer.isNotEmpty)
        .toList();

    final quiz = ((json['quiz'] as List?) ?? const [])
        .map((q) {
          final options = ((q['options'] as List?) ?? const [])
              .map((o) => o.toString())
              .toList();
          final correct = (q['correctIndex'] as num?)?.toInt() ?? 0;
          return QuizQuestion(
            id: _uuid.v4(),
            question: (q['question'] ?? '').toString(),
            options: options,
            // Keep the answer index inside the options, whatever the AI sent.
            correctIndex: options.isEmpty
                ? 0
                : correct.clamp(0, options.length - 1).toInt(),
            explanation: (q['explanation'] ?? '').toString(),
          );
        })
        .where((q) => q.question.isNotEmpty && q.options.length >= 2)
        .toList();

    if (flashcards.isEmpty && quiz.isEmpty) {
      throw Exception('AI did not return usable study material');
    }

    return (flashcards: flashcards, quiz: quiz);
  }

  String _truncate(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max)}\n[...truncated]';

  String _stripCodeFences(String s) {
    var t = s.trim();
    if (t.startsWith('```')) {
      t = t.replaceFirst(RegExp(r'^```[a-zA-Z]*\n?'), '');
      if (t.endsWith('```')) {
        t = t.substring(0, t.length - 3);
      }
    }
    return t.trim();
  }
}
