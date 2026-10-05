import 'package:hive/hive.dart';
import 'flashcard.dart';
import 'quiz_question.dart';
part 'study_deck.g.dart';

@HiveType(typeId: 0)
class StudyDeck extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  List<Flashcard> flashcards;

  @HiveField(3)
  List<QuizQuestion> quizQuestions;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime lastReviewedAt;

  @HiveField(6)
  int totalReviews;

  @HiveField(7)
  int correctAnswers;

  StudyDeck({
    required this.id,
    required this.title,
    this.flashcards = const [],
    this.quizQuestions = const [],
    required this.createdAt,
    DateTime? lastReviewedAt,
    this.totalReviews = 0,
    this.correctAnswers = 0,
  }) : lastReviewedAt = lastReviewedAt ?? createdAt;

  double get accuracy => totalReviews == 0 ? 0 : correctAnswers / totalReviews;

  int get dueCards => flashcards.where((f) => f.isDue).length;

  int get masteredCards => flashcards.where((f) => f.repetitions >= 5).length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'flashcards': flashcards.map((f) => f.toJson()).toList(),
        'quizQuestions': quizQuestions.map((q) => q.toJson()).toList(),
      };
}
