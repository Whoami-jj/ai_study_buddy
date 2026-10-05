import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'data/models/flashcard.dart';
import 'data/models/quiz_question.dart';
import 'data/models/study_deck.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // A missing .env file should not stop the app from opening. Saved decks
  // and reviews work without it; only AI generation needs the key, and it
  // reports the problem when used.
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Could not load .env: $e');
  }

  // Init Hive
  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(StudyDeckAdapter());
  Hive.registerAdapter(FlashcardAdapter());
  Hive.registerAdapter(QuizQuestionAdapter());

  // Open boxes
  await Hive.openBox<StudyDeck>('decks');
  await Hive.openBox('settings');

  runApp(const ProviderScope(child: StudyBuddyApp()));
}
