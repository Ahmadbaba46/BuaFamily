import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/family_book.dart';
import '../../l10n/l10n.dart';
import '../../state/providers.dart';
import '../screens/import_export_screen.dart' show saveBytes;
import '../theme.dart';
import 'common.dart';

/// Asks whether to include photos, then makes the family book and offers it
/// to save or share.
Future<void> makeFamilyBook(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  var photos = true;
  final go = await showDialog<bool>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, setState) => AlertDialog(
        title: Text(l.familyBookAction),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.familyBookHint, style: TextStyle(fontSize: 14, height: 1.45, color: Bua.inkMuted)),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.includePhotos),
            subtitle: Text(l.includePhotosHint),
            value: photos,
            onChanged: (v) => setState(() => photos = v),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.makeBook)),
        ],
      ),
    ),
  );
  if (go != true || !context.mounted) return;

  final navigator = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(children: [
          const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
          const SizedBox(width: 16),
          Expanded(child: Text(l.makingBook)),
        ]),
      ),
    ),
  );
  Uint8List? bytes;
  Object? error;
  String family = 'Bua';
  try {
    final graph = await ref.read(graphProvider.future);
    final settings = ref.read(settingsProvider).value;
    family = settings?.familyName ?? 'Bua';
    final root = [settings?.rootPersonId, graph.suggestedRoot()].firstWhere((id) => id != null && graph[id] != null,
        orElse: () => graph.persons.keys.firstOrNull);
    if (root == null) throw StateError('empty tree');
    final images = <String, Uint8List>{};
    if (photos) {
      final repo = ref.read(repositoryProvider);
      final wanted = graph.persons.values.where((p) => p.photoPath != null).toList();
      // A few at a time, so a slow connection still gets there.
      for (var i = 0; i < wanted.length; i += 6) {
        await Future.wait([
          for (final p in wanted.skip(i).take(6))
            repo.photoBytes(p.photoPath!).then((b) => images[p.id] = b).catchError((Object _) => Uint8List(0)),
        ]);
      }
      images.removeWhere((_, b) => b.isEmpty);
    }
    bytes = await familyBookPdf(
      graph,
      root,
      l,
      regular: pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Regular.ttf')),
      bold: pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Bold.ttf')),
      familyName: family,
      generatedAt: DateTime.now(),
      photos: images,
    );
  } catch (e) {
    error = e;
  }
  navigator.pop();
  if (!context.mounted) return;
  if (error != null || bytes == null) {
    showError(context, error ?? StateError('no book'));
    return;
  }
  final name = '${family.toLowerCase().replaceAll(RegExp(r'\s+'), '-')}-family-book.pdf';
  await saveBytes(context, name, bytes, 'application/pdf');
}
