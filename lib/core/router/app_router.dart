import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/create_deck/create_deck_screen.dart';
import '../../features/deck_detail/deck_detail_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/review/review_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/splash/splash_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: '/create',
        builder: (_, __) => const CreateDeckScreen(),
      ),
      GoRoute(
        path: '/deck/:id',
        builder: (_, state) =>
            DeckDetailScreen(deckId: state.pathParameters['id']!),
      ),
      // Review the cards that are due in one deck.
      GoRoute(
        path: '/review/:id',
        builder: (_, state) =>
            ReviewScreen(deckId: state.pathParameters['id']!),
      ),
      // Review everything that is due, across all decks.
      GoRoute(
        path: '/review-all',
        builder: (_, __) => const ReviewScreen(),
      ),
      // Go through every card in a deck without changing its schedule.
      GoRoute(
        path: '/practice/:id',
        builder: (_, state) => ReviewScreen(
          deckId: state.pathParameters['id']!,
          practice: true,
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, __) => const SettingsScreen(),
      ),
    ],
  );
});
