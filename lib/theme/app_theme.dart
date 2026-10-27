import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:xterm/xterm.dart';

class AppColors {
  // Deep obsidian Termius background
  static const Color background = Color(0xFF0A0D14);
  static const Color sidebar = Color(0xFF07090E);
  static const Color surface = Color(0xFF121722);
  static const Color surfaceElevated = Color(0xFF1A2232);
  static const Color card = Color(0xFF141A26);
  static const Color border = Color(0xFF232D42);
  static const Color borderFocus = Color(0xFF00D2FF);

  // Termius vibrant neon accents
  static const Color cyan = Color(0xFF00D2FF);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color emerald = Color(0xFF10B981);
  static const Color amber = Color(0xFFF59E0B);
  static const Color rose = Color(0xFFF43F5E);
  static const Color blue = Color(0xFF3B82F6);

  // Typography shades
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.cyan,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.cyan,
        secondary: AppColors.purple,
        surface: AppColors.surface,
        error: AppColors.rose,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        outline: AppColors.border,
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.cyan, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cyan,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.sidebar,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // Termius Sleek Dark Terminal Theme
  static const TerminalTheme termiusDark = TerminalTheme(
    cursor: AppColors.cyan,
    selection: Color(0x4400D2FF),
    foreground: Color(0xFFE2E8F0),
    background: Color(0xFF0B0F17),
    black: Color(0xFF1E293B),
    red: Color(0xFFF43F5E),
    green: Color(0xFF10B981),
    yellow: Color(0xFFF59E0B),
    blue: Color(0xFF38BDF8),
    magenta: Color(0xFFA855F7),
    cyan: Color(0xFF06B6D4),
    white: Color(0xFFF8FAFC),
    brightBlack: Color(0xFF475569),
    brightRed: Color(0xFFFB7185),
    brightGreen: Color(0xFF34D399),
    brightYellow: Color(0xFFFBBF24),
    brightBlue: Color(0xFF60A5FA),
    brightMagenta: Color(0xFFC084FC),
    brightCyan: Color(0xFF22D3EE),
    brightWhite: Color(0xFFFFFFFF),
    searchHitBackground: Color(0xFFFDE047),
    searchHitBackgroundCurrent: Color(0xFF38BDF8),
    searchHitForeground: Color(0xFF000000),
  );

  // Dracula Terminal Theme
  static const TerminalTheme dracula = TerminalTheme(
    cursor: Color(0xFFF8F8F2),
    selection: Color(0x4444475A),
    foreground: Color(0xFFF8F8F2),
    background: Color(0xFF282A36),
    black: Color(0xFF21222C),
    red: Color(0xFFFF5555),
    green: Color(0xFF50FA7B),
    yellow: Color(0xFFF1FA8C),
    blue: Color(0xFFBD93F9),
    magenta: Color(0xFFFF79C6),
    cyan: Color(0xFF8BE9FD),
    white: Color(0xFFF8F8F2),
    brightBlack: Color(0xFF6272A4),
    brightRed: Color(0xFFFF6E6E),
    brightGreen: Color(0xFF69FF94),
    brightYellow: Color(0xFFFFFFA5),
    brightBlue: Color(0xFFD6ACFF),
    brightMagenta: Color(0xFFFF92DF),
    brightCyan: Color(0xFFA4FFFF),
    brightWhite: Color(0xFFFFFFFF),
    searchHitBackground: Color(0xFFF1FA8C),
    searchHitBackgroundCurrent: Color(0xFF50FA7B),
    searchHitForeground: Color(0xFF282A36),
  );

  // Nord Terminal Theme
  static const TerminalTheme nord = TerminalTheme(
    cursor: Color(0xFFD8DEE9),
    selection: Color(0x444C566A),
    foreground: Color(0xFFD8DEE9),
    background: Color(0xFF2E3440),
    black: Color(0xFF3B4252),
    red: Color(0xFFBF616A),
    green: Color(0xFFA3BE8C),
    yellow: Color(0xFFEBCB8B),
    blue: Color(0xFF81A1C1),
    magenta: Color(0xFFB48EAD),
    cyan: Color(0xFF88C0D0),
    white: Color(0xFFE5E9F0),
    brightBlack: Color(0xFF4C566A),
    brightRed: Color(0xFFBF616A),
    brightGreen: Color(0xFFA3BE8C),
    brightYellow: Color(0xFFEBCB8B),
    brightBlue: Color(0xFF81A1C1),
    brightMagenta: Color(0xFFB48EAD),
    brightCyan: Color(0xFF8FBCBB),
    brightWhite: Color(0xFFECEFF4),
    searchHitBackground: Color(0xFFEBCB8B),
    searchHitBackgroundCurrent: Color(0xFF88C0D0),
    searchHitForeground: Color(0xFF2E3440),
  );

  // Monokai Pro Theme
  static const TerminalTheme monokai = TerminalTheme(
    cursor: Color(0xFFFFD866),
    selection: Color(0x44403E41),
    foreground: Color(0xFFFCFCFA),
    background: Color(0xFF2D2A2E),
    black: Color(0xFF221F22),
    red: Color(0xFFFF6188),
    green: Color(0xFFA9DC76),
    yellow: Color(0xFFFFD866),
    blue: Color(0xFF78DCE8),
    magenta: Color(0xFFAB9DF2),
    cyan: Color(0xFF78DCE8),
    white: Color(0xFFFCFCFA),
    brightBlack: Color(0xFF727072),
    brightRed: Color(0xFFFF6188),
    brightGreen: Color(0xFFA9DC76),
    brightYellow: Color(0xFFFFD866),
    brightBlue: Color(0xFF78DCE8),
    brightMagenta: Color(0xFFAB9DF2),
    brightCyan: Color(0xFF78DCE8),
    brightWhite: Color(0xFFFFFFFF),
    searchHitBackground: Color(0xFFFFD866),
    searchHitBackgroundCurrent: Color(0xFFA9DC76),
    searchHitForeground: Color(0xFF2D2A2E),
  );

  static TerminalTheme getTerminalTheme(String name) {
    switch (name) {
      case 'Dracula':
        return dracula;
      case 'Nord':
        return nord;
      case 'Monokai Pro':
        return monokai;
      case 'Default':
        return TerminalThemes.defaultTheme;
      case 'Termius Obsidian Dark':
      default:
        return termiusDark;
    }
  }
}
