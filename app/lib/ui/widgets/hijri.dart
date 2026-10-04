import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../models/hijri.dart';
import '../../state/prefs.dart';
import '../../state/providers.dart';

const _monthsEn = [
  'Muharram', 'Safar', 'Rabiʻ al-Awwal', 'Rabiʻ al-Thani', 'Jumada al-Ula', 'Jumada al-Akhirah',
  'Rajab', 'Shaʻban', 'Ramadan', 'Shawwal', 'Dhu al-Qaʻdah', 'Dhu al-Hijjah',
];
const _monthsHa = [
  'Muharram', 'Safar', "Rabi'ul Awwal", "Rabi'us Sani", 'Jimada Ula', 'Jimada Akhir',
  'Rajab', "Sha'aban", 'Ramadan', 'Shawwal', 'Zulƙida', 'Zulhajji',
];

extension HijriLabels on AppLocalizations {
  String hijriMonth(int month) => (localeName == 'ha' ? _monthsHa : _monthsEn)[(month - 1).clamp(0, 11)];

  /// "21 Rabiʻ al-Thani 1448 AH".
  String hijriDate(HijriDate h) => '${h.day} ${hijriMonth(h.month)} ${h.year} ${localeName == 'ha' ? 'BH' : 'AH'}';

  String occasionName(Occasion o) => switch (o) {
        Occasion.islamicNewYear => occIslamicNewYear,
        Occasion.ashura => occAshura,
        Occasion.mawlid => occMawlid,
        Occasion.ramadan => occRamadan,
        Occasion.laylatAlQadr => occLaylatAlQadr,
        Occasion.eidAlFitr => occEidAlFitr,
        Occasion.arafah => occArafah,
        Occasion.eidAlAdha => occEidAlAdha,
      };

  /// What to say on the day.
  String? occasionGreeting(Occasion o, int hijriYear) => switch (o) {
        Occasion.eidAlFitr => greetEidFitr,
        Occasion.eidAlAdha => greetEidAdha,
        Occasion.ramadan => greetRamadan,
        Occasion.islamicNewYear => greetNewYear(hijriYear),
        _ => null,
      };

  /// What to say the day before.
  String? occasionEve(Occasion o) => switch (o) {
        Occasion.eidAlFitr => eveEidFitr,
        Occasion.eidAlAdha => eveEidAdha,
        Occasion.ramadan => eveRamadan,
        _ => null,
      };
}

/// Days added to the calculated calendar, as admins set it for the moon sighting.
final hijriOffsetProvider = Provider<int>((ref) => ref.watch(settingsProvider).value?.hijriOffset ?? 0);

/// "21 Rabiʻ al-Thani 1448 AH" for [date], or null when this device hides Islamic dates.
String? hijriFor(WidgetRef ref, AppLocalizations l, DateTime date) {
  if (!ref.watch(devicePrefsProvider).showHijri) return null;
  return l.hijriDate(HijriDate.fromDate(date, offset: ref.watch(hijriOffsetProvider)));
}

/// Today's greeting occasion, or tomorrow's (eve: true), if any.
({Occasion occasion, bool eve, HijriDate hijri})? greetingFor(DateTime today, int offset) {
  final h = HijriDate.fromDate(today, offset: offset);
  final now = Occasion.on(h);
  if (now != null && now.greet) return (occasion: now, eve: false, hijri: h);
  final t = HijriDate.fromDate(today.add(const Duration(days: 1)), offset: offset);
  final next = Occasion.on(t);
  if (next != null && next.greet && next != Occasion.islamicNewYear) return (occasion: next, eve: true, hijri: t);
  return null;
}
