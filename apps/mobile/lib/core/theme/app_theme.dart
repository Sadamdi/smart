import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Satu set warna lengkap untuk satu mode tampilan.
class Palet {
  const Palet({
    required this.primary,
    required this.primarySoft,
    required this.navy,
    required this.ink,
    required this.muted,
    required this.surface,
    required this.kartu,
    required this.container1,
    required this.container2,
    required this.container3,
    required this.container4,
    required this.error,
    required this.errorSoft,
    required this.outline,
    required this.sukses,
    required this.suksesSoft,
    required this.brightness,
  });

  final Color primary,
      primarySoft,
      navy,
      ink,
      muted,
      surface,
      kartu,
      container1,
      container2,
      container3,
      container4,
      error,
      errorSoft,
      outline,
      sukses,
      suksesSoft;
  final Brightness brightness;

  /// Token desain dari Figma (Dokument/03-Frontend/03-RENCANA-UIUX-DARI-FIGMA.md).
  static const terang = Palet(
    primary: Color(0xFF225EAA),
    primarySoft: Color(0xFF6C9FEF),
    navy: Color(0xFF051B38),
    ink: Color(0xFF424751),
    muted: Color(0xFF576676),
    surface: Color(0xFFF9F9FF),
    kartu: Color(0xFFFFFFFF),
    container1: Color(0xFFF0F3FF),
    container2: Color(0xFFE7EEFF),
    container3: Color(0xFFDFE8FF),
    container4: Color(0xFFD6E3FF),
    error: Color(0xFFBA1A1A),
    errorSoft: Color(0xFFFFDAD6),
    outline: Color(0xFFC2C6D3),
    sukses: Color(0xFF1B6B3A),
    suksesSoft: Color(0xFFDDF3E4),
    brightness: Brightness.light,
  );

  /// Biru malam: latar hampir hitam kebiruan, kartu sedikit lebih terang, teks putih kebiruan.
  static const gelap = Palet(
    primary: Color(0xFF3F7FD4),
    primarySoft: Color(0xFF9CC0F5),
    navy: Color(0xFFE8EEFA),
    ink: Color(0xFFC6CEDC),
    muted: Color(0xFF93A1B5),
    surface: Color(0xFF0C1320),
    kartu: Color(0xFF141E30),
    container1: Color(0xFF111A2A),
    container2: Color(0xFF18243A),
    container3: Color(0xFF203050),
    container4: Color(0xFF2A3D60),
    error: Color(0xFFFF8F86),
    errorSoft: Color(0xFF4A2224),
    outline: Color(0xFF384662),
    sukses: Color(0xFF6FD39A),
    suksesSoft: Color(0xFF173A28),
    brightness: Brightness.dark,
  );
}

/// Akses warna dari mana saja. Mengikuti mode aktif; [pakai] dipanggil sekali oleh aplikasi sebelum
/// menggambar, dan seluruh tampilan dibangun ulang ketika mode berganti.
class Warna {
  Warna._();

  static Palet _p = Palet.terang;
  static void pakai(Palet p) => _p = p;
  static bool get gelap => _p.brightness == Brightness.dark;

  /// Biru tua datar untuk kartu hero (Beranda, kepala Profil) dan teks lembut di atasnya.
  static Color get hero =>
      gelap ? const Color(0xFF143F7C) : const Color(0xFF1E4F94);
  static const heroTeks = Color(0xFFD5E2F6);

  static Color get primary => _p.primary;
  static Color get primarySoft => _p.primarySoft;
  static Color get navy => _p.navy;
  static Color get ink => _p.ink;
  static Color get muted => _p.muted;
  static Color get surface => _p.surface;
  static Color get kartu => _p.kartu;
  static Color get container1 => _p.container1;
  static Color get container2 => _p.container2;
  static Color get container3 => _p.container3;
  static Color get container4 => _p.container4;
  static Color get error => _p.error;
  static Color get errorSoft => _p.errorSoft;
  static Color get outline => _p.outline;
  static Color get sukses => _p.sukses;
  static Color get suksesSoft => _p.suksesSoft;

  /// Putih murni untuk teks dan ikon di atas warna utama; untuk latar kartu pakai [kartu].
  static const putih = Color(0xFFFFFFFF);
}

class Jari {
  Jari._();

  static const double kontrol = 8;
  static const double kartuDalam = 12;
  static const double kartu = 16;
  static const double bulat = 9999;
}

/// Bayangan tipis kartu putih: 0 1px 2px rgba(0,0,0,0.05).
List<BoxShadow> get bayanganKartu => Warna.gelap
    ? const []
    : const [
        BoxShadow(
          color: Color(0x0D000000),
          offset: Offset(0, 1),
          blurRadius: 2,
        ),
      ];

/// [googleFonts] dimatikan pada uji agar tidak mengunduh huruf.
ThemeData buatTema({bool googleFonts = true, Palet w = Palet.terang}) {
  final skema = ColorScheme(
    brightness: w.brightness,
    primary: w.primary,
    onPrimary: Warna.putih,
    primaryContainer: w.container4,
    onPrimaryContainer: w.navy,
    secondary: w.primarySoft,
    onSecondary: w.navy,
    secondaryContainer: w.container2,
    onSecondaryContainer: w.navy,
    tertiary: w.muted,
    onTertiary: Warna.putih,
    error: w.error,
    onError: Warna.putih,
    errorContainer: w.errorSoft,
    onErrorContainer: w.error,
    surface: w.surface,
    onSurface: w.ink,
    onSurfaceVariant: w.muted,
    outline: w.outline,
    outlineVariant: w.container4,
    surfaceContainerLowest: w.kartu,
    surfaceContainerLow: w.container1,
    surfaceContainer: w.container2,
    surfaceContainerHigh: w.container3,
    surfaceContainerHighest: w.container4,
  );

  final dasar = ThemeData(
    useMaterial3: true,
    colorScheme: skema,
    scaffoldBackgroundColor: w.surface,
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
      fontSize: 26,
      fontWeight: FontWeight.w700,
      color: w.navy,
    ),
    titleLarge: teks.titleLarge?.copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: w.navy,
    ),
    titleMedium: teks.titleMedium?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: w.navy,
    ),
    titleSmall: teks.titleSmall?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: w.navy,
    ),
    bodyLarge: teks.bodyLarge?.copyWith(fontSize: 16, color: w.ink),
    bodyMedium: teks.bodyMedium?.copyWith(fontSize: 14, color: w.ink),
    bodySmall: teks.bodySmall?.copyWith(fontSize: 12, color: w.muted),
    labelLarge: teks.labelLarge?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    labelSmall: teks.labelSmall?.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      color: w.muted,
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
      backgroundColor: w.surface,
      foregroundColor: w.navy,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: tema.titleMedium,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: w.kartu,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: tema.bodyMedium?.copyWith(color: w.outline),
      border: garis(w.outline),
      enabledBorder: garis(w.outline),
      focusedBorder: garis(w.primary, 2),
      errorBorder: garis(w.error),
      focusedErrorBorder: garis(w.error, 2),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: w.primary,
        foregroundColor: Warna.putih,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: tema.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: w.primary,
        minimumSize: const Size.fromHeight(48),
        side: BorderSide(color: w.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: tema.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: w.primary,
        textStyle: tema.labelLarge,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 68,
      indicatorColor: w.container3,
      indicatorShape: const StadiumBorder(),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected) ? w.primary : w.muted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => tema.labelSmall?.copyWith(
          fontSize: 11,
          letterSpacing: 0,
          fontWeight: s.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: s.contains(WidgetState.selected) ? w.primary : w.muted,
        ),
      ),
    ),
    dividerTheme: DividerThemeData(color: w.container4, space: 1),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
