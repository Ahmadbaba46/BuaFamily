import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/l10n.dart';

sealed class FieldSpec {
  const FieldSpec(this.key, this.label);
  final String key;
  final String label;
}

class TextSpec extends FieldSpec {
  const TextSpec(super.key, super.label,
      {this.initial, this.number = false, this.multiline = false, this.required = false});
  final Object? initial;
  final bool number;
  final bool multiline;
  final bool required;
}

class ChoiceSpec<T> extends FieldSpec {
  const ChoiceSpec(super.key, super.label, {required this.options, this.initial});
  final Map<T, String> options;
  final T? initial;
}

class SwitchSpec extends FieldSpec {
  const SwitchSpec(super.key, super.label, {this.initial = false});
  final bool initial;
}

/// A small form in a dialog. Returns field values by key (text → String? with
/// empty as null, number → int?, choice → value, switch → bool), or null if cancelled.
Future<Map<String, Object?>?> showFormDialog(
  BuildContext context, {
  required String title,
  required List<FieldSpec> fields,
  String? note,
}) {
  return showDialog<Map<String, Object?>>(
    context: context,
    builder: (_) => _FormDialog(title: title, fields: fields, note: note),
  );
}

class _FormDialog extends StatefulWidget {
  const _FormDialog({required this.title, required this.fields, this.note});

  final String title;
  final List<FieldSpec> fields;
  final String? note;

  @override
  State<_FormDialog> createState() => _FormDialogState();
}

class _FormDialogState extends State<_FormDialog> {
  final _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _text = {
    for (final f in widget.fields.whereType<TextSpec>())
      f.key: TextEditingController(text: f.initial?.toString() ?? ''),
  };
  late final Map<String, Object?> _values = {
    for (final f in widget.fields)
      if (f is ChoiceSpec) f.key: f.initial else if (f is SwitchSpec) f.key: f.initial,
  };

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    final out = <String, Object?>{..._values};
    for (final f in widget.fields.whereType<TextSpec>()) {
      final v = _text[f.key]!.text.trim();
      out[f.key] = v.isEmpty ? null : (f.number ? int.tryParse(v) : v);
    }
    Navigator.pop(context, out);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (widget.note != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(widget.note!, style: Theme.of(context).textTheme.bodySmall),
                ),
              for (final f in widget.fields)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: switch (f) {
                    TextSpec() => TextFormField(
                        controller: _text[f.key],
                        keyboardType: f.number ? TextInputType.number : null,
                        inputFormatters: f.number ? [FilteringTextInputFormatter.digitsOnly] : null,
                        maxLines: f.multiline ? 4 : 1,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(labelText: f.label),
                        validator: (v) => f.required && (v ?? '').trim().isEmpty ? l.required : null,
                      ),
                    ChoiceSpec() => DropdownButtonFormField<Object?>(
                        initialValue: _values[f.key],
                        decoration: InputDecoration(labelText: f.label),
                        items: [
                          for (final e in f.options.entries)
                            DropdownMenuItem(value: e.key, child: Text(e.value)),
                        ],
                        onChanged: (v) => setState(() => _values[f.key] = v),
                      ),
                    SwitchSpec() => SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(f.label),
                        value: _values[f.key] as bool,
                        onChanged: (v) => setState(() => _values[f.key] = v),
                      ),
                  },
                ),
            ]),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(onPressed: _submit, child: Text(l.save)),
      ],
    );
  }
}
