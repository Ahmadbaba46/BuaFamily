import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../models/social.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';

/// New event or announcement.
class NewEventScreen extends ConsumerStatefulWidget {
  const NewEventScreen({super.key, this.announcement = false});

  final bool announcement;

  @override
  ConsumerState<NewEventScreen> createState() => _NewEventScreenState();
}

class _NewEventScreenState extends ConsumerState<NewEventScreen> {
  late bool _announcement = widget.announcement;
  final _title = TextEditingController();
  final _place = TextEditingController();
  final _address = TextEditingController();
  final _details = TextEditingController();
  final _body = TextEditingController();
  EventCategory _category = EventCategory.meeting;
  DateTime? _date;
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 0);
  bool _askReply = true;
  bool _pin = false;
  bool _notify = true;
  bool _sms = false;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_title, _place, _address, _details, _body]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }

  Future<void> _submit() async {
    final l = context.l10n;
    final repo = ref.read(repositoryProvider);
    if (_announcement) {
      if (_body.text.trim().isEmpty) return showSnack(context, l.postEmptyError);
    } else {
      if (_title.text.trim().isEmpty) return showSnack(context, l.titleRequired);
      if (_date == null) return showSnack(context, '${l.date}: ${l.required}');
    }
    setState(() => _saving = true);
    String? eventId;
    final ok = await guarded(context, () async {
      if (_announcement) {
        await repo.createPost(
          kind: PostKind.announcement,
          body: _body.text,
          pinned: _pin,
          notify: _notify,
          sendSms: _notify && _sms,
        );
      } else {
        final d = _date!;
        final starts = DateTime(d.year, d.month, d.day, _time.hour, _time.minute);
        String? opt(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
        eventId = await repo.createEvent({
          'title': _title.text.trim(),
          'category': _category.name,
          'starts_at': starts.toUtc().toIso8601String(),
          'place': opt(_place),
          'address': opt(_address),
          'details': opt(_details),
          'rsvp_enabled': _askReply,
          if (_pin) 'pinned': true,
          'notify': _notify,
          if (_notify && _sms) 'send_sms': true,
        });
      }
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) return;
    ref.invalidate(feedProvider);
    ref.invalidate(eventsProvider);
    if (eventId != null) {
      context.pushReplacement('/events/$eventId');
    } else {
      context.canPop() ? context.pop() : context.go('/events');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final isAdmin = ref.watch(isAdminProvider);
    final smsOn = ref.watch(settingsProvider).value?.smsEnabled ?? false;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l.close,
          icon: const Icon(Icons.close),
          onPressed: () => context.canPop() ? context.pop() : context.go('/events'),
        ),
        title: Text(l.newPost, style: Theme.of(context).textTheme.titleMedium),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
        Center(
          child: PillSegmented<bool>(
            values: const [false, true],
            labelOf: (a) => a ? l.announcement : l.event,
            selected: _announcement,
            onChanged: (a) => setState(() => _announcement = a),
          ),
        ),
        const SizedBox(height: 16),
        if (_announcement)
          SectionCard(padding: const EdgeInsets.all(16), children: [
            TextField(
              controller: _body,
              minLines: 5,
              maxLines: 12,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(hintText: l.announcementHint),
            ),
          ])
        else
          SectionCard(padding: const EdgeInsets.all(16), children: [
            LabeledField(
              label: l.whatsHappening,
              child: TextField(controller: _title, textCapitalization: TextCapitalization.sentences),
            ),
            const SizedBox(height: 14),
            LabeledField(
              label: l.eventType,
              child: DropdownButtonFormField<EventCategory>(
                initialValue: _category,
                items: [
                  for (final c in EventCategory.values)
                    DropdownMenuItem(value: c, child: Text(l.eventCategory(c.name))),
                ],
                onChanged: (c) => setState(() => _category = c ?? _category),
              ),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: LabeledField(
                  label: l.date,
                  child: _PickerField(
                    text: _date == null ? l.pickDate : l.weekdayDate(_date!),
                    icon: Icons.calendar_today_outlined,
                    onTap: _pickDate,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 130,
                child: LabeledField(
                  label: l.time,
                  child: _PickerField(
                    text: l.clock(DateTime(2000, 1, 1, _time.hour, _time.minute)),
                    icon: Icons.schedule,
                    onTap: _pickTime,
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            LabeledField(label: l.place, child: TextField(controller: _place)),
            const SizedBox(height: 14),
            LabeledField(label: l.addressOrArea, child: TextField(controller: _address)),
            const SizedBox(height: 14),
            LabeledField(
              label: l.details,
              child: TextField(
                controller: _details,
                minLines: 3,
                maxLines: 8,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ]),
        const SizedBox(height: 14),
        SectionCard(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), children: [
          if (!_announcement) ...[
            ToggleRow(
              title: l.askReply,
              subtitle: l.askReplySub,
              value: _askReply,
              onChanged: (v) => setState(() => _askReply = v),
            ),
            const Divider(height: 1),
          ],
          ToggleRow(
            title: l.notifyFamily,
            subtitle: l.notifyFamilySub,
            value: _notify,
            onChanged: (v) => setState(() => _notify = v),
          ),
          if (isAdmin && smsOn) ...[
            const Divider(height: 1),
            ToggleRow(
              title: l.alsoSms,
              subtitle: l.alsoSmsSub,
              value: _notify && _sms,
              onChanged: _notify ? (v) => setState(() => _sms = v) : null,
            ),
          ],
          const Divider(height: 1),
          ToggleRow(
            title: l.pinToHome,
            subtitle: l.adminsOnly,
            value: _pin,
            onChanged: isAdmin ? (v) => setState(() => _pin = v) : null,
          ),
        ]),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _saving ? null : _submit,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(_announcement ? l.postAnnouncement : l.postEvent),
        ),
      ]),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({required this.text, required this.icon, required this.onTap});

  final String text;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(suffixIcon: Icon(icon, size: 18, color: Bua.inkSubtle)),
        child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15)),
      ),
    );
  }
}
