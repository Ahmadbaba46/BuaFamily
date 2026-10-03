import 'package:flutter/material.dart';

/// Colours from the Bua Family design ("Arewa green": deep green with a gold
/// zanen-gida motif). Text colours meet WCAG AA on their intended backgrounds.
abstract final class Bua {
  static const green = Color(0xFF1D6B40);
  static const greenDark = Color(0xFF134A2C);
  static const greenTint = Color(0xFFE3F0E7);
  static const greenIndicator = Color(0xFFD6EADC);
  static const greenOnDark = Color(0xFFD6EADC);

  static const ground = Color(0xFFF4F6F2);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFEEF2EC);
  static const track = Color(0xFFE6EBE5);
  static const line = Color(0xFFDDE3DA);
  static const lineStrong = Color(0xFFC9D3CC);
  static const connector = Color(0xFF9AA79E);

  static const ink = Color(0xFF17231B);
  static const inkBody = Color(0xFF2A372E);
  static const inkMuted = Color(0xFF4E5C52);
  static const inkSubtle = Color(0xFF5B6960);

  static const gold = Color(0xFFC99A3B);
  static const goldTint = Color(0xFFFBF3E3);
  static const goldLine = Color(0xFFEAD7AE);
  static const goldInk = Color(0xFF8A5A12);
  static const goldInkDark = Color(0xFF5A3D0C);
  static const goldOnDark = Color(0xFFE2C98F);

  static const lateRing = Color(0xFF8B958E);
  static const lateCard = Color(0xFFF7F8F6);
  static const memorial = Color(0xFF2F3B33);

  static const danger = Color(0xFFB3261E);
  static const dangerInk = Color(0xFF8C1D17);
  static const dangerTint = Color(0xFFFDECEA);

  static const maleBg = Color(0xFFDCEDE2);
  static const maleFg = Color(0xFF134A2C);
  static const femaleBg = Color(0xFFF3E6CF);
  static const femaleFg = Color(0xFF6B4410);
  static const unknownBg = Color(0xFFE6EBE5);
  static const unknownFg = Color(0xFF3E4A42);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: Bua.green).copyWith(
    primary: Bua.green,
    onPrimary: Colors.white,
    primaryContainer: Bua.greenTint,
    onPrimaryContainer: Bua.greenDark,
    secondary: Bua.gold,
    tertiary: Bua.goldInk,
    tertiaryContainer: Bua.goldTint,
    onTertiaryContainer: Bua.goldInkDark,
    surface: Bua.surface,
    onSurface: Bua.ink,
    onSurfaceVariant: Bua.inkMuted,
    surfaceContainerLowest: Bua.surface,
    surfaceContainerLow: Bua.ground,
    surfaceContainer: Bua.surfaceMuted,
    surfaceContainerHigh: Bua.surfaceMuted,
    surfaceContainerHighest: Bua.track,
    outline: Bua.lineStrong,
    outlineVariant: Bua.line,
    error: Bua.danger,
  );

  const radius12 = BorderRadius.all(Radius.circular(12));
  const radius14 = BorderRadius.all(Radius.circular(14));
  OutlineInputBorder border(Color c, [double w = 1]) =>
      OutlineInputBorder(borderRadius: radius12, borderSide: BorderSide(color: c, width: w));

  final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: 'NotoSans');
  final text = base.textTheme.apply(bodyColor: Bua.ink, displayColor: Bua.ink).copyWith(
        headlineSmall: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Bua.ink),
        titleLarge: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Bua.ink),
        titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Bua.ink),
        titleSmall: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Bua.ink),
        bodyLarge: const TextStyle(fontSize: 15, height: 1.5, color: Bua.inkBody),
        bodyMedium: const TextStyle(fontSize: 14, color: Bua.ink),
        bodySmall: const TextStyle(fontSize: 13, color: Bua.inkSubtle),
        labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        labelSmall: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      )
      // The styles above replace the base ones, so set the font again: the
      // web's default font lacks the Hausa letters (ɗ ƙ ƴ).
      .apply(fontFamily: 'NotoSans');

  return base.copyWith(
    scaffoldBackgroundColor: Bua.ground,
    textTheme: text,
    appBarTheme: const AppBarTheme(
      backgroundColor: Bua.ground,
      foregroundColor: Bua.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontFamily: 'NotoSans', fontSize: 20, fontWeight: FontWeight.w700, color: Bua.ink),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Bua.green,
        foregroundColor: Colors.white,
        minimumSize: const Size(64, 48),
        shape: const RoundedRectangleBorder(borderRadius: radius14),
        textStyle: const TextStyle(fontFamily: 'NotoSans', fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Bua.greenDark,
        minimumSize: const Size(64, 48),
        side: const BorderSide(color: Bua.lineStrong),
        shape: const RoundedRectangleBorder(borderRadius: radius14),
        textStyle: const TextStyle(fontFamily: 'NotoSans', fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Bua.green,
        minimumSize: const Size(44, 44),
        textStyle: const TextStyle(fontFamily: 'NotoSans', fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(minimumSize: const Size(44, 44))),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Bua.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border(Bua.lineStrong),
      enabledBorder: border(Bua.lineStrong),
      focusedBorder: border(Bua.green, 2),
      errorBorder: border(Bua.danger),
      focusedErrorBorder: border(Bua.danger, 2),
      labelStyle: const TextStyle(color: Bua.inkMuted),
      hintStyle: const TextStyle(color: Bua.inkSubtle),
    ),
    cardTheme: const CardThemeData(
      color: Bua.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Bua.surface,
      selectedColor: Bua.green,
      side: const BorderSide(color: Bua.lineStrong),
      shape: const StadiumBorder(),
      showCheckmark: false,
      labelStyle: const TextStyle(fontFamily: 'NotoSans', fontSize: 13, fontWeight: FontWeight.w500, color: Bua.ink),
      secondaryLabelStyle:
          const TextStyle(fontFamily: 'NotoSans', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Bua.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Bua.greenIndicator,
      height: 76,
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
            fontFamily: 'NotoSans',
            fontSize: 11.5,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? Bua.greenDark : Bua.inkMuted,
          )),
      iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(color: s.contains(WidgetState.selected) ? Bua.greenDark : Bua.inkMuted)),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Bua.surface,
      indicatorColor: Bua.greenIndicator,
      selectedIconTheme: IconThemeData(color: Bua.greenDark),
      unselectedIconTheme: IconThemeData(color: Bua.inkMuted),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: Bua.greenDark,
      unselectedLabelColor: Bua.inkMuted,
      indicatorColor: Bua.green,
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Bua.line,
      labelStyle: TextStyle(fontFamily: 'NotoSans', fontSize: 14, fontWeight: FontWeight.w700),
      unselectedLabelStyle: TextStyle(fontFamily: 'NotoSans', fontSize: 14, fontWeight: FontWeight.w500),
    ),
    dividerTheme: const DividerThemeData(color: Bua.surfaceMuted, space: 1, thickness: 1),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Bua.green : Bua.lineStrong),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Bua.green : null),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Bua.green,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18))),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    dialogTheme: const DialogThemeData(
      backgroundColor: Bua.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
    ),
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Bua.surface, surfaceTintColor: Colors.transparent),
    popupMenuTheme: const PopupMenuThemeData(color: Bua.surface, surfaceTintColor: Colors.transparent),
    badgeTheme: const BadgeThemeData(backgroundColor: Bua.danger),
  );
}
