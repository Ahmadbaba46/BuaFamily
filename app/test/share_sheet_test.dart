import 'package:bua_family/l10n/l10n.dart';
import 'package:bua_family/ui/widgets/share_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('share: WhatsApp or copy the link with its text', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
      return null;
    });
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showShareSheet(context, link: shareLink('event', 'e1'), text: 'Sallah lunch · Sat 10 Oct'),
            child: const Text('go'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('Share on WhatsApp'), findsOneWidget);
    expect(find.textContaining('only family members can open'), findsOneWidget);
    await tester.tap(find.text('Copy link'));
    await tester.pumpAndSettle();
    expect(copied, 'Sallah lunch · Sat 10 Oct\nhttps://buafamily.vercel.app/s/event/e1?l=en');
  });
}
