import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings kept on this phone only.
class DevicePrefs {
  const DevicePrefs({this.tapToLoadPhotos = false, this.shrinkUploads = true});

  /// Data saver: photos load only when tapped.
  final bool tapToLoadPhotos;

  /// Resize photos before upload (up to 80% less data).
  final bool shrinkUploads;

  DevicePrefs copyWith({bool? tapToLoadPhotos, bool? shrinkUploads}) => DevicePrefs(
        tapToLoadPhotos: tapToLoadPhotos ?? this.tapToLoadPhotos,
        shrinkUploads: shrinkUploads ?? this.shrinkUploads,
      );
}

class DevicePrefsNotifier extends Notifier<DevicePrefs> {
  static const _tapKey = 'tap_to_load_photos';
  static const _shrinkKey = 'shrink_uploads';

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
      );
    } catch (_) {
      // No storage (e.g. private browsing): keep defaults.
    }
  }

  Future<void> set({bool? tapToLoadPhotos, bool? shrinkUploads}) async {
    state = state.copyWith(tapToLoadPhotos: tapToLoadPhotos, shrinkUploads: shrinkUploads);
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_tapKey, state.tapToLoadPhotos);
      await p.setBool(_shrinkKey, state.shrinkUploads);
    } catch (_) {}
  }
}

final devicePrefsProvider = NotifierProvider<DevicePrefsNotifier, DevicePrefs>(DevicePrefsNotifier.new);
