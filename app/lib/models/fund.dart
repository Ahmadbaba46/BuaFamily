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
    this.duesPlanId,
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

  /// Paid towards dues rather than a cause.
  final String? duesPlanId;

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
        duesPlanId: j['dues_plan_id'] as String?,
      );
}

DateTime? _date(Object? v) => v == null ? null : DateTime.parse(v as String);

// ---------------------------------------------------------------- dues

enum DuesPeriod { monthly, quarterly, yearly }

/// "Monthly dues, ₦2,000", from a start month, for every active member.
class DuesPlan {
  const DuesPlan({
    required this.id,
    required this.title,
    required this.amount,
    required this.startsOn,
    this.period = DuesPeriod.monthly,
    this.active = true,
    this.autoRemind = true,
  });

  final String id;
  final String title;
  final double amount;
  final DuesPeriod period;
  final DateTime startsOn;
  final bool active;
  final bool autoRemind;

  factory DuesPlan.fromJson(Map<String, dynamic> j) => DuesPlan(
        id: j['id'] as String,
        title: j['title'] as String,
        amount: _num(j['amount']),
        period: DuesPeriod.values.byName(j['period'] as String? ?? 'monthly'),
        startsOn: DateTime.parse(j['starts_on'] as String),
        active: j['active'] as bool? ?? true,
        autoRemind: j['auto_remind'] as bool? ?? true,
      );
}

/// Where one member stands on one plan.
class DuesStanding {
  const DuesStanding({
    required this.planId,
    required this.userId,
    this.name = '',
    this.personId,
    this.exempt = false,
    this.startsOn,
    this.periodsDue = 0,
    this.paid = 0,
    this.pending = 0,
    this.owed = 0,
    this.owedPeriods = 0,
    this.paidThrough,
    this.nextDue,
    this.lastPaidAt,
  });

  final String planId;
  final String userId;
  final String name;
  final String? personId;
  final bool exempt;
  final DateTime? startsOn;
  final int periodsDue;
  final double paid;

  /// Recorded but not yet confirmed.
  final double pending;
  final double owed;
  final int owedPeriods;

  /// The start of the last period fully paid.
  final DateTime? paidThrough;
  final DateTime? nextDue;
  final DateTime? lastPaidAt;

  bool get paidUp => !exempt && owed <= 0;

  factory DuesStanding.fromJson(Map<String, dynamic> j) => DuesStanding(
        planId: j['plan_id'] as String,
        userId: j['user_id'] as String,
        name: j['name'] as String? ?? '',
        personId: j['person_id'] as String?,
        exempt: j['exempt'] as bool? ?? false,
        startsOn: _date(j['starts_on']),
        periodsDue: (j['periods_due'] as num?)?.toInt() ?? 0,
        paid: _num(j['paid']),
        pending: _num(j['pending']),
        owed: _num(j['owed']),
        owedPeriods: (j['owed_periods'] as num?)?.toInt() ?? 0,
        paidThrough: _date(j['paid_through']),
        nextDue: _date(j['next_due']),
        lastPaidAt: j['last_paid_at'] == null ? null : DateTime.parse(j['last_paid_at'] as String).toLocal(),
      );
}

// ---------------------------------------------------------------- reports

class ReportSource {
  const ReportSource({required this.kind, required this.moneyIn, required this.moneyOut, this.id, this.title});

  /// 'cause', 'dues' or 'general'.
  final String kind;
  final String? id;
  final String? title;
  final double moneyIn;
  final double moneyOut;
}

class ReportMonth {
  const ReportMonth(this.month, this.moneyIn, this.moneyOut);

  final DateTime month;
  final double moneyIn;
  final double moneyOut;
}

class ReportTransaction {
  const ReportTransaction({required this.date, required this.isIn, required this.amount, this.name, this.title, this.method});

  final DateTime date;
  final bool isIn;
  final double amount;

  /// The member (money in) or the payout note (money out).
  final String? name;
  final String? title;
  final PayMethod? method;
}

class DuesSummary {
  const DuesSummary({
    required this.planId,
    required this.title,
    required this.amount,
    required this.period,
    this.members = 0,
    this.owing = 0,
    this.owed = 0,
    this.collected = 0,
  });

  final String planId;
  final String title;
  final double amount;
  final DuesPeriod period;
  final int members;
  final int owing;
  final double owed;
  final double collected;
}

/// A statement for a period. [transactions] and [dues] are for the committee only.
class FundReport {
  const FundReport({
    required this.from,
    required this.to,
    this.family = 'Bua',
    this.opening = 0,
    this.moneyIn = 0,
    this.moneyOut = 0,
    this.closing = 0,
    this.payments = 0,
    this.contributors = 0,
    this.sources = const [],
    this.months = const [],
    this.transactions,
    this.dues,
  });

  final DateTime from;
  final DateTime to;
  final String family;
  final double opening;
  final double moneyIn;
  final double moneyOut;
  final double closing;
  final int payments;
  final int contributors;
  final List<ReportSource> sources;
  final List<ReportMonth> months;
  final List<ReportTransaction>? transactions;
  final List<DuesSummary>? dues;

  factory FundReport.fromJson(Map<String, dynamic> j) {
    List<Map<String, dynamic>> rows(Object? v) => [for (final r in (v as List? ?? const [])) (r as Map).cast<String, dynamic>()];
    return FundReport(
      from: DateTime.parse(j['from'] as String),
      to: DateTime.parse(j['to'] as String),
      family: j['family'] as String? ?? 'Bua',
      opening: _num(j['opening']),
      moneyIn: _num(j['in']),
      moneyOut: _num(j['out']),
      closing: _num(j['closing']),
      payments: (j['payments'] as num?)?.toInt() ?? 0,
      contributors: (j['contributors'] as num?)?.toInt() ?? 0,
      sources: [
        for (final r in rows(j['sources']))
          ReportSource(
            kind: r['kind'] as String,
            id: r['id'] as String?,
            title: r['title'] as String?,
            moneyIn: _num(r['in']),
            moneyOut: _num(r['out']),
          ),
      ],
      months: [
        for (final r in rows(j['months'])) ReportMonth(DateTime.parse(r['month'] as String), _num(r['in']), _num(r['out'])),
      ],
      transactions: j['transactions'] == null
          ? null
          : [
              for (final r in rows(j['transactions']))
                ReportTransaction(
                  date: DateTime.parse(r['date'] as String),
                  isIn: r['kind'] == 'in',
                  amount: _num(r['amount']),
                  name: r['name'] as String?,
                  title: r['title'] as String?,
                  method: PayMethod.values.where((m) => m.name == r['method']).firstOrNull,
                ),
            ],
      dues: j['dues'] == null
          ? null
          : [
              for (final r in rows(j['dues']))
                DuesSummary(
                  planId: r['plan_id'] as String,
                  title: r['title'] as String,
                  amount: _num(r['amount']),
                  period: DuesPeriod.values.byName(r['period'] as String? ?? 'monthly'),
                  members: (r['members'] as num?)?.toInt() ?? 0,
                  owing: (r['owing'] as num?)?.toInt() ?? 0,
                  owed: _num(r['owed']),
                  collected: _num(r['collected']),
                ),
            ],
    );
  }
}
