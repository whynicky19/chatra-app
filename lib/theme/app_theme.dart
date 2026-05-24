import 'package:flutter/material.dart';

typedef AppColors = C;

class C {
  static const teal = Color(0xFF00B1C9);
  static const tealDk = Color(0xFF009AAF);
  static const tealLt = Color(0xFFE6F9FB);
  static const bg = Color(0xFFF5F7F8);
  static const surface = Colors.white;
  static const surface2 = Color(0xFFF0F4F5);
  static const border = Color(0xFFE2E8F0);
  static const text1 = Color(0xFF0D2D33);
  static const text2 = Color(0xFF1E3A44);
  static const text3 = Color(0xFF4A7A86);
  static const text4 = Color(0xFF7AABB5);
  static const red = Color(0xFFDC2626);
  static const redLt = Color(0xFFFEE2E2);
  static const redLight = redLt;
  static const green = Color(0xFF16A34A);
  static const greenLt = Color(0xFFDCFCE7);
  static const greenLight = greenLt;
  static const yellow = Color(0xFFFBBF24);
  static const tealLight = tealLt;
}

class AppTheme {
  static ThemeData get light => ThemeData(
    brightness: Brightness.light, primaryColor: C.teal, scaffoldBackgroundColor: C.bg,
    colorScheme: ColorScheme.light(primary: C.teal, secondary: C.tealDk, surface: C.surface, error: C.red),
    appBarTheme: AppBarTheme(backgroundColor: C.surface, foregroundColor: C.text1, elevation: 0, surfaceTintColor: Colors.transparent),
    inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: C.surface2,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: C.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: C.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: C.teal, width: 1.5)),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14), hintStyle: TextStyle(color: C.text4, fontSize: 14)),
    elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: C.teal, foregroundColor: Colors.white, elevation: 0, padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), textStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(foregroundColor: C.teal, side: BorderSide(color: C.teal, width: 1.5), padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(backgroundColor: C.surface, selectedItemColor: C.teal, unselectedItemColor: C.text4, type: BottomNavigationBarType.fixed, showUnselectedLabels: true, selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700), unselectedLabelStyle: TextStyle(fontSize: 11)),
    snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
  );

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark, primaryColor: C.teal, scaffoldBackgroundColor: Color(0xFF0A1214),
    colorScheme: ColorScheme.dark(primary: C.teal, secondary: C.tealDk, surface: Color(0xFF111B1E), error: C.red),
    appBarTheme: AppBarTheme(backgroundColor: Color(0xFF111B1E), foregroundColor: Color(0xFFE8F4F6), elevation: 0, surfaceTintColor: Colors.transparent),
    cardTheme: CardThemeData(color: Color(0xFF111B1E), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Color(0xFF1E3040).withOpacity(0.5)))),
    inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Color(0xFF1A2830),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFF1E3040))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFF1E3040))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: C.teal, width: 1.5)),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14), hintStyle: TextStyle(color: Color(0xFF4A7A86), fontSize: 14)),
    elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: C.teal, foregroundColor: Colors.white, elevation: 0, padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), textStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(foregroundColor: C.teal, side: BorderSide(color: C.teal, width: 1.5), padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(backgroundColor: Color(0xFF111B1E), selectedItemColor: C.teal, unselectedItemColor: Color(0xFF4A7A86), type: BottomNavigationBarType.fixed, showUnselectedLabels: true, selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700), unselectedLabelStyle: TextStyle(fontSize: 11)),
    snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
  );
}
