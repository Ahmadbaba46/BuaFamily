import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;

/// Colours from the Bua Family design ("Arewa green": deep green with a gold
/// zanen-gida motif). Text colours meet WCAG AA on their intended backgrounds.
abstract final class Bua {
  /// Dark colours are in use. The app sets this from the member's choice
  /// (or the phone's setting) and rebuilds everything when it changes.
  static bool dark = false;

  static Color _pick(int light, int night) => Color(dark ? night : light);

  /// Deep green for text on white chips and buttons, the same in both modes.
  static const onWhite = Color(0xFF134A2C);

  static Color get green => _pick(0xFF1D6B40, 0xFF2F8F59);
  static Color get greenDark => _pick(0xFF134A2C, 0xFFA8DDB9);
  static Color get greenTint => _pick(0xFFE3F0E7, 0xFF1E3326);
  static Color get greenIndicator => _pick(0xFFD6EADC, 0xFF27432F);
  static Color get greenOnDark => _pick(0xFFD6EADC, 0xFFD6EADC);

  static Color get ground => _pick(0xFFF4F6F2, 0xFF0F1511);
  static Color get surface => _pick(0xFFFFFFFF, 0xFF18201B);
  static Color get surfaceMuted => _pick(0xFFEEF2EC, 0xFF202A23);
  static Color get track => _pick(0xFFE6EBE5, 0xFF26312A);
  static Color get line => _pick(0xFFDDE3DA, 0xFF2C3830);
  static Color get lineStrong => _pick(0xFFC9D3CC, 0xFF3B4A40);
  static Color get connector => _pick(0xFF9AA79E, 0xFF5E6E63);

  static Color get ink => _pick(0xFF17231B, 0xFFE8EEE9);
  static Color get inkBody => _pick(0xFF2A372E, 0xFFD5DDD7);
  static Color get inkMuted => _pick(0xFF4E5C52, 0xFFB4C0B7);
  static Color get inkSubtle => _pick(0xFF5B6960, 0xFF9AA79E);

  static Color get gold => _pick(0xFFC99A3B, 0xFFC99A3B);
  static Color get goldTint => _pick(0xFFFBF3E3, 0xFF2E2618);
  static Color get goldLine => _pick(0xFFEAD7AE, 0xFF5A4A28);
  static Color get goldInk => _pick(0xFF8A5A12, 0xFFE2C98F);
  static Color get goldInkDark => _pick(0xFF5A3D0C, 0xFFF0DDB0);
  static Color get goldOnDark => _pick(0xFFE2C98F, 0xFFE2C98F);

  static Color get lateRing => _pick(0xFF8B958E, 0xFF6F7A73);
  static Color get lateCard => _pick(0xFFF7F8F6, 0xFF1C221E);
  static Color get memorial => _pick(0xFF2F3B33, 0xFF28322C);

  static Color get danger => _pick(0xFFB3261E, 0xFFDB5248);
  static Color get dangerInk => _pick(0xFF8C1D17, 0xFFF2B8B3);
  static Color get dangerTint => _pick(0xFFFDECEA, 0xFF3A1D1B);

  static Color get maleBg => _pick(0xFFDCEDE2, 0xFF1E3326);
  static Color get maleFg => _pick(0xFF134A2C, 0xFFA8DDB9);
  static Color get femaleBg => _pick(0xFFF3E6CF, 0xFF3A2E1A);
  static Color get femaleFg => _pick(0xFF6B4410, 0xFFF0D29C);
  static Color get unknownBg => _pick(0xFFE6EBE5, 0xFF26312A);
  static Color get unknownFg => _pick(0xFF3E4A42, 0xFFC5CFC8);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Bua.green,
    brightness: Bua.dark ? Brightness.dark : Brightness.light,
  ).copyWith(
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
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Bua.ink),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Bua.ink),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Bua.ink),
        titleSmall: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Bua.ink),
        bodyLarge: TextStyle(fontSize: 15, height: 1.5, color: Bua.inkBody),
        bodyMedium: TextStyle(fontSize: 14, color: Bua.ink),
        bodySmall: TextStyle(fontSize: 13, color: Bua.inkSubtle),
        labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        labelSmall: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      )
      // The styles above replace the base ones, so set the font again: the
      // web's default font lacks the Hausa letters (ɗ ƙ ƴ).
      .apply(fontFamily: 'NotoSans');

  return base.copyWith(
    scaffoldBackgroundColor: Bua.ground,
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: Bua.ground,
      foregroundColor: Bua.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: Bua.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
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
        side: BorderSide(color: Bua.lineStrong),
        shape: const RoundedRectangleBorder(borderRadius: radius14),
        textStyle: const TextStyle(fontFamily: 'NotoSans', fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        // Lighter in the dark, where the button green is too dim to read.
        foregroundColor: Bua.dark ? Bua.greenDark : Bua.green,
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
      labelStyle: TextStyle(color: Bua.inkMuted),
      hintStyle: TextStyle(color: Bua.inkSubtle),
    ),
    cardTheme: CardThemeData(
      color: Bua.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Bua.surface,
      selectedColor: Bua.green,
      side: BorderSide(color: Bua.lineStrong),
      shape: const StadiumBorder(),
      showCheckmark: false,
      labelStyle: TextStyle(fontFamily: 'NotoSans', fontSize: 13, fontWeight: FontWeight.w500, color: Bua.ink),
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
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Bua.surface,
      indicatorColor: Bua.greenIndicator,
      selectedIconTheme: IconThemeData(color: Bua.greenDark),
      unselectedIconTheme: IconThemeData(color: Bua.inkMuted),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: Bua.greenDark,
      unselectedLabelColor: Bua.inkMuted,
      indicatorColor: Bua.green,
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Bua.line,
      labelStyle: TextStyle(fontFamily: 'NotoSans', fontSize: 14, fontWeight: FontWeight.w700),
      unselectedLabelStyle: TextStyle(fontFamily: 'NotoSans', fontSize: 14, fontWeight: FontWeight.w500),
    ),
    dividerTheme: DividerThemeData(color: Bua.surfaceMuted, space: 1, thickness: 1),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Bua.green : Bua.lineStrong),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Bua.green : null),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Bua.green,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18))),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    dialogTheme: DialogThemeData(
      backgroundColor: Bua.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
    ),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: Bua.surface, surfaceTintColor: Colors.transparent),
    popupMenuTheme: PopupMenuThemeData(color: Bua.surface, surfaceTintColor: Colors.transparent),
    badgeTheme: BadgeThemeData(backgroundColor: Bua.danger),
  );
}
