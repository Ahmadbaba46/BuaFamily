enum Audience { family, private }

Audience _aud(Object? v) => v == 'private' ? Audience.private : Audience.family;

class Education {
  const Education({
    this.id,
    required this.personId,
    required this.institution,
    this.qualification,
    this.field,
    this.startYear,
    this.endYear,
  });

  final String? id;
  final String personId;
  final String institution;
  final String? qualification;
  final String? field;
  final int? startYear;
  final int? endYear;

  factory Education.fromJson(Map<String, dynamic> j) => Education(
        id: j['id'] as String?,
        personId: j['person_id'] as String,
        institution: j['institution'] as String,
        qualification: j['qualification'] as String?,
        field: j['field'] as String?,
        startYear: j['start_year'] as int?,
        endYear: j['end_year'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'person_id': personId,
        'institution': institution,
        'qualification': qualification,
        'field': field,
        'start_year': startYear,
        'end_year': endYear,
      };
}

class Occupation {
  const Occupation({
    this.id,
    required this.personId,
    required this.title,
    this.organization,
    this.industry,
    this.location,
    this.startYear,
    this.endYear,
    this.isCurrent = false,
  });

  final String? id;
  final String personId;
  final String title;
  final String? organization;
  final String? industry;
  final String? location;
  final int? startYear;
  final int? endYear;
  final bool isCurrent;

  factory Occupation.fromJson(Map<String, dynamic> j) => Occupation(
        id: j['id'] as String?,
        personId: j['person_id'] as String,
        title: j['title'] as String,
        organization: j['organization'] as String?,
        industry: j['industry'] as String?,
        location: j['location'] as String?,
        startYear: j['start_year'] as int?,
        endYear: j['end_year'] as int?,
        isCurrent: j['is_current'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'person_id': personId,
        'title': title,
        'organization': organization,
        'industry': industry,
        'location': location,
        'start_year': startYear,
        'end_year': endYear,
        'is_current': isCurrent,
      };
}

class Skill {
  const Skill({this.id, required this.personId, required this.skill});

  final String? id;
  final String personId;
  final String skill;

  factory Skill.fromJson(Map<String, dynamic> j) =>
      Skill(id: j['id'] as String?, personId: j['person_id'] as String, skill: j['skill'] as String);
}

class Contact {
  const Contact({
    required this.personId,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.country,
    this.visibility = Audience.family,
  });

  final String personId;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String? country;
  final Audience visibility;

  bool get isEmpty => [phone, email, address, city, country].every((v) => v == null || v.isEmpty);

  factory Contact.fromJson(Map<String, dynamic> j) => Contact(
        personId: j['person_id'] as String,
        phone: j['phone'] as String?,
        email: j['email'] as String?,
        address: j['address'] as String?,
        city: j['city'] as String?,
        country: j['country'] as String?,
        visibility: _aud(j['visibility']),
      );

  Map<String, dynamic> toJson() => {
        'person_id': personId,
        'phone': phone,
        'email': email,
        'address': address,
        'city': city,
        'country': country,
        'visibility': visibility.name,
      };
}

class Health {
  const Health({
    required this.personId,
    this.bloodGroup,
    this.genotype,
    this.conditions,
    this.visibility = Audience.private,
  });

  static const bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  static const genotypes = ['AA', 'AS', 'AC', 'SS', 'SC', 'CC'];

  final String personId;
  final String? bloodGroup;
  final String? genotype;
  final String? conditions;
  final Audience visibility;

  bool get isEmpty => bloodGroup == null && genotype == null && (conditions?.isEmpty ?? true);

  factory Health.fromJson(Map<String, dynamic> j) => Health(
        personId: j['person_id'] as String,
        bloodGroup: j['blood_group'] as String?,
        genotype: j['genotype'] as String?,
        conditions: j['conditions'] as String?,
        visibility: _aud(j['visibility']),
      );

  Map<String, dynamic> toJson() => {
        'person_id': personId,
        'blood_group': bloodGroup,
        'genotype': genotype,
        'conditions': conditions,
        'visibility': visibility.name,
      };
}

/// Everything shown in the detail sections of a profile.
class PersonDetails {
  const PersonDetails({
    this.education = const [],
    this.occupations = const [],
    this.skills = const [],
    this.contact,
    this.health,
  });

  final List<Education> education;
  final List<Occupation> occupations;
  final List<Skill> skills;
  final Contact? contact;
  final Health? health;
}
