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

  @override
  String get welcomeBack => 'Barka da dawowa';

  @override
  String get createYourAccount => 'Buɗe asusunka';

  @override
  String get privateSpaceNote =>
      'Wuri na sirri ga iyalin Bua. Shugaban iyali ne ke amincewa da sababbin asusai.';

  @override
  String pendingGreeting(String name) {
    return 'Salamu alaikum, $name. Shugaban iyali zai amince da asusunka ya haɗa ka da wurinka a bishiya.';
  }

  @override
  String get claimHelp =>
      'Ambaci iyayenka ko kakanninka domin shugaba ya gane ka da sauri.';

  @override
  String get stepCreated => 'An buɗe asusu';

  @override
  String get stepReview => 'Shugaba zai duba ya haɗa ka';

  @override
  String get stepExplore => 'Bincika bishiyar iyali';

  @override
  String get startingFrom => 'Farawa daga';

  @override
  String get change => 'Canja';

  @override
  String get findRelative => 'Nemo dangi';

  @override
  String get zoomIn => 'Ƙara girma';

  @override
  String get zoomOut => 'Rage girma';

  @override
  String get centreOnMe => 'Nuna ni';

  @override
  String yourRelation(String relation) {
    return '$relation';
  }

  @override
  String get sideFather => 'ta wajen uba';

  @override
  String get sideMother => 'ta wajen uwa';

  @override
  String get educationWork => 'Ilimi da aiki';

  @override
  String get addEducation => 'Ƙara ilimi';

  @override
  String get addWork => 'Ƙara aiki';

  @override
  String get addSkill => 'Ƙara ƙwarewa';

  @override
  String get sharedWithFamily => 'An raba da iyali';

  @override
  String get privateLabel => 'Sirri';

  @override
  String get addingTo => 'Ana ƙarawa ga';

  @override
  String newPersonIs(String name) {
    return 'Dangantakar sabon mutum da $name…';
  }

  @override
  String get approvalBanner =>
      'Shugaba zai duba wannan kafin ya bayyana a bishiya. Za ka gan shi a Ƙari › Buƙatuna.';

  @override
  String get sendForApproval => 'Aika don amincewa';

  @override
  String get approveAndLink => 'Amince ka haɗa';

  @override
  String get linkSomeoneElse => 'Haɗa da wani';

  @override
  String get adminAlwaysOwn =>
      '\'Yan iyali kullum za su iya gyara hotonsu, aikinsu da ƙwarewarsu';

  @override
  String get adminAlwaysDirect =>
      'Shugabanni kullum suna ƙara da gyara kai tsaye';

  @override
  String get privacyTitle => 'Sirri.';

  @override
  String get privacyNote =>
      '\'Yan iyali da aka amince da su kaɗai za su iya buɗe manhajar. Bayanan lafiya sirri ne sai mutum ya raba su; shugabanni na iya ganinsu koyaushe.';

  @override
  String get adminRequestsAccounts => 'Shugabanci: buƙatu da asusai';

  @override
  String get viewMyProfile => 'Duba bayanina';

  @override
  String get account => 'Asusu';

  @override
  String pendingCount(int count) {
    return '$count na jira';
  }

  @override
  String get myRequestsHelp =>
      'Gyaran da ka bayar zai bayyana a bishiya da zarar shugaba ya amince.';

  @override
  String get seeInTree => 'Duba a bishiya';

  @override
  String get married => 'Da aure';

  @override
  String get navHome => 'Gida';

  @override
  String get navEvents => 'Taruka';

  @override
  String greeting(String name) {
    return 'Salamu alaikum, $name';
  }

  @override
  String get birthdayToday => 'Ranar haihuwa yau';

  @override
  String turnsAge(String name, int age) {
    return '$name: shekara $age yau';
  }

  @override
  String get sendGreeting => 'Aika gaisuwa';

  @override
  String get remembrance => 'Tunawa';

  @override
  String yearsSincePassed(int count, String name) {
    return 'Shekara $count da rasuwar $name';
  }

  @override
  String get addPrayer => 'Yi addu\'a';

  @override
  String get announcement => 'Sanarwa';

  @override
  String get pinned => 'An lika';

  @override
  String fromAuthor(String name, String time) {
    return 'Daga $name · $time';
  }

  @override
  String get shareMomentPrompt => 'Raba wani abu da iyali…';

  @override
  String get maShaAllah => 'Ma sha Allah';

  @override
  String commentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sharhi $count',
      zero: 'Sharhi',
    );
    return '$_temp0';
  }

  @override
  String addedPhotosTo(int count) {
    return 'An ƙara hoto $count a';
  }

  @override
  String get feedEmpty => 'Babu abin da aka raba tukuna. Ka zama na farko.';

  @override
  String get timeJustNow => 'yanzu';

  @override
  String timeMinutes(int n) {
    return 'minti $n';
  }

  @override
  String timeHours(int n) {
    return 'awa $n';
  }

  @override
  String get timeYesterday => 'Jiya';

  @override
  String timeDaysAgo(int n) {
    return 'kwana $n da suka wuce';
  }

  @override
  String get postOptions => 'Zaɓuɓɓuka';

  @override
  String get deletePost => 'Goge rubutu';

  @override
  String get confirmDeletePost => 'A goge wannan rubutu ga kowa?';

  @override
  String get pinToHome => 'Lika a Gida';

  @override
  String get unpin => 'Cire lika';

  @override
  String get adminsOnly => 'Masu gudanarwa kaɗai';

  @override
  String get shareAMoment => 'Raba wani abu';

  @override
  String get post => 'Wallafa';

  @override
  String onlyFamilyCanSee(String family) {
    return 'Iyalin $family kaɗai ke ganin wannan';
  }

  @override
  String get whatsHappening => 'Me ke faruwa?';

  @override
  String get addPhotos => 'Ƙara hotuna';

  @override
  String get removePhoto => 'Cire hoto';

  @override
  String get whosInIt => 'Su wa ke ciki?';

  @override
  String get tagFamily => 'Saka dangi';

  @override
  String get untag => 'Cire alama';

  @override
  String get alsoAddToAlbum => 'Kuma saka a kundi';

  @override
  String get dontAddToAlbum => 'Kada a saka a kundi';

  @override
  String get dataSaverNote =>
      'Ana rage girman hotuna kafin a ɗora su don adana data.';

  @override
  String get postEmptyError => 'Rubuta wani abu ko ƙara hoto.';

  @override
  String get albums => 'Kundin hotuna';

  @override
  String get newAlbum => 'Sabon kundi';

  @override
  String get albumName => 'Sunan kundi';

  @override
  String get create => 'Ƙirƙira';

  @override
  String get photosOfYou => 'Hotunanka';

  @override
  String photosTaggedIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hoto $count da aka saka ka',
      zero: 'Hotunan da aka saka ka za su bayyana a nan',
    );
    return '$_temp0';
  }

  @override
  String photoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hoto $count',
      zero: 'Babu hoto tukuna',
    );
    return '$_temp0';
  }

  @override
  String get albumsEmpty =>
      'Babu kundi tukuna. Fara ɗaya don aure, Sallah ko tsofaffin hotunan iyali.';

  @override
  String get everyone => 'Kowa';

  @override
  String addedByRelatives(int count) {
    return 'dangi $count suka ƙara';
  }

  @override
  String get noPhotos => 'Babu hotuna a nan tukuna.';

  @override
  String photoXofY(int x, int y) {
    return '$x cikin $y';
  }

  @override
  String get inThisPhoto => 'A cikin wannan hoto';

  @override
  String get tagSomeone => 'Saka wani';

  @override
  String addedBy(String name) {
    return 'Daga $name';
  }

  @override
  String memoriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tuna baya $count',
      zero: 'Raba tuna baya',
    );
    return '$_temp0';
  }

  @override
  String get editDetails => 'Gyara bayani';

  @override
  String get caption => 'Bayani';

  @override
  String get yearTaken => 'Shekarar da aka ɗauka';

  @override
  String get deletePhoto => 'Goge hoto';

  @override
  String get confirmDeletePhoto => 'A goge wannan hoto?';

  @override
  String get comments => 'Sharhi';

  @override
  String get writeComment => 'Rubuta sharhi…';

  @override
  String get noCommentsYet => 'Babu sharhi tukuna.';

  @override
  String get send => 'Aika';

  @override
  String get newLabel => 'Sabo';

  @override
  String get upcoming => 'Masu zuwa';

  @override
  String get announcements => 'Sanarwa';

  @override
  String get past => 'Sun wuce';

  @override
  String get latestAnnouncements => 'Sabbin sanarwa';

  @override
  String get noUpcomingEvents => 'Babu taro mai zuwa.';

  @override
  String get noPastEvents => 'Babu taron da ya wuce.';

  @override
  String get noAnnouncements => 'Babu sanarwa tukuna.';

  @override
  String get youreGoing => 'Za ka je';

  @override
  String get youSaidMaybe => 'Ka ce watakila';

  @override
  String get youCantGo => 'Ba za ka samu ba';

  @override
  String get replyNeeded => 'Ana jiran amsarka';

  @override
  String goingCount(int count) {
    return '$count za su je';
  }

  @override
  String maybeCount(int count) {
    return '$count watakila';
  }

  @override
  String eventCategory(String category) {
    String _temp0 = intl.Intl.selectLogic(category, {
      'naming': 'Suna',
      'wedding': 'Aure',
      'meeting': 'Taron iyali',
      'condolence': 'Ta\'aziyya',
      'graduation': 'Yaye',
      'other': 'Taro',
    });
    return '$_temp0';
  }

  @override
  String hostedBy(String name) {
    return 'Mai shiryawa: $name';
  }

  @override
  String get addToCalendar => 'Saka a kalanda';

  @override
  String get directions => 'Hanya';

  @override
  String get areYouComing => 'Za ka zo?';

  @override
  String get rsvpGoing => 'Zan je';

  @override
  String get rsvpMaybe => 'Watakila';

  @override
  String get rsvpNo => 'Ba zan samu ba';

  @override
  String get bringingOthers => 'Masu rakiyarka';

  @override
  String get oneFewer => 'Ragi ɗaya';

  @override
  String get oneMore => 'Ƙari ɗaya';

  @override
  String get seeAll => 'Duba duka';

  @override
  String get wishes => 'Fatan alheri';

  @override
  String get writeWish => 'Rubuta fatan alheri…';

  @override
  String get deleteEvent => 'Goge taro';

  @override
  String get confirmDeleteEvent => 'A goge wannan taro ga kowa?';

  @override
  String get newPost => 'Sabon rubutu';

  @override
  String get event => 'Taro';

  @override
  String get eventType => 'Iri';

  @override
  String get date => 'Rana';

  @override
  String get time => 'Lokaci';

  @override
  String get place => 'Wuri';

  @override
  String get addressOrArea => 'Adireshi ko unguwa';

  @override
  String get details => 'Bayani';

  @override
  String get askReply => 'Nemi mutane su amsa';

  @override
  String get askReplySub => 'Zan je · Watakila · Ba zan samu ba';

  @override
  String get postEvent => 'Wallafa taro';

  @override
  String get postAnnouncement => 'Wallafa sanarwa';

  @override
  String get announcementHint => 'Rubuta sanarwar…';

  @override
  String get titleRequired => 'Saka suna.';

  @override
  String get family => 'Iyali';

  @override
  String get photos => 'Hotuna';

  @override
  String get notifications => 'Saƙonni';

  @override
  String get markAllRead => 'Karanta duka';

  @override
  String get noNotifications => 'Babu sabon saƙo.';

  @override
  String get today => 'Yau';

  @override
  String get earlier => 'A baya';

  @override
  String notifEvent(String title) {
    return 'Sabon taro: $title';
  }

  @override
  String notifBirthday(String name, int age) {
    return 'Ranar haihuwar $name yau ($age)';
  }

  @override
  String notifEventReminder(String title) {
    return 'Gobe: $title';
  }

  @override
  String get notifTaggedPost => 'An saka ka a wani rubutu';

  @override
  String get notifTaggedPhoto => 'An saka ka a hoto';

  @override
  String notifComment(String body) {
    return 'Sabon sharhi: “$body”';
  }

  @override
  String get notificationsSms => 'Saƙonni da SMS';

  @override
  String get phoneNumber => 'Lambar waya';

  @override
  String get phoneHint => '0803 123 4567';

  @override
  String get phoneInvalid => 'Saka lambar waya daidai.';

  @override
  String get smsOptIn => 'Karɓi SMS a wannan waya';

  @override
  String get smsOptInSub => 'Muhimman labaran iyali ta SMS, ko babu data.';

  @override
  String get smsBirthdays => 'Tunatarwar ranar haihuwa';

  @override
  String get smsBirthdaysSub => 'SMS da safe idan ranar haihuwar ɗan uwa ce.';

  @override
  String get smsEvents => 'Taruka da sanarwa';

  @override
  String get smsEventsSub =>
      'Taruka da sanarwar da masu gudanarwa suka aika, da tunatarwa kwana ɗaya kafin taron da za ka je.';

  @override
  String get inAppNote =>
      'Kullum za ka ga saƙonni a cikin manhaja, ƙarƙashin ƙararrawa a Gida.';

  @override
  String get smsOffNote =>
      'Ba a kunna SMS ga iyali ba tukuna. Mai gudanarwa zai iya kunna shi a Gudanarwa › Saituna.';

  @override
  String get smsTitle => 'SMS (Termii)';

  @override
  String get smsEnable => 'Aika SMS ga iyali';

  @override
  String get smsEnableSub =>
      'Yana amfani da kuɗin Termii. Kowa yana zaɓar abin da yake so.';

  @override
  String get senderId => 'Sunan mai aikawa';

  @override
  String get senderIdHint => 'Wanda aka yi rajista da Termii, haruffa 3–11.';

  @override
  String get smsRoute => 'Hanya';

  @override
  String get routeGeneric => 'Generic';

  @override
  String get routeDnd => 'DND (har da lambobin DND; sai Termii ya kunna)';

  @override
  String get apiKey => 'Makullin API na Termii';

  @override
  String get apiKeySaved => 'An adana';

  @override
  String get apiKeyMissing => 'Ba a saka ba';

  @override
  String get apiKeyNote =>
      'Za ka same shi a dashboard na Termii. Ana adana shi a ɓoye kuma ba za a sake nuna shi ba.';

  @override
  String get baseUrl => 'Adireshin API (ba dole ba)';

  @override
  String get baseUrlHint =>
      'Yana cikin dashboard na Termii. Bar shi babu komai don https://api.ng.termii.com';

  @override
  String get sendTestSms => 'Aiko min da gwajin SMS';

  @override
  String get testSmsSent => 'An aika gwajin SMS. Zai iso cikin minti ɗaya.';

  @override
  String smsStats(int subscribers, int sent, int failed) {
    return '$subscribers sun yi rajista · $sent an aika a wannan mako · $failed sun kasa';
  }

  @override
  String smsQueued(int count) {
    return '$count suna jiran aikawa';
  }

  @override
  String lastError(String error) {
    return 'Kuskure na ƙarshe: $error';
  }

  @override
  String get smsSetupSteps =>
      '1. Samo makullin API da sunan mai aikawa daga Termii. 2. Adana su a nan. 3. Kunna SMS ka aika wa kanka gwaji.';

  @override
  String get notifyFamily => 'Sanar da dukan iyali';

  @override
  String get notifyFamilySub => 'A cikin manhaja';

  @override
  String get alsoSms => 'Kuma aika SMS';

  @override
  String get alsoSmsSub => 'Masu gudanarwa kaɗai · yana amfani da kuɗin SMS';

  @override
  String get whoCanHelp => 'Wa zai iya taimakawa?';

  @override
  String get whoCanHelpSub => 'Ƙwarewa da gogewa a cikin iyali';

  @override
  String get searchSkills => 'Nemi ƙwarewa, aiki ko karatu';

  @override
  String helpCategory(String category) {
    String _temp0 = intl.Intl.selectLogic(category, {
      'health': 'Lafiya',
      'law': 'Shari\'a',
      'trades': 'Sana\'o\'i',
      'teaching': 'Koyarwa',
      'business': 'Kasuwanci',
      'engineering': 'Injiniya',
      'tech': 'Fasaha',
      'islamic': 'Karatun addini',
      'other': 'Wasu',
    });
    return '$_temp0';
  }

  @override
  String relativesIn(int count, String category) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dangi $count a $category',
      zero: 'Babu kowa a $category tukuna',
    );
    return '$_temp0';
  }

  @override
  String relativesMatching(int count, String query) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dangi $count sun dace da “$query”',
      zero: 'Babu wanda ya dace da “$query”',
    );
    return '$_temp0';
  }

  @override
  String relativesWithSkills(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dangi $count da suka saka ƙwarewa ko aiki',
      zero: 'Ba a saka ƙwarewa ko aiki ba tukuna',
    );
    return '$_temp0';
  }

  @override
  String get helpEmptyNote =>
      'Saka aikinka, karatunka da ƙwarewarka a shafinka don dangi su same ka.';

  @override
  String get contactNote =>
      'Maɓallin kira yana bayyana ne kawai ga waɗanda suka raba lambarsu da iyali.';

  @override
  String callPerson(String name) {
    return 'Kira $name';
  }

  @override
  String get profile => 'Shafi';

  @override
  String get bloodDonors => 'Masu ba da jini';

  @override
  String get requestBlood => 'Nemi jini';

  @override
  String get urgent => 'Gaggawa';

  @override
  String pintsFor(int count, String name) {
    return 'Pint $count don $name';
  }

  @override
  String askedBy(String name) {
    return '$name ne ya nema';
  }

  @override
  String get iCanDonate => 'Zan bayar';

  @override
  String get youOffered => 'Ka yi tayi';

  @override
  String offersSoFar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dangi $count sun yi tayi zuwa yanzu.',
      zero: 'Babu wanda ya yi tayi tukuna.',
    );
    return '$_temp0';
  }

  @override
  String get closeRequest => 'Rufe buƙata';

  @override
  String get closed => 'An rufe';

  @override
  String notCompatible(String group) {
    return 'Jininka ($group) ba zai dace da wannan buƙata ba.';
  }

  @override
  String get matchesFor => 'Masu dacewa da';

  @override
  String canReceiveFrom(String group, String groups) {
    return '$group (zai karɓi $groups)';
  }

  @override
  String get noDonors => 'Babu masu ba da jini da suka dace tukuna.';

  @override
  String get onDonorList => 'Kana cikin jerin masu ba da jini';

  @override
  String get changeInHealth => 'Canza a bayanan lafiyarka';

  @override
  String get joinDonorList => 'Shiga jerin masu ba da jini';

  @override
  String get joinDonorListSub =>
      'Saka rukunin jininka a bayanan lafiya ka zaɓi “Mai ba da jini”.';

  @override
  String get donorPrivacy =>
      'Waɗanda suka amince ne kawai ke bayyana a nan, da rukunin jininsu da garinsu kaɗai. Ba a taɓa nuna genotype ko wasu bayanan lafiya ba.';

  @override
  String get bloodDonorOptIn => 'Saka ni cikin masu ba da jini';

  @override
  String get bloodDonorOptInSub =>
      'Dangi za su ga rukunin jininka da garinka kaɗai.';

  @override
  String get bloodDonorLabel => 'Mai ba da jini';

  @override
  String get bloodGroupNeeded => 'Rukunin jinin da ake buƙata';

  @override
  String get units => 'Pint';

  @override
  String get patient => 'Don wa ne?';

  @override
  String get patientHint => 'Zaɓi daga iyali, ko rubuta suna';

  @override
  String get pickFromFamily => 'Zaɓi daga iyali';

  @override
  String get hospital => 'Asibiti';

  @override
  String get contactPhone => 'Lambar da za a kira';

  @override
  String get noteOptional => 'Bayani (ba dole ba)';

  @override
  String get bloodRequestSent => 'An saka buƙatar. An sanar da masu dacewa.';

  @override
  String notifBloodRequest(String group, String patient, String hospital) {
    return 'Ana buƙatar jini $group don $patient a $hospital';
  }

  @override
  String notifBloodOffer(String group) {
    return 'Wani ɗan uwa zai iya ba da jini ($group)';
  }

  @override
  String get memorialPage => 'Shafin tunawa';

  @override
  String get inLovingMemory => 'Cikin ƙauna da tunawa';

  @override
  String memorialPrayer(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'female': 'Allah ya jikanta da rahama',
      'other': 'Allah ya jikansa da rahama',
    });
    return '$_temp0';
  }

  @override
  String lifeOf(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'female': 'Rayuwarta',
      'other': 'Rayuwarsa',
    });
    return '$_temp0';
  }

  @override
  String get noLifeStory =>
      'Babu labarin rayuwa tukuna. Iyali za su iya saka shi a shafin.';

  @override
  String get seeFullProfile => 'Duba cikakken shafi da iyali';

  @override
  String allPhotos(int count) {
    return 'Duka $count';
  }

  @override
  String prayersMemories(int count) {
    return 'Addu\'o\'i da tunawa · $count';
  }

  @override
  String get addPrayerMemory => 'Ƙara addu\'a ko tunawa…';

  @override
  String get noMemoriesYet => 'Ka zama na farko da zai raba addu\'a ko tunawa.';

  @override
  String remindMeEvery(String date) {
    return 'Tunatar da ni kowace $date';
  }

  @override
  String get remindMeEverySub => 'Saƙon tunawa mai sauƙi';

  @override
  String notifRemembrance(int count, String name) {
    return 'Shekara $count da rasuwar $name';
  }

  @override
  String notifMemory(String name, String body) {
    return 'Sabon tunawa da $name: “$body”';
  }

  @override
  String get howRelated => 'Yaya muke dangantaka?';

  @override
  String get you => 'Kai';

  @override
  String get swap => 'Musanya';

  @override
  String get pickSomeone => 'Zaɓi wani';

  @override
  String relatedIsYour(String name) {
    return '$name a gare ka:';
  }

  @override
  String relatedIsOf(String name, String other) {
    return '$name a gare $other:';
  }

  @override
  String pathChildOf(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'female': '\'yar',
      'other': 'ɗan',
    });
    return '$_temp0';
  }

  @override
  String pathParentOf(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'female': 'mahaifiyar',
      'other': 'mahaifin',
    });
    return '$_temp0';
  }

  @override
  String pathSpouseOf(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'male': 'mijin',
      'female': 'matar',
      'other': 'abokin auren',
    });
    return '$_temp0';
  }

  @override
  String pathShared(String relation) {
    return '$relation da kuke tarayya';
  }

  @override
  String youSuffix(String name) {
    return '$name (kai)';
  }

  @override
  String get showBothInTree => 'Nuna a bishiya';

  @override
  String get notConnected => 'Ba a rubuta wata alaƙa a bishiyar ba tukuna.';

  @override
  String get sameDistantRelative => 'Dangi';

  @override
  String get tapToLoad => 'Taɓa don buɗe hoto';

  @override
  String get remindersTitle => 'Ranakun haihuwa da tunawa';

  @override
  String todayDate(String date) {
    return 'Yau · $date';
  }

  @override
  String get thisWeek => 'Wannan mako';

  @override
  String get comingUp => 'Masu zuwa';

  @override
  String yearsMarried(String names, int count) {
    return '$names · shekara $count da aure';
  }

  @override
  String get kindBirthday => 'Ranar haihuwa';

  @override
  String get kindWedding => 'Ranar aure';

  @override
  String get greet => 'Gaisa';

  @override
  String get pray => 'Yi addu\'a';

  @override
  String get remindersNote =>
      'Ranakun tunawa sun fito daga ranakun rasuwa da aka rubuta. Ranakun haihuwa na masu rai ne kaɗai.';

  @override
  String get nothingComingUp => 'Babu komai a wata mai zuwa.';

  @override
  String get editMyDetails => 'Gyara bayanaina';

  @override
  String get nameDatesNote => 'Suna da ranaku:';

  @override
  String get askAnAdmin => 'nemi mai gudanarwa';

  @override
  String get aboutMe => 'Game da ni';

  @override
  String get myStory => 'Labarina';

  @override
  String get whoSeesContact => 'Wa zai ga bayanan tuntuɓata?';

  @override
  String get whoSeesHealth => 'Wa zai ga bayanan lafiyata?';

  @override
  String get wholeFamily => 'Dukan iyali';

  @override
  String get onlyMeAdmins => 'Ni da masu gudanarwa kaɗai';

  @override
  String get notLinkedEdit =>
      'Ba a haɗa asusunka da wurinka a bishiya ba tukuna. Mai gudanarwa zai iya haɗa shi.';

  @override
  String get settingsScreen => 'Saituna';

  @override
  String get languageHarshe => 'Harshe · Language';

  @override
  String get dataSaver => 'Adana data';

  @override
  String get tapToLoadPhotos => 'Buɗe hotuna sai na taɓa su';

  @override
  String get tapToLoadPhotosSub => 'Yana adana data a wannan waya';

  @override
  String get shrinkUploads => 'Rage girman hotuna kafin ɗorawa';

  @override
  String get shrinkUploadsSub => 'Yana rage amfani da data har kashi 80';

  @override
  String get notifyMeAbout => 'Sanar da ni game da';

  @override
  String get notifEventsAnnouncements => 'Sanarwa da taruka';

  @override
  String get notifBirthdaysRemembrance => 'Ranakun haihuwa da tunawa';

  @override
  String get notifTagged => 'Idan an saka ni a hotuna';

  @override
  String get notifCommentsMine => 'Sharhi kan rubutuna';

  @override
  String get urgentBlood => 'Buƙatun jini na gaggawa';

  @override
  String get alwaysOn => 'Kullum a kunne';

  @override
  String get privacyOfMyDetails => 'Sirrin bayanaina';

  @override
  String get welfareFund => 'Asusun taimakon iyali';

  @override
  String get fundBalance => 'Kuɗin da ke cikin asusu';

  @override
  String treasurerLine(String names, String time) {
    return 'Ma\'aji: $names · an sabunta $time';
  }

  @override
  String get treasurer => 'Ma\'aji';

  @override
  String get makeTreasurer => 'Mai da shi ma\'aji';

  @override
  String get removeTreasurer => 'Cire daga ma\'aji';

  @override
  String get contribute => 'Ba da gudummawa';

  @override
  String get askForSupport => 'Nemi taimako';

  @override
  String get openCauses => 'Buƙatun da ake tarawa';

  @override
  String raisedOf(String raised, String target) {
    return '$raised cikin $target';
  }

  @override
  String contributorsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Masu gudummawa $count',
      zero: 'Babu masu gudummawa tukuna',
    );
    return '$_temp0';
  }

  @override
  String closesOn(String date) {
    return 'za a rufe $date';
  }

  @override
  String get fundNote =>
      'Ba a karɓar kuɗi a cikin manhaja. Kana biya asusun iyali ko ma\'aji kai tsaye, ka rubuta a nan, sannan ma\'aji ya tabbatar.';

  @override
  String get howToPay => 'Yadda ake biya';

  @override
  String get bank => 'Banki';

  @override
  String get accountNumber => 'Lambar asusu';

  @override
  String get accountName => 'Sunan asusu';

  @override
  String get copyAccountNumber => 'Kwafi lambar asusu';

  @override
  String get copied => 'An kwafa';

  @override
  String get noAccountYet =>
      'Ma\'aji bai saka bayanan asusu ba tukuna. Za ka iya ba ma\'aji kuɗi hannu.';

  @override
  String get recordContribution => 'Rubuta gudummawarka';

  @override
  String get amountNaira => 'Adadi (₦)';

  @override
  String get payTransfer => 'Tura ta banki';

  @override
  String get payCash => 'Hannu ga ma\'aji';

  @override
  String get payMobile => 'Kuɗin waya';

  @override
  String get attachReceipt => 'Haɗa rasit (ba dole ba)';

  @override
  String get receiptAttached => 'An haɗa rasit';

  @override
  String get showMyName => 'Nuna sunana a jerin masu gudummawa';

  @override
  String get recordContributionButton => 'Rubuta gudummawa';

  @override
  String get contributionNote =>
      'Ma\'aji yana tabbatar da kowace gudummawa. Kai da kwamiti kaɗai ke ganin adadin.';

  @override
  String get contributionRecorded => 'An rubuta. Ma\'aji zai tabbatar.';

  @override
  String get amountInvalid => 'Saka adadi.';

  @override
  String get generalFund => 'Asusun gaba ɗaya';

  @override
  String get contributeToFund => 'Ba da gudummawa ga asusu';

  @override
  String get myContributions => 'Gudummawata';

  @override
  String get contribPending => 'Ana jiran ma\'aji';

  @override
  String get contribConfirmed => 'An tabbatar';

  @override
  String get contribRejected => 'Ba a tabbatar ba';

  @override
  String toConfirm(int count) {
    return 'Don tabbatarwa · $count';
  }

  @override
  String get confirmAction => 'Tabbatar';

  @override
  String get notReceived => 'Ba a karɓa ba';

  @override
  String get viewReceipt => 'Rasit';

  @override
  String get supportRequests => 'Buƙatun taimako';

  @override
  String get openCause => 'Buɗe';

  @override
  String get decline => 'Ƙi';

  @override
  String get closeCause => 'Rufe';

  @override
  String get newCause => 'Sabuwar buƙata';

  @override
  String get causeTitle => 'Don me ne?';

  @override
  String get targetAmount => 'Adadin da ake buƙata (₦)';

  @override
  String get closesOnLabel => 'Ranar rufewa (ba dole ba)';

  @override
  String get askSupportNote =>
      'Buƙatarka za ta tafi ga ma\'aji da masu gudanarwa kaɗai. Idan suka buɗe ta, iyali za su iya ba da gudummawa.';

  @override
  String get requestSent => 'An aika ga ma\'aji da masu gudanarwa.';

  @override
  String get recordPayout => 'Rubuta taimakon da aka biya';

  @override
  String get forCause => 'Don';

  @override
  String get editAccount => 'Gyara bayanan asusu';

  @override
  String get openingBalance => 'Kuɗin da ke cikin asusu tun farko (₦)';

  @override
  String get waitingReview => 'Ana jiran dubawa';

  @override
  String notifFundContribution(String amount) {
    return 'Sabuwar gudummawa da za a tabbatar: $amount';
  }

  @override
  String notifFundConfirmed(String amount) {
    return 'An tabbatar da gudummawarka ta $amount. Na gode!';
  }

  @override
  String notifFundRequest(String title) {
    return 'An nemi taimako: $title';
  }

  @override
  String get mentorsTitle => 'Masu jagora da tallafin karatu';

  @override
  String get tabMentors => 'Masu jagora';

  @override
  String get tabStudents => 'Ɗalibai';

  @override
  String get tabOpportunities => 'Damarmaki';

  @override
  String get newOpportunity => 'Sabuwar dama';

  @override
  String sharedBy(String name) {
    return '$name ne ya raba';
  }

  @override
  String deadlineOn(String date) {
    return 'wa\'adi $date';
  }

  @override
  String get offeringGuidance => 'Dangin da ke ba da jagora';

  @override
  String get lookingForHelp => 'Ɗaliban da ke neman taimako';

  @override
  String get ask => 'Tambaya';

  @override
  String askMentorTitle(String name) {
    return 'Tambayi $name';
  }

  @override
  String get askMentorHint => 'Me kake son taimako a kai?';

  @override
  String askSent(String name) {
    return 'An aika. $name zai ga saƙonka.';
  }

  @override
  String get asksToYou => 'Tambayoyi gare ka';

  @override
  String get offerToMentor => 'Ba da jagora';

  @override
  String get editMentoring => 'Gyara jagorana';

  @override
  String get stopMentoring => 'Daina ba da jagora';

  @override
  String get mentorAreas => 'Fannonin da za ka iya taimakawa';

  @override
  String get mentorAreasHint => 'misali Likitanci · neman aiki a asibiti';

  @override
  String get imLookingForHelp => 'Ina neman taimako';

  @override
  String get editMyRequest => 'Gyara buƙatata';

  @override
  String get removeMyRequest => 'Cire buƙatata';

  @override
  String get studyField => 'Me kake karanta?';

  @override
  String get whatHelp => 'Wane taimako kake nema?';

  @override
  String get shareOpportunity => 'Raba wata dama';

  @override
  String get opportunityTitle => 'Suna';

  @override
  String get link => 'Hanyar yanar gizo (ba dole ba)';

  @override
  String get deadlineOptional => 'Wa\'adi (ba dole ba)';

  @override
  String get open => 'Buɗe';

  @override
  String get noMentorsYet => 'Babu wanda ya ba da jagora tukuna.';

  @override
  String get noStudentsYet => 'Babu ɗalibin da ke neman taimako yanzu.';

  @override
  String get noOpportunitiesYet => 'Ba a raba wata dama ba tukuna.';

  @override
  String get pollsTitle => 'Ƙuri\'u';

  @override
  String get newPoll => 'Sabuwar ƙuri\'a';

  @override
  String closesDate(String date) {
    return 'za a rufe $date';
  }

  @override
  String get youVoted => 'ka jefa ƙuri\'a';

  @override
  String get notVotedYet => 'ba ka jefa ba tukuna';

  @override
  String get vote => 'Jefa ƙuri\'a';

  @override
  String get changeVote => 'Canza ƙuri\'ata';

  @override
  String votedOf(int count, int eligible) {
    return '$count cikin $eligible sun jefa ƙuri\'a';
  }

  @override
  String get decided => 'An yanke';

  @override
  String decidedLine(int percent, String date) {
    return 'Kashi $percent sun zaɓa · an yanke $date';
  }

  @override
  String get closePoll => 'Rufe ƙuri\'a';

  @override
  String get deletePoll => 'Goge ƙuri\'a';

  @override
  String get question => 'Tambaya';

  @override
  String get pollContext => 'Don me ne? (ba dole ba)';

  @override
  String get pollContextHint => 'misali Don taron iyali';

  @override
  String get choices => 'Zaɓuɓɓuka';

  @override
  String choiceN(int n) {
    return 'Zaɓi na $n';
  }

  @override
  String get addChoice => 'Ƙara zaɓi';

  @override
  String get closesOnPoll => 'Ranar rufe ƙuri\'a';

  @override
  String get needTwoChoices => 'Saka tambaya da zaɓuɓɓuka biyu aƙalla.';

  @override
  String get noPollsYet => 'Babu ƙuri\'a tukuna. Yi wa iyali tambaya.';

  @override
  String get secretBallot =>
      'Ƙuri\'u a ɓoye suke. Za ka ga sakamako bayan ka jefa ko idan an rufe.';

  @override
  String notifMentorRequest(String body) {
    return 'Wani ya nemi jagorarka: “$body”';
  }

  @override
  String notifOpportunity(String title) {
    return 'Sabuwar dama: $title';
  }

  @override
  String notifPoll(String question) {
    return 'Sabuwar ƙuri\'a: $question';
  }

  @override
  String get storiesTitle => 'Labaran dattijai';

  @override
  String get storiesSubtitle =>
      'Muryoyin iyali, an adana su don zuri\'a mai zuwa';

  @override
  String get nowPlaying => 'Ana saurara';

  @override
  String get listen => 'Saurara';

  @override
  String get otherLanguage => 'Wani';

  @override
  String get transcript => 'Rubutaccen labari';

  @override
  String get noStoriesYet => 'Babu labari tukuna. Naɗi na farko.';

  @override
  String get recordStory => 'Naɗi labarin dattijo';

  @override
  String get recordHint =>
      'Gwada tambaya: Yaya kuka haɗu? Yaya Kano take lokacin kuruciyarku?';

  @override
  String get deleteStory => 'Share labari';

  @override
  String get deleteStoryConfirm => 'A share wannan labari da naɗinsa?';

  @override
  String get newStory => 'Sabon labari';

  @override
  String get tapToRecord => 'Taɓa don fara naɗi';

  @override
  String recordingNow(String time) {
    return 'Ana naɗi… $time';
  }

  @override
  String get tapToStop => 'Taɓa don tsayawa';

  @override
  String recordedLength(String time) {
    return 'An naɗa · $time';
  }

  @override
  String get recordAgain => 'Sake naɗi';

  @override
  String get chooseAudioFile =>
      'Ko zaɓi fayil ɗin sauti (daga kaset, saƙon murya)';

  @override
  String get micDenied => 'Ba da izinin makirufo a saitunan wayarka don naɗi.';

  @override
  String get storyTitle => 'Labarin mene ne?';

  @override
  String get whoSpeaking => 'Wane ne ke magana?';

  @override
  String get sourceNote => 'A ina kuma yaushe aka naɗa? (ba dole ba)';

  @override
  String get sourceNoteHint =>
      'misali An naɗa a 1979 a kaset, Bello ya mayar da shi na zamani';

  @override
  String get transcriptOptional => 'Rubutaccen labari (ba dole ba)';

  @override
  String get saveStory => 'Adana labari';

  @override
  String get uploading => 'Ana ɗorawa…';

  @override
  String get needAudio => 'Fara naɗi ko zaɓi naɗi tukuna.';

  @override
  String get needTitleSpeaker => 'Saka suna da wanda ke magana.';

  @override
  String notifStory(String speaker, String title) {
    return 'Sabon labari daga $speaker: $title';
  }

  @override
  String get dataTitle => 'Shigowa, fitarwa da ajiya';

  @override
  String get dataSubtitle => 'Shugabanni kawai · bayananku ba a kulle suke ba';

  @override
  String get exportHeading => 'Fitarwa';

  @override
  String get exportGedcom => 'Bishiyar iyali (GEDCOM)';

  @override
  String get exportGedcomSub => 'Yana buɗewa a wasu manhajojin asalin iyali';

  @override
  String get exportCsv => 'Fitar da CSV';

  @override
  String get exportCsvSub => 'Kowa, tare da kwanaki da wurare';

  @override
  String get exportPdf => 'Bishiyar bugawa (PDF)';

  @override
  String get exportPdfSub => 'Babban hoto, don taron iyali';

  @override
  String get includeDetails => 'Haɗa da lambobin sadarwa da bayanan lafiya';

  @override
  String savedFile(String file) {
    return 'An adana $file';
  }

  @override
  String get importHeading => 'Shigo da bayanai';

  @override
  String get chooseImportFile => 'Zaɓi fayil ɗin GEDCOM ko CSV';

  @override
  String get importReviewNote =>
      'Za ka duba waɗanda suka yi daidai kafin a ƙara komai';

  @override
  String get downloadTemplate => 'Sauke samfurin tebur';

  @override
  String importError(String message) {
    return 'Ba a iya karanta fayil ɗin ba: $message';
  }

  @override
  String get weeklyBackupOn => 'Ajiyar mako-mako tana aiki';

  @override
  String get weeklyBackupOff => 'Ajiyar mako-mako a kashe take';

  @override
  String lastBackup(String date) {
    return 'Ajiya ta ƙarshe $date';
  }

  @override
  String get noBackupYet => 'Babu ajiya tukuna';

  @override
  String get download => 'Sauke';

  @override
  String get keepWeeklyBackup => 'Riƙa ajiya kowane mako';

  @override
  String get backupNow => 'Yi ajiya yanzu';

  @override
  String get backupDone => 'An adana ajiya';

  @override
  String get earlierBackups => 'Ajiyoyin baya';

  @override
  String get backupsKept => 'Ana riƙe ajiyoyin makonni takwas na ƙarshe.';

  @override
  String get reviewImport => 'Duba abin da za a shigo da shi';

  @override
  String importSummary(int added, int matched, int links) {
    return '$added sababbi · $matched suna cikin bishiya · alaƙa $links';
  }

  @override
  String get importNew => 'Sabo';

  @override
  String sameAs(String name) {
    return 'Daidai da $name a bishiya';
  }

  @override
  String get notSame => 'Ba shi ba ne';

  @override
  String get addToTree => 'Ƙara cikin bishiya';

  @override
  String importDone(int people, int links) {
    return 'An ƙara mutane $people da alaƙa $links.';
  }

  @override
  String importSkipped(int count) {
    return 'An tsallake alaƙa $count saboda ba su dace da bishiyar ba.';
  }

  @override
  String treePosterTitle(String family) {
    return 'Iyalan $family';
  }

  @override
  String treePosterSubtitle(int count, String date) {
    return 'Mutane $count · an buga $date';
  }

  @override
  String get restoreTitle => 'Maido da bayanai daga ajiya';

  @override
  String get restoreSubtitle =>
      'Dawo da bayanan iyali da aka goge ko aka sauya';

  @override
  String get restoreEllipsis => 'Maido…';

  @override
  String get chooseBackup => 'Zaɓi ajiya';

  @override
  String beforeLastRestore(String date) {
    return 'Kafin maidowar ƙarshe · $date';
  }

  @override
  String get backupFile => 'Fayil ɗin ajiya…';

  @override
  String backupFileChosen(String name) {
    return 'Fayil: $name';
  }

  @override
  String get notABackup => 'Wannan fayil ba ajiyar Bua Family ba ne.';

  @override
  String get undoChanges => 'Har da soke sauye-sauyen da aka yi bayan haka';

  @override
  String get undoChangesSub =>
      'Za a mayar da gyare-gyaren da aka yi bayan ajiyar. Ba a goge komai ba.';

  @override
  String get restorePreview => 'Abin da zai faru';

  @override
  String get checkingBackup => 'Ana duba ajiyar…';

  @override
  String get restoreUpToDate =>
      'Babu abin da za a maido: bayanan yau sun riga sun ƙunshi komai na wannan ajiyar.';

  @override
  String restoreGroup(String group) {
    String _temp0 = intl.Intl.selectLogic(group, {
      'tree': 'Bishiyar iyali',
      'details': 'Aiki, karatu, sadarwa da lafiya',
      'sharing': 'Rubuce-rubuce da hotuna',
      'events': 'Taruka',
      'memories': 'Tunawa da labarai',
      'support': 'Neman jini da asusun walwala',
      'other': 'Jagoranci da ƙuri\'u',
    });
    return '$_temp0';
  }

  @override
  String restoreCounts(int added, int updated) {
    return '$added za a dawo da su · $updated za a mayar';
  }

  @override
  String restoreSkippedCount(int count) {
    return '$count ba za su dawo ba';
  }

  @override
  String get restoreSafety =>
      'Za a adana kwafin bayanan yau tukuna, don ka iya soke wannan daga “Kafin maidowar ƙarshe”.';

  @override
  String get restoreLimits =>
      'Ba a maido da asusun shiga ba: membobi za su sake shiga, shugaba ya haɗa su. Hotuna, naɗaɗɗun murya da rasit fayiloli ne; ajiyar na da bayaninsu amma ba fayilolin ba.';

  @override
  String get restoreButton => 'Maido';

  @override
  String get restoreConfirm => 'A maido da wannan ajiyar yanzu?';

  @override
  String restoreDone(int added, int updated) {
    return 'An maido: $added sun dawo, $updated an mayar.';
  }

  @override
  String get pushOnThisPhone => 'Sanarwa a wannan waya';

  @override
  String get pushInThisBrowser => 'Sanarwa a wannan burauza';

  @override
  String get pushOnSub =>
      'Sababbin sanarwa za su bayyana nan ko da manhajar a rufe take.';

  @override
  String get pushOffSub =>
      'A sanar da kai game da taruka, neman jini, ƙuri\'u da sauransu, ko da manhajar a rufe take.';

  @override
  String get pushBlocked =>
      'An toshe sanarwa. Ba da izini ga Bua Family a saitunan wayarka ko burauza, sannan ka sake gwadawa.';

  @override
  String get pushUnavailable =>
      'Wannan sigar manhajar ba za ta iya karɓar sanarwa ba tukuna.';

  @override
  String get pushNotSetUp => 'Wani shugaba bai saita sanarwar waya ba tukuna.';

  @override
  String get pushTurnedOn => 'An kunna sanarwa a wannan na\'ura.';

  @override
  String get pushFailed =>
      'Ba a iya kunna sanarwa ba. Duba haɗin intanet sannan ka sake gwadawa.';

  @override
  String get pushPromptTitle => 'Karɓi sanarwa a wannan waya';

  @override
  String get pushPromptBody =>
      'Ka sani nan take game da neman jini, taruka da labaran iyali.';

  @override
  String get turnOn => 'Kunna';

  @override
  String get notNow => 'Ba yanzu ba';

  @override
  String get pushAdminTitle => 'Sanarwar waya';

  @override
  String get pushAdminSub =>
      'Aika kowace sanarwa zuwa wayoyi da burauzan membobi (kyauta, ta Firebase).';

  @override
  String get pushSetupSteps =>
      '1. Ƙirƙiri aiki kyauta a console.firebase.google.com. 2. A Project settings › Service accounts, zaɓi “Generate new private key”. 3. Zaɓi wannan fayil a ƙasa. Manhajar na buƙatar saitunan Firebase ɗinku (duba README).';

  @override
  String get firebaseKey => 'Makullin Firebase';

  @override
  String firebaseKeySaved(String project) {
    return 'An adana · $project';
  }

  @override
  String get chooseKeyFile => 'Zaɓi fayil ɗin makulli (.json)';

  @override
  String pushStats(int members, int devices, int sent, int received) {
    return 'Membobi $members a na\'urori $devices · an aika $sent, burauza sun karɓi $received a wannan mako';
  }

  @override
  String get sendTestPush => 'Aiko mini gwajin sanarwa';

  @override
  String get testPushSent =>
      'An aika. Za ta zo a duk na\'urar da ka kunna sanarwa.';

  @override
  String get notifTest => 'Gwajin sanarwa: sanarwa na aiki a wannan na\'ura.';

  @override
  String get addPhoto => 'Saka hoto';

  @override
  String get photoLabel => 'Hoto';

  @override
  String notifAccountRequest(String name) {
    return 'Sabon rajista na jiran amincewa: $name';
  }

  @override
  String notifAccountNote(String name, String note) {
    return 'Bayani daga $name: “$note”';
  }

  @override
  String notifChangeAdd(String name, String person) {
    return 'Shawara daga $name: a ƙara $person a bishiyar iyali';
  }

  @override
  String notifChangeEdit(String name, String person) {
    return 'Shawara daga $name: gyara bayanin $person';
  }

  @override
  String get notifAccountApproved => 'Barka da zuwa! An amince da asusunka.';

  @override
  String notifRequestApproved(String person) {
    return 'An amince da shawararka game da $person';
  }

  @override
  String notifRequestDeclined(String person) {
    return 'Ba a karɓi shawararka game da $person ba';
  }

  @override
  String get notifSomeone => 'wani';

  @override
  String get notifTheTree => 'bishiyar iyali';

  @override
  String get pendingPushHint => 'Sami sanarwa da zarar admin ya amince da kai.';

  @override
  String notifCommentBy(String name, String body) {
    return 'Sharhi daga $name: “$body”';
  }

  @override
  String notifCommentAlso(String name, String body) {
    return 'Sabon sharhi daga $name a inda ka yi sharhi: “$body”';
  }

  @override
  String notifAccountClaim(String name, String person) {
    return '$name: “Ni ne $person” a bishiyar iyali';
  }

  @override
  String get postGone => 'An cire wannan rubutu.';

  @override
  String get findMeInTree => 'Nemo kanka a bishiyar iyali';

  @override
  String get findMeHint =>
      'Haɗa asusunka da wurinka a bishiyar iyali don samun bayananka, hotonka da cikakkun bayanai.';

  @override
  String linkWaiting(String name) {
    return 'Ana jiran admin ya haɗa ka da $name';
  }

  @override
  String get linkedNow => 'An haɗa. Wannan ne bayananka yanzu.';

  @override
  String get birthOrder => 'Matsayin haihuwa tsakanin \'yan uwa';

  @override
  String get birthOrderHint =>
      '1 ga ɗan fari. Za a jera \'yan uwa a wannan tsari.';

  @override
  String get birthOrderNone => 'Ba a saka ba';

  @override
  String reqRemoveParentChild(String parent, String child) {
    return 'Cire $parent a matsayin iyayen $child';
  }

  @override
  String reqRemoveUnion(String a, String b) {
    return 'Cire auren $a da $b';
  }

  @override
  String get removeRelationship => 'Cire dangantaka';

  @override
  String confirmRemoveParent(String parent, String child) {
    return 'A cire $parent a matsayin iyayen $child? Dukansu za su ci gaba da kasancewa a bishiyar iyali.';
  }

  @override
  String confirmRemoveUnion(String a, String b) {
    return 'A cire auren $a da $b? Dukansu za su ci gaba da kasancewa a bishiyar iyali.';
  }

  @override
  String get relationshipRemoved => 'An cire dangantakar';

  @override
  String get checkTree => 'Duba bishiyar iyali';

  @override
  String get checkTreeHint =>
      'Haɗe-haɗen da ba su yi daidai ba, don a gyara su';

  @override
  String get treeLooksRight => 'Babu abin da ya yi kuskure a bishiyar iyali.';

  @override
  String problemMarriedInLine(String a, String b) {
    return '$a da $b sun yi aure, amma ɗaya ya fito daga zuriyar ɗayan';
  }

  @override
  String problemParentYounger(String a, String b) {
    return '$a iyayen $b ne amma bai girme shi da shekara 10 ba';
  }

  @override
  String problemBornAfterDeath(String a, String b) {
    return 'An haifi $b fiye da shekara ɗaya bayan rasuwar $a';
  }

  @override
  String problemSameBirthOrder(String a, String b) {
    return '$a da $b suna da matsayin haihuwa iri ɗaya';
  }

  @override
  String get removeLink => 'Cire haɗin';

  @override
  String get sortBy => 'Jera';

  @override
  String get sortName => 'Suna (A–Z)';

  @override
  String get sortOldest => 'Manya da farko';

  @override
  String get sortYoungest => 'Ƙanana da farko';

  @override
  String get sortFamily => 'Tsarin iyali';

  @override
  String get helpEachOther => 'Taimakon juna';

  @override
  String get openMenu => 'Buɗe jerin zaɓuɓɓuka';

  @override
  String get updateAvailableTitle => 'Sabon salo na manhajar ya fito';

  @override
  String updateAvailableBody(String version) {
    return 'Salo $version. Sauke shi, sannan ka buɗe fayil ɗin don sabuntawa.';
  }

  @override
  String get getAppTitle => 'Bua Family a Android';

  @override
  String get getAppSub => 'Saka manhajar iyali a wayarka ta Android.';

  @override
  String getAppVersion(String version, String date) {
    return 'Salo $version · $date';
  }

  @override
  String get getAppSteps =>
      '1. Taɓa Sauke.\n2. Buɗe fayil ɗin da aka sauke.\n3. Idan wayarka ta tambaya, ka yarda a saka manhajoji daga wannan wurin, sannan ka taɓa Install (ko Update).';

  @override
  String get getAppLatest => 'Kana da sabon salo.';

  @override
  String get getAppNone => 'Ba a fitar da manhajar Android ba tukuna.';

  @override
  String get getAppIphone =>
      'A iPhone, yi amfani da shafin yanar gizo: buɗe shi a Safari, taɓa Share, sannan Add to Home Screen.';

  @override
  String get getTheApp => 'Sami manhajar Android';

  @override
  String get whatsNew => 'Abin da ya sabunta';

  @override
  String get androidAppAdmin => 'Manhajar Android';

  @override
  String androidPublished(String version, String date) {
    return 'An fitar da $version · $date';
  }

  @override
  String get androidNotPublished =>
      'Ba a fitar ba tukuna. Gina APK a kwamfutarka, sannan ka fitar da shi a nan.';

  @override
  String get publishVersion => 'Fitar da sabon salo';

  @override
  String get buildNumber => 'Lambar gini';

  @override
  String get versionLabel => 'Salo';

  @override
  String get whatsNewOptional => 'Abin da ya sabunta (ba dole ba)';

  @override
  String get appPublished =>
      'An fitar. An sanar da masu amfani da manhajar Android.';

  @override
  String get shareAppLink => 'Hanyar saukewa don rabawa';

  @override
  String notifAppUpdate(String version) {
    return 'Sabon salo na manhajar ya fito ($version). Taɓa don saukewa.';
  }

  @override
  String get searchUsers => 'Nemi suna, imel, waya ko mutum';

  @override
  String get filterWaiting => 'Ana jira';

  @override
  String get filterActive => 'Masu aiki';

  @override
  String get filterSuspended => 'An dakatar';

  @override
  String get filterAdmins => 'Admins';

  @override
  String get filterTreasurers => 'Ma\'aji';

  @override
  String get filterNotLinked => 'Ba a bishiya ba';

  @override
  String get filterNoPush => 'Babu sanarwa';

  @override
  String get filterInactive => 'Ba su shigo kwana 30 ba';

  @override
  String usersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Asusu $count',
      one: 'Asusu 1',
    );
    return '$_temp0';
  }

  @override
  String get platformFilter => 'Manhajar da ake amfani da ita';

  @override
  String get platformAny => 'Kowace';

  @override
  String get platformAndroid => 'Manhajar Android';

  @override
  String get platformWeb => 'Shafin yanar gizo';

  @override
  String get sortNewest => 'Sababbi';

  @override
  String get sortLastActive => 'Shigowa ta ƙarshe';

  @override
  String get sortMostActive => 'Masu yawan shigowa';

  @override
  String get neverSeen => 'Bai shigo ba tukuna';

  @override
  String lastSeen(String when) {
    return 'Ya shigo $when';
  }

  @override
  String activeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ya shigo kwanaki $count cikin 30',
      one: 'Ya shigo rana 1 cikin kwanaki 30',
      zero: 'Bai shigo ba a kwanaki 30 da suka wuce',
    );
    return '$_temp0';
  }

  @override
  String postsAndComments(int posts, int comments) {
    return 'Rubutu $posts · sharhi $comments';
  }

  @override
  String get noPushDevices => 'Ba a kunna sanarwa ba';

  @override
  String pushOn(String devices) {
    return 'Sanarwa a: $devices';
  }

  @override
  String androidVersionOf(String version) {
    return 'Manhajar Android $version';
  }

  @override
  String joinedOn(String date) {
    return 'Ya shiga $date';
  }

  @override
  String get emailTab => 'Imel';

  @override
  String get phoneTab => 'Waya';

  @override
  String get yourNameNew => 'Sunanka (idan sabo ne)';

  @override
  String get sendCode => 'Aiko mini lamba';

  @override
  String codeSent(String phone) {
    return 'Mun aika lamba mai lambobi 6 zuwa $phone.';
  }

  @override
  String get enterCode => 'Lambar da ke cikin saƙon';

  @override
  String get resendCode => 'Sake aikawa';

  @override
  String resendIn(int seconds) {
    return 'Sake aikawa bayan daƙiƙa $seconds';
  }

  @override
  String get changeNumber => 'Canja lamba';

  @override
  String get invalidPhone => 'Shigar da ingantacciyar lambar waya';

  @override
  String get inviteTitle => 'An gayyace ka';

  @override
  String inviteBody(String inviter, String family) {
    return '$inviter ya gayyace ka zuwa manhajar iyalin $family.';
  }

  @override
  String inviteBodyGeneric(String family) {
    return 'An gayyace ka zuwa manhajar iyalin $family.';
  }

  @override
  String inviteFor(String person) {
    return 'Wannan gayyata ta $person ce.';
  }

  @override
  String get inviteInvalid =>
      'An riga an yi amfani da wannan hanyar gayyata ko ta ƙare. Nemi sabuwa daga admin na iyali.';

  @override
  String get joinWithInvite => 'Shiga iyali';

  @override
  String get acceptInvite => 'Karɓi gayyatar';

  @override
  String get inviteAccepted => 'Barka da zuwa manhajar iyali!';

  @override
  String get inviteSomeone => 'Gayyaci wani';

  @override
  String get inviteSomeoneHint =>
      'Ƙirƙiri hanyar da za ka aika a WhatsApp. Duk wanda ya shiga da ita za a amince da shi nan take.';

  @override
  String get invitePerson => 'Ga wani a bishiyar iyali (ba dole ba)';

  @override
  String get createInvite => 'Ƙirƙiri hanyar';

  @override
  String get inviteReady =>
      'Hanyar ta shirya. Sau ɗaya take aiki, na kwanaki 30.';

  @override
  String get shareWhatsApp => 'Raba a WhatsApp';

  @override
  String get copyLink => 'Kwafi hanyar';

  @override
  String inviteMessage(String family, String link) {
    return 'Assalamu alaikum! Shiga manhajar iyalin $family: $link';
  }

  @override
  String inviteMessageFor(String name, String family, String link) {
    return 'Assalamu alaikum $name! Shiga manhajar iyalin $family: $link';
  }

  @override
  String get offlineSaved =>
      'Babu intanet. Ana nuna abin da aka ajiye a wannan wayar.';

  @override
  String get metricsTitle => 'Ƙididdigar iyali';

  @override
  String get metricsSub => 'Yadda iyali ke amfani da manhajar';

  @override
  String get period7 => 'Kwana 7';

  @override
  String get period30 => 'Kwana 30';

  @override
  String get period90 => 'Kwana 90';

  @override
  String get period365 => 'Wata 12';

  @override
  String get periodCustom => 'Zaɓi…';

  @override
  String get byDay => 'Kowace rana';

  @override
  String get byWeek => 'Kowane mako';

  @override
  String get byMonth => 'Kowane wata';

  @override
  String get allPlatforms => 'Duk manhajoji';

  @override
  String get allBranches => 'Duk rassa';

  @override
  String get comparePrevious => 'Kwatanta da lokacin da ya gabata';

  @override
  String get previousPeriod => 'Lokacin da ya gabata';

  @override
  String vsPrevious(String change) {
    return '$change idan aka kwatanta da baya';
  }

  @override
  String get noChange => 'Daidai da lokacin baya';

  @override
  String get newThisPeriod => 'Sabo a wannan lokacin';

  @override
  String get customiseTiles => 'Zaɓi ƙididdiga';

  @override
  String get customiseTilesHint => 'Zaɓi abin da zai bayyana a allonka.';

  @override
  String get showTable => 'Tebur';

  @override
  String get showChart => 'Zane';

  @override
  String get breakdownBy => 'Raba ta';

  @override
  String get byBranch => 'Reshe';

  @override
  String get byPlatform => 'Manhaja';

  @override
  String get byMember => 'Mutum';

  @override
  String get noBranch => 'Babu reshe';

  @override
  String get unknownLabel => 'Ba a sani ba';

  @override
  String get snapshotTitle => 'Yanzu';

  @override
  String get funnelAccounts => 'Asusu';

  @override
  String get funnelApproved => 'An amince';

  @override
  String get funnelLinked => 'A bishiya';

  @override
  String get funnelActive30 => 'Sun shigo cikin kwana 30';

  @override
  String get funnelPush => 'Sanarwa a kunne';

  @override
  String get funnelAndroid => 'Manhajar Android';

  @override
  String get treeQuality => 'Bishiyar iyali';

  @override
  String treePeople(int count, int living) {
    return 'Mutum $count · $living a raye';
  }

  @override
  String withPhotoPct(int pct) {
    return '$pct% suna da hoto';
  }

  @override
  String withBirthPct(int pct) {
    return '$pct% suna da ranar haihuwa';
  }

  @override
  String withAccountPct(int pct) {
    return '$pct% suna da asusu';
  }

  @override
  String get fundBalanceLabel => 'Kuɗin asusun taimako';

  @override
  String get openBloodLabel => 'Buƙatun jini a buɗe';

  @override
  String get pendingSuggestionsLabel => 'Shawarwari masu jira';

  @override
  String get noDataYet => 'Babu komai a wannan lokacin tukuna.';

  @override
  String get mgPeople => 'Mutane';

  @override
  String get mgTree => 'Bishiyar iyali';

  @override
  String get mgSharing => 'Rabawa';

  @override
  String get mgEvents => 'Taruka da ƙuri\'u';

  @override
  String get mgHelping => 'Taimakon juna';

  @override
  String get mgReach => 'Isar da saƙo';

  @override
  String get m_signups => 'Rajista';

  @override
  String get m_active_members => 'Masu shigowa';

  @override
  String get m_active_android => 'Masu shigowa ta Android';

  @override
  String get m_active_web => 'Masu shigowa ta yanar gizo';

  @override
  String get m_people_added => 'Mutanen da aka ƙara';

  @override
  String get m_relationships_added => 'Dangantakar da aka ƙara';

  @override
  String get m_suggestions => 'Shawarwarin da aka aika';

  @override
  String get m_suggestions_reviewed => 'Shawarwarin da aka duba';

  @override
  String get m_moments => 'Rubutun da aka saka';

  @override
  String get m_announcements => 'Sanarwa';

  @override
  String get m_posting_members => 'Masu saka rubutu';

  @override
  String get m_photos => 'Hotuna';

  @override
  String get m_comments => 'Sharhi';

  @override
  String get m_likes => 'Ma sha Allah';

  @override
  String get m_stories => 'Labaran da aka naɗa';

  @override
  String get m_memories => 'Tunawar da aka rubuta';

  @override
  String get m_events => 'Tarukan da aka ƙirƙira';

  @override
  String get m_rsvps => 'Amsoshin gayyata';

  @override
  String get m_polls => 'Ƙuri\'u';

  @override
  String get m_votes => 'Zaɓe';

  @override
  String get m_blood_requests => 'Buƙatun jini';

  @override
  String get m_blood_offers => 'Masu son ba da jini';

  @override
  String get m_contributions => 'Gudummawar da aka rubuta';

  @override
  String get m_money_in => 'Kuɗin da aka tabbatar';

  @override
  String get m_money_out => 'Kuɗin da aka biya';

  @override
  String get m_causes => 'Buƙatun da aka buɗe';

  @override
  String get m_mentor_asks => 'Buƙatun jagora';

  @override
  String get m_opportunities => 'Damarmakin da aka raba';

  @override
  String get m_notifications => 'Sanarwar da aka aika';

  @override
  String get m_notifications_received => 'Sanarwar da aka karɓa';

  @override
  String get m_sms_sent => 'Saƙonnin tes da aka aika';

  @override
  String get storiesAdminOnly =>
      'Masu gudanarwa ne ke naɗar labaran dattawa. Idan kana da labari, gaya wa mai gudanarwa.';

  @override
  String get aboutTitle => 'Game da manhajar';

  @override
  String get aboutSub => 'Siga, abubuwan da ke ciki da wanda ya yi ta';

  @override
  String get aboutTagline =>
      'Iyali ɗaya, wuri ɗaya: bishiyarmu, labarunmu da kulawarmu ga juna.';

  @override
  String aboutVersion(String version, String build) {
    return 'Siga $version · gini $build';
  }

  @override
  String get aboutOnWeb => 'Manhajar yanar gizo';

  @override
  String get aboutOnAndroid => 'Manhajar Android';

  @override
  String aboutLatestAndroid(String version) {
    return 'Sabuwar manhajar Android: $version';
  }

  @override
  String get aboutUpToDate => 'Kana da sabuwar siga.';

  @override
  String get featuresTitle => 'Abubuwan da ke cikin manhajar';

  @override
  String get fTree => 'Bishiyar iyali';

  @override
  String get fTreeD =>
      'Kowa da hotuna da tsarin haihuwa, da bincike don daidaito.';

  @override
  String get fMembers => '\'Yan uwa da bayanansu';

  @override
  String get fMembersD => 'Nemo kowa, kira ko aika saƙo, ka sabunta bayananka.';

  @override
  String get fRelated => 'Yaya muke da dangantaka?';

  @override
  String get fRelatedD => 'Hanyar dangantaka tsakanin kowane mutum biyu.';

  @override
  String get fSharing => 'Lokuta, kundin hotuna da sanarwa';

  @override
  String get fSharingD =>
      'Raba labarai da hotuna; yi sharhi, so da ambaton \'yan uwa.';

  @override
  String get fEvents => 'Taruka da tunatarwa';

  @override
  String get fEventsD =>
      'Bukukuwan aure, suna da taruka, da amsa gayyata, ranakun haihuwa da tunawa.';

  @override
  String get fBlood => 'Masu ba da jini';

  @override
  String get fBloodD =>
      'Nemi jini a gaggawa ka sami masu bayarwa a cikin iyali nan take.';

  @override
  String get fFund => 'Asusun walwala';

  @override
  String get fFundD => 'Gudummawa, buƙatu da biya, a fili ga iyali.';

  @override
  String get fMentors => 'Jagoranci da damammaki';

  @override
  String get fMentorsD =>
      'Nemi shawara daga ɗan uwa mai gogewa; raba ayyuka da tallafin karatu.';

  @override
  String get fStories => 'Labaran dattawa';

  @override
  String get fStoriesD =>
      'Muryoyin dattawanmu, an naɗa an adana don zuriya masu zuwa.';

  @override
  String get fPolls => 'Ƙuri\'u';

  @override
  String get fPollsD => 'Mu yanke shawara tare.';

  @override
  String get fMemorial => 'Shafukan tunawa';

  @override
  String get fMemorialD =>
      'Tunawa da waɗanda suka rasu, da addu\'o\'i da tunani.';

  @override
  String get fReach => 'Sanarwa da SMS';

  @override
  String get fReachD =>
      'A waya, a yanar gizo, da SMS ga waɗanda ba su da data.';

  @override
  String get fOffline => 'Tana aiki ba tare da intanet ba';

  @override
  String get fOfflineD =>
      'Abin da ka gani yana nan a wayarka idan intanet ya yanke.';

  @override
  String get fLanguages => 'Turanci da Hausa';

  @override
  String get fLanguagesD => 'Canza a kowane lokaci a Ƙari.';

  @override
  String get fPrivate => 'Na iyali kaɗai';

  @override
  String get fPrivateD =>
      'Sai \'yan uwa da aka amince da su ke gani. Masu gudanarwa ne ke amincewa da kowane asusu.';

  @override
  String get developerTitle => 'Mai haɓakawa';

  @override
  String get developedBy => 'Wanda ya tsara kuma ya haɓaka';

  @override
  String get contactCall => 'Kira';

  @override
  String get contactWhatsApp => 'WhatsApp';

  @override
  String get contactEmail => 'Imel';

  @override
  String get contactWebsite => 'Shafin yanar gizo';

  @override
  String get licensesLabel => 'Lasisin buɗaɗɗen manhaja';

  @override
  String copyrightLine(String year, String company) {
    return '© $year $company. Duk haƙƙoƙi a kiyaye.';
  }

  @override
  String get aboutSettings => 'Shafin game da manhaja: mai haɓakawa';

  @override
  String get aboutSettingsHint =>
      'Ana nuna su a shafin game da manhaja ga kowa a cikin iyali.';

  @override
  String get developerName => 'Sunan mai haɓakawa';

  @override
  String get developerCompany => 'Kamfani';

  @override
  String get developerWebsite => 'Shafin yanar gizo (https://…)';

  @override
  String notifMentorRequestFrom(String name, String body) {
    return '$name ya nemi jagorarka: “$body”';
  }

  @override
  String notifMentorReply(String name, String body) {
    return '$name: “$body”';
  }

  @override
  String get yourAsks => 'Tambayoyinka';

  @override
  String get conversationTitle => 'Jagoranci';

  @override
  String conversationWithMentor(String areas) {
    return 'Jagoranka · $areas';
  }

  @override
  String get conversationWithStudent => 'Ya nemi jagorarka';

  @override
  String get conversationPrivate =>
      'Ku biyu ne kaɗai ke ganin wannan tattaunawa.';

  @override
  String get writeMessage => 'Rubuta saƙo…';

  @override
  String get replyAction => 'Amsa';

  @override
  String get conversationGone => 'An cire wannan tattaunawa.';

  @override
  String get deleteConversation => 'Share tattaunawa';

  @override
  String get deleteConversationConfirm =>
      'A share wannan tattaunawa ga ku biyu?';

  @override
  String youPrefix(String text) {
    return 'Kai: $text';
  }

  @override
  String get newMessages => 'Sabo';

  @override
  String get activityTitle => 'Ayyuka';

  @override
  String get activitySub => 'Waɗanda ke kan layi da abin da suka yi';

  @override
  String get tabOnline => 'Kan layi';

  @override
  String get tabActivityLog => 'Rajistar ayyuka';

  @override
  String get onlineNow => 'Suna kan layi yanzu';

  @override
  String get earlierToday => 'A baya';

  @override
  String get nobodyOnline => 'Babu wanda ke amfani da manhajar yanzu.';

  @override
  String onlineFor(String time) {
    return 'tsawon $time';
  }

  @override
  String seenAgo(String time) {
    return 'an gan shi $time';
  }

  @override
  String minutesShort(int n) {
    return 'minti $n';
  }

  @override
  String hoursShort(int h, int m) {
    return 'awa $h minti $m';
  }

  @override
  String onPage(String page) {
    return 'a $page';
  }

  @override
  String get platformAndroidShort => 'Android';

  @override
  String get platformWebShort => 'Yanar gizo';

  @override
  String get logAll => 'Duka';

  @override
  String get logChanges => 'Canje-canje';

  @override
  String get logPages => 'Shafuka';

  @override
  String get logSessions => 'Shiga';

  @override
  String get logAnyone => 'Kowa';

  @override
  String get logToday => 'Yau';

  @override
  String get log7 => 'Kwana 7';

  @override
  String get log30 => 'Kwana 30';

  @override
  String get logAnyTime => 'Kowane lokaci';

  @override
  String get logSearch => 'Nemi suna, shafi, take…';

  @override
  String get logEmpty => 'Babu komai a nan tukuna.';

  @override
  String get loadMore => 'Nuna ƙari';

  @override
  String get logPrivacyNote =>
      'Masu gudanarwa kaɗai ke ganin wannan. Ba a rubuta abin da ke cikin tattaunawar sirri ba.';

  @override
  String get actOpenedApp => 'ya buɗe manhajar';

  @override
  String get actSignedIn => 'ya shiga';

  @override
  String get actSignedOut => 'ya fita';

  @override
  String actViewed(String page) {
    return 'ya buɗe $page';
  }

  @override
  String actAdded(String thing) {
    return 'ya ƙara $thing';
  }

  @override
  String actChanged(String thing) {
    return 'ya gyara $thing';
  }

  @override
  String actRemoved(String thing) {
    return 'ya cire $thing';
  }

  @override
  String get actLiked => 'ya so wani abu';

  @override
  String get actUnliked => 'ya janye so';

  @override
  String get actRsvp => 'ya amsa gayyata';

  @override
  String get actVoted => 'ya jefa ƙuri\'a';

  @override
  String get actReviewed => 'ya duba shawara';

  @override
  String get actAccount => 'ya gyara asusu';

  @override
  String get actSettings => 'ya canza saitunan manhaja';

  @override
  String get actMentorAsk => 'ya nemi jagora';

  @override
  String get actMentorMessage => 'ya aika saƙon jagoranci';

  @override
  String get actConfirmed => 'ya tabbatar da gudummawa';

  @override
  String get entPerson => 'mutum';

  @override
  String get entRelationship => 'dangantaka';

  @override
  String get entSuggestion => 'shawara';

  @override
  String get entAlbum => 'kundin hotuna';

  @override
  String get entPost => 'rubutu';

  @override
  String get entAnnouncement => 'sanarwa';

  @override
  String get entPhoto => 'hoto';

  @override
  String get entEvent => 'taro';

  @override
  String get entComment => 'sharhi';

  @override
  String get entBloodRequest => 'buƙatar jini';

  @override
  String get entBloodOffer => 'tayin ba da jini';

  @override
  String get entMemory => 'tunawa';

  @override
  String get entCause => 'buƙatar asusu';

  @override
  String get entContribution => 'gudummawa';

  @override
  String get entPayout => 'biya';

  @override
  String get entMentor => 'tayin jagoranci';

  @override
  String get entStudent => 'neman jagora';

  @override
  String get entOpportunity => 'dama';

  @override
  String get entPoll => 'ƙuri\'a';

  @override
  String get entStory => 'labarin dattijo';

  @override
  String get entInvite => 'hanyar gayyata';

  @override
  String get entOther => 'wani abu';

  @override
  String get pageHome => 'Gida';

  @override
  String pagePerson(String name) {
    return 'shafin $name';
  }

  @override
  String get pageAPerson => 'shafin mutum';

  @override
  String get pageAnEvent => 'taro';

  @override
  String get pageAMoment => 'rubutu';

  @override
  String get pageAnAlbum => 'kundin hotuna';

  @override
  String get pageAPhoto => 'hoto';

  @override
  String get pageAConversation => 'tattaunawar jagoranci';

  @override
  String get pageSignIn => 'shiga';

  @override
  String get continueWithGoogle => 'Ci gaba da Google';

  @override
  String get orWord => 'ko';

  @override
  String get resetHowTitle => 'Sabunta kalmar sirri';

  @override
  String get resetByEmail => 'Aika hanyar haɗi zuwa imel ɗina';

  @override
  String get resetByEmailHint => 'Rubuta imel ɗinka a sama tukuna.';

  @override
  String get resetByText => 'Aika lamba zuwa wayata';

  @override
  String get resetByTextHint => 'Lambar wayar da ke kan bayananka';

  @override
  String get sendResetCode => 'Aika lamba';

  @override
  String resetCodeSentTo(String phone) {
    return 'Idan $phone na kan wani asusu, lamba na zuwa. Tana aiki na minti 10.';
  }

  @override
  String get newPasswordLabel => 'Sabuwar kalmar sirri (haruffa 8 ko fiye)';

  @override
  String get setNewPassword => 'Saita sabuwar kalmar sirri';

  @override
  String get resetDone => 'An canza kalmar sirri. Barka da dawowa!';

  @override
  String get resetSmsOff =>
      'Ba a saita saƙon waya ba tukuna. Yi amfani da imel ɗinka.';

  @override
  String get resetTooMany =>
      'Don Allah ka jira kaɗan kafin ka sake neman lamba.';

  @override
  String get resetWrongCode => 'Lambar ba daidai ba ce. Duba saƙon.';

  @override
  String get resetExpired => 'Lambar ta ƙare. Nemi sabuwa.';

  @override
  String get occIslamicNewYear => 'Sabuwar Shekarar Musulunci';

  @override
  String get occAshura => 'Ranar Ashura';

  @override
  String get occMawlid => 'Mauludi';

  @override
  String get occRamadan => 'Farkon Azumin Ramadan';

  @override
  String get occLaylatAlQadr => 'Lailatul Qadri (dare na 27)';

  @override
  String get occEidAlFitr => 'Karamar Sallah';

  @override
  String get occArafah => 'Ranar Arafa';

  @override
  String get occEidAlAdha => 'Babbar Sallah';

  @override
  String get greetEidFitr => 'Barka da Sallah! Allah ya maimaita mana.';

  @override
  String get greetEidAdha => 'Barka da Babbar Sallah! Allah ya karɓi ibadunmu.';

  @override
  String get greetRamadan => 'Barka da azumi! Allah ya karɓi ibadunmu.';

  @override
  String greetNewYear(int year) {
    return 'Barka da sabuwar shekara ta $year!';
  }

  @override
  String get eveEidFitr => 'Ana sa ran Karamar Sallah gobe, idan an ga wata.';

  @override
  String get eveEidAdha => 'Ana sa ran Babbar Sallah gobe.';

  @override
  String get eveRamadan =>
      'Ana sa ran fara azumin Ramadan gobe, idan an ga wata.';

  @override
  String greetingFrom(String family) {
    return 'Daga dukkanmu a iyalin $family';
  }

  @override
  String get shareGreeting => 'Aika gaisuwa';

  @override
  String get islamicOccasions => 'Lokutan Musulunci';

  @override
  String get moonNote =>
      'Ranakun suna bin kalandar Musulunci kuma suna iya canzawa da kwana ɗaya idan an ga wata.';

  @override
  String inDaysCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'nan da kwana $n',
      one: 'gobe',
      zero: 'yau',
    );
    return '$_temp0';
  }

  @override
  String get hijriSettingsTitle => 'Kalandar Musulunci';

  @override
  String get hijriAdjust => 'Daidaita ganin wata';

  @override
  String get hijriAdjustHint =>
      'Idan an sanar da sabon wata kwana ɗaya kafin abin da manhajar ta nuna, ƙara kwana; idan bayan haka, rage kwana.';

  @override
  String hijriTodayIs(String date) {
    return 'Yau a manhajar: $date';
  }

  @override
  String get islamicGreetingsToggle =>
      'Gaisar da iyali a Ramadan, Sallah da sabuwar shekara';

  @override
  String get showHijriDates => 'Nuna ranakun Musulunci';

  @override
  String get showHijriDatesHint =>
      'Kusa da ranaku, misali 21 Rabi\'us Sani 1448';

  @override
  String get hijriNoAdjust => 'Babu gyara';

  @override
  String hijriDaysSigned(String sign, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'kwana $n',
      one: 'kwana 1',
    );
    return '$sign $_temp0';
  }

  @override
  String get duesTitle => 'Gudummawar dole';

  @override
  String get myDues => 'Gudummawata ta dole';

  @override
  String duesEvery(String amount, String per) {
    return '$amount $per';
  }

  @override
  String get perMonth => 'a wata';

  @override
  String get perQuarter => 'a kowane wata uku';

  @override
  String get perYear => 'a shekara';

  @override
  String youOwe(String amount) {
    return 'Ana binka $amount';
  }

  @override
  String owesAmount(String amount) {
    return 'Ana binsa $amount';
  }

  @override
  String unpaidPeriods(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'lokuta $n ba a biya ba',
      one: 'lokaci 1 ba a biya ba',
    );
    return '$_temp0';
  }

  @override
  String paidUpTo(String date) {
    return 'An biya har zuwa $date';
  }

  @override
  String get paidUpNothingYet => 'An biya duka';

  @override
  String get duesExempt => 'An kebe';

  @override
  String waitingConfirmation(String amount) {
    return '$amount na jiran tabbatarwa';
  }

  @override
  String get payDues => 'Biya';

  @override
  String payDuesTitle(String title) {
    return 'Biya: $title';
  }

  @override
  String get myStatement => 'Bayanin asusuna (PDF)';

  @override
  String get fundReports => 'Rahotanni';

  @override
  String get recordForMember => 'Rubuta biya a madadin ɗan uwa';

  @override
  String get newDuesPlan => 'Sabon tsarin gudummawa';

  @override
  String get editDuesPlan => 'Gyara tsari';

  @override
  String get planTitleLabel => 'Suna (misali Gudummawar wata)';

  @override
  String get planPeriod => 'Sau nawa';

  @override
  String get periodMonthly => 'Kowane wata';

  @override
  String get periodQuarterly => 'Kowane wata uku';

  @override
  String get periodYearly => 'Kowace shekara';

  @override
  String get planStarts => 'Farawa';

  @override
  String get planActive => 'Yana aiki';

  @override
  String get planAutoRemind => 'Tunatar da masu bashi a farkon kowane lokaci';

  @override
  String get noDuesPlans =>
      'Babu gudummawar dole tukuna. Ƙirƙiri tsari, misali ₦2,000 a wata.';

  @override
  String get duesFilterAll => 'Duka';

  @override
  String get duesFilterOwing => 'Masu bashi';

  @override
  String get duesFilterPaidUp => 'Sun biya';

  @override
  String get duesFilterExempt => 'An kebe';

  @override
  String duesSummaryLine(int owing, int total, String owed) {
    return '$owing cikin $total na da bashi · $owed ba a biya ba';
  }

  @override
  String get remindOwing => 'Tunatar da masu bashi';

  @override
  String remindedCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'An aika tunatarwa $n',
      one: 'An aika tunatarwa 1',
      zero: 'Babu wanda za a tunatar',
    );
    return '$_temp0';
  }

  @override
  String get duesStartLabel => 'Farkon gudummawa';

  @override
  String get exemptToggle => 'Kebe daga wannan tsari';

  @override
  String recordPaymentFrom(String name) {
    return 'Rubuta biya daga $name';
  }

  @override
  String get paymentRecorded => 'An rubuta biya.';

  @override
  String get chooseMember => 'Wa ya biya?';

  @override
  String get forWhat => 'Domin';

  @override
  String notifDuesReminder(String title, String owed) {
    return '$title: ana binka $owed. Taɓa don biya.';
  }

  @override
  String get reportTitle => 'Rahoton asusu';

  @override
  String get periodThisMonth => 'Wannan wata';

  @override
  String get periodLastMonth => 'Watan jiya';

  @override
  String get periodThisYear => 'Wannan shekara';

  @override
  String get periodLastYear => 'Bara';

  @override
  String get openingLabel => 'Kuɗin farko';

  @override
  String get moneyIn => 'Kuɗin shiga';

  @override
  String get moneyOut => 'Kuɗin fita';

  @override
  String get closingLabel => 'Ragowar kuɗi';

  @override
  String get bySourceTitle => 'Ta buƙata da gudummawa';

  @override
  String get monthByMonth => 'Wata-wata';

  @override
  String get transactionsTitle => 'Duk mu\'amaloli';

  @override
  String get duesStandingTitle => 'Matsayin gudummawa';

  @override
  String paymentsFrom(int p, int c) {
    String _temp0 = intl.Intl.pluralLogic(
      p,
      locale: localeName,
      other: 'biya $p',
      one: 'biya 1',
    );
    String _temp1 = intl.Intl.pluralLogic(
      c,
      locale: localeName,
      other: '\'yan uwa $c',
      one: 'ɗan uwa 1',
    );
    return '$_temp0 daga $_temp1';
  }

  @override
  String reportGenerated(String date) {
    return 'An samar $date';
  }

  @override
  String get reportCommitteeNote =>
      '\'Yan uwa suna ganin jimilla. Sunaye da adadi na kwamiti ne kaɗai.';

  @override
  String get downloadPdf => 'PDF';

  @override
  String statementFor(String name) {
    return 'Bayanin asusu na $name';
  }

  @override
  String get contributionsLabel => 'Gudummawa';

  @override
  String get statusConfirmedLabel => 'An tabbatar';

  @override
  String get inOut => 'Shiga';

  @override
  String get outLabel => 'Fita';

  @override
  String get nothingInPeriod => 'Babu kuɗin shiga ko fita a wannan lokaci.';

  @override
  String get searchByName => 'Nemi da suna';

  @override
  String get paymentMethod => 'Yadda aka biya';

  @override
  String get filterClaims => 'Masu cewa ni ne';

  @override
  String get claimTitle => 'Ya ce shi ne wannan a bishiyar iyali';

  @override
  String get claimConfirm => 'Tabbatar ka haɗa';

  @override
  String get claimDecline => 'Ƙi';

  @override
  String get claimDeclineTitle => 'A ƙi wannan buƙata?';

  @override
  String get claimDeclineReason => 'Dalili gare su (ba dole ba)';

  @override
  String claimAlreadyLinked(String name) {
    return 'Asusun $name an riga an haɗa shi da wannan mutum. Cire shi da farko idan wannan buƙata daidai ce.';
  }

  @override
  String get claimConfirmed => 'An haɗa. Za a sanar da su.';

  @override
  String get claimDeclined => 'An ƙi. Za a sanar da su.';

  @override
  String claimsOnPerson(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Mutane $n sun ce su ne wannan',
      one: 'Wani ya ce shi ne wannan',
    );
    return '$_temp0';
  }

  @override
  String personFacts(String born, String parents) {
    return 'An haife shi $born · $parents';
  }

  @override
  String childOf(String names) {
    return 'ɗan $names';
  }

  @override
  String notifClaimApproved(String person) {
    return 'An haɗa ka da $person a bishiyar iyali.';
  }

  @override
  String notifClaimDeclined(String person) {
    return 'Ba a karɓi buƙatarka ta zama $person ba.';
  }

  @override
  String notifClaimDeclinedWhy(String person, String reason) {
    return 'Ba a karɓi buƙatarka ta zama $person ba: “$reason”';
  }

  @override
  String get showDetails => 'Nuna bayanai';

  @override
  String get hideDetails => 'Ɓoye bayanai';

  @override
  String get viewPhoto => 'Duba hoto';

  @override
  String get changePhoto2 => 'Canza hoto';

  @override
  String get searchTitle => 'Nema';

  @override
  String get searchEverything => 'Nemi mutane, rubutu, taruka, labarai…';

  @override
  String get searchAll => 'Duka';

  @override
  String get kindPeople => 'Mutane';

  @override
  String get kindPost => 'Rubutu';

  @override
  String get kindEvent => 'Taruka';

  @override
  String get kindAlbum => 'Kundin hotuna';

  @override
  String get kindPhoto => 'Hotuna';

  @override
  String get kindStory => 'Labaran dattawa';

  @override
  String get kindCause => 'Asusun walwala';

  @override
  String get kindPoll => 'Ƙuri\'u';

  @override
  String get kindOpportunity => 'Damammaki';

  @override
  String get kindMemory => 'Tunawa';

  @override
  String get kindSkill => 'Ƙwarewa';

  @override
  String get kindWork => 'Aiki';

  @override
  String get recentSearches => 'Bincike na baya';

  @override
  String get clearRecent => 'Share';

  @override
  String searchNothing(String q) {
    return 'Ba a sami komai ba don “$q”.';
  }

  @override
  String get searchTypeMore => 'Rubuta aƙalla haruffa 2.';

  @override
  String get searchTips =>
      'Gwada suna, wuri, kalma daga rubutu, ƙwarewa kamar “nas”, ko taro.';

  @override
  String showAllCount(int n) {
    return 'Nuna duka $n';
  }

  @override
  String get familyMakeup => 'Su waye ke cikin iyali';

  @override
  String get menLabel => 'Maza';

  @override
  String get womenLabel => 'Mata';

  @override
  String get sexNotSet => 'Ba a saka ba';

  @override
  String get totalLabel => 'Jimilla';

  @override
  String get bloodFamily => '\'Yan uwa na jini';

  @override
  String get marriedIn => 'Ta hanyar aure';

  @override
  String get notConnectedYet => 'Ba a haɗa su ba tukuna';

  @override
  String livingMenWomen(int men, int women) {
    return 'Masu rai: maza $men · mata $women';
  }

  @override
  String get familyMakeupHelp =>
      '\'Yan uwa na jini: kakannin farko da duk wanda aka haifa ko aka ɗauka cikin zuriyar. Ta hanyar aure: mazaje da matan da suka shigo daga waje.';

  @override
  String get viewTree => 'Bishiya duka';

  @override
  String get viewFamilyLine => 'Zuriya';

  @override
  String childrenWithParent(String name) {
    return 'Da $name';
  }

  @override
  String childCountShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '\'Ya\'ya $count',
      one: 'Ɗa 1',
      zero: 'Ba a saka \'ya\'ya ba',
    );
    return '$_temp0';
  }

  @override
  String grandchildrenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Jikoki $count',
      one: 'Jika 1',
    );
    return '$_temp0';
  }

  @override
  String descendantsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zuriya $count',
      one: 'Zuriya 1',
    );
    return '$_temp0';
  }

  @override
  String get openProfile => 'Buɗe bayanai';

  @override
  String upTo(String name) {
    return 'Koma wurin $name';
  }

  @override
  String get familyLineHint => 'Taɓa ɗa don ganin iyalinsa.';

  @override
  String get noChildrenYet => 'Ba a saka \'ya\'ya ba tukuna.';

  @override
  String childrenHeading(int count) {
    return '\'Ya\'ya ($count)';
  }

  @override
  String parentsNames(String names) {
    return 'Iyaye: $names';
  }
}
