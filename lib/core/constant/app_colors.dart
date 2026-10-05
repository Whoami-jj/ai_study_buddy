import 'package:flutter/material.dart';

/// Raw colour values. Screens should not read these directly: use
/// `Theme.of(context).colorScheme` for the standard roles and
/// `context.palette` for the app-specific ones, so both light and dark mode
/// are handled in one place.
class AppColors {
  AppColors._();

  // Brand: a chalkboard green with a highlighter-yellow accent.
  static const board = Color(0xFF1F6F5C);
  static const boardDeep = Color(0xFF173B31);
  static const chalkMint = Color(0xFF6FD3B2);
  static const highlighter = Color(0xFFFFD84D);
  static const ink = Color(0xFF1C2321);

  // Light mode surfaces and text.
  static const bgLight = Color(0xFFF3F6F2);
  static const cardLight = Color(0xFFFFFFFF);
  static const lineLight = Color(0xFFE0E6E1);
  static const textLight = ink;
  static const mutedLight = Color(0xFF5E6B66);

  // Dark mode surfaces and text.
  static const bgDark = Color(0xFF0F1714);
  static const cardDark = Color(0xFF18231F);
  static const lineDark = Color(0xFF2A3A34);
  static const textDark = Color(0xFFEDF2EE);
  static const mutedDark = Color(0xFF9DB0A8);

  // How well a card was remembered.
  static const again = Color(0xFFD9534F);
  static const hard = Color(0xFFE0912F);
  static const good = Color(0xFF2E9E6E);
  static const easy = Color(0xFF2F8FBF);

  /// Colours used to tell decks apart. A deck's colour is picked from its
  /// id, so it stays the same without being stored.
  static const deckTints = <Color>[
    Color(0xFF1F6F5C),
    Color(0xFF2F8FBF),
    Color(0xFFB8632B),
    Color(0xFF7A5BB5),
    Color(0xFFC2456B),
    Color(0xFF5D7F2E),
  ];

  static Color deckTint(String deckId) =>
      deckTints[deckId.hashCode.abs() % deckTints.length];
}

/// App-specific colours that change between light and dark mode.
///
/// Read with `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  /// Hairlines and card outlines.
  final Color line;

  /// Secondary text.
  final Color muted;

  /// Background of the "today" card on the home screen.
  final Color board;

  /// Text and icons on [board].
  final Color onBoard;

  /// Highlighter yellow, for the things that need attention (cards due).
  final Color highlight;

  /// Text on [highlight].
  final Color onHighlight;

  /// Slightly tinted fill, for chips, icon backgrounds and read-only areas.
  final Color tint;

  final Color again;
  final Color hard;
  final Color good;
  final Color easy;

  const AppPalette({
    required this.line,
    required this.muted,
    required this.board,
    required this.onBoard,
    required this.highlight,
    required this.onHighlight,
    required this.tint,
    required this.again,
    required this.hard,
    required this.good,
    required this.easy,
  });

  static const light = AppPalette(
    line: AppColors.lineLight,
    muted: AppColors.mutedLight,
    board: AppColors.board,
    onBoard: Colors.white,
    highlight: AppColors.highlighter,
    onHighlight: AppColors.ink,
    tint: Color(0xFFE9EFEA),
    again: AppColors.again,
    hard: AppColors.hard,
    good: AppColors.good,
    easy: AppColors.easy,
  );

  static const dark = AppPalette(
    line: AppColors.lineDark,
    muted: AppColors.mutedDark,
    board: AppColors.boardDeep,
    onBoard: AppColors.textDark,
    highlight: AppColors.highlighter,
    onHighlight: AppColors.ink,
    tint: Color(0xFF1F2D28),
    again: Color(0xFFEF7D79),
    hard: Color(0xFFF0AC55),
    good: Color(0xFF5FCB9B),
    easy: Color(0xFF6DB9E0),
  );

  @override
  AppPalette copyWith({
    Color? line,
    Color? muted,
    Color? board,
    Color? onBoard,
    Color? highlight,
    Color? onHighlight,
    Color? tint,
    Color? again,
    Color? hard,
    Color? good,
    Color? easy,
  }) {
    return AppPalette(
      line: line ?? this.line,
      muted: muted ?? this.muted,
      board: board ?? this.board,
      onBoard: onBoard ?? this.onBoard,
      highlight: highlight ?? this.highlight,
      onHighlight: onHighlight ?? this.onHighlight,
      tint: tint ?? this.tint,
      again: again ?? this.again,
      hard: hard ?? this.hard,
      good: good ?? this.good,
      easy: easy ?? this.easy,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      line: Color.lerp(line, other.line, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      board: Color.lerp(board, other.board, t)!,
      onBoard: Color.lerp(onBoard, other.onBoard, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      onHighlight: Color.lerp(onHighlight, other.onHighlight, t)!,
      tint: Color.lerp(tint, other.tint, t)!,
      again: Color.lerp(again, other.again, t)!,
      hard: Color.lerp(hard, other.hard, t)!,
      good: Color.lerp(good, other.good, t)!,
      easy: Color.lerp(easy, other.easy, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  /// The app-specific colours for the current theme.
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
