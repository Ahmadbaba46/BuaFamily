import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings kept on this phone only.
class DevicePrefs {
  const DevicePrefs({
    this.tapToLoadPhotos = false,
    this.shrinkUploads = true,
    this.showHijri = true,
    this.familyLine = false,
    this.appearance = Appearance.system,
    this.textScale = 1.0,
  });

  /// Data saver: photos load only when tapped.
  final bool tapToLoadPhotos;

  /// Resize photos before upload (up to 80% less data).
  final bool shrinkUploads;

  /// Islamic (Hijri) dates next to the usual ones.
  final bool showHijri;

  /// The Tree page opens on the family line (one generation at a time)
  /// instead of the whole tree.
  final bool familyLine;

  /// Light, dark, or as the phone is set.
  final Appearance appearance;

  /// Text size on top of the phone's own: 1.0, 1.15 or 1.3.
  final double textScale;

  DevicePrefs copyWith({
    bool? tapToLoadPhotos,
    bool? shrinkUploads,
    bool? showHijri,
    bool? familyLine,
    Appearance? appearance,
    double? textScale,
  }) =>
      DevicePrefs(
        tapToLoadPhotos: tapToLoadPhotos ?? this.tapToLoadPhotos,
        shrinkUploads: shrinkUploads ?? this.shrinkUploads,
        showHijri: showHijri ?? this.showHijri,
        familyLine: familyLine ?? this.familyLine,
        appearance: appearance ?? this.appearance,
        textScale: textScale ?? this.textScale,
      );
}

enum Appearance { system, light, dark }

/// The text sizes members can choose (on top of the phone's own setting).
const textScales = [1.0, 1.15, 1.3];

class DevicePrefsNotifier extends Notifier<DevicePrefs> {
  static const _tapKey = 'tap_to_load_photos';
  static const _shrinkKey = 'shrink_uploads';
  static const _hijriKey = 'show_hijri';
  static const _familyLineKey = 'tree_family_line';
  static const _appearanceKey = 'appearance';
  static const _textScaleKey = 'text_scale';

  @override
  DevicePrefs build() {
    _load();
    return const DevicePrefs();
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      state = DevicePrefs(
        tapToLoadPhotos: p.getBool(_tapKey) ?? false,
        shrinkUploads: p.getBool(_shrinkKey) ?? true,
        showHijri: p.getBool(_hijriKey) ?? true,
        familyLine: p.getBool(_familyLineKey) ?? false,
        appearance: Appearance.values.asNameMap()[p.getString(_appearanceKey)] ?? Appearance.system,
        textScale: textScales.contains(p.getDouble(_textScaleKey)) ? p.getDouble(_textScaleKey)! : 1.0,
      );
    } catch (_) {
      // No storage (e.g. private browsing): keep defaults.
    }
  }

  Future<void> set({
    bool? tapToLoadPhotos,
    bool? shrinkUploads,
    bool? showHijri,
    bool? familyLine,
    Appearance? appearance,
    double? textScale,
  }) async {
    state = state.copyWith(
      tapToLoadPhotos: tapToLoadPhotos,
      shrinkUploads: shrinkUploads,
      showHijri: showHijri,
      familyLine: familyLine,
      appearance: appearance,
      textScale: textScale,
    );
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_tapKey, state.tapToLoadPhotos);
      await p.setBool(_shrinkKey, state.shrinkUploads);
      await p.setBool(_hijriKey, state.showHijri);
      await p.setBool(_familyLineKey, state.familyLine);
      await p.setString(_appearanceKey, state.appearance.name);
      await p.setDouble(_textScaleKey, state.textScale);
    } catch (_) {}
  }
}

final devicePrefsProvider = NotifierProvider<DevicePrefsNotifier, DevicePrefs>(DevicePrefsNotifier.new);
