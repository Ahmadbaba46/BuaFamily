import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings kept on this phone only.
class DevicePrefs {
  const DevicePrefs({this.tapToLoadPhotos = false, this.shrinkUploads = true, this.showHijri = true});

  /// Data saver: photos load only when tapped.
  final bool tapToLoadPhotos;

  /// Resize photos before upload (up to 80% less data).
  final bool shrinkUploads;

  /// Islamic (Hijri) dates next to the usual ones.
  final bool showHijri;

  DevicePrefs copyWith({bool? tapToLoadPhotos, bool? shrinkUploads, bool? showHijri}) => DevicePrefs(
        tapToLoadPhotos: tapToLoadPhotos ?? this.tapToLoadPhotos,
        shrinkUploads: shrinkUploads ?? this.shrinkUploads,
        showHijri: showHijri ?? this.showHijri,
      );
}

class DevicePrefsNotifier extends Notifier<DevicePrefs> {
  static const _tapKey = 'tap_to_load_photos';
  static const _shrinkKey = 'shrink_uploads';
  static const _hijriKey = 'show_hijri';

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
      );
    } catch (_) {
      // No storage (e.g. private browsing): keep defaults.
    }
  }

  Future<void> set({bool? tapToLoadPhotos, bool? shrinkUploads, bool? showHijri}) async {
    state = state.copyWith(tapToLoadPhotos: tapToLoadPhotos, shrinkUploads: shrinkUploads, showHijri: showHijri);
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_tapKey, state.tapToLoadPhotos);
      await p.setBool(_shrinkKey, state.shrinkUploads);
      await p.setBool(_hijriKey, state.showHijri);
    } catch (_) {}
  }
}

final devicePrefsProvider = NotifierProvider<DevicePrefsNotifier, DevicePrefs>(DevicePrefsNotifier.new);
