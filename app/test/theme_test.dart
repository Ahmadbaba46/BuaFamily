import 'package:bua_family/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

void main() {
  tearDown(() => Bua.dark = false);

  test('the palette and theme follow light or dark', () {
    expect(Bua.surface, const Color(0xFFFFFFFF));
    expect(buildTheme().colorScheme.brightness, Brightness.light);
    Bua.dark = true;
    expect(Bua.surface, const Color(0xFF18201B));
    final theme = buildTheme();
    expect(theme.colorScheme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, Bua.ground);
    expect(Bua.onWhite, const Color(0xFF134A2C), reason: 'text on white chips stays dark in both modes');
  });

  test('text stays readable in the dark', () {
    Bua.dark = true;
    expect(_contrast(Bua.ink, Bua.surface), greaterThan(7));
    expect(_contrast(Bua.inkMuted, Bua.surface), greaterThan(4.5));
    expect(_contrast(Bua.inkSubtle, Bua.surface), greaterThan(4.5));
    expect(_contrast(Bua.greenDark, Bua.greenTint), greaterThan(4.5));
    expect(_contrast(Bua.goldInk, Bua.goldTint), greaterThan(4.5));
    expect(_contrast(Bua.dangerInk, Bua.dangerTint), greaterThan(4.5));
    expect(_contrast(Colors.white, Bua.green), greaterThan(3.9), reason: 'button labels on green');
  });
}
