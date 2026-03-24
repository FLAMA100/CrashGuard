import 'package:flutter/material.dart';

class AppTheme {
  static const bg          = Color(0xFF0A0C0F);
  static const surface     = Color(0xFF111418);
  static const card        = Color(0xFF161B22);
  static const border      = Color(0xFF1E2530);
  static const red         = Color(0xFFE53935);
  static const redSoft     = Color(0x14E53935);
  static const green       = Color(0xFF00C853);
  static const muted       = Color(0xFF7A8394);
  static const textPrimary = Color(0xFFF0F2F5);

  static ThemeData get dark => ThemeData.dark().copyWith(
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      primary: red,
      surface: surface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bg,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
      iconTheme: IconThemeData(color: textPrimary),
    ),
  );
}
// Theme developed by Kingballer24
