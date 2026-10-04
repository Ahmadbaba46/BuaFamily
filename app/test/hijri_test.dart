import 'package:bua_family/l10n/l10n.dart';
import 'package:bua_family/models/hijri.dart';
import 'package:bua_family/ui/widgets/hijri.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('converts both ways', () {
    expect(HijriDate.fromDate(DateTime(2026, 10, 4)), const HijriDate(1448, 4, 21));
    expect(HijriDate.fromDate(DateTime(2026, 3, 20)), const HijriDate(1447, 10, 1)); // Eid al-Fitr
    expect(HijriDate.fromDate(DateTime(2026, 5, 27)), const HijriDate(1447, 12, 10)); // Eid al-Adha
    expect(const HijriDate(1448, 9, 1).toDate(), DateTime(2027, 2, 8));
    for (var d = DateTime(2024, 1, 1); d.isBefore(DateTime(2029, 1, 1)); d = d.add(const Duration(days: 1))) {
      final h = HijriDate.fromDate(d);
      expect(h.toDate(), DateTime(d.year, d.month, d.day), reason: '$d');
      expect(h.day, inInclusiveRange(1, 30));
    }
  });

  test('the moon-sighting offset moves the calendar', () {
    expect(HijriDate.fromDate(DateTime(2026, 3, 19), offset: 1), const HijriDate(1447, 10, 1));
    expect(const HijriDate(1447, 10, 1).toDate(offset: -1), DateTime(2026, 3, 21));
  });

  test('upcoming occasions, soonest first', () {
    final list = Occasion.upcoming(DateTime(2026, 10, 4));
    expect(list.first.$1, Occasion.ramadan);
    expect(list.firstWhere((o) => o.$1 == Occasion.ramadan).$2, DateTime(2027, 2, 8));
    expect(list.firstWhere((o) => o.$1 == Occasion.eidAlFitr).$2, DateTime(2027, 3, 10));
    expect(Occasion.eidAlFitr.nextFrom(DateTime(2026, 3, 20)), DateTime(2026, 3, 20));
    expect(Occasion.on(const HijriDate(1448, 12, 10)), Occasion.eidAlAdha);
  });

  test('greetings on the day, a notice the day before', () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final ha = await AppLocalizations.delegate.load(const Locale('ha'));
    final eve = greetingFor(DateTime(2026, 3, 19), 0)!;
    expect((eve.occasion, eve.eve), (Occasion.eidAlFitr, true));
    expect(en.occasionEve(eve.occasion), 'Eid al-Fitr is expected tomorrow, if the moon is sighted.');
    final day = greetingFor(DateTime(2026, 3, 20), 0)!;
    expect((day.occasion, day.eve), (Occasion.eidAlFitr, false));
    expect(ha.occasionGreeting(day.occasion, day.hijri.year), 'Barka da Sallah! Allah ya maimaita mana.');
    expect(greetingFor(DateTime(2026, 10, 4), 0), isNull);
    expect(greetingFor(DateTime(2026, 3, 18), 1)!.eve, isTrue, reason: 'the offset moves the notice too');
    expect(en.hijriDate(const HijriDate(1448, 4, 21)), '21 Rabiʻ al-Thani 1448 AH');
    expect(ha.hijriDate(const HijriDate(1447, 12, 10)), '10 Zulhajji 1447 BH');
  });
}
