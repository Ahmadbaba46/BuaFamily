import 'details.dart';
import 'person.dart';

/// Broad areas for "Who can help?". Matching is by keywords (English and
/// Hausa) in skills, job titles, industries and fields of study.
enum HelpCategory {
  health([
    'doctor', 'medic', 'mbbs', 'nurse', 'nursing', 'midwi', 'pharmac', 'health', 'hospital', 'clinic',
    'dent', 'surgeon', 'paediatric', 'pediatric', 'physio', 'laborator', 'lab scien', 'radiograph',
    'optometr', 'likita', 'asibiti', 'unguwar zoma',
  ]),
  law(['law', 'lawyer', 'legal', 'barrister', 'solicitor', 'judge', 'llb', 'attorney', 'court', 'lauya', 'shari']),
  trades([
    'carpent', 'tailor', 'sewing', 'mechanic', 'electrician', 'plumb', 'weld', 'mason', 'builder',
    'barber', 'hairdress', 'farm', 'driver', 'painter', 'fashion', 'kafinta', 'dinki', 'teloli', 'makanike',
    'manomi', 'noma', 'aski',
  ]),
  teaching(['teach', 'lecturer', 'professor', 'tutor', 'school', 'education', 'principal', 'malami', 'malama', 'koyarwa']),
  business([
    'business', 'trader', 'trading', 'sales', 'account', 'finance', 'bank', 'market', 'entrepreneur',
    'procurement', 'insurance', 'economics', 'audit', 'kasuwanci', 'dan kasuwa', 'yar kasuwa',
  ]),
  engineering(['engineer', 'architect', 'surveyor', 'construction', 'civil', 'mechanical', 'electrical', 'injiniya']),
  tech([
    'software', 'developer', 'programm', 'computer', 'data', 'network', 'web', 'tech', ' it ', 'ict',
    'cyber', 'design', 'kwamfuta',
  ]),
  islamic([
    'islamic', 'islam', 'quran', "qur'an", 'arabic', 'sharia', 'imam', 'tafsir', 'hadith', 'fiqh',
    'islamiyya', 'alkali', 'malam ', 'tsangaya', 'larabci',
  ]);

  const HelpCategory(this.keywords);

  final List<String> keywords;

  bool matches(String text) => keywords.any(text.contains);
}

/// Someone in the tree with skills, work or study the family can call on.
class HelpProfile {
  HelpProfile({
    required this.person,
    this.occupations = const [],
    this.education = const [],
    this.skills = const [],
    this.phone,
    this.city,
  }) : _text = ' ${[
          for (final o in occupations) ...[o.title, o.organization, o.industry],
          for (final e in education) ...[e.qualification, e.field, e.institution],
          for (final s in skills) s.skill,
        ].whereType<String>().join(' ').toLowerCase()} ';

  final Person person;
  final List<Occupation> occupations;
  final List<Education> education;
  final List<Skill> skills;

  /// Only when the person shares their contact with the family.
  final String? phone;
  final String? city;
  final String _text;

  bool get hasAnything => occupations.isNotEmpty || education.isNotEmpty || skills.isNotEmpty;

  bool inCategory(HelpCategory c) => c.matches(_text);

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final hay = '$_text ${person.displayName.toLowerCase()}';
    return q.split(RegExp(r'\s+')).every(hay.contains);
  }

  /// "Consultant paediatrician · AKTH Kano", else what they studied, else skills.
  String headline() {
    final jobs = [...occupations]..sort((a, b) {
        if (a.isCurrent != b.isCurrent) return a.isCurrent ? -1 : 1;
        return (b.endYear ?? b.startYear ?? 0).compareTo(a.endYear ?? a.startYear ?? 0);
      });
    if (jobs.isNotEmpty) {
      final j = jobs.first;
      return [j.title, j.organization ?? j.location].whereType<String>().where((s) => s.isNotEmpty).join(' · ');
    }
    if (education.isNotEmpty) {
      final e = ([...education]..sort((a, b) => (b.endYear ?? b.startYear ?? 0).compareTo(a.endYear ?? a.startYear ?? 0)))
          .first;
      final what = [e.qualification, e.field].whereType<String>().where((s) => s.isNotEmpty).join(' ');
      return [if (what.isNotEmpty) what, e.institution].join(' · ');
    }
    return skills.map((s) => s.skill).join(', ');
  }
}

/// Red-cell compatibility: can [donor] give blood to [recipient]?
bool canDonate(String donor, String recipient) => switch (recipient) {
      'AB+' => true,
      'AB-' => const {'AB-', 'A-', 'B-', 'O-'}.contains(donor),
      'A+' => const {'A+', 'A-', 'O+', 'O-'}.contains(donor),
      'A-' => const {'A-', 'O-'}.contains(donor),
      'B+' => const {'B+', 'B-', 'O+', 'O-'}.contains(donor),
      'B-' => const {'B-', 'O-'}.contains(donor),
      'O+' => const {'O+', 'O-'}.contains(donor),
      'O-' => donor == 'O-',
      _ => false,
    };

/// Blood groups that can give to [recipient].
List<String> donorGroupsFor(String recipient) => [for (final g in Health.bloodGroups) if (canDonate(g, recipient)) g];

class BloodDonor {
  const BloodDonor({required this.personId, required this.bloodGroup, this.town});

  final String personId;
  final String bloodGroup;
  final String? town;

  factory BloodDonor.fromJson(Map<String, dynamic> j) => BloodDonor(
        personId: j['person_id'] as String,
        bloodGroup: j['blood_group'] as String,
        town: j['town'] as String?,
      );
}

class BloodRequest {
  const BloodRequest({
    required this.id,
    required this.bloodGroup,
    required this.hospital,
    required this.requestedBy,
    required this.createdAt,
    this.units = 1,
    this.patientPersonId,
    this.patientName,
    this.contactPhone,
    this.note,
    this.urgent = true,
    this.open = true,
    this.offers = const [],
  });

  final String id;
  final String bloodGroup;
  final String hospital;
  final String requestedBy;
  final DateTime createdAt;
  final int units;
  final String? patientPersonId;
  final String? patientName;
  final String? contactPhone;
  final String? note;
  final bool urgent;
  final bool open;

  /// User ids of relatives who said "I can donate".
  final List<String> offers;

  static const select = '*, blood_offers(user_id)';

  factory BloodRequest.fromJson(Map<String, dynamic> j) => BloodRequest(
        id: j['id'] as String,
        bloodGroup: j['blood_group'] as String,
        hospital: j['hospital'] as String,
        requestedBy: j['requested_by'] as String,
        createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
        units: j['units'] as int? ?? 1,
        patientPersonId: j['patient_person_id'] as String?,
        patientName: j['patient_name'] as String?,
        contactPhone: j['contact_phone'] as String?,
        note: j['note'] as String?,
        urgent: j['urgent'] as bool? ?? true,
        open: j['status'] == 'open',
        offers: [for (final o in (j['blood_offers'] as List? ?? const [])) (o as Map)['user_id'] as String],
      );
}
