import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Token desain dari Figma (Dokument/03-Frontend/03-RENCANA-UIUX-DARI-FIGMA.md).
class Warna {
  Warna._();

  static const primary = Color(0xFF225EAA);
  static const primarySoft = Color(0xFF6C9FEF);
  static const navy = Color(0xFF051B38);
  static const ink = Color(0xFF424751);
  static const muted = Color(0xFF576676);
  static const surface = Color(0xFFF9F9FF);
  static const container1 = Color(0xFFF0F3FF);
  static const container2 = Color(0xFFE7EEFF);
  static const container3 = Color(0xFFDFE8FF);
  static const container4 = Color(0xFFD6E3FF);
  static const error = Color(0xFFBA1A1A);
  static const errorSoft = Color(0xFFFFDAD6);
  static const outline = Color(0xFFC2C6D3);
  static const putih = Color(0xFFFFFFFF);
  static const sukses = Color(0xFF1B6B3A);
  static const suksesSoft = Color(0xFFDDF3E4);
}

class Jari {
  Jari._();

  static const double kontrol = 8;
  static const double kartuDalam = 12;
  static const double kartu = 16;
  static const double bulat = 9999;
}

/// Bayangan tipis kartu putih: 0 1px 2px rgba(0,0,0,0.05).
const bayanganKartu = [
  BoxShadow(color: Color(0x0D000000), offset: Offset(0, 1), blurRadius: 2),
];

/// [googleFonts] dimatikan pada uji agar tidak mengunduh huruf.
ThemeData buatTema({bool googleFonts = true}) {
  const skema = ColorScheme(
    brightness: Brightness.light,
    primary: Warna.primary,
    onPrimary: Warna.putih,
    primaryContainer: Warna.container4,
    onPrimaryContainer: Warna.navy,
    secondary: Warna.primarySoft,
    onSecondary: Warna.navy,
    secondaryContainer: Warna.container2,
    onSecondaryContainer: Warna.navy,
    tertiary: Warna.muted,
    onTertiary: Warna.putih,
    error: Warna.error,
    onError: Warna.putih,
    errorContainer: Warna.errorSoft,
    onErrorContainer: Warna.error,
    surface: Warna.surface,
    onSurface: Warna.ink,
    onSurfaceVariant: Warna.muted,
    outline: Warna.outline,
    outlineVariant: Warna.container4,
    surfaceContainerLowest: Warna.putih,
    surfaceContainerLow: Warna.container1,
    surfaceContainer: Warna.container2,
    surfaceContainerHigh: Warna.container3,
    surfaceContainerHighest: Warna.container4,
  );

  final dasar = ThemeData(
    useMaterial3: true,
    colorScheme: skema,
    scaffoldBackgroundColor: Warna.surface,
  );
  // Dipetakan per gaya karena TextTheme google_fonts bertipe lain dari TextTheme Flutter.
  TextStyle? pj(TextStyle? s) =>
      googleFonts && s != null ? GoogleFonts.plusJakartaSans(textStyle: s) : s;
  final d = dasar.textTheme;
  final teks = TextTheme(
    displayLarge: pj(d.displayLarge),
    displayMedium: pj(d.displayMedium),
    displaySmall: pj(d.displaySmall),
    headlineLarge: pj(d.headlineLarge),
    headlineMedium: pj(d.headlineMedium),
    headlineSmall: pj(d.headlineSmall),
    titleLarge: pj(d.titleLarge),
    titleMedium: pj(d.titleMedium),
    titleSmall: pj(d.titleSmall),
    bodyLarge: pj(d.bodyLarge),
    bodyMedium: pj(d.bodyMedium),
    bodySmall: pj(d.bodySmall),
    labelLarge: pj(d.labelLarge),
    labelMedium: pj(d.labelMedium),
    labelSmall: pj(d.labelSmall),
  );
  final tema = teks.copyWith(
    headlineMedium: teks.headlineMedium?.copyWith(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: Warna.navy,
    ),
    titleLarge: teks.titleLarge?.copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: Warna.navy,
    ),
    titleMedium: teks.titleMedium?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: Warna.navy,
    ),
    titleSmall: teks.titleSmall?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Warna.navy,
    ),
    bodyLarge: teks.bodyLarge?.copyWith(fontSize: 16, color: Warna.ink),
    bodyMedium: teks.bodyMedium?.copyWith(fontSize: 14, color: Warna.ink),
    bodySmall: teks.bodySmall?.copyWith(fontSize: 12, color: Warna.muted),
    labelLarge: teks.labelLarge?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    labelSmall: teks.labelSmall?.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      color: Warna.muted,
    ),
  );

  OutlineInputBorder garis(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(Jari.kontrol),
    borderSide: BorderSide(color: c, width: w),
  );

  return dasar.copyWith(
    textTheme: tema,
    primaryTextTheme: tema,
    appBarTheme: AppBarTheme(
      backgroundColor: Warna.surface,
      foregroundColor: Warna.navy,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: tema.titleMedium,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Warna.putih,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: tema.bodyMedium?.copyWith(color: Warna.outline),
      border: garis(Warna.outline),
      enabledBorder: garis(Warna.outline),
      focusedBorder: garis(Warna.primary, 2),
      errorBorder: garis(Warna.error),
      focusedErrorBorder: garis(Warna.error, 2),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Warna.primary,
        foregroundColor: Warna.putih,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Jari.kartuDalam),
        ),
        textStyle: tema.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Warna.primary,
        minimumSize: const Size.fromHeight(44),
        side: const BorderSide(color: Warna.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Jari.kartuDalam),
        ),
        textStyle: tema.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Warna.primary,
        textStyle: tema.labelLarge,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Warna.putih,
      indicatorColor: Warna.container3,
      labelTextStyle: WidgetStatePropertyAll(
        tema.labelSmall?.copyWith(letterSpacing: 0),
      ),
    ),
    dividerTheme: const DividerThemeData(color: Warna.container4, space: 1),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
