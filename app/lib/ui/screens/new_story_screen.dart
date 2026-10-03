import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../l10n/l10n.dart';
import '../../models/person.dart';
import '../../models/story.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';
import 'stories_screen.dart' show languageName;

/// Record an elder (or upload an old recording) and describe it.
class NewStoryScreen extends ConsumerStatefulWidget {
  const NewStoryScreen({super.key});

  @override
  ConsumerState<NewStoryScreen> createState() => _NewStoryScreenState();
}

class _NewStoryScreenState extends ConsumerState<NewStoryScreen> {
  final _title = TextEditingController();
  final _source = TextEditingController();
  final _transcript = TextEditingController();
  String _speakerText = '';
  Person? _speaker;
  String _language = 'ha';

  AudioRecorder? _recorder;
  Timer? _ticker;
  DateTime? _startedAt;
  Duration _elapsed = Duration.zero;

  Uint8List? _audio;
  String _ext = 'm4a';
  String? _fileName;
  Duration? _length;
  bool _saving = false;

  bool get _recording => _startedAt != null;

  @override
  void dispose() {
    _ticker?.cancel();
    _recorder?.dispose();
    for (final c in [_title, _source, _transcript]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _start() async {
    final l = context.l10n;
    final rec = _recorder ??= AudioRecorder();
    try {
      if (!await rec.hasPermission()) {
        if (mounted) showSnack(context, l.micDenied);
        return;
      }
      // AAC plays on every phone; browsers that can't record it use Opus.
      final aac = await rec.isEncoderSupported(AudioEncoder.aacLc);
      _ext = aac ? 'm4a' : (kIsWeb ? 'webm' : 'ogg');
      final path = kIsWeb
          ? ''
          : '${(await getTemporaryDirectory()).path}/story_${DateTime.now().millisecondsSinceEpoch}.$_ext';
      await rec.start(
        RecordConfig(encoder: aac ? AudioEncoder.aacLc : AudioEncoder.opus, bitRate: 64000, numChannels: 1),
        path: path,
      );
    } catch (e) {
      if (mounted) showError(context, e);
      return;
    }
    setState(() {
      _audio = null;
      _fileName = null;
      _startedAt = DateTime.now();
      _elapsed = Duration.zero;
    });
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted && _startedAt != null) setState(() => _elapsed = DateTime.now().difference(_startedAt!));
    });
  }

  Future<void> _stop() async {
    _ticker?.cancel();
    final length = DateTime.now().difference(_startedAt!);
    try {
      final out = await _recorder!.stop();
      final bytes = out == null ? null : await XFile(out).readAsBytes();
      setState(() {
        _startedAt = null;
        _audio = bytes;
        _length = length;
      });
    } catch (e) {
      setState(() => _startedAt = null);
      if (mounted) showError(context, e);
    }
  }

  Future<void> _chooseFile() async {
    final f = await FilePicker.pickFile(type: FileType.audio);
    if (f == null) return;
    final bytes = await f.readAsBytes();
    setState(() {
      _audio = bytes;
      _ext = (f.extension ?? 'mp3').toLowerCase();
      _fileName = f.name;
      _length = null;
    });
  }

  Future<void> _save() async {
    final l = context.l10n;
    if (_audio == null) return showSnack(context, l.needAudio);
    if (_title.text.trim().isEmpty || (_speaker == null && _speakerText.trim().isEmpty)) {
      return showSnack(context, l.needTitleSpeaker);
    }
    String? opt(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    setState(() => _saving = true);
    final ok = await guarded(
      context,
      () => ref.read(repositoryProvider).addStory(
            audio: _audio!,
            extension: _ext,
            title: _title.text,
            speakerId: _speaker?.id,
            speakerName: _speakerText,
            language: _language,
            durationSeconds: _length?.inSeconds,
            sourceNote: opt(_source),
            transcript: opt(_transcript),
          ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) return;
    ref.invalidate(storiesProvider);
    context.canPop() ? context.pop() : context.go('/stories');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final people = ref.watch(graphProvider).value?.persons.values.toList() ?? const <Person>[];

    final status = _recording
        ? l.recordingNow(clockDuration(_elapsed))
        : _audio == null
            ? l.tapToRecord
            : _fileName ?? l.recordedLength(clockDuration(_length ?? Duration.zero));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l.close,
          icon: const Icon(Icons.close),
          onPressed: () => context.canPop() ? context.pop() : context.go('/stories'),
        ),
        title: Text(l.newStory, style: Theme.of(context).textTheme.titleMedium),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
          child: Column(children: [
            Material(
              color: _recording ? Bua.dangerInk : Bua.danger,
              shape: const CircleBorder(),
              elevation: _recording ? 0 : 4,
              shadowColor: Bua.danger.withValues(alpha: 0.4),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _saving ? null : (_recording ? _stop : _start),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: Icon(_recording ? Icons.stop_rounded : Icons.mic_none, color: Colors.white, size: 34,
                      semanticLabel: _recording ? l.tapToStop : l.tapToRecord),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _recording ? Bua.danger : Bua.ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                )),
            const SizedBox(height: 4),
            if (_recording)
              Text(l.tapToStop, style: const TextStyle(fontSize: 13, color: Bua.inkSubtle))
            else if (_audio != null)
              TextButton.icon(onPressed: _start, icon: const Icon(Icons.refresh, size: 18), label: Text(l.recordAgain))
            else
              Text(l.recordHint,
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, height: 1.4, color: Bua.inkMuted)),
            const Divider(height: 28),
            TextButton.icon(
              onPressed: _recording || _saving ? null : _chooseFile,
              icon: const Icon(Icons.audio_file_outlined, size: 18),
              label: Text(l.chooseAudioFile, textAlign: TextAlign.center),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        SectionCard(padding: const EdgeInsets.all(16), children: [
          LabeledField(
            label: l.storyTitle,
            child: TextField(controller: _title, textCapitalization: TextCapitalization.sentences),
          ),
          const SizedBox(height: 14),
          LabeledField(
            label: l.whoSpeaking,
            child: Autocomplete<Person>(
              displayStringForOption: (p) => p.displayName,
              optionsBuilder: (v) {
                final q = v.text.trim().toLowerCase();
                if (q.isEmpty) return const [];
                return people.where((p) => p.displayName.toLowerCase().contains(q)).take(8);
              },
              onSelected: (p) => setState(() {
                _speaker = p;
                _speakerText = p.displayName;
              }),
              fieldViewBuilder: (context, controller, focus, onSubmit) => TextField(
                controller: controller,
                focusNode: focus,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.person_search_outlined, size: 20)),
                onChanged: (t) => setState(() {
                  _speakerText = t;
                  if (_speaker != null && t != _speaker!.displayName) _speaker = null;
                }),
              ),
            ),
          ),
          const SizedBox(height: 14),
          LabeledField(
            label: l.language,
            child: PillSegmented<String>(
              values: const ['ha', 'en', 'other'],
              expand: true,
              height: 38,
              labelOf: (c) => languageName(l, c),
              selected: _language,
              onChanged: (c) => setState(() => _language = c),
            ),
          ),
          const SizedBox(height: 14),
          LabeledField(
            label: l.sourceNote,
            child: TextField(controller: _source, decoration: InputDecoration(hintText: l.sourceNoteHint)),
          ),
          const SizedBox(height: 14),
          LabeledField(
            label: l.transcriptOptional,
            child: TextField(controller: _transcript, minLines: 3, maxLines: 10),
          ),
        ]),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _saving || _recording ? null : _save,
          child: Text(_saving ? l.uploading : l.saveStory),
        ),
      ]),
    );
  }
}
