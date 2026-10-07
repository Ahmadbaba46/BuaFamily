import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config.dart';
import 'l10n/l10n.dart';
import 'services/push_background.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    runApp(const _NotConfiguredApp());
    return;
  }
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);
  listenForPushInBackground();
  runApp(const ProviderScope(child: BuaFamilyApp()));
}

class _NotConfiguredApp extends StatelessWidget {
  const _NotConfiguredApp();

  @override
  Widget build(BuildContext context) => MaterialApp(
        localizationsDelegates: localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(context.l10n.notConfigured, textAlign: TextAlign.center),
              ),
            ),
          ),
        ),
      );
}
