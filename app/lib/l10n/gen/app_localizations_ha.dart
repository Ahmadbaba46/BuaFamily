// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hausa (`ha`).
class AppLocalizationsHa extends AppLocalizations {
  AppLocalizationsHa([String locale = 'ha']) : super(locale);

  @override
  String get appTitle => 'Iyalin Bua';

  @override
  String get navTree => 'Bishiya';

  @override
  String get navMembers => '\'Yan uwa';

  @override
  String get navAdmin => 'Shugabanci';

  @override
  String get navMore => 'Ƙari';

  @override
  String get signIn => 'Shiga';

  @override
  String get signUp => 'Buɗe asusu';

  @override
  String get email => 'Imel';

  @override
  String get password => 'Kalmar sirri';

  @override
  String get displayName => 'Sunanka';

  @override
  String get haveAccount => 'Kana da asusu? Shiga';

  @override
  String get noAccount => 'Sabon shiga? Buɗe asusu';

  @override
  String get signOut => 'Fita';

  @override
  String get forgotPassword => 'Ka manta kalmar sirri?';

  @override
  String get resetPasswordSent => 'An aika imel don sabunta kalmar sirri.';

  @override
  String get checkEmailToConfirm =>
      'Duba imel ɗinka don tabbatar da asusunka, sannan ka shiga.';

  @override
  String get required => 'Ana bukata';

  @override
  String get invalidEmail => 'Shigar da ingantaccen imel';

  @override
  String get passwordTooShort => 'Aƙalla haruffa 8';

  @override
  String get welcomeTagline => 'Bishiyarmu, lokutanmu, iyalinmu.';

  @override
  String get pendingTitle => 'Ana jiran amincewa';

  @override
  String get pendingBody =>
      'Dole ne shugaban iyali ya amince da asusunka. Gaya musu kai wanene domin su haɗa ka da wurinka a cikin bishiya.';

  @override
  String get claimNoteLabel => 'Kai wanene a cikin iyali?';

  @override
  String get claimNoteHint => 'misali: Aisha, \'yar Musa Bua ta Kano';

  @override
  String get suspendedTitle => 'An dakatar da asusu';

  @override
  String get suspendedBody =>
      'An dakatar da asusunka. Da fatan za a tuntuɓi shugaban iyali.';

  @override
  String get checkAgain => 'Sake dubawa';

  @override
  String get save => 'Ajiye';

  @override
  String get saved => 'An ajiye';

  @override
  String get cancel => 'Soke';

  @override
  String get delete => 'Goge';

  @override
  String get edit => 'Gyara';

  @override
  String get add => 'Ƙara';

  @override
  String get refresh => 'Sabunta';

  @override
  String get retry => 'Sake gwadawa';

  @override
  String get close => 'Rufe';

  @override
  String get yes => 'Eh';

  @override
  String get no => 'A\'a';

  @override
  String errorGeneric(String error) {
    return 'An samu matsala: $error';
  }

  @override
  String get notConfigured =>
      'Ba a haɗa manhajar da sabar ba tukuna. Gina ta da SUPABASE_URL da SUPABASE_PUBLISHABLE_KEY.';

  @override
  String get treeEmpty => 'Babu kowa a cikin bishiyar iyali tukuna.';

  @override
  String get addFirstPerson => 'Ƙara mutum na farko';

  @override
  String get chooseRoot => 'Fara bishiya daga…';

  @override
  String get fitToScreen => 'Daidaita da allo';

  @override
  String get expandAll => 'Buɗe duka';

  @override
  String get collapseDeep => 'Naɗe tsararraki na ƙasa';

  @override
  String hiddenCount(int count) {
    return '+$count';
  }

  @override
  String get shownElsewhere => 'An nuna a wani wuri a bishiyar';

  @override
  String get searchHint => 'Nema da suna, wuri ko reshe';

  @override
  String peopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mutane $count',
      one: 'Mutum 1',
    );
    return '$_temp0';
  }

  @override
  String get noResults => 'Ba a samu kowa ba';

  @override
  String get filterAll => 'Duka';

  @override
  String get filterLiving => 'Masu rai';

  @override
  String get filterDeceased => 'Marigayai';

  @override
  String lateLabel(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'female': 'Marigayiya',
      'other': 'Marigayi',
    });
    return '$_temp0';
  }

  @override
  String get born => 'Haihuwa';

  @override
  String get died => 'Rasuwa';

  @override
  String get buried => 'An binne a';

  @override
  String get branch => 'Reshe';

  @override
  String get thisIsYou => 'Wannan kai ne';

  @override
  String get relationshipToYou => 'Dangantaka da kai';

  @override
  String get sectionFamily => 'Iyali';

  @override
  String get parents => 'Iyaye';

  @override
  String get spouses => 'Ma\'aurata';

  @override
  String get children => '\'Ya\'ya';

  @override
  String get siblings => '\'Yan\'uwa';

  @override
  String get sectionAbout => 'Game da shi/ita';

  @override
  String get education => 'Ilimi';

  @override
  String get work => 'Aiki';

  @override
  String get skills => 'Ƙwarewa';

  @override
  String get contact => 'Tuntuɓa';

  @override
  String get health => 'Lafiya';

  @override
  String get nothingYet => 'Ba a ƙara komai ba tukuna';

  @override
  String get addRelative => 'Ƙara dangi';

  @override
  String get linkExisting => 'Haɗa da wani da ke cikin bishiya';

  @override
  String get editPerson => 'Gyara bayanai';

  @override
  String get suggestEdit => 'Ba da shawarar gyara';

  @override
  String get deletePerson => 'Cire daga bishiya';

  @override
  String confirmDeletePerson(String name) {
    return 'A cire $name da duk alaƙarsa daga bishiya? Ba za a iya maido da wannan ba.';
  }

  @override
  String get changePhoto => 'Canja hoto';

  @override
  String get viewInTree => 'Duba a bishiya';

  @override
  String get thisIsMe => 'Wannan ni ne';

  @override
  String get thisIsMeSent => 'An aika. Shugaba zai tabbatar ya haɗa asusunka.';

  @override
  String get addFather => 'Uba';

  @override
  String get addMother => 'Uwa';

  @override
  String get addSpouse => 'Abokin aure';

  @override
  String get addSon => 'Ɗa';

  @override
  String get addDaughter => '\'Ya';

  @override
  String get title => 'Laƙabi (misali Alhaji, Hajiya, Dr)';

  @override
  String get firstName => 'Suna';

  @override
  String get middleName => 'Suna na tsakiya';

  @override
  String get lastName => 'Sunan iyali';

  @override
  String get nickname => 'Lakabi / alkunya';

  @override
  String get sex => 'Jinsi';

  @override
  String get male => 'Namiji';

  @override
  String get female => 'Mace';

  @override
  String get unknown => 'Ba a sani ba';

  @override
  String get birthDate => 'Ranar haihuwa';

  @override
  String get dateApprox => 'Kimanin (shekara kawai)';

  @override
  String get birthPlace => 'Wurin haihuwa';

  @override
  String get isLiving => 'Yana da rai';

  @override
  String get deathDate => 'Ranar rasuwa';

  @override
  String get deathPlace => 'Wurin rasuwa';

  @override
  String get burialPlace => 'Wurin binnewa';

  @override
  String get biography => 'Tarihin rayuwa';

  @override
  String get otherParent => 'Ɗayan mahaifi';

  @override
  String get otherParentUnknown => 'Ba a rubuta ba';

  @override
  String get relationKind => 'Iri';

  @override
  String get kindBiological => 'Na jini';

  @override
  String get kindAdopted => 'Riƙo (adopted)';

  @override
  String get kindFoster => 'Reno';

  @override
  String get kindStep => 'Na aure';

  @override
  String get unionStatus => 'Matsayin aure';

  @override
  String get statusMarried => 'Da aure';

  @override
  String get statusDivorced => 'Saki';

  @override
  String get statusWidowed => 'Mutuwar aure';

  @override
  String get statusSeparated => 'Rabuwa';

  @override
  String get pickDate => 'Zaɓi rana';

  @override
  String get clear => 'Share';

  @override
  String newPersonTitle(String relation) {
    return 'Ƙara $relation';
  }

  @override
  String get newPerson => 'Ƙara mutum';

  @override
  String ofPerson(String name) {
    return 'na $name';
  }

  @override
  String get selectPerson => 'Zaɓi mutum';

  @override
  String relationIs(String name) {
    return '$name shi ne…';
  }

  @override
  String get relationParentOf => 'Mahaifin wannan mutum';

  @override
  String get relationChildOf => 'Ɗan wannan mutum';

  @override
  String get relationSpouseOf => 'Abokin auren wannan mutum';

  @override
  String get sentForApproval => 'An aika wa shugabanni don amincewa';

  @override
  String get coreChangesSent =>
      'An aika sauye-sauyen suna, kwanan wata da matsayin rai ga shugabanni don amincewa.';

  @override
  String get contributionsOff => 'Shugabanni sun kashe ƙara dangi a yanzu.';

  @override
  String get requestsTitle => 'Buƙatu';

  @override
  String get pendingRequests => 'Buƙatun da ke jira';

  @override
  String get myRequests => 'Buƙatuna';

  @override
  String get noRequests => 'Babu buƙatu';

  @override
  String get approve => 'Amince';

  @override
  String get reject => 'Ƙi';

  @override
  String get rejectReason => 'Dalili (ba dole ba)';

  @override
  String get statusPending => 'Ana jira';

  @override
  String get statusApproved => 'An amince';

  @override
  String get statusRejected => 'An ƙi';

  @override
  String requestedBy(String name) {
    return 'Daga $name';
  }

  @override
  String reqCreatePerson(String name) {
    return 'Ƙara $name';
  }

  @override
  String reqRelation(String relation, String other) {
    return 'a matsayin $relation na $other';
  }

  @override
  String reqUpdatePerson(String name) {
    return 'Sabunta bayanan $name';
  }

  @override
  String reqAddParentChild(String parent, String child) {
    return '$parent mahaifi ne na $child';
  }

  @override
  String reqAddUnion(String a, String b) {
    return '$a da $b ma\'aurata ne';
  }

  @override
  String get withdraw => 'Janye';

  @override
  String get accountsTitle => 'Asusai';

  @override
  String get pendingAccounts => 'Ana jiran amincewa';

  @override
  String get activeAccounts => 'Masu aiki';

  @override
  String get suspendedAccounts => 'An dakatar';

  @override
  String get activate => 'Amince';

  @override
  String get suspend => 'Dakatar';

  @override
  String get makeAdmin => 'Mai da shugaba';

  @override
  String get makeMember => 'Cire shugabanci';

  @override
  String get linkToPerson => 'Haɗa da mutum';

  @override
  String linkedTo(String name) {
    return 'An haɗa da $name';
  }

  @override
  String get notLinked => 'Ba a haɗa da kowa a bishiya ba';

  @override
  String wantsToBe(String name) {
    return 'Ya ce shi ne: $name';
  }

  @override
  String get roleAdmin => 'Shugaba';

  @override
  String get roleMember => 'Ɗan iyali';

  @override
  String get settingsTitle => 'Saituna';

  @override
  String get familyName => 'Sunan iyali';

  @override
  String get memberContributions => '\'Yan iyali za su iya ƙara dangi';

  @override
  String get memberContributionsHelp =>
      'Idan an kunna, \'yan iyali za su iya ba da shawarar sababbin mutane da alaƙa. Shugabanni za su amince da kowanne kafin ya bayyana a bishiya.';

  @override
  String get treeRoot => 'Bishiya ta fara daga';

  @override
  String get treeRootAuto => 'Kai tsaye (kakan farko)';

  @override
  String get language => 'Harshe';

  @override
  String get english => 'Turanci';

  @override
  String get hausa => 'Hausa';

  @override
  String get myProfile => 'Bayanina';

  @override
  String get institution => 'Makaranta';

  @override
  String get qualification => 'Takardar shaida';

  @override
  String get field => 'Fannin karatu';

  @override
  String get startYear => 'Shekarar farawa';

  @override
  String get endYear => 'Shekarar gamawa';

  @override
  String get jobTitle => 'Sana\'a / aiki';

  @override
  String get organization => 'Kamfani / kasuwanci';

  @override
  String get industry => 'Fanni';

  @override
  String get location => 'Wuri';

  @override
  String get currentJob => 'A yanzu';

  @override
  String get skill => 'Ƙwarewa';

  @override
  String get notes => 'Bayani';

  @override
  String get phone => 'Waya';

  @override
  String get address => 'Adireshi';

  @override
  String get city => 'Gari';

  @override
  String get country => 'Ƙasa';

  @override
  String get visibleTo => 'Wa zai iya gani';

  @override
  String get visibleFamily => 'Duk iyali';

  @override
  String get visiblePrivate => 'Mutumin kawai da shugabanni';

  @override
  String get bloodGroup => 'Rukunin jini';

  @override
  String get genotype => 'Genotype';

  @override
  String get conditions => 'Cututtukan gado ko na dindindin';

  @override
  String get healthPrivacyNote =>
      'Bayanan lafiya sirri ne sai dai idan ka zaɓi raba su da iyali.';

  @override
  String get relSelf => 'Kai ne';

  @override
  String relSpouse(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'male': 'Miji',
      'female': 'Mata',
      'other': 'Abokin aure',
    });
    return '$_temp0';
  }

  @override
  String relParent(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'male': 'Uba',
      'female': 'Uwa',
      'other': 'Mahaifi',
    });
    return '$_temp0';
  }

  @override
  String relChild(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'female': '\'Ya',
      'other': 'Ɗa',
    });
    return '$_temp0';
  }

  @override
  String relSibling(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'female': '\'Yar\'uwa shaƙiƙiya',
      'other': 'Ɗan\'uwa shaƙiƙi',
    });
    return '$_temp0';
  }

  @override
  String relHalfSibling(String sex, String via) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'female': '\'Yar\'uwa',
      'other': 'Ɗan\'uwa',
    });
    String _temp1 = intl.Intl.selectLogic(via, {
      'male': 'uba ɗaya',
      'female': 'uwa ɗaya',
      'other': 'mahaifi ɗaya',
    });
    return '$_temp0 ($_temp1)';
  }

  @override
  String relGrandparent(int greats, String sex) {
    String _temp0 = intl.Intl.pluralLogic(
      greats,
      locale: localeName,
      other: 'Kakan kaka (tsara $greats)',
      one: 'Kakan kaka',
      zero: 'Kaka',
    );
    return '$_temp0';
  }

  @override
  String relGrandchild(int greats, String sex) {
    String _temp0 = intl.Intl.pluralLogic(
      greats,
      locale: localeName,
      other: 'Tattaɓa kunne (tsara $greats)',
      one: 'Tattaɓa kunne',
      zero: 'Jika',
    );
    return '$_temp0';
  }

  @override
  String relUncleAunt(int greats, String sex, String side) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'female': 'Inna',
      'other': 'Kawu',
    });
    String _temp1 = intl.Intl.selectLogic(sex, {
      'female': 'Gwaggo',
      'other': 'Baffa',
    });
    String _temp2 = intl.Intl.selectLogic(side, {
      'maternal': '$_temp0',
      'other': '$_temp1',
    });
    String _temp3 = intl.Intl.pluralLogic(
      greats,
      locale: localeName,
      other: ' (ɗan\'uwan kaka)',
      zero: '',
    );
    return '$_temp2$_temp3';
  }

  @override
  String relNephewNiece(int greats, String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'female': '\'Yar ɗan\'uwa',
      'other': 'Ɗan ɗan\'uwa',
    });
    String _temp1 = intl.Intl.pluralLogic(
      greats,
      locale: localeName,
      other: ' (jika)',
      zero: '',
    );
    return '$_temp0$_temp1';
  }

  @override
  String relCousin(int degree, int removed, String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'female': '\'Yar\'uwa',
      'other': 'Ɗan\'uwa',
    });
    String _temp1 = intl.Intl.pluralLogic(
      degree,
      locale: localeName,
      other: 'nesa',
      two: 'biyu',
      one: 'farko',
    );
    String _temp2 = intl.Intl.pluralLogic(
      removed,
      locale: localeName,
      other: ' – tsara $removed a tsakani',
      zero: '',
    );
    return '$_temp0 (zumunci na $_temp1)$_temp2';
  }

  @override
  String relStepParent(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'male': 'Mijin uwa',
      'female': 'Matar uba',
      'other': 'Mahaifin riƙo',
    });
    return '$_temp0';
  }

  @override
  String relStepChild(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'female': '\'Yar abokin aure',
      'other': 'Ɗan abokin aure',
    });
    return '$_temp0';
  }

  @override
  String relCoSpouse(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'female': 'Kishiya',
      'other': 'Abokin aure na tare',
    });
    return '$_temp0';
  }

  @override
  String relParentInLaw(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'female': 'Surukuwa',
      'other': 'Suruki',
    });
    return '$_temp0';
  }

  @override
  String relChildInLaw(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'female': 'Surukuwa',
      'other': 'Suruki',
    });
    return '$_temp0';
  }

  @override
  String relSiblingInLaw(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'female': 'Surukuwa',
      'other': 'Suruki',
    });
    return '$_temp0';
  }

  @override
  String get relByMarriage => 'Dangin aure';

  @override
  String get relNone => 'Babu dangantaka da aka rubuta';
}
