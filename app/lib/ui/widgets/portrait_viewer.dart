import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../models/person.dart';
import '../../state/providers.dart';
import 'common.dart';

/// A person's photo, full screen: pinch to zoom; "Change photo" for those
/// allowed (the person themselves and admins).
Future<void> showPortrait(BuildContext context, Person person, {VoidCallback? onChange}) => Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, _, _) => PortraitViewer(person: person, onChange: onChange),
        transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
      ),
    );

class PortraitViewer extends ConsumerWidget {
  const PortraitViewer({super.key, required this.person, this.onChange});

  final Person person;
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final path = person.photoPath;
    final url = path == null ? null : (ref.watch(portraitUrlsProvider).value?[path] ?? ref.watch(photoUrlProvider(path)).value);
    final image = path == null ? null : cachedPhoto(path, url);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(person.displayName, style: const TextStyle(color: Colors.white, fontSize: 17)),
        actions: [
          if (onChange != null)
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              onPressed: () {
                Navigator.of(context).pop();
                onChange!();
              },
              icon: const Icon(Icons.photo_camera_outlined, size: 18),
              label: Text(l.changePhoto2),
            ),
        ],
      ),
      body: GestureDetector(
        onVerticalDragEnd: (d) {
          if ((d.primaryVelocity ?? 0).abs() > 600) Navigator.of(context).pop();
        },
        child: Center(
          child: path == null
              ? PersonAvatar(person: person, radius: 96, gapColor: Colors.black)
              : image == null
              ? const CircularProgressIndicator(color: Colors.white54)
              : InteractiveViewer(
                  maxScale: 5,
                  child: Hero(
                    tag: 'portrait-${person.id}',
                    child: Image(image: image, fit: BoxFit.contain, width: double.infinity),
                  ),
                ),
        ),
      ),
    );
  }
}
