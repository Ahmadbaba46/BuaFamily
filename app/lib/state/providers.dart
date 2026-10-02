import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repository.dart';
import '../models/account.dart';
import '../models/details.dart';
import '../models/family_graph.dart';

final repositoryProvider = Provider<FamilyRepository>(
  (ref) => FamilyRepository(Supabase.instance.client),
);

/// Tracks the signed-in session and the account profile. Drives navigation.
class AuthController extends ChangeNotifier {
  AuthController(this._repo) {
    _sub = _repo.auth.onAuthStateChange.listen((_) => refresh());
    refresh();
  }

  final FamilyRepository _repo;
  late final StreamSubscription<AuthState> _sub;

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

  Future<void> signOut() => _repo.auth.signOut();

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

final profilesProvider = FutureProvider<List<Profile>>(
  (ref) => ref.watch(repositoryProvider).allProfiles(),
);

final photoUrlProvider = FutureProvider.family<String, String>(
  (ref, path) => ref.watch(repositoryProvider).photoUrl(path),
);

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
