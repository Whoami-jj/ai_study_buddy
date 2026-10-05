import 'package:hive/hive.dart';
part 'quiz_question.g.dart'; // ← must be here

@HiveType(typeId: 2)
class QuizQuestion extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String question;

  @HiveField(2)
  List<String> options;

  @HiveField(3)
  int correctIndex;

  @HiveField(4)
  String explanation;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explanation = '',
  });

  Map<String, dynamic> toJson() => {
        'question': question,
        'options': options,
        'correctIndex': correctIndex,
        'explanation': explanation,
      };
}
