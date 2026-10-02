enum Sex { male, female, unknown }

Sex sexFromString(String? v) => switch (v) {
      'male' => Sex.male,
      'female' => Sex.female,
      _ => Sex.unknown,
    };

DateTime? _date(Object? v) => v == null ? null : DateTime.tryParse(v as String);
String? _dateStr(DateTime? d) => d == null
    ? null
    : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Anyone in the family tree, living or deceased. Not necessarily an app user.
class Person {
  const Person({
    required this.id,
    required this.firstName,
    this.title,
    this.middleName,
    this.lastName,
    this.nickname,
    this.sex = Sex.unknown,
    this.birthDate,
    this.birthDateApprox = false,
    this.birthPlace,
    this.isLiving = true,
    this.deathDate,
    this.deathDateApprox = false,
    this.deathPlace,
    this.burialPlace,
    this.biography,
    this.photoPath,
    this.branch,
  });

  final String id;
  final String? title;
  final String firstName;
  final String? middleName;
  final String? lastName;
  final String? nickname;
  final Sex sex;
  final DateTime? birthDate;
  final bool birthDateApprox;
  final String? birthPlace;
  final bool isLiving;
  final DateTime? deathDate;
  final bool deathDateApprox;
  final String? deathPlace;
  final String? burialPlace;
  final String? biography;
  final String? photoPath;
  final String? branch;

  factory Person.fromJson(Map<String, dynamic> j) => Person(
        id: j['id'] as String,
        title: j['title'] as String?,
        firstName: j['first_name'] as String,
        middleName: j['middle_name'] as String?,
        lastName: j['last_name'] as String?,
        nickname: j['nickname'] as String?,
        sex: sexFromString(j['sex'] as String?),
        birthDate: _date(j['birth_date']),
        birthDateApprox: j['birth_date_approx'] as bool? ?? false,
        birthPlace: j['birth_place'] as String?,
        isLiving: j['is_living'] as bool? ?? true,
        deathDate: _date(j['death_date']),
        deathDateApprox: j['death_date_approx'] as bool? ?? false,
        deathPlace: j['death_place'] as String?,
        burialPlace: j['burial_place'] as String?,
        biography: j['biography'] as String?,
        photoPath: j['photo_path'] as String?,
        branch: j['branch'] as String?,
      );

  /// Fields that members cannot change on their own record without approval.
  static const coreFields = {
    'first_name', 'middle_name', 'last_name', 'sex', 'birth_date', 'birth_date_approx',
    'is_living', 'death_date', 'death_date_approx', 'death_place', 'burial_place',
  };

  Map<String, dynamic> toJson() => {
        'title': title,
        'first_name': firstName,
        'middle_name': middleName,
        'last_name': lastName,
        'nickname': nickname,
        'sex': sex.name,
        'birth_date': _dateStr(birthDate),
        'birth_date_approx': birthDateApprox,
        'birth_place': birthPlace,
        'is_living': isLiving,
        'death_date': _dateStr(deathDate),
        'death_date_approx': deathDateApprox,
        'death_place': deathPlace,
        'burial_place': burialPlace,
        'biography': biography,
        'branch': branch,
      };

  String get fullName => [firstName, middleName, lastName]
      .where((s) => s != null && s.trim().isNotEmpty)
      .join(' ');

  String get displayName => [if (title?.trim().isNotEmpty ?? false) title, fullName].join(' ');

  String get initials {
    final parts = [firstName, lastName].where((s) => s != null && s.trim().isNotEmpty).toList();
    return parts.map((s) => s!.trim()[0].toUpperCase()).join();
  }

  /// e.g. "1920 – 1990", "c. 1920 – ", "b. 1985".
  String lifespan({String approxPrefix = 'c. '}) {
    String y(DateTime? d, bool approx) => d == null ? '?' : '${approx ? approxPrefix : ''}${d.year}';
    if (isLiving) {
      return birthDate == null ? '' : y(birthDate, birthDateApprox);
    }
    if (birthDate == null && deathDate == null) return '';
    return '${y(birthDate, birthDateApprox)} – ${y(deathDate, deathDateApprox)}';
  }

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final hay = [displayName, nickname, branch, birthPlace].whereType<String>().join(' ').toLowerCase();
    return q.split(RegExp(r'\s+')).every(hay.contains);
  }
}
