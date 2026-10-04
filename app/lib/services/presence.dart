import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../data/repository.dart';

/// Tells the server this member has the app open, and on which page: every
/// minute while it's in front, and soon after each page change. Admins see it
/// as "online now".
class PresenceTracker {
  PresenceTracker({required this.repo, required this.router, required this.platform});

  final FamilyRepository repo;
  final GoRouter router;
  final String platform;

  static const beat = Duration(seconds: 60);

  Timer? _timer;
  Timer? _settle;
  bool _running = false;

  bool get running => _running;

  String get page {
    try {
      return router.routerDelegate.currentConfiguration.uri.path;
    } catch (_) {
      return '';
    }
  }

  void start() {
    if (_running) return;
    _running = true;
    router.routerDelegate.addListener(_pageChanged);
    _send();
    _timer = Timer.periodic(beat, (_) => _send());
  }

  /// In the background, closed, or signed out.
  void stop({bool leave = true}) {
    if (!_running) return;
    _running = false;
    _timer?.cancel();
    _settle?.cancel();
    router.routerDelegate.removeListener(_pageChanged);
    if (leave) repo.leavePresence().catchError((Object _) {});
  }

  // Wait for redirects to settle so one tap is one page.
  void _pageChanged() {
    _settle?.cancel();
    _settle = Timer(const Duration(milliseconds: 800), _send);
  }

  Future<void> _send() async {
    if (!_running) return;
    try {
      await repo.touchPresence(page, platform);
    } catch (e) {
      debugPrint('presence: $e');
    }
  }
}
