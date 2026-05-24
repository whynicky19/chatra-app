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

const _r14 = BorderRadius.all(Radius.circular(14));

InputDecorationTheme _input(Color fill, Color focus) => InputDecorationTheme(
  filled: true, fillColor: fill,
  border: OutlineInputBorder(borderRadius: _r14, borderSide: BorderSide.none),
  enabledBorder: OutlineInputBorder(borderRadius: _r14, borderSide: BorderSide.none),
  focusedBorder: OutlineInputBorder(borderRadius: _r14, borderSide: BorderSide(color: focus, width: 1.5)),
  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  hintStyle: TextStyle(color: C.text4, fontSize: 14),
);

ElevatedButtonThemeData _btn() => ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
  backgroundColor: C.teal, foregroundColor: Colors.white, elevation: 0,
  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
  shape: RoundedRectangleBorder(borderRadius: _r14),
));

const _pageTransitions = PageTransitionsTheme(builders: {
  TargetPlatform.android: CupertinoPageTransitionsBuilder(),
  TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
});

class AppTheme {
  static final light = ThemeData(
    brightness: Brightness.light, primaryColor: C.teal, scaffoldBackgroundColor: C.bg,
    colorScheme: ColorScheme.light(primary: C.teal, secondary: C.tealDk, surface: C.surface, error: C.red),
    appBarTheme: AppBarTheme(backgroundColor: C.surface, foregroundColor: C.text1, elevation: 0, surfaceTintColor: Colors.transparent),
    cardTheme: CardThemeData(color: C.surface, elevation: 0, shape: RoundedRectangleBorder(borderRadius: _r14)),
    inputDecorationTheme: _input(C.surface2, C.teal),
    elevatedButtonTheme: _btn(),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(foregroundColor: C.teal, side: BorderSide(color: C.teal, width: 1.5), padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: _r14))),
    snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: _r14)),
    pageTransitionsTheme: _pageTransitions,
    dividerColor: C.border,
  );

  static final dark = ThemeData(
    brightness: Brightness.dark, primaryColor: C.teal, scaffoldBackgroundColor: Color(0xFF0A1214),
    colorScheme: ColorScheme.dark(primary: C.teal, secondary: C.tealDk, surface: Color(0xFF111B1E), error: C.red),
    appBarTheme: AppBarTheme(backgroundColor: Color(0xFF111B1E), foregroundColor: Color(0xFFE8F4F6), elevation: 0, surfaceTintColor: Colors.transparent),
    cardTheme: CardThemeData(color: Color(0xFF111B1E), elevation: 0, shape: RoundedRectangleBorder(borderRadius: _r14)),
    inputDecorationTheme: _input(Color(0xFF1A2830), C.teal),
    elevatedButtonTheme: _btn(),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(foregroundColor: C.teal, side: BorderSide(color: C.teal, width: 1.5), padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: _r14))),
    snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: _r14)),
    pageTransitionsTheme: _pageTransitions,
    dividerColor: Color(0xFF1E3040).withOpacity(0.4),
  );
}
