import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../models/story.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';

/// Admins: put a backup back. A trial run shows what will change first.
class RestoreScreen extends ConsumerStatefulWidget {
  const RestoreScreen({super.key});

  @override
  ConsumerState<RestoreScreen> createState() => _RestoreScreenState();
}

class _RestoreScreenState extends ConsumerState<RestoreScreen> {
  int? _slot;
  Object? _fileData;
  String? _fileName;
  bool _undoChanges = false;

  RestoreSummary? _preview;
  Object? _previewError;
  bool _checking = false;
  bool _restoring = false;
  int _request = 0;

  bool get _chosen => _slot != null || _fileData != null;

  Future<Map<String, dynamic>> _run({required bool dryRun}) {
    final repo = ref.read(repositoryProvider);
    return _fileData != null
        ? repo.restoreData(_fileData!, undoChanges: _undoChanges, dryRun: dryRun)
        : repo.restoreBackup(_slot!, undoChanges: _undoChanges, dryRun: dryRun);
  }

  Future<void> _check() async {
    if (!_chosen) return;
    final id = ++_request;
    setState(() {
      _checking = true;
      _preview = null;
      _previewError = null;
    });
    try {
      final r = await _run(dryRun: true);
      if (mounted && id == _request) setState(() => _preview = RestoreSummary(r));
    } catch (e) {
      if (mounted && id == _request) setState(() => _previewError = e);
    }
    if (mounted && id == _request) setState(() => _checking = false);
  }

  Future<void> _chooseFile() async {
    final l = context.l10n;
    final f = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['json']);
    if (f == null || !mounted) return;
    try {
      final data = jsonDecode(utf8.decode(await f.readAsBytes()));
      if (data is! Map || data['format'] != 'bua-family-backup') throw const FormatException();
      setState(() {
        _fileData = data;
        _fileName = f.name;
        _slot = null;
      });
      await _check();
    } on FormatException {
      if (mounted) showSnack(context, l.notABackup);
    }
  }

  Future<void> _restore() async {
    final l = context.l10n;
    if (!await confirm(context, l.restoreConfirm) || !mounted) return;
    setState(() => _restoring = true);
    RestoreSummary? done;
    final ok = await guarded(context, () async => done = RestoreSummary(await _run(dryRun: false)));
    if (!mounted) return;
    setState(() => _restoring = false);
    if (!ok || done == null) return;
    for (final p in [graphProvider, backupsProvider, storiesProvider, feedProvider, eventsProvider, settingsProvider]) {
      ref.invalidate(p);
    }
    refreshFund(ref);
    showSnack(context, l.restoreDone(done!.added, done!.updated));
    context.canPop() ? context.pop() : context.go('/admin/data');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final backups = ref.watch(backupsProvider);

    String label(Backup b) => b.isRestorePoint
        ? l.beforeLastRestore('${l.weekdayDate(b.takenAt)}, ${l.clock(b.takenAt)}')
        : '${l.weekdayDate(b.takenAt)} · ${l.clock(b.takenAt)}';

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/admin/data')),
        titleSpacing: 0,
        toolbarHeight: 68,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.restoreTitle, style: Theme.of(context).textTheme.titleLarge, overflow: TextOverflow.ellipsis),
            Text(
              l.restoreSubtitle,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Bua.inkSubtle),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          SectionCard(
            title: l.chooseBackup,
            children: [
              Material(
                type: MaterialType.transparency,
                child: RadioGroup<Object>(
                  groupValue: _fileData != null ? 'file' : _slot,
                  onChanged: (v) {
                    if (v == 'file') {
                      _chooseFile();
                    } else if (v is int) {
                      setState(() {
                        _slot = v;
                        _fileData = null;
                        _fileName = null;
                      });
                      _check();
                    }
                  },
                  child: Column(
                    children: [
                      for (final b in backups.value ?? const <Backup>[])
                        RadioListTile<Object>(
                          value: b.slot,
                          title: Text(label(b), style: const TextStyle(fontSize: 15)),
                          subtitle: Text('${(b.sizeBytes / 1024).ceil()} KB', style: const TextStyle(fontSize: 12)),
                          secondary: Icon(b.isRestorePoint ? Icons.undo : Icons.inventory_2_outlined, color: Bua.green),
                        ),
                      if (backups.isLoading)
                        const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
                      RadioListTile<Object>(
                        value: 'file',
                        title: Text(
                          _fileName == null ? l.backupFile : l.backupFileChosen(_fileName!),
                          style: const TextStyle(fontSize: 15),
                        ),
                        secondary: const Icon(Icons.upload_file_outlined, color: Bua.green),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SectionCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            children: [
              ToggleRow(
                title: l.undoChanges,
                subtitle: l.undoChangesSub,
                value: _undoChanges,
                onChanged: (v) {
                  setState(() => _undoChanges = v);
                  _check();
                },
              ),
            ],
          ),
          if (_chosen) ...[
            const SizedBox(height: 12),
            SectionCard(
              title: l.restorePreview,
              padding: const EdgeInsets.fromLTRB(0, 6, 0, 14),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _checking
                      ? Row(
                          children: [
                            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                            const SizedBox(width: 12),
                            Text(l.checkingBackup, style: const TextStyle(color: Bua.inkMuted)),
                          ],
                        )
                      : _previewError != null
                      ? Text(errorText(_previewError!), style: const TextStyle(color: Bua.danger))
                      : _preview == null
                      ? const SizedBox.shrink()
                      : _PreviewList(summary: _preview!),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          InfoBanner(icon: Icons.shield_outlined, text: l.restoreSafety, tone: BannerTone.green),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(l.restoreLimits, style: const TextStyle(fontSize: 12, height: 1.45, color: Bua.inkSubtle)),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _restoring || _checking || _preview == null || _preview!.nothingToDo ? null : _restore,
            icon: _restoring
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.settings_backup_restore),
            label: Text(l.restoreButton),
          ),
        ],
      ),
    );
  }
}

class _PreviewList extends StatelessWidget {
  const _PreviewList({required this.summary});

  final RestoreSummary summary;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (summary.nothingToDo) {
      return Text(l.restoreUpToDate, style: const TextStyle(fontSize: 14, height: 1.4, color: Bua.inkMuted));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final g in RestoreSummary.order)
          if (summary.groups[g] case final c? when !c.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.restoreGroup(g == 'community' ? 'other' : g),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    [
                      if (c.added > 0 || c.updated > 0) l.restoreCounts(c.added, c.updated),
                      if (c.skipped > 0) l.restoreSkippedCount(c.skipped),
                    ].join(' · '),
                    style: TextStyle(fontSize: 13, color: c.added + c.updated > 0 ? Bua.green : Bua.inkSubtle),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}
