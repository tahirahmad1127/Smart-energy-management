import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EnergyTheme {
  // Dark theme colors
  static const Color background = Color(0xFF050B18);
  static const Color surface = Color(0xFF0F1C2F);
  static const Color panel = Color(0xFF152645);
  static const Color electricBlue = Color(0xFF00E0FF);
  static const Color neonPurple = Color(0xFF7C5CFF);
  static const Color amberGlow = Color(0xFFFFC857);
  
  // Primary app color (commonly used across app)
  static const Color primaryCyan = Color(0xff23ABC3);
  
  // Light theme colors
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightPanel = Color(0xFFE8F4F8);

  static LinearGradient electricGradient = const LinearGradient(
    colors: [electricBlue, neonPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient primaryGradient = const LinearGradient(
    colors: [Color(0xff000000), primaryCyan, Color(0xffFFFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static LinearGradient darkGradient = const LinearGradient(
    colors: [Color(0xFF121212), Color(0xFF1E1E1E), Color(0xFF2C2C2C)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static ThemeData get lightTheme {
    final base = ThemeData(brightness: Brightness.light, useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: lightBackground,
      colorScheme: ColorScheme.light(
        primary: primaryCyan,
        secondary: electricBlue,
        background: lightBackground,
        surface: lightSurface,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
          .apply(bodyColor: Colors.black87, displayColor: Colors.black87),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryCyan,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardColor: lightSurface,
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: TextStyle(color: Colors.grey.shade700),
        hintStyle: TextStyle(color: Colors.grey.shade500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryCyan, width: 1.4),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: Colors.black87,
        textColor: Colors.black87,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primaryCyan : Colors.grey.shade300,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primaryCyan.withOpacity(0.5)
              : Colors.grey.shade300,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.dark(
        primary: primaryCyan,
        secondary: electricBlue,
        background: background,
        surface: surface,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
          .apply(bodyColor: Colors.white, displayColor: Colors.white),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardColor: panel,
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panel,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryCyan, width: 1.4),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: Colors.white,
        textColor: Colors.white,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primaryCyan : Colors.grey.shade700,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primaryCyan.withOpacity(0.3)
              : Colors.white12,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}




