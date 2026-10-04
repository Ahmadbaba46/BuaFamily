/// The Islamic (Hijri) calendar, by the tabular (arithmetic) method. The
/// real month starts with the moon sighting, which can differ by a day or
/// two: admins set that difference (app settings, hijri_offset), and the
/// database uses the same method (private.hijri) for its greetings.
library;

class HijriDate {
  const HijriDate(this.year, this.month, this.day);

  final int year;

  /// 1 = Muharram … 9 = Ramadan, 10 = Shawwal, 12 = Dhul-Hijjah.
  final int month;
  final int day;

  /// [offset] days are added first, so +1 means "the moon was seen a day early".
  factory HijriDate.fromDate(DateTime date, {int offset = 0}) {
    final d = DateTime(date.year, date.month, date.day).add(Duration(days: offset));
    var l = _toJd(d.year, d.month, d.day) - 1948440 + 10632;
    final n = (l - 1) ~/ 10631;
    l = l - 10631 * n + 354;
    final j = ((10985 - l) ~/ 5316) * ((50 * l) ~/ 17719) + (l ~/ 5670) * ((43 * l) ~/ 15238);
    l = l - ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) - (j ~/ 16) * ((15238 * j) ~/ 43) + 29;
    final m = (24 * l) ~/ 709;
    return HijriDate(30 * n + j - 30, m, l - (709 * m) ~/ 24);
  }

  /// The Gregorian day this Hijri date falls on, with the same [offset].
  DateTime toDate({int offset = 0}) {
    final jd = (11 * year + 3) ~/ 30 + 354 * year + 30 * month - (month - 1) ~/ 2 + day + 1948440 - 385;
    return _fromJd(jd).subtract(Duration(days: offset));
  }

  bool isOn(int month, int day) => this.month == month && this.day == day;

  @override
  bool operator ==(Object other) => other is HijriDate && other.year == year && other.month == month && other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => '$year-$month-$day AH';
}

int _toJd(int y, int m, int d) {
  final a = (14 - m) ~/ 12;
  final yy = y + 4800 - a;
  final mm = m + 12 * a - 3;
  return d + (153 * mm + 2) ~/ 5 + 365 * yy + yy ~/ 4 - yy ~/ 100 + yy ~/ 400 - 32045;
}

DateTime _fromJd(int jd) {
  final a = jd + 32044;
  final b = (4 * a + 3) ~/ 146097;
  final c = a - 146097 * b ~/ 4;
  final d = (4 * c + 3) ~/ 1461;
  final e = c - 1461 * d ~/ 4;
  final m = (5 * e + 2) ~/ 153;
  return DateTime(100 * b + d - 4800 + m ~/ 10, m + 3 - 12 * (m ~/ 10), e - (153 * m + 2) ~/ 5 + 1);
}

/// The days the family marks.
enum Occasion {
  islamicNewYear(1, 1, greet: true),
  ashura(1, 10),
  mawlid(3, 12),
  ramadan(9, 1, greet: true),
  laylatAlQadr(9, 27),
  eidAlFitr(10, 1, greet: true),
  arafah(12, 9),
  eidAlAdha(12, 10, greet: true);

  const Occasion(this.month, this.day, {this.greet = false});

  final int month;
  final int day;

  /// A greeting on the day (and a "tomorrow" notice for Ramadan and the Eids).
  final bool greet;

  /// The next time it falls on or after [from].
  DateTime nextFrom(DateTime from, {int offset = 0}) {
    final today = DateTime(from.year, from.month, from.day);
    final h = HijriDate.fromDate(today, offset: offset);
    for (final y in [h.year, h.year + 1]) {
      final d = HijriDate(y, month, day).toDate(offset: offset);
      if (!d.isBefore(today)) return d;
    }
    return HijriDate(h.year + 2, month, day).toDate(offset: offset);
  }

  static Occasion? on(HijriDate h) => Occasion.values.where((o) => h.isOn(o.month, o.day)).firstOrNull;

  /// The coming occasions after [from], soonest first.
  static List<(Occasion, DateTime)> upcoming(DateTime from, {int offset = 0}) =>
      [for (final o in Occasion.values) (o, o.nextFrom(from, offset: offset))]..sort((a, b) => a.$2.compareTo(b.$2));
}
