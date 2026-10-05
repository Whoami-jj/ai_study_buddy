import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constant/app_colors.dart';
import '../constant/app_sizes.dart';

/// Light and dark themes, built from the same recipe so they stay in step.
///
/// Type: Lexend for headings and buttons, Atkinson Hyperlegible for body
/// text. Both were designed for easy reading, which suits a study app.
class AppTheme {
  AppTheme._();

  static final light = _build(Brightness.light);
  static final dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;

    final primary = isDark ? AppColors.chalkMint : AppColors.board;
    final onPrimary = isDark ? AppColors.ink : Colors.white;
    final bg = isDark ? AppColors.bgDark : AppColors.bgLight;
    final card = isDark ? AppColors.cardDark : AppColors.cardLight;
    final text = isDark ? AppColors.textDark : AppColors.textLight;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.board,
      brightness: brightness,
    ).copyWith(
      primary: primary,
      onPrimary: onPrimary,
      secondary: AppColors.highlighter,
      onSecondary: AppColors.ink,
      surface: card,
      onSurface: text,
      error: palette.again,
      onError: Colors.white,
      outline: palette.line,
      outlineVariant: palette.line,
    );

    final baseText = GoogleFonts.atkinsonHyperlegibleTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    ).apply(bodyColor: text, displayColor: text);

    TextStyle heading(TextStyle? style, FontWeight weight) =>
        GoogleFonts.lexend(textStyle: style, fontWeight: weight, color: text);

    final textTheme = baseText.copyWith(
      headlineMedium: heading(baseText.headlineMedium, FontWeight.w600),
      headlineSmall: heading(baseText.headlineSmall, FontWeight.w600),
      titleLarge: heading(baseText.titleLarge, FontWeight.w600),
      titleMedium: heading(baseText.titleMedium, FontWeight.w600),
      titleSmall: heading(baseText.titleSmall, FontWeight.w600),
      labelLarge: heading(baseText.labelLarge, FontWeight.w600),
      bodySmall: baseText.bodySmall?.copyWith(color: palette.muted),
    );

    final buttonText = GoogleFonts.lexend(
      fontSize: 15,
      fontWeight: FontWeight.w600,
    );
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
    );
    const buttonPadding = EdgeInsets.symmetric(vertical: 14, horizontal: 20);

    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      extensions: [palette],
      textTheme: textTheme,
      dividerColor: palette.line,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.lexend(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: card,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          side: BorderSide(color: palette.line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        hintStyle: TextStyle(color: palette.muted),
        labelStyle: TextStyle(color: palette.muted),
        border: inputBorder(palette.line),
        enabledBorder: inputBorder(palette.line),
        focusedBorder: inputBorder(primary, 1.6),
        errorBorder: inputBorder(palette.again),
        focusedErrorBorder: inputBorder(palette.again, 1.6),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: BorderSide(color: palette.line),
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: buttonText,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 2,
        extendedTextStyle: buttonText,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.textDark : AppColors.ink,
        contentTextStyle: baseText.bodyMedium?.copyWith(
          color: isDark ? AppColors.ink : Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXl),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          side: BorderSide(color: palette.line),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: palette.line,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: primary.withValues(alpha: 0.15),
        circularTrackColor: primary.withValues(alpha: 0.15),
      ),
      listTileTheme: ListTileThemeData(iconColor: palette.muted),
    );
  }
}
