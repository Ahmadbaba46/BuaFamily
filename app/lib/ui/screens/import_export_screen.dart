import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/family_files.dart';
import '../../domain/tree_pdf.dart';
import '../../l10n/l10n.dart';
import '../../models/story.dart' show Backup;
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';
import '../widgets/family_book_dialog.dart';

String _stamp(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Saves [bytes] where the user chooses (or downloads it, on the web).
Future<void> saveBytes(BuildContext context, String name, Uint8List bytes, String mime) async {
  final l = context.l10n;
  final uri = await FilePicker.saveFile(fileName: name, bytes: bytes, mimeType: mime);
  if (uri != null && context.mounted) showSnack(context, l.savedFile(name));
}

/// Admins: export the tree, import a file, and download backups.
class ImportExportScreen extends ConsumerStatefulWidget {
  const ImportExportScreen({super.key});

  @override
  ConsumerState<ImportExportScreen> createState() => _ImportExportScreenState();
}

enum _Export { gedcom, csv, pdf }

class _ImportExportScreenState extends ConsumerState<ImportExportScreen> {
  bool _details = false;
  _Export? _busy;
  bool _reading = false;
  bool _backingUp = false;

  String get _family => ref.read(settingsProvider).value?.familyName ?? 'Bua';

  Future<void> _export(_Export kind) async {
    final l = context.l10n;
    setState(() => _busy = kind);
    await guarded(context, () async {
      final graph = await ref.read(graphProvider.future);
      final repo = ref.read(repositoryProvider);
      ExportDetails? details;
      if (_details && kind != _Export.pdf) {
        final d = await repo.allDetails();
        details = ExportDetails(contacts: d.contacts, health: d.health);
      }
      final base = '${_family.toLowerCase().replaceAll(RegExp(r'\s+'), '-')}-family-${_stamp(DateTime.now())}';
      final (String name, Uint8List bytes, String mime) = switch (kind) {
        _Export.gedcom => (
            '$base.ged',
            utf8.encode(exportGedcom(graph, details: details, familyName: _family)),
            'text/plain',
          ),
        // The byte-order mark lets Excel read Hausa letters correctly.
        _Export.csv => ('$base.csv', utf8.encode('﻿${exportFamilyCsv(graph, details: details)}'), 'text/csv'),
        _Export.pdf => (
            '$base.pdf',
            await printableTreePdf(
              graph,
              ref.read(settingsProvider).value?.rootPersonId ?? graph.suggestedRoot() ?? graph.persons.keys.first,
              regular: pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Regular.ttf')),
              bold: pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Bold.ttf')),
              title: l.treePosterTitle(_family),
              subtitle: l.treePosterSubtitle(graph.persons.length, l.formatDate(DateTime.now())),
            ),
            'application/pdf',
          ),
      };
      if (mounted) await saveBytes(context, name, bytes, mime);
    });
    if (mounted) setState(() => _busy = null);
  }

  Future<void> _import() async {
    final l = context.l10n;
    final f = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['ged', 'csv', 'txt']);
    if (f == null || !mounted) return;
    setState(() => _reading = true);
    try {
      final bytes = await f.readAsBytes();
      String text;
      try {
        text = utf8.decode(bytes);
      } on FormatException {
        text = latin1.decode(bytes);
      }
      final isGedcom = (f.extension ?? '').toLowerCase() == 'ged' || text.trimLeft().replaceFirst('﻿', '').startsWith('0 HEAD');
      final file = isGedcom ? parseGedcom(text) : parseFamilyCsv(text);
      final graph = await ref.read(graphProvider.future);
      if (mounted) await context.push('/admin/import', extra: planImport(file, graph));
    } on FileFormatException catch (e) {
      if (mounted) showSnack(context, l.importError(e.message));
    } catch (e) {
      if (mounted) showError(context, e);
    }
    if (mounted) setState(() => _reading = false);
  }

  Future<void> _downloadBackup(Backup b) => guarded(context, () async {
        final data = await ref.read(repositoryProvider).backupData(b.slot);
        final json = const JsonEncoder.withIndent(' ').convert(data);
        if (mounted) {
          await saveBytes(context, 'bua-family-backup-${_stamp(b.takenAt)}.json', utf8.encode(json), 'application/json');
        }
      });

  Future<void> _backupNow() async {
    setState(() => _backingUp = true);
    final ok = await guarded(context, ref.read(repositoryProvider).backupNow);
    if (!mounted) return;
    setState(() => _backingUp = false);
    if (ok) {
      ref.invalidate(backupsProvider);
      showSnack(context, context.l10n.backupDone);
    }
  }

  void _earlierBackups(List<Backup> all) {
    final l = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text(l.earlierBackups, style: Theme.of(c).textTheme.titleMedium),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(l.backupsKept, style: const TextStyle(fontSize: 13, color: Bua.inkSubtle)),
          ),
          for (final b in all)
            ListTile(
              leading: Icon(b.isRestorePoint ? Icons.undo : Icons.inventory_2_outlined, color: Bua.green),
              title: Text(b.isRestorePoint ? l.beforeLastRestore(l.weekdayDate(b.takenAt)) : l.weekdayDate(b.takenAt)),
              subtitle: Text('${l.clock(b.takenAt)} · ${(b.sizeBytes / 1024).ceil()} KB'),
              trailing: IconButton(
                tooltip: l.download,
                icon: const Icon(Icons.download_outlined),
                onPressed: () {
                  Navigator.pop(c);
                  _downloadBackup(b);
                },
              ),
            ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final weekly = ref.watch(settingsProvider).value?.weeklyBackup ?? true;
    final backups = ref.watch(backupsProvider).value ?? const <Backup>[];
    final latest = backups.where((b) => !b.isRestorePoint).firstOrNull;

    Widget exportRow(_Export kind, IconData icon, String title, String subtitle) => InkWell(
          onTap: _busy == null ? () => _export(kind) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              IconTile(icon, background: Bua.greenTint),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: Bua.inkMuted)),
                ]),
              ),
              if (_busy == kind)
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              else
                const Icon(Icons.download_outlined, color: Bua.inkSubtle, size: 20),
            ]),
          ),
        );

    Widget heading(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Text(text.toUpperCase(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: Bua.green)),
        );

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/more')),
        titleSpacing: 0,
        toolbarHeight: 68,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.dataTitle, style: Theme.of(context).textTheme.titleLarge, overflow: TextOverflow.ellipsis),
          Text(l.dataSubtitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Bua.inkSubtle), overflow: TextOverflow.ellipsis),
        ]),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
        SectionCard(children: [
          heading(l.exportHeading),
          exportRow(_Export.gedcom, Icons.account_tree_outlined, l.exportGedcom, l.exportGedcomSub),
          exportRow(_Export.csv, Icons.table_chart_outlined, l.exportCsv, l.exportCsvSub),
          exportRow(_Export.pdf, Icons.print_outlined, l.exportPdf, l.exportPdfSub),
          InkWell(
            onTap: _busy == null ? () => makeFamilyBook(context, ref) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(children: [
                const IconTile(Icons.menu_book_outlined, background: Bua.greenTint),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l.familyBookAction, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    Text(l.familyBookHint, style: const TextStyle(fontSize: 13, color: Bua.inkMuted)),
                  ]),
                ),
                const Icon(Icons.download_outlined, color: Bua.inkSubtle, size: 20),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ToggleRow(title: l.includeDetails, value: _details, onChanged: (v) => setState(() => _details = v)),
          ),
        ]),
        const SizedBox(height: 12),
        SectionCard(padding: const EdgeInsets.fromLTRB(0, 6, 0, 6), children: [
          heading(l.importHeading),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DashedBox(
              color: Bua.connector,
              fill: Bua.ground,
              onTap: _reading ? null : _import,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Column(children: [
                  if (_reading)
                    const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    const Icon(Icons.upload_outlined, color: Bua.green, size: 26),
                  const SizedBox(height: 8),
                  Text(l.chooseImportFile,
                      textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(l.importReviewNote,
                      textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Bua.inkSubtle)),
                ]),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextButton(
                onPressed: () => saveBytes(
                    context, 'bua-family-template.csv', utf8.encode('﻿${familyCsvTemplate()}'), 'text/csv'),
                child: Text(l.downloadTemplate),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        SectionCard(padding: const EdgeInsets.fromLTRB(16, 14, 16, 6), children: [
          Row(children: [
            IconTile(weekly ? Icons.verified_user_outlined : Icons.shield_outlined,
                background: weekly ? Bua.greenTint : Bua.surfaceMuted, color: weekly ? Bua.green : Bua.inkSubtle),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(weekly ? l.weeklyBackupOn : l.weeklyBackupOff,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                Text(latest == null ? l.noBackupYet : l.lastBackup(l.weekdayDate(latest.takenAt)),
                    style: const TextStyle(fontSize: 13, color: Bua.inkMuted)),
              ]),
            ),
            if (latest != null) OutlinedButton(onPressed: () => _downloadBackup(latest), child: Text(l.download)),
          ]),
          const SizedBox(height: 4),
          ToggleRow(
            title: l.keepWeeklyBackup,
            value: weekly,
            onChanged: (v) async {
              if (await guarded(context, () => ref.read(repositoryProvider).updateSettings({'weekly_backup': v}))) {
                ref.invalidate(settingsProvider);
              }
            },
          ),
          Wrap(spacing: 4, children: [
            TextButton.icon(
              onPressed: _backingUp ? null : _backupNow,
              icon: _backingUp
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.backup_outlined, size: 18),
              label: Text(l.backupNow),
            ),
            TextButton.icon(
              onPressed: () => context.push('/admin/restore'),
              icon: const Icon(Icons.settings_backup_restore, size: 18),
              label: Text(l.restoreEllipsis),
            ),
            if (backups.length > 1)
              TextButton.icon(
                onPressed: () => _earlierBackups(backups),
                icon: const Icon(Icons.history, size: 18),
                label: Text(l.earlierBackups),
              ),
          ]),
        ]),
      ]),
    );
  }
}

/// Check what an import will add before anything changes.
class ImportReviewScreen extends ConsumerStatefulWidget {
  const ImportReviewScreen({super.key, required this.plan});

  final ImportPlan plan;

  @override
  ConsumerState<ImportReviewScreen> createState() => _ImportReviewScreenState();
}

class _ImportReviewScreenState extends ConsumerState<ImportReviewScreen> {
  bool _saving = false;

  Future<void> _add() async {
    final l = context.l10n;
    setState(() => _saving = true);
    Map<String, dynamic>? result;
    final ok = await guarded(context, () async {
      result = await ref.read(repositoryProvider).adminImport(widget.plan.toJson());
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok || result == null) return;
    final r = result!;
    final links = (r['parents'] as int? ?? 0) + (r['unions'] as int? ?? 0);
    final skipped = r['skipped'] as int? ?? 0;
    showSnack(context, [l.importDone(r['people'] as int? ?? 0, links), if (skipped > 0) l.importSkipped(skipped)].join(' '));
    ref.invalidate(graphProvider);
    context.canPop() ? context.pop() : context.go('/admin/data');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final plan = widget.plan;
    final rows = [...plan.rows]..sort((a, b) => (a.isNew ? 0 : 1).compareTo(b.isNew ? 0 : 1));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l.close,
          icon: const Icon(Icons.close),
          onPressed: () => context.canPop() ? context.pop() : context.go('/admin/data'),
        ),
        title: Text(l.reviewImport, style: Theme.of(context).textTheme.titleMedium),
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Text(l.importSummary(plan.newCount, plan.matchCount, plan.linkCount),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Bua.inkBody)),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: rows.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final r = rows[i];
              final year = r.person.birthYear;
              return Material(
                color: Bua.surface,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text([r.person.name, if (year != null) '$year'].join(' · '),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: r.isNew && !r.include ? Bua.inkSubtle : Bua.ink,
                              decoration: r.isNew && !r.include ? TextDecoration.lineThrough : null,
                            )),
                        if (r.isNew)
                          Text(l.importNew,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Bua.goldInk))
                        else
                          Text(l.sameAs(r.match!.displayName),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Bua.green)),
                      ]),
                    ),
                    if (r.isNew)
                      Checkbox(value: r.include, onChanged: (v) => setState(() => r.include = v ?? true))
                    else
                      TextButton(onPressed: () => setState(() => r.match = null), child: Text(l.notSame)),
                  ]),
                ),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: FilledButton(
              onPressed: _saving || (plan.newCount == 0 && plan.linkCount == 0) ? null : _add,
              child: Text(_saving ? l.uploading : l.addToTree),
            ),
          ),
        ),
      ]),
    );
  }
}
