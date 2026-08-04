import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Recreated from the README's description (dark/neon/glassmorphic
/// Material 3) since the original theme file wasn't part of what was
/// shared into this session. Swap this out for your original
/// `core/theme/app_theme.dart` if you still have it - everything else
/// in Phase 3 only depends on `Theme.of(context).colorScheme`, so it'll
/// drop in without touching the auth code.
class AppTheme {
  AppTheme._();

  static const _neonPink = Color(0xFFFF2E9A);
  static const _neonCyan = Color(0xFF2EE6FF);
  static const _bgDeep = Color(0xFF0B0B14);
  static const _bgSurface = Color(0xFF15151F);

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.rajdhaniTextTheme(base.textTheme).apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    );

    return base.copyWith(
      scaffoldBackgroundColor: _bgDeep,
      textTheme: textTheme,
      colorScheme: const ColorScheme.dark(
        primary: _neonCyan,
        secondary: _neonPink,
        surface: _bgDeep,
        surfaceContainerHighest: _bgSurface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _neonCyan,
          foregroundColor: Colors.black,
        ),
      ),
    );
  }
}
