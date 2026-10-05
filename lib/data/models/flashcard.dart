import 'package:hive/hive.dart';
part 'flashcard.g.dart'; // ← must be here

@HiveType(typeId: 1)
class Flashcard extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String question;

  @HiveField(2)
  String answer;

  /// SM-2 algorithm fields
  @HiveField(3)
  int repetitions;

  @HiveField(4)
  double easeFactor;

  @HiveField(5)
  int intervalDays;

  @HiveField(6)
  DateTime dueDate;

  @HiveField(7)
  int lastQuality;

  Flashcard({
    required this.id,
    required this.question,
    required this.answer,
    this.repetitions = 0,
    this.easeFactor = 2.5,
    this.intervalDays = 0,
    DateTime? dueDate,
    this.lastQuality = 0,
  }) : dueDate = dueDate ?? DateTime.now();

  bool get isDue => DateTime.now().isAfter(dueDate);

  bool get isNew => repetitions == 0;

  bool get isMastered => repetitions >= 5 && easeFactor >= 2.5;

  Map<String, dynamic> toJson() => {
        'question': question,
        'answer': answer,
      };
}
