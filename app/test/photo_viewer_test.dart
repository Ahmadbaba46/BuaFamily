import 'package:bua_family/l10n/l10n.dart';
import 'package:bua_family/models/account.dart';
import 'package:bua_family/models/social.dart';
import 'package:bua_family/state/prefs.dart';
import 'package:bua_family/state/providers.dart';
import 'package:bua_family/ui/screens/photo_screen.dart';
import 'package:bua_family/ui/widgets/portrait_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'domain_test.dart' show buildFamily;

/// Photos wait for a tap (data saver), so nothing is fetched in tests.
class _SaverPrefs extends DevicePrefsNotifier {
  @override
  DevicePrefs build() => const DevicePrefs(tapToLoadPhotos: true);
}

void main() {
  final graph = buildFamily();
  final tagged = graph.persons.keys.take(8).toList();

  Widget app(Widget home) => ProviderScope(
        overrides: [
          devicePrefsProvider.overrideWith(_SaverPrefs.new),
          profileProvider.overrideWithValue(const Profile(
            id: 'u1',
            displayName: 'Aisha',
            role: AppRole.member,
            status: AccountStatus.active,
          )),
          graphProvider.overrideWith((ref) async => graph),
          membersProvider.overrideWith((ref) async => const {}),
          albumsProvider.overrideWith((ref) async => const []),
          albumPhotosProvider.overrideWith((ref, id) async => [
                Photo(
                  id: 'p1',
                  storagePath: 'a/p1.jpg',
                  uploadedBy: 'u1',
                  createdAt: DateTime(2026, 10, 1),
                  caption: 'Sallah at the family house',
                  people: tagged,
                  likeCount: 3,
                ),
              ]),
        ],
        child: MaterialApp(
          localizationsDelegates: localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      );

  testWidgets('the photo keeps the screen; details fold away', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(const PhotoScreen(photoId: 'p1', albumId: 'a')));
    await tester.pumpAndSettle();

    // Folded: one line with the caption and counts; the photo fills the screen.
    expect(find.text('Sallah at the family house'), findsOneWidget);
    expect(find.text('${tagged.length}'), findsOneWidget);
    expect(find.text('IN THIS PHOTO'), findsNothing);
    expect(tester.getSize(find.byType(PageView)).height, 800);

    // Open: tags, likes; the photo still keeps its size underneath.
    await tester.tap(find.byTooltip('Show details'));
    await tester.pumpAndSettle();
    expect(find.text('IN THIS PHOTO'), findsOneWidget);
    expect(tester.getSize(find.byType(PageView)).height, 800);

    await tester.tap(find.byTooltip('Hide details'));
    await tester.pumpAndSettle();
    expect(find.text('IN THIS PHOTO'), findsNothing);
  });

  testWidgets('a member photo opens full screen, with change for those allowed', (tester) async {
    final person = graph.persons.values.first;
    var changed = false;
    await tester.pumpWidget(app(Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => showPortrait(context, person, onChange: () => changed = true),
          child: const Text('open'),
        ),
      ),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text(person.displayName), findsOneWidget);
    await tester.tap(find.text('Change photo'));
    await tester.pumpAndSettle();
    expect(changed, isTrue);
  });
}
