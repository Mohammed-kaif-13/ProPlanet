import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color secondaryGreen = Color(0xFF81C784);
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color lightGreen = Color(0xFFC8E6C9);
  static const Color darkGreen = Color(0xFF2E7D32);
  static const Color backgroundColor = Color(0xFFF1F8E9);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);

  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.green,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      
      
      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          
        ),
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondary,
          
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimary,
          
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textPrimary,
          
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: textSecondary,
          
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            
          ),
        ),
      ),
      
      // Card Theme
      cardTheme: CardTheme(
        color: cardColor,
        elevation: 4,
        shadowColor: Colors.grey.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: primaryGreen,
        size: 24,
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardColor,
        selectedItemColor: primaryGreen,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: Brightness.light,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      primarySwatch: Colors.green,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardColor: const Color(0xFF1E1E1E),
      
      
      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          
        ),
      ),
      
      // Text Theme (adjusted for dark mode)
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: Colors.white,
          
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: Colors.white,
          
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Colors.white,
          
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
          
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white70,
          
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: Colors.white,
          
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Colors.white,
          
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: Colors.white70,
          
        ),
      ),
      
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: Brightness.dark,
      ),
    );
  }
}
