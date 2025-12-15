import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart'; // Uncomment when dependency added

import 'transit_colors.dart';

/// Application theme configuration with Jeepney-inspired color palette.
/// Based on Philippine flag colors: Blue, Yellow, Red.
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // Brand Colors
  static const Color _seedColor = Color(0xFF0038A8); // PH Blue
  static const Color _secondaryColor = Color(0xFFFCD116); // PH Yellow
  static const Color _tertiaryColor = Color(0xFFCE1126); // PH Red

  /// Light theme for the application.
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
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          height: 1.2,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
          height: 1.4,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),

      // Component Themes
      cardTheme: CardThemeData(
        elevation:
            0, // Flat by default for modern look, outline handles separation
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF2F2F2),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
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

      // Theme Extensions
      extensions: const <ThemeExtension<dynamic>>[TransitColors.light],
    );
  }

  /// Dark theme using Material 3 standard colors from research.
  /// Background: #141218 (dark purple-grey, NOT pure black)
  /// Uses M3 surface container system for proper elevation hierarchy.
  static ThemeData get darkTheme {
    // M3 Standard Dark Mode Colors (from research doc)
    const Color m3DarkBackground = Color(0xFF141218);
    const Color m3DarkSurface = Color(0xFF141218);
    const Color m3DarkSurfaceContainerLowest = Color(0xFF0F0D13);
    const Color m3DarkSurfaceContainerLow = Color(0xFF1D1B20);
    const Color m3DarkSurfaceContainer = Color(0xFF211F26);
    const Color m3DarkSurfaceContainerHigh = Color(0xFF2B2930);
    const Color m3DarkSurfaceContainerHighest = Color(0xFF36343B);
    const Color m3DarkOnSurface = Color(0xFFE6E0E9);
    const Color m3DarkOnSurfaceVariant = Color(0xFFCAC4D0);
    const Color m3DarkOutline = Color(0xFF938F99);
    const Color m3DarkOutlineVariant = Color(0xFF49454F);

    // Pastel colors for dark mode (derived from PH flag colors)
    const Color m3DarkPrimary = Color(0xFFB8C9FF); // Soft pastel blue
    const Color m3DarkOnPrimary = Color(0xFF002C71);
    const Color m3DarkPrimaryContainer = Color(0xFF1B4496);
    const Color m3DarkOnPrimaryContainer = Color(0xFFD9E2FF);
    const Color m3DarkSecondary = Color(0xFFE5C54C); // Soft pastel yellow
    const Color m3DarkOnSecondary = Color(0xFF3B2F00);
    const Color m3DarkTertiary = Color(0xFFFFB4AB); // Soft pastel red
    const Color m3DarkOnTertiary = Color(0xFF561E18);
    const Color m3DarkError = Color(0xFFF2B8B5); // M3 soft error red

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: m3DarkBackground,
      colorScheme: const ColorScheme.dark(
        primary: m3DarkPrimary,
        onPrimary: m3DarkOnPrimary,
        primaryContainer: m3DarkPrimaryContainer,
        onPrimaryContainer: m3DarkOnPrimaryContainer,
        secondary: m3DarkSecondary,
        onSecondary: m3DarkOnSecondary,
        tertiary: m3DarkTertiary,
        onTertiary: m3DarkOnTertiary,
        error: m3DarkError,
        surface: m3DarkSurface,
        onSurface: m3DarkOnSurface,
        onSurfaceVariant: m3DarkOnSurfaceVariant,
        surfaceContainerLowest: m3DarkSurfaceContainerLowest,
        surfaceContainerLow: m3DarkSurfaceContainerLow,
        surfaceContainer: m3DarkSurfaceContainer,
        surfaceContainerHigh: m3DarkSurfaceContainerHigh,
        surfaceContainerHighest: m3DarkSurfaceContainerHighest,
        outline: m3DarkOutline,
        outlineVariant: m3DarkOutlineVariant,
      ),

      // Typography - MUST match light theme for consistent layout
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          height: 1.2,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
          height: 1.4,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),

      // Card theme - MUST match light theme structure for consistent layout
      cardTheme: CardThemeData(
        elevation: 0, // Same as light theme
        color: m3DarkSurfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: m3DarkOutlineVariant, width: 1),
        ),
        margin: EdgeInsets.zero, // Same as light theme
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: m3DarkSurfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: m3DarkPrimary, width: 2),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: m3DarkPrimary,
          foregroundColor: m3DarkOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),

      // Outlined button theme - MUST match light theme for consistent layout
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: m3DarkPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const StadiumBorder(),
          side: const BorderSide(color: m3DarkPrimary),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),

      // AppBar theme - MUST match light theme for consistent layout
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: m3DarkOnSurface,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: m3DarkOnSurface),
      ),

      navigationBarTheme: NavigationBarThemeData(
        elevation: 0, // Same as light theme
        backgroundColor: m3DarkSurfaceContainer,
        indicatorColor: m3DarkPrimary.withValues(alpha: 0.2),
        labelBehavior: NavigationDestinationLabelBehavior
            .alwaysShow, // Same as light theme
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: m3DarkPrimary);
          }
          return const IconThemeData(color: m3DarkOnSurfaceVariant);
        }),
      ),

      // Theme Extensions
      extensions: const <ThemeExtension<dynamic>>[TransitColors.dark],
    );
  }
}
