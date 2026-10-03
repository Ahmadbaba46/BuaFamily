/// The family welfare fund: causes, contributions and payouts.
library;

import 'package:intl/intl.dart';

double _num(Object? v) => v == null ? 0 : (v as num).toDouble();

/// "₦1,240,000" (kobo only when there is some).
String naira(num amount) => '₦${NumberFormat('#,##0.##', 'en').format(amount)}';

class FundOverview {
  const FundOverview({
    this.balance = 0,
    this.treasurers = const [],
    this.updatedAt,
    this.bankName,
    this.accountNumber,
    this.accountName,
    this.openingBalance = 0,
    this.pending,
  });

  final double balance;
  final List<String> treasurers;
  final DateTime? updatedAt;
  final String? bankName;
  final String? accountNumber;
  final String? accountName;
  final double openingBalance;

  /// Contributions waiting for confirmation (committee only).
  final int? pending;

  bool get hasAccount => (accountNumber?.isNotEmpty ?? false);

  factory FundOverview.fromJson(Map<String, dynamic> j) => FundOverview(
        balance: _num(j['balance']),
        treasurers: [for (final t in (j['treasurers'] as List? ?? const [])) t as String],
        updatedAt: j['updated_at'] == null ? null : DateTime.parse(j['updated_at'] as String).toLocal(),
        bankName: j['bank_name'] as String?,
        accountNumber: j['account_number'] as String?,
        accountName: j['account_name'] as String?,
        openingBalance: _num(j['opening_balance']),
        pending: (j['pending'] as num?)?.toInt(),
      );
}

enum CauseStatus { proposed, open, closed, declined }

class FundCause {
  const FundCause({
    required this.id,
    required this.title,
    required this.createdAt,
    this.description,
    this.target,
    this.closesOn,
    this.urgent = false,
    this.status = CauseStatus.open,
    this.createdBy,
    this.raised = 0,
    this.contributors = 0,
    this.names = const [],
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final String? description;
  final double? target;
  final DateTime? closesOn;
  final bool urgent;
  final CauseStatus status;
  final String? createdBy;
  final double raised;
  final int contributors;

  /// Contributors who chose to be listed.
  final List<String> names;

  double get progress => target == null || target == 0 ? 0 : (raised / target!).clamp(0, 1).toDouble();

  factory FundCause.fromJson(Map<String, dynamic> j, {Map<String, dynamic>? totals}) => FundCause(
        id: j['id'] as String,
        title: j['title'] as String,
        createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
        description: j['description'] as String?,
        target: j['target_amount'] == null ? null : _num(j['target_amount']),
        closesOn: j['closes_on'] == null ? null : DateTime.parse(j['closes_on'] as String),
        urgent: j['urgent'] as bool? ?? false,
        status: CauseStatus.values.byName(j['status'] as String? ?? 'open'),
        createdBy: j['created_by'] as String?,
        raised: _num(totals?['raised']),
        contributors: (totals?['contributors'] as num?)?.toInt() ?? 0,
        names: [for (final n in (totals?['names'] as List? ?? const [])) n as String],
      );
}

enum PayMethod { transfer, cash, mobile }

enum ContributionStatus { pending, confirmed, rejected }

class Contribution {
  const Contribution({
    required this.id,
    required this.userId,
    required this.amount,
    required this.method,
    required this.createdAt,
    this.causeId,
    this.receiptPath,
    this.showName = true,
    this.status = ContributionStatus.pending,
  });

  final String id;
  final String userId;
  final double amount;
  final PayMethod method;
  final DateTime createdAt;
  final String? causeId;
  final String? receiptPath;
  final bool showName;
  final ContributionStatus status;

  factory Contribution.fromJson(Map<String, dynamic> j) => Contribution(
        id: j['id'] as String,
        userId: j['user_id'] as String,
        amount: _num(j['amount']),
        method: PayMethod.values.byName(j['method'] as String),
        createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
        causeId: j['cause_id'] as String?,
        receiptPath: j['receipt_path'] as String?,
        showName: j['show_name'] as bool? ?? true,
        status: ContributionStatus.values.byName(j['status'] as String),
      );
}
