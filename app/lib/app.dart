import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'l10n/l10n.dart';
import 'state/providers.dart';
import 'ui/screens/admin_screen.dart';
import 'ui/screens/albums_screen.dart';
import 'ui/screens/app_settings_screen.dart';
import 'ui/screens/blood_donors_screen.dart';
import 'ui/screens/edit_profile_screen.dart';
import 'ui/screens/event_screen.dart';
import 'ui/screens/events_screen.dart';
import 'ui/screens/fund_cause_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/how_related_screen.dart';
import 'ui/screens/import_export_screen.dart';
import 'ui/screens/memorial_screen.dart';
import 'ui/screens/mentorship_screen.dart';
import 'ui/screens/members_screen.dart';
import 'ui/screens/more_screen.dart';
import 'ui/screens/my_requests_screen.dart';
import 'ui/screens/new_event_screen.dart';
import 'ui/screens/new_moment_screen.dart';
import 'ui/screens/new_story_screen.dart';
import 'ui/screens/notification_settings_screen.dart';
import 'ui/screens/notifications_screen.dart';
import 'ui/screens/pending_screen.dart';
import 'ui/screens/person_form_screen.dart';
import 'ui/screens/person_screen.dart';
import 'ui/screens/photo_screen.dart';
import 'ui/screens/polls_screen.dart';
import 'ui/screens/reminders_screen.dart';
import 'ui/screens/sign_in_screen.dart';
import 'ui/screens/stories_screen.dart';
import 'ui/screens/tree_screen.dart';
import 'ui/screens/welfare_fund_screen.dart';
import 'ui/screens/who_can_help_screen.dart';
import 'domain/family_files.dart' show ImportPlan;
import 'ui/theme.dart';
import 'ui/widgets/home_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider.notifier);
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: auth,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (auth.loading) return loc == '/splash' ? null : '/splash';
      if (!auth.signedIn) return loc == '/sign-in' ? null : '/sign-in';
      final profile = auth.profile;
      if (profile == null) return loc == '/splash' ? null : '/splash';
      if (!profile.isActive) return loc == '/pending' ? null : '/pending';
      if (loc == '/sign-in' || loc == '/pending' || loc == '/splash') return '/home';
      if (loc.startsWith('/admin') && !profile.isAdmin) return '/home';
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
            GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
          ]),
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
            GoRoute(path: '/events', builder: (_, _) => const EventsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/more', builder: (_, _) => const MoreScreen()),
          ]),
        ],
      ),
      GoRoute(
        path: '/new-moment',
        builder: (_, s) => NewMomentScreen(
          albumId: s.uri.queryParameters['album'],
          tagPersonId: s.uri.queryParameters['tag'],
        ),
      ),
      GoRoute(
        path: '/events/new',
        builder: (_, s) => NewEventScreen(announcement: s.uri.queryParameters['type'] == 'announcement'),
      ),
      GoRoute(path: '/events/:id', builder: (_, s) => EventScreen(eventId: s.pathParameters['id']!)),
      GoRoute(path: '/reminders', builder: (_, _) => const RemindersScreen()),
      GoRoute(path: '/settings', builder: (_, _) => const AppSettingsScreen()),
      GoRoute(path: '/me/edit', builder: (_, _) => const EditProfileScreen()),
      GoRoute(path: '/notifications', builder: (_, _) => const NotificationsScreen()),
      GoRoute(path: '/settings/notifications', builder: (_, _) => const NotificationSettingsScreen()),
      GoRoute(
        path: '/related',
        builder: (_, s) => HowRelatedScreen(fromId: s.uri.queryParameters['a'], toId: s.uri.queryParameters['b']),
      ),
      GoRoute(path: '/fund', builder: (_, _) => const WelfareFundScreen()),
      GoRoute(path: '/fund/give', builder: (_, _) => const FundCauseScreen()),
      GoRoute(path: '/fund/new', builder: (_, s) => NewCauseScreen(ask: s.uri.queryParameters['ask'] == '1')),
      GoRoute(path: '/fund/cause/:id', builder: (_, s) => FundCauseScreen(causeId: s.pathParameters['id'])),
      GoRoute(path: '/help', builder: (_, _) => const WhoCanHelpScreen()),
      GoRoute(path: '/blood', builder: (_, _) => const BloodDonorsScreen()),
      GoRoute(path: '/blood/request', builder: (_, _) => const NewBloodRequestScreen()),
      GoRoute(path: '/mentors', builder: (_, s) => MentorshipScreen(initialTab: s.uri.queryParameters['tab'])),
      GoRoute(path: '/polls', builder: (_, _) => const PollsScreen()),
      GoRoute(path: '/polls/new', builder: (_, _) => const NewPollScreen()),
      GoRoute(path: '/albums', builder: (_, _) => const AlbumsScreen()),
      GoRoute(path: '/albums/of/:person', builder: (_, s) => AlbumScreen(personId: s.pathParameters['person'])),
      GoRoute(path: '/albums/:id', builder: (_, s) => AlbumScreen(albumId: s.pathParameters['id'])),
      GoRoute(
        path: '/photo/:id',
        builder: (_, s) => PhotoScreen(
          photoId: s.pathParameters['id']!,
          albumId: s.uri.queryParameters['album'],
          postId: s.uri.queryParameters['post'],
          personId: s.uri.queryParameters['of'],
        ),
      ),
      // Opened from More; admins only (see redirect).
      GoRoute(
        path: '/admin',
        builder: (_, s) => AdminScreen(initialTab: s.uri.queryParameters['tab'] == 'settings' ? 2 : 0),
      ),
      GoRoute(path: '/admin/data', builder: (_, _) => const ImportExportScreen()),
      GoRoute(
        path: '/admin/import',
        redirect: (_, s) => s.extra is ImportPlan ? null : '/admin/data',
        builder: (_, s) => ImportReviewScreen(plan: s.extra! as ImportPlan),
      ),
      GoRoute(path: '/stories', builder: (_, _) => const StoriesScreen()),
      GoRoute(path: '/stories/new', builder: (_, _) => const NewStoryScreen()),
      GoRoute(path: '/my-requests', builder: (_, _) => const MyRequestsScreen()),
      GoRoute(
        path: '/person/:id',
        builder: (_, s) => PersonScreen(personId: s.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (_, s) => PersonFormScreen(editId: s.pathParameters['id']),
          ),
          GoRoute(path: 'memorial', builder: (_, s) => MemorialScreen(personId: s.pathParameters['id']!)),
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
      theme: buildTheme(),
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
