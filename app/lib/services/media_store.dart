import 'dart:io' show Directory, File;

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Photos and voice notes from conversations, kept on the phone once
/// downloaded, so they show straight away (and offline) the next time.
class MediaStore {
  MediaStore._();

  static final instance = MediaStore._();

  bool _disabled = false;
  Directory? _dir;

  Future<Directory?> _folder() async {
    if (_disabled || kIsWeb) return null;
    try {
      return _dir ??= await Directory('${(await getApplicationSupportDirectory()).path}/dm_media').create(recursive: true);
    } catch (_) {
      _disabled = true; // e.g. in tests
      return null;
    }
  }

  String _name(String path) => path.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');

  /// The saved copy's file, if there is one.
  Future<File?> file(String path) async {
    final dir = await _folder();
    if (dir == null) return null;
    final f = File('${dir.path}/${_name(path)}');
    return await f.exists() ? f : null;
  }

  Future<Uint8List?> read(String path) async {
    try {
      return await (await file(path))?.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  Future<File?> write(String path, Uint8List bytes) async {
    try {
      final dir = await _folder();
      if (dir == null) return null;
      return await File('${dir.path}/${_name(path)}').writeAsBytes(bytes, flush: true);
    } catch (_) {
      return null;
    }
  }
}
