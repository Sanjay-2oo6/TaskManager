import 'package:flutter/material.dart';

class AppTheme {
  // --- INNO TECH HUB Palette (Clean & Light) ---
  
  // New Core Semantic Colors
  static const Color backgroundLight = Color(0xFFF0F0F5); // Light Gray Work area
  static const Color surfaceWhite = Color(0xFFFFFFFF); // Clean White Cards
  static const Color sidebarDark = Color(0xFF1A1A2E); // Dark Charcoal Sidebar
  
  static const Color primaryCoral = Color(0xFFFF6B6B); // Primary Action
  static const Color secondaryBlue = Color(0xFF4A7CFF); // Secondary / In Progress
  static const Color successGreen = Color(0xFF4ADE80); // Completed / Success
  static const Color accentPurple = Color(0xFF9333EA); // Accent / Super Admin
  
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textMuted = Color(0xFF8E8E93);
  static const Color borderLight = Color(0xFFE5E5EA);

  // --- Legacy Mappings (Preserving to avoid breaking existing pages during transition) ---
  static const Color darkBg = backgroundLight;
  static const Color obsidianCard = surfaceWhite;
  static const Color pineGlass = surfaceWhite; 
  static const Color champagneGold = textDark; 
  static const Color warmOchre = secondaryBlue; 
  static const Color mutedForest = textMuted; 
  
  static const Color sageMint = successGreen; 
  static const Color copperBlaze = primaryCoral; 
  static const Color azureSky = secondaryBlue;
  static const Color violetPulse = textMuted; 
  
  // Standard Status Mapping (Updated for Light Theme)
  static const Color pendingColor = textMuted; 
  static const Color inProgressColor = secondaryBlue;
  static const Color submittedColor = secondaryBlue;
  static const Color completedColor = successGreen;
  static const Color highPriorityColor = primaryCoral;
  static const Color mediumPriorityColor = secondaryBlue;
  static const Color lowPriorityColor = successGreen;

  // Global Light Theme Configuration
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryCoral,
    scaffoldBackgroundColor: backgroundLight,
    fontFamily: 'Inter', // Defaulting to an elegant sans-serif
    colorScheme: const ColorScheme.light(
      primary: primaryCoral,
      secondary: secondaryBlue,
      surface: surfaceWhite,
      error: primaryCoral,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: textDark),
      titleTextStyle: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 20),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: textDark, fontWeight: FontWeight.bold, letterSpacing: 1),
      bodyMedium: TextStyle(color: textDark),
    ),
  );
}
