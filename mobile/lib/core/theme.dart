import 'package:flutter/material.dart';

/// Couleurs du site (frontend/src/styles.scss) : YOBALEMA en vert, « sn » en orange.
class Couleurs {
  static const vert = Color(0xFF0C6B3F);
  static const vertClair = Color(0xFFE3F2EA);
  static const orange = Color(0xFFF29A1F);
  static const fond = Color(0xFFF4F6FB);
  static const surface2 = Color(0xFFEEF2FB);
  static const texte = Color(0xFF111827);
  static const texte2 = Color(0xFF4B5563);
  static const erreur = Color(0xFFC0262D);
}

ThemeData themeYobalema() {
  final schema = ColorScheme.fromSeed(
    seedColor: Couleurs.vert,
    primary: Couleurs.vert,
    secondary: Couleurs.orange,
    error: Couleurs.erreur,
    surface: Colors.white,
  );
  final rond = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
  return ThemeData(
    colorScheme: schema,
    scaffoldBackgroundColor: Couleurs.fond,
    appBarTheme: const AppBarTheme(
      backgroundColor: Couleurs.fond,
      foregroundColor: Couleurs.texte,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Couleurs.texte),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Couleurs.surface2)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Couleurs.vert, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: rond,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), shape: rond),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Couleurs.vertClair,
    ),
    useMaterial3: true,
  );
}

/// Logo texte : « YOBALEMA » en vert et « sn » en orange.
class Logo extends StatelessWidget {
  const Logo({super.key, this.taille = 26});

  final double taille;

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(children: [
          TextSpan(text: 'YOBALEMA', style: TextStyle(color: Couleurs.vert, fontSize: taille, fontWeight: FontWeight.w900)),
          TextSpan(text: 'sn', style: TextStyle(color: Couleurs.orange, fontSize: taille, fontWeight: FontWeight.w900)),
        ]),
      );
}
