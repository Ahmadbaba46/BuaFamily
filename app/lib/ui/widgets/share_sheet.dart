import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/l10n.dart';
import '../../services/app_update.dart' show siteUrl;
import '../theme.dart';
import 'common.dart';

/// A link that shows a card on WhatsApp (see app/api/share.js) and opens
/// [kind] [id] in the app: 'event', 'post', 'album' or 'join'.
String shareLink(String kind, String id, {String lang = 'en'}) => '$siteUrl/s/$kind/$id?l=$lang';

/// Share on WhatsApp, or copy the link.
Future<void> showShareSheet(BuildContext context, {required String link, String? text}) {
  final l = context.l10n;
  final message = [?text, link].join('\n');
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(l.shareHint, style: TextStyle(fontSize: 13, height: 1.4, color: Bua.inkMuted)),
        ),
        ListTile(
          leading: const Icon(Icons.chat, color: Color(0xFF1FA855)),
          title: Text(l.shareWhatsApp),
          onTap: () {
            Navigator.pop(sheet);
            launchUrl(Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}'),
                mode: LaunchMode.externalApplication);
          },
        ),
        ListTile(
          leading: const Icon(Icons.link),
          title: Text(l.copyLink),
          onTap: () async {
            Navigator.pop(sheet);
            await Clipboard.setData(ClipboardData(text: message));
            if (context.mounted) showSnack(context, l.copied);
          },
        ),
        const SizedBox(height: 8),
      ]),
    ),
  );
}
