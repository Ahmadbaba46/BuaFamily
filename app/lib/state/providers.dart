import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repository.dart';
import '../models/account.dart';
import '../models/community.dart';
import '../models/details.dart';
import '../models/family_graph.dart';
import '../models/fund.dart';
import '../models/help.dart';
import '../models/messages.dart';
import '../models/notification.dart';
import '../models/social.dart';
import '../models/story.dart';
import '../services/app_update.dart' show activityPlatform;
import '../services/offline_cache.dart';

final repositoryProvider = Provider<FamilyRepository>(
  (ref) => FamilyRepository(Supabase.instance.client),
);

/// Shows messages above every page (e.g. notifications that arrive while the
/// app is open).
final rootMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Tracks the signed-in session and the account profile. Drives navigation.
class AuthController extends ChangeNotifier {
  AuthController(this._repo) {
    _signedInBefore = _repo.auth.currentSession != null;
    _sub = _repo.auth.onAuthStateChange.listen((s) {
      if (s.event == AuthChangeEvent.signedIn && !_signedInBefore) {
        _repo.logSession('sign_in', activityPlatform).catchError((Object _) {});
      }
      _signedInBefore = s.session != null;
      refresh();
    });
    refresh();
  }

  final FamilyRepository _repo;
  late final StreamSubscription<AuthState> _sub;

  // A restored session isn't a sign-in; only log the change from signed out.
  bool _signedInBefore = false;

  bool loading = true;
  Profile? profile;
  Object? error;

  bool get signedIn => _repo.auth.currentSession != null;

  Future<void> refresh() async {
    if (!signedIn) {
      profile = null;
      loading = false;
      notifyListeners();
      return;
    }
    try {
      profile = await _repo.myProfile();
      error = null;
    } catch (e) {
      error = e;
    }
    loading = false;
    notifyListeners();
  }

  /// Runs first on sign-out, e.g. to stop this device getting the account's notifications.
  Future<void> Function()? beforeSignOut;

  Future<void> signOut() async {
    try {
      await beforeSignOut?.call();
    } catch (_) {}
    try {
      await _repo.logSession('sign_out', activityPlatform);
    } catch (_) {}
    await _repo.auth.signOut();
    // Nothing of this account stays on the device.
    await OfflineCache.instance.clear();
  }

  /// Deletes this account for good, then leaves nothing of it on the device.
  Future<void> deleteAccount() async {
    await _repo.deleteMyAccount();
    try {
      await beforeSignOut?.call();
    } catch (_) {}
    try {
      await _repo.auth.signOut(scope: SignOutScope.local);
    } catch (_) {}
    await OfflineCache.instance.clear();
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final authProvider = ChangeNotifierProvider<AuthController>(
  (ref) => AuthController(ref.watch(repositoryProvider)),
);

final profileProvider = Provider<Profile?>((ref) => ref.watch(authProvider).profile);

final isAdminProvider = Provider<bool>((ref) => ref.watch(profileProvider)?.isAdmin ?? false);

/// The family tree, loaded once and refreshed after edits.
final graphProvider = FutureProvider<FamilyGraph>((ref) {
  // Reload when the account changes (sign in / out / approval).
  ref.watch(profileProvider.select((p) => (p?.id, p?.status)));
  return ref.watch(repositoryProvider).loadGraph();
});

final settingsProvider = FutureProvider<AppSettings>((ref) {
  ref.watch(profileProvider.select((p) => p?.id));
  return ref.watch(repositoryProvider).settings();
});

/// Whether the current user may add or link relatives (directly or by request).
final canContributeProvider = Provider<bool>((ref) {
  if (ref.watch(isAdminProvider)) return true;
  return ref.watch(settingsProvider).value?.memberContributionsEnabled ?? false;
});

final detailsProvider = FutureProvider.family<PersonDetails, String>(
  (ref, personId) => ref.watch(repositoryProvider).details(personId),
);

final requestsProvider = FutureProvider.family<List<ChangeRequest>, RequestStatus?>(
  (ref, status) => ref.watch(repositoryProvider).requests(status: status),
);

final adminUsersProvider = FutureProvider<List<UserRow>>((ref) => ref.watch(repositoryProvider).adminUsers());

final profilesProvider = FutureProvider<List<Profile>>(
  (ref) => ref.watch(repositoryProvider).allProfiles(),
);

final photoUrlProvider = FutureProvider.family<String, String>(
  (ref, path) => ref.watch(repositoryProvider).photoUrl(path),
);

/// Links to everyone's profile photo, fetched together whenever the tree
/// changes. Avatars use these first, so lists and the tree don't each ask for
/// photos one by one.
final portraitUrlsProvider = FutureProvider<Map<String, String>>((ref) async {
  // The links last six hours; fetch new ones before they run out.
  final renew = Timer(const Duration(hours: 5), ref.invalidateSelf);
  ref.onDispose(renew.cancel);
  final graph = await ref.watch(graphProvider.future);
  final paths = [for (final p in graph.persons.values) ?p.photoPath];
  if (paths.isEmpty) return const {};
  return ref.watch(repositoryProvider).photoUrls(paths);
});

/// UI language. Null means "follow the account / device".
class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() {
    final saved = ref.watch(profileProvider.select((p) => p?.locale));
    return saved == null ? null : Locale(saved);
  }

  Future<void> set(Locale locale) async {
    state = locale;
    if (ref.read(profileProvider) != null) {
      await ref.read(repositoryProvider).updateMyProfile(locale: locale.languageCode);
    }
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(LocaleNotifier.new);

// ---------------------------------------------------------------- sharing & events

/// Active accounts by user id, for author names.
final membersProvider = FutureProvider<Map<String, Member>>((ref) {
  ref.watch(profileProvider.select((p) => p?.id));
  return ref.watch(repositoryProvider).memberDirectory();
});

final feedProvider = FutureProvider<List<Post>>((ref) => ref.watch(repositoryProvider).feed());

final myLikesProvider = FutureProvider<Set<String>>((ref) {
  ref.watch(profileProvider.select((p) => p?.id));
  return ref.watch(repositoryProvider).myLikes();
});

final albumsProvider = FutureProvider<List<Album>>((ref) => ref.watch(repositoryProvider).albums());

final albumPhotosProvider = FutureProvider.family<List<Photo>, String>(
  (ref, albumId) => ref.watch(repositoryProvider).albumPhotos(albumId),
);

final photosOfProvider = FutureProvider.family<List<Photo>, String>(
  (ref, personId) => ref.watch(repositoryProvider).photosOf(personId),
);

final eventsProvider = FutureProvider<List<FamilyEvent>>((ref) => ref.watch(repositoryProvider).events());

/// Fetched fresh each time comments are opened.
final commentsProvider = FutureProvider.autoDispose.family<List<Comment>, Target>(
  (ref, target) => ref.watch(repositoryProvider).comments(target),
);

final postProvider = FutureProvider.autoDispose.family<Post?, String>(
  (ref, id) => ref.watch(repositoryProvider).post(id),
);

/// Refetches what other members may have changed meanwhile: used when the app
/// comes back to the foreground and when a new notification arrives.
void refreshSharedContent(WidgetRef ref, {bool inbox = false}) {
  if (inbox) ref.invalidate(notificationsProvider);
  ref.invalidate(feedProvider);
  ref.invalidate(myLikesProvider);
  ref.invalidate(eventsProvider);
  ref.invalidate(commentsProvider);
  ref.invalidate(postProvider);
  ref.invalidate(albumsProvider);
  ref.invalidate(bloodRequestsProvider);
  ref.invalidate(pollsProvider);
  ref.invalidate(storiesProvider);
}

// ---------------------------------------------------------------- notifications

/// Newest first, updated live.
final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final id = ref.watch(profileProvider.select((p) => p?.isActive ?? false ? p!.id : null));
  if (id == null) return Stream.value(const []);
  return ref.watch(repositoryProvider).notifications().map((list) => list.reversed.toList());
});

final unreadCountProvider = Provider<int>(
  (ref) => ref.watch(notificationsProvider).value?.where((n) => !n.isRead).length ?? 0,
);

final smsStatusProvider = FutureProvider<SmsStatus>((ref) => ref.watch(repositoryProvider).smsStatus());

final pushStatusProvider = FutureProvider<Map<String, dynamic>>((ref) => ref.watch(repositoryProvider).pushStatus());

// ---------------------------------------------------------------- who can help & blood

final helpDirectoryProvider = FutureProvider<List<HelpProfile>>((ref) async {
  final graph = await ref.watch(graphProvider.future);
  return ref.watch(repositoryProvider).helpDirectory(graph);
});

final bloodDonorsProvider = FutureProvider<List<BloodDonor>>((ref) => ref.watch(repositoryProvider).bloodDonors());

final bloodRequestsProvider =
    FutureProvider<List<BloodRequest>>((ref) => ref.watch(repositoryProvider).bloodRequests());

// ---------------------------------------------------------------- memorial pages

final memoriesProvider = FutureProvider.family<List<Memory>, String>(
  (ref, personId) => ref.watch(repositoryProvider).memories(personId),
);

final remembranceReminderProvider = FutureProvider.family<bool, String>(
  (ref, personId) => ref.watch(repositoryProvider).remembranceReminder(personId),
);

// ---------------------------------------------------------------- welfare fund

final fundOverviewProvider = FutureProvider<FundOverview>((ref) => ref.watch(repositoryProvider).fundOverview());

final fundCausesProvider = FutureProvider<List<FundCause>>((ref) => ref.watch(repositoryProvider).fundCauses());

final contributionsProvider =
    FutureProvider<List<Contribution>>((ref) => ref.watch(repositoryProvider).contributions());

final receiptUrlProvider = FutureProvider.family<String, String>(
  (ref, path) => ref.watch(repositoryProvider).receiptUrl(path),
);

/// Refresh everything shown on the fund pages.
/// Search results for a query (people come from the tree, not from here).
final searchProvider = FutureProvider.autoDispose.family<List<SearchHit>, String>(
  (ref, q) => q.trim().length < 2 ? Future.value(const <SearchHit>[]) : ref.watch(repositoryProvider).searchAll(q, limit: 20),
);

final duesPlansProvider = FutureProvider<List<DuesPlan>>((ref) => ref.watch(repositoryProvider).duesPlans());

/// Your standing on each active dues plan.
final myDuesProvider = FutureProvider<List<DuesStanding>>((ref) => ref.watch(repositoryProvider).duesStatus());

/// Committee: everyone's standing.
final allDuesProvider =
    FutureProvider.autoDispose<List<DuesStanding>>((ref) => ref.watch(repositoryProvider).duesStatus(everyone: true));

final fundReportProvider = FutureProvider.autoDispose.family<FundReport, (DateTime, DateTime)>(
  (ref, p) => ref.watch(repositoryProvider).fundReport(p.$1, p.$2),
);

void refreshFund(WidgetRef ref) {
  ref.invalidate(fundOverviewProvider);
  ref.invalidate(fundCausesProvider);
  ref.invalidate(contributionsProvider);
  ref.invalidate(duesPlansProvider);
  ref.invalidate(myDuesProvider);
  ref.invalidate(allDuesProvider);
  ref.invalidate(fundReportProvider);
}

// ---------------------------------------------------------------- mentorship & polls

final mentorshipProvider = FutureProvider<Mentorship>((ref) => ref.watch(repositoryProvider).mentorship());

final mentorAskProvider =
    FutureProvider.autoDispose.family<MentorAsk?, String>((ref, id) => ref.watch(repositoryProvider).mentorAsk(id));

final mentorMessagesProvider = StreamProvider.autoDispose
    .family<List<MentorMessage>, String>((ref, id) => ref.watch(repositoryProvider).mentorMessages(id));

// ---------------------------------------------------------------- direct messages

final dmThreadsProvider = StreamProvider<List<DmThread>>((ref) {
  ref.watch(profileProvider.select((p) => (p?.id, p?.status)));
  return ref.watch(repositoryProvider).dmThreads();
});

/// Conversations with something new for me.
final dmUnreadProvider = Provider<int>((ref) {
  final me = ref.watch(profileProvider)?.id;
  return ref.watch(dmThreadsProvider).value?.where((t) => t.unreadFor(me)).length ?? 0;
});

final dmMessagesProvider = StreamProvider.autoDispose
    .family<List<DmMessage>, String>((ref, id) => ref.watch(repositoryProvider).dmMessages(id));

final pollsProvider = FutureProvider<List<Poll>>((ref) => ref.watch(repositoryProvider).polls());

// ---------------------------------------------------------------- stories & backups

final storiesProvider = FutureProvider<List<Story>>((ref) => ref.watch(repositoryProvider).stories());

final backupsProvider = FutureProvider<List<Backup>>((ref) {
  if (!ref.watch(isAdminProvider)) return const [];
  return ref.watch(repositoryProvider).backups();
});
