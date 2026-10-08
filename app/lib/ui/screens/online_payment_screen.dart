import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/l10n.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Pays [amount] through Korapay: opens Korapay's page (card or transfer),
/// then shows whether the payment came through.
Future<void> payOnline(
  BuildContext context,
  WidgetRef ref, {
  required double amount,
  String? causeId,
  String? duesPlanId,
  bool showName = true,
  String? eventId,
  String? note,
}) async {
  ({String reference, String checkoutUrl})? started;
  final ok = await guarded(context, () async {
    started = await ref.read(repositoryProvider).startOnlinePayment(
        amount: amount, causeId: causeId, duesPlanId: duesPlanId, showName: showName, eventId: eventId, note: note);
  });
  if (!ok || started == null || !context.mounted) return;
  final s = started!;
  // On the website Korapay's page replaces ours and comes back to
  // /fund/paid/<reference>; in the app it opens in the browser.
  final messenger = ScaffoldMessenger.maybeOf(context);
  final l = context.l10n;
  if (!kIsWeb) context.push('/fund/paid/${s.reference}${eventId == null ? '' : '?event=$eventId'}');
  try {
    await launchUrl(
      Uri.parse(s.checkoutUrl),
      mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      webOnlyWindowName: kIsWeb ? '_self' : null,
    );
  } catch (e) {
    messenger?.showSnackBar(SnackBar(content: Text(l.errorGeneric(errorText(e)))));
  }
}

/// After paying: checks with Korapay (again when you come back to the app).
class OnlinePaymentScreen extends ConsumerStatefulWidget {
  const OnlinePaymentScreen({super.key, required this.reference, this.eventId});

  final String reference;

  /// A wedding or naming gift: back to this event, not the welfare fund.
  final String? eventId;

  @override
  ConsumerState<OnlinePaymentScreen> createState() => _OnlinePaymentScreenState();
}

class _OnlinePaymentScreenState extends ConsumerState<OnlinePaymentScreen> {
  /// 'paid', 'failed', 'waiting', or null while checking.
  String? _status;
  String? _error;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: () {
      if (_status == 'waiting' || _error != null) _check();
    });
    _check();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    setState(() {
      _status = null;
      _error = null;
    });
    try {
      final s = await ref.read(repositoryProvider).checkOnlinePayment(widget.reference);
      if (!mounted) return;
      setState(() => _status = s);
      if (s == 'paid') {
        refreshFund(ref);
        if (widget.eventId != null) ref.invalidate(eventGiftsProvider(widget.eventId!));
      }
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    }
  }

  String get _home => widget.eventId == null ? '/fund' : '/events/${widget.eventId}';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final (icon, color, title, body) = switch (_status) {
      'paid' => (
          Icons.check_circle,
          Bua.green,
          l.paymentReceived,
          widget.eventId == null ? l.paymentReceivedBody : l.giftPaymentReceivedBody
        ),
      'failed' => (Icons.cancel_outlined, Bua.danger, l.paymentFailed, l.paymentFailedBody),
      'waiting' => (Icons.hourglass_top_rounded, Bua.gold, l.paymentWaiting, l.paymentWaitingBody),
      _ => (Icons.sync, Bua.inkSubtle, l.paymentChecking, _error ?? ''),
    };
    final done = _status == 'paid' || _status == 'failed';
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go(_home)),
        title: Text(l.payNowTitle),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (_status == null && _error == null)
              const SizedBox(width: 56, height: 56, child: CircularProgressIndicator())
            else
              Icon(icon, size: 64, color: color),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
            if (body.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(body, textAlign: TextAlign.center, style: TextStyle(color: Bua.inkMuted, height: 1.45)),
            ],
            const SizedBox(height: 24),
            if (!done && (_status != null || _error != null))
              FilledButton.icon(onPressed: _check, icon: const Icon(Icons.refresh), label: Text(l.checkAgain)),
            if (done)
              FilledButton(
                onPressed: () => context.go(_home),
                child: Text(widget.eventId == null ? l.backToFund : l.backToEvent),
              ),
          ]),
        ),
      ),
    );
  }
}
