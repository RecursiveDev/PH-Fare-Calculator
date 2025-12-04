# Theme Specification (`AppTheme`)

## File Location
`lib/src/core/theme/app_theme.dart` (Suggested new location)

## Dependencies
*   `google_fonts` (For Poppins/Inter)

## Dart Implementation Spec

```dart
import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart'; // Uncomment when dependency added

class AppTheme {
  // Brand Colors
  static const Color _seedColor = Color(0xFF0038A8); // PH Blue
  static const Color _secondaryColor = Color(0xFFFCD116); // PH Yellow
  static const Color _tertiaryColor = Color(0xFFCE1126); // PH Red

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        secondary: _secondaryColor,
        tertiary: _tertiaryColor,
        brightness: Brightness.light,
        surface: const Color(0xFFFFFFFF),
        surfaceContainerLowest: const Color(0xFFF8F9FA), // Background
      ),
      
      // Typography
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32, 
          fontWeight: FontWeight.bold, 
          letterSpacing: -0.5,
          height: 1.2
        ),
        headlineMedium: TextStyle(
          fontSize: 24, 
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          height: 1.2
        ),
        titleLarge: TextStyle(
          fontSize: 20, 
          fontWeight: FontWeight.w600,
          height: 1.3
        ),
        titleMedium: TextStyle(
          fontSize: 16, 
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
          height: 1.4
        ),
        bodyLarge: TextStyle(
          fontSize: 16, 
          fontWeight: FontWeight.normal,
          height: 1.5
        ),
        bodyMedium: TextStyle(
          fontSize: 14, 
          fontWeight: FontWeight.normal,
          height: 1.5
        ),
        labelLarge: TextStyle(
          fontSize: 14, 
          fontWeight: FontWeight.w600, 
          letterSpacing: 0.1
        ),
      ),

      // Component Themes
      cardTheme: CardTheme(
        elevation: 0, // Flat by default for modern look, outline handles separation
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF2F2F2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _seedColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _tertiaryColor, width: 1),
        ),
        labelStyle: const TextStyle(color: Color(0xFF757575)),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _seedColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _seedColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const StadiumBorder(),
          side: const BorderSide(color: _seedColor),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFF1A1C1E),
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Color(0xFF1A1C1E)),
      ),
      
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: const Color(0xFFF0F4FF), // Very light blue tint
        indicatorColor: _seedColor.withValues(alpha: 0.2),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
           if (states.contains(WidgetState.selected)) {
             return const IconThemeData(color: _seedColor);
           }
           return const IconThemeData(color: Color(0xFF757575));
        }),
      ),
    );
  }

  // Dark Theme (High Contrast Friendly)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212),
      
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFB3C5FF), // Pastel Blue
        onPrimary: Color(0xFF002A78),
        secondary: Color(0xFFFDE26C), // Pastel Yellow
        onSecondary: Color(0xFF3B2F00),
        tertiary: Color(0xFFFFB4AB), // Pastel Red
        error: Color(0xFFCF6679),
        surface: Color(0xFF1E1E1E),
        onSurface: Color(0xFFE2E2E2),
        surfaceContainerLowest: Color(0xFF121212),
      ),

      // Reuse typography styles but ensure colors adapt automatically via Theme.of(context)
      
      cardTheme: CardTheme(
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF444444), width: 1),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB3C5FF), width: 2),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFB3C5FF),
          foregroundColor: const Color(0xFF002A78),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const StadiumBorder(),
        ),
      ),
      
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        indicatorColor: const Color(0xFFB3C5FF).withValues(alpha: 0.2),
        iconTheme: WidgetStateProperty.resolveWith((states) {
           if (states.contains(WidgetState.selected)) {
             return const IconThemeData(color: Color(0xFFB3C5FF));
           }
           return const IconThemeData(color: Color(0xFFC4C4C4));
        }),
      ),
    );
  }
}