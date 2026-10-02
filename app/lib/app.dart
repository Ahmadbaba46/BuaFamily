import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'l10n/l10n.dart';
import 'state/providers.dart';
import 'ui/screens/admin_screen.dart';
import 'ui/screens/members_screen.dart';
import 'ui/screens/more_screen.dart';
import 'ui/screens/pending_screen.dart';
import 'ui/screens/person_form_screen.dart';
import 'ui/screens/person_screen.dart';
import 'ui/screens/sign_in_screen.dart';
import 'ui/screens/tree_screen.dart';
import 'ui/widgets/home_shell.dart';

const _seed = Color(0xFF1F6F43); // deep green

ThemeData _theme(Brightness b) {
  final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: b);
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    fontFamily: 'NotoSans',
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
    cardTheme: const CardThemeData(margin: EdgeInsets.zero),
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider.notifier);
  return GoRouter(
    initialLocation: '/tree',
    refreshListenable: auth,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (auth.loading) return loc == '/splash' ? null : '/splash';
      if (!auth.signedIn) return loc == '/sign-in' ? null : '/sign-in';
      final profile = auth.profile;
      if (profile == null) return loc == '/splash' ? null : '/splash';
      if (!profile.isActive) return loc == '/pending' ? null : '/pending';
      if (loc == '/sign-in' || loc == '/pending' || loc == '/splash') return '/tree';
      if (loc.startsWith('/admin') && !profile.isAdmin) return '/tree';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const _Splash()),
      GoRoute(path: '/sign-in', builder: (_, _) => const SignInScreen()),
      GoRoute(path: '/pending', builder: (_, _) => const PendingScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/tree',
              builder: (_, s) => TreeScreen(focusId: s.uri.queryParameters['focus']),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/members', builder: (_, _) => const MembersScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/admin', builder: (_, _) => const AdminScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/more', builder: (_, _) => const MoreScreen()),
          ]),
        ],
      ),
      GoRoute(
        path: '/person/:id',
        builder: (_, s) => PersonScreen(personId: s.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (_, s) => PersonFormScreen(editId: s.pathParameters['id']),
          ),
        ],
      ),
      GoRoute(
        path: '/new-person',
        builder: (_, s) => PersonFormScreen(
          relationType: s.uri.queryParameters['type'],
          relationTo: s.uri.queryParameters['of'],
          presetSex: s.uri.queryParameters['sex'],
        ),
      ),
    ],
  );
});

class BuaFamilyApp extends ConsumerWidget {
  const BuaFamilyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      onGenerateTitle: (c) => c.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      locale: ref.watch(localeProvider),
      localizationsDelegates: localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(routerProvider),
    );
  }
}

class _Splash extends ConsumerWidget {
  const _Splash();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    if (auth.error == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(context.l10n.errorGeneric('${auth.error}'), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: auth.refresh, child: Text(context.l10n.retry)),
            TextButton(onPressed: auth.signOut, child: Text(context.l10n.signOut)),
          ]),
        ),
      ),
    );
  }
}
