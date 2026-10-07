import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../theme.dart';

/// One message: mine on the right in green, theirs on the left.
class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.text, required this.at, required this.mine, this.onLongPress});

  final String text;
  final DateTime at;
  final bool mine;

  /// Holding the message (e.g. to report it).
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        child: GestureDetector(
          onLongPress: onLongPress,
          child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.fromLTRB(14, 9, 14, 7),
          decoration: BoxDecoration(
            color: mine ? Bua.greenTint : Bua.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(mine ? 18 : 4),
              bottomRight: Radius.circular(mine ? 4 : 18),
            ),
            border: Border.all(color: mine ? Bua.greenIndicator : Bua.line),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Align(
              alignment: Alignment.centerLeft,
              child: onLongPress == null
                  ? SelectableText(text, style: const TextStyle(fontSize: 15, height: 1.4))
                  : Text(text, style: const TextStyle(fontSize: 15, height: 1.4)),
            ),
            const SizedBox(height: 2),
            Text(l.ago(at), style: TextStyle(fontSize: 11, color: Bua.inkSubtle)),
          ]),
          ),
        ),
      ),
    );
  }
}
