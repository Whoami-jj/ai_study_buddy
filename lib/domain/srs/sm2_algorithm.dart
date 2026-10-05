import '../../data/models/flashcard.dart';

class SM2Algorithm {
  SM2Algorithm._();

  static Flashcard schedule(Flashcard card, int quality) {
    assert(quality >= 0 && quality <= 5, 'Quality must be 0–5');

    int repetitions = card.repetitions;
    double easeFactor = card.easeFactor;
    int intervalDays = card.intervalDays;

    if (quality < 3) {
      // Failed — restart
      repetitions = 0;
      intervalDays = 1;
    } else {
      // Passed
      if (repetitions == 0) {
        intervalDays = 1;
      } else if (repetitions == 1) {
        intervalDays = 6;
      } else {
        intervalDays = (intervalDays * easeFactor).round();
      }
      repetitions += 1;
    }

    // Update ease factor
    easeFactor =
        easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    if (easeFactor < 1.3) easeFactor = 1.3;

    card.repetitions = repetitions;
    card.easeFactor = easeFactor;
    card.intervalDays = intervalDays;
    card.dueDate = DateTime.now().add(Duration(days: intervalDays));
    card.lastQuality = quality;

    return card;
  }
}
