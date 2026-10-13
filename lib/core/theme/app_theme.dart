export '../motion/app_motion.dart';
export 'journal_accent.dart';
import 'journal_accent.dart';
import 'package:flutter/material.dart';

class AppColors {
  static const deepNavy = Color(0xFF20233F);
  static const navy = Color(0xFF343175);
  static const indigo = Color(0xFF5856D6);
  static const violet = Color(0xFF7770EC);
  static const background = Color(0xFFF8F8FC);
  static const muted = Color(0xFF626879);
  static const primaryGradient = LinearGradient(
    colors: [deepNavy, navy, indigo],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppLayout {
  static const pagePadding = 24.0;
  static const contentWidth = 720.0;
  static const expandedWidth = 1000.0;
  static const radius = 20.0;
}

class AppTheme {
  static ThemeData get light => _theme(Brightness.light);
  static ThemeData get dark => _theme(Brightness.dark);

  static ThemeData themed(Brightness brightness, JournalAccent accent) =>
      _theme(brightness, accent);

  static ThemeData _theme(
    Brightness brightness, [
    JournalAccent palette = JournalAccent.indigo,
  ]) {
    final dark = brightness == Brightness.dark;
    final background = dark ? const Color(0xFF14151F) : AppColors.background;
    final surface = dark ? const Color(0xFF20222F) : Colors.white;
    final ink = dark ? const Color(0xFFF0EFF8) : const Color(0xFF202339);
    final secondary = dark ? const Color(0xFFBABCCD) : AppColors.muted;
    final accent = palette == JournalAccent.indigo && dark
        ? const Color(0xFFADA8FF)
        : readableColor(palette.seed, surface);
    final gradientStart = readableColor(palette.start, Colors.white);
    final gradientEnd = readableColor(palette.end, Colors.white);
    final scheme =
        ColorScheme.fromSeed(
          seedColor: palette.seed,
          brightness: brightness,
          surface: surface,
        ).copyWith(
          primary: accent,
          onPrimary: accent.computeLuminance() > .179
              ? Colors.black
              : Colors.white,
          onSurface: ink,
          onSurfaceVariant: secondary,
        );
    return ThemeData(
      useMaterial3: true,
      extensions: [
        AccentPalette(
          start: gradientStart,
          end: gradientEnd,
          soft: Color.alphaBlend(accent.withValues(alpha: .10), surface),
          border: accent.withValues(alpha: .35),
        ),
      ],
      brightness: brightness,
      scaffoldBackgroundColor: background,
      colorScheme: scheme,
      dividerColor: dark ? const Color(0xFF3D4053) : const Color(0xFFDFE0EB),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: AppLayout.pagePadding,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: -1,
          height: 1.2,
          color: ink,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
          height: 1.25,
          color: ink,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: ink,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        bodyLarge: TextStyle(fontSize: 17, height: 1.6, color: ink),
        bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: secondary),
        labelLarge: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppLayout.radius),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accent,
        selectionColor: accent.withValues(alpha: 0.22),
        selectionHandleColor: accent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: const UnderlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        hintStyle: TextStyle(color: secondary),
      ),
    );
  }
}
