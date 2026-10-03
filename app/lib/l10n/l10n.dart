import 'package:flutter/cupertino.dart' show CupertinoLocalizations;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../domain/kinship.dart';
import '../models/family_graph.dart';
import '../models/person.dart';
import 'gen/app_localizations.dart';

export 'gen/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

String _sex(Sex s) => switch (s) {
      Sex.male => 'male',
      Sex.female => 'female',
      Sex.unknown => 'other',
    };

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

extension KinshipLabel on AppLocalizations {
  String kinship(Kinship k) {
    final sex = _sex(k.sex);
    return switch (k.type) {
      KinType.self => relSelf,
      KinType.spouse => relSpouse(sex),
      KinType.parent => relParent(sex),
      KinType.child => relChild(sex),
      KinType.sibling => k.isHalf ? relHalfSibling(sex, _sex(k.halfVia!)) : relSibling(sex),
      KinType.grandparent => relGrandparent(k.generations - 2, sex),
      KinType.grandchild => relGrandchild(k.generations - 2, sex),
      KinType.uncleAunt => _cap(relUncleAunt(k.generations - 1, sex, k.side.name)),
      KinType.nephewNiece => _cap(relNephewNiece(k.generations - 1, sex)),
      KinType.cousin => relCousin(k.cousinDegree, k.removed, sex),
      KinType.stepParent => relStepParent(sex),
      KinType.stepChild => relStepChild(sex),
      KinType.coSpouse => relCoSpouse(sex),
      KinType.parentInLaw => relParentInLaw(sex),
      KinType.childInLaw => relChildInLaw(sex),
      KinType.siblingInLaw => relSiblingInLaw(sex),
      KinType.relatedByMarriage => relByMarriage,
      KinType.none => relNone,
    };
  }

  /// "Your uncle · father’s side" — how a person relates to the viewer.
  String kinshipToYou(Kinship k) {
    final label = kinship(k);
    if (k.type == KinType.none || k.type == KinType.relatedByMarriage || k.type == KinType.self) return label;
    final base = localeName == 'ha' ? yourRelation(label) : yourRelation(label[0].toLowerCase() + label.substring(1));
    final side = switch (k.side) {
      FamilySide.paternal => sideFather,
      FamilySide.maternal => sideMother,
      FamilySide.unknown => null,
    };
    const sided = {KinType.grandparent, KinType.uncleAunt, KinType.cousin};
    return side != null && sided.contains(k.type) ? '$base · $side' : base;
  }

  String sexLabel(Sex s) => switch (s) {
        Sex.male => male,
        Sex.female => female,
        Sex.unknown => unknown,
      };

  String parentKindLabel(ParentKind k) => switch (k) {
        ParentKind.biological => kindBiological,
        ParentKind.adopted => kindAdopted,
        ParentKind.foster => kindFoster,
        ParentKind.step => kindStep,
      };

  String unionStatusLabel(UnionStatus s) => switch (s) {
        UnionStatus.married => statusMarried,
        UnionStatus.divorced => statusDivorced,
        UnionStatus.widowed => statusWidowed,
        UnionStatus.separated => statusSeparated,
      };

  /// "Late" prefix for deceased people.
  String late(Person p) => lateLabel(_sex(p.sex));

  String approxPrefix() => localeName == 'ha' ? 'kimanin ' : 'c. ';

  /// Full date, or just the year (with "c.") when only approximately known.
  String formatDate(DateTime d, {bool approx = false}) {
    if (approx) return '${approxPrefix()}${d.year}';
    if (localeName == 'ha') return '${d.day} ${_haMonths[d.month - 1]}, ${d.year}';
    return DateFormat.yMMMMd('en').format(d);
  }
}

// intl has no Hausa date data, so month names are provided here.
const _haMonths = [
  'Janairu', 'Fabrairu', 'Maris', 'Afirilu', 'Mayu', 'Yuni',
  'Yuli', 'Agusta', 'Satumba', 'Oktoba', 'Nuwamba', 'Disamba',
];

/// Flutter ships no Material/Cupertino strings for Hausa. These delegates fall
/// back to English for built-in widgets (date pickers, dialogs) while the app's
/// own text stays in Hausa.
class _FallbackDelegate<T> extends LocalizationsDelegate<T> {
  const _FallbackDelegate(this._inner);
  final LocalizationsDelegate<T> _inner;

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ha';

  @override
  Future<T> load(Locale locale) => _inner.load(const Locale('en'));

  @override
  bool shouldReload(covariant LocalizationsDelegate<T> old) => false;
}

const localizationsDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  _FallbackDelegate<MaterialLocalizations>(GlobalMaterialLocalizations.delegate),
  _FallbackDelegate<WidgetsLocalizations>(GlobalWidgetsLocalizations.delegate),
  _FallbackDelegate<CupertinoLocalizations>(GlobalCupertinoLocalizations.delegate),
];
