// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Bua Family';

  @override
  String get navTree => 'Tree';

  @override
  String get navMembers => 'Members';

  @override
  String get navAdmin => 'Admin';

  @override
  String get navMore => 'More';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Create account';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get displayName => 'Your name';

  @override
  String get haveAccount => 'Already have an account? Sign in';

  @override
  String get noAccount => 'New here? Create an account';

  @override
  String get signOut => 'Sign out';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get resetPasswordSent => 'Password reset email sent.';

  @override
  String get checkEmailToConfirm =>
      'Check your email to confirm your account, then sign in.';

  @override
  String get required => 'Required';

  @override
  String get invalidEmail => 'Enter a valid email';

  @override
  String get passwordTooShort => 'At least 8 characters';

  @override
  String get welcomeTagline => 'Our tree, our moments, our family.';

  @override
  String get pendingTitle => 'Waiting for approval';

  @override
  String get pendingBody =>
      'A family admin needs to approve your account. Tell them who you are so they can link you to your place in the tree.';

  @override
  String get claimNoteLabel => 'Who are you in the family?';

  @override
  String get claimNoteHint => 'e.g. Aisha, daughter of Musa Bua of Kano';

  @override
  String get suspendedTitle => 'Account suspended';

  @override
  String get suspendedBody =>
      'Your account has been suspended. Please contact a family admin.';

  @override
  String get checkAgain => 'Check again';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get refresh => 'Refresh';

  @override
  String get retry => 'Retry';

  @override
  String get close => 'Close';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String errorGeneric(String error) {
    return 'Something went wrong: $error';
  }

  @override
  String get notConfigured =>
      'The app is not connected to a server yet. Build it with SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY.';

  @override
  String get treeEmpty => 'No one is in the family tree yet.';

  @override
  String get addFirstPerson => 'Add the first person';

  @override
  String get chooseRoot => 'Start tree from…';

  @override
  String get fitToScreen => 'Fit to screen';

  @override
  String get expandAll => 'Expand all';

  @override
  String get collapseDeep => 'Collapse lower generations';

  @override
  String hiddenCount(int count) {
    return '+$count';
  }

  @override
  String get shownElsewhere => 'Shown elsewhere in the tree';

  @override
  String get searchHint => 'Search by name, place or branch';

  @override
  String peopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$_temp0';
  }

  @override
  String get noResults => 'No one found';

  @override
  String get filterAll => 'All';

  @override
  String get filterLiving => 'Living';

  @override
  String get filterDeceased => 'Deceased';

  @override
  String lateLabel(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'female': 'Late',
      'other': 'Late',
    });
    return '$_temp0';
  }

  @override
  String get born => 'Born';

  @override
  String get died => 'Died';

  @override
  String get buried => 'Buried at';

  @override
  String get branch => 'Branch';

  @override
  String get thisIsYou => 'This is you';

  @override
  String get relationshipToYou => 'Relationship to you';

  @override
  String get sectionFamily => 'Family';

  @override
  String get parents => 'Parents';

  @override
  String get spouses => 'Spouses';

  @override
  String get children => 'Children';

  @override
  String get siblings => 'Siblings';

  @override
  String get sectionAbout => 'About';

  @override
  String get education => 'Education';

  @override
  String get work => 'Work';

  @override
  String get skills => 'Skills';

  @override
  String get contact => 'Contact';

  @override
  String get health => 'Health';

  @override
  String get nothingYet => 'Nothing added yet';

  @override
  String get addRelative => 'Add relative';

  @override
  String get linkExisting => 'Link someone already in the tree';

  @override
  String get editPerson => 'Edit details';

  @override
  String get suggestEdit => 'Suggest an edit';

  @override
  String get deletePerson => 'Remove from tree';

  @override
  String confirmDeletePerson(String name) {
    return 'Remove $name and all their links from the tree? This cannot be undone.';
  }

  @override
  String get changePhoto => 'Change photo';

  @override
  String get viewInTree => 'View in tree';

  @override
  String get thisIsMe => 'This is me';

  @override
  String get thisIsMeSent =>
      'Sent. An admin will confirm and link your account.';

  @override
  String get addFather => 'Father';

  @override
  String get addMother => 'Mother';

  @override
  String get addSpouse => 'Spouse';

  @override
  String get addSon => 'Son';

  @override
  String get addDaughter => 'Daughter';

  @override
  String get title => 'Title (e.g. Alhaji, Hajiya, Dr)';

  @override
  String get firstName => 'First name';

  @override
  String get middleName => 'Middle name';

  @override
  String get lastName => 'Surname / family name';

  @override
  String get nickname => 'Nickname (lakabi)';

  @override
  String get sex => 'Sex';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get unknown => 'Unknown';

  @override
  String get birthDate => 'Date of birth';

  @override
  String get dateApprox => 'Approximate (year only)';

  @override
  String get birthPlace => 'Place of birth';

  @override
  String get isLiving => 'Living';

  @override
  String get deathDate => 'Date of death';

  @override
  String get deathPlace => 'Place of death';

  @override
  String get burialPlace => 'Place of burial';

  @override
  String get biography => 'Life story / biography';

  @override
  String get otherParent => 'Other parent';

  @override
  String get otherParentUnknown => 'Not recorded';

  @override
  String get relationKind => 'Type';

  @override
  String get kindBiological => 'Biological';

  @override
  String get kindAdopted => 'Adopted';

  @override
  String get kindFoster => 'Foster';

  @override
  String get kindStep => 'Step';

  @override
  String get unionStatus => 'Marriage status';

  @override
  String get statusMarried => 'Married';

  @override
  String get statusDivorced => 'Divorced';

  @override
  String get statusWidowed => 'Widowed';

  @override
  String get statusSeparated => 'Separated';

  @override
  String get pickDate => 'Pick date';

  @override
  String get clear => 'Clear';

  @override
  String newPersonTitle(String relation) {
    return 'Add $relation';
  }

  @override
  String get newPerson => 'Add person';

  @override
  String ofPerson(String name) {
    return 'of $name';
  }

  @override
  String get selectPerson => 'Select a person';

  @override
  String relationIs(String name) {
    return '$name is the…';
  }

  @override
  String get relationParentOf => 'Parent of this person';

  @override
  String get relationChildOf => 'Child of this person';

  @override
  String get relationSpouseOf => 'Spouse of this person';

  @override
  String get sentForApproval => 'Sent to the admins for approval';

  @override
  String get coreChangesSent =>
      'Name, date and life-status changes were sent to the admins for approval.';

  @override
  String get contributionsOff =>
      'Adding relatives is currently turned off by the admins.';

  @override
  String get requestsTitle => 'Requests';

  @override
  String get pendingRequests => 'Pending requests';

  @override
  String get myRequests => 'My requests';

  @override
  String get noRequests => 'No requests';

  @override
  String get approve => 'Approve';

  @override
  String get reject => 'Reject';

  @override
  String get rejectReason => 'Reason (optional)';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusApproved => 'Approved';

  @override
  String get statusRejected => 'Rejected';

  @override
  String requestedBy(String name) {
    return 'Requested by $name';
  }

  @override
  String reqCreatePerson(String name) {
    return 'Add $name';
  }

  @override
  String reqRelation(String relation, String other) {
    return 'as $relation of $other';
  }

  @override
  String reqUpdatePerson(String name) {
    return 'Update details of $name';
  }

  @override
  String reqAddParentChild(String parent, String child) {
    return '$parent is a parent of $child';
  }

  @override
  String reqAddUnion(String a, String b) {
    return '$a and $b are married';
  }

  @override
  String get withdraw => 'Withdraw';

  @override
  String get accountsTitle => 'Accounts';

  @override
  String get pendingAccounts => 'Waiting for approval';

  @override
  String get activeAccounts => 'Active';

  @override
  String get suspendedAccounts => 'Suspended';

  @override
  String get activate => 'Approve';

  @override
  String get suspend => 'Suspend';

  @override
  String get makeAdmin => 'Make admin';

  @override
  String get makeMember => 'Remove admin';

  @override
  String get linkToPerson => 'Link to person';

  @override
  String linkedTo(String name) {
    return 'Linked to $name';
  }

  @override
  String get notLinked => 'Not linked to anyone in the tree';

  @override
  String wantsToBe(String name) {
    return 'Says they are: $name';
  }

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleMember => 'Member';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get familyName => 'Family name';

  @override
  String get memberContributions => 'Members can add relatives';

  @override
  String get memberContributionsHelp =>
      'When on, members can propose new people and relationships. Admins approve each one before it appears in the tree.';

  @override
  String get treeRoot => 'Tree starts from';

  @override
  String get treeRootAuto => 'Automatic (eldest ancestor)';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get hausa => 'Hausa';

  @override
  String get myProfile => 'My profile';

  @override
  String get institution => 'School / institution';

  @override
  String get qualification => 'Qualification';

  @override
  String get field => 'Field of study';

  @override
  String get startYear => 'Start year';

  @override
  String get endYear => 'End year';

  @override
  String get jobTitle => 'Occupation / job title';

  @override
  String get organization => 'Organisation / business';

  @override
  String get industry => 'Industry';

  @override
  String get location => 'Location';

  @override
  String get currentJob => 'Current';

  @override
  String get skill => 'Skill';

  @override
  String get notes => 'Notes';

  @override
  String get phone => 'Phone';

  @override
  String get address => 'Address';

  @override
  String get city => 'City / town';

  @override
  String get country => 'Country';

  @override
  String get visibleTo => 'Who can see this';

  @override
  String get visibleFamily => 'The whole family';

  @override
  String get visiblePrivate => 'Only this person and admins';

  @override
  String get bloodGroup => 'Blood group';

  @override
  String get genotype => 'Genotype';

  @override
  String get conditions => 'Known hereditary or chronic conditions';

  @override
  String get healthPrivacyNote =>
      'Health details are private unless you choose to share them with the family.';

  @override
  String get relSelf => 'You';

  @override
  String relSpouse(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'male': 'Husband',
      'female': 'Wife',
      'other': 'Spouse',
    });
    return '$_temp0';
  }

  @override
  String relParent(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'male': 'Father',
      'female': 'Mother',
      'other': 'Parent',
    });
    return '$_temp0';
  }

  @override
  String relChild(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'male': 'Son',
      'female': 'Daughter',
      'other': 'Child',
    });
    return '$_temp0';
  }

  @override
  String relSibling(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'male': 'Brother',
      'female': 'Sister',
      'other': 'Sibling',
    });
    return '$_temp0';
  }

  @override
  String relHalfSibling(String sex, String via) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'male': 'Half-brother',
      'female': 'Half-sister',
      'other': 'Half-sibling',
    });
    String _temp1 = intl.Intl.selectLogic(via, {
      'male': 'same father',
      'female': 'same mother',
      'other': 'one shared parent',
    });
    return '$_temp0 ($_temp1)';
  }

  @override
  String relGrandparent(int greats, String sex) {
    String _temp0 = intl.Intl.pluralLogic(
      greats,
      locale: localeName,
      other: '$greats× great-grand',
      two: 'Great-great-grand',
      one: 'Great-grand',
      zero: 'Grand',
    );
    String _temp1 = intl.Intl.selectLogic(sex, {
      'male': 'father',
      'female': 'mother',
      'other': 'parent',
    });
    return '$_temp0$_temp1';
  }

  @override
  String relGrandchild(int greats, String sex) {
    String _temp0 = intl.Intl.pluralLogic(
      greats,
      locale: localeName,
      other: '$greats× great-grand',
      two: 'Great-great-grand',
      one: 'Great-grand',
      zero: 'Grand',
    );
    String _temp1 = intl.Intl.selectLogic(sex, {
      'male': 'son',
      'female': 'daughter',
      'other': 'child',
    });
    return '$_temp0$_temp1';
  }

  @override
  String relUncleAunt(int greats, String sex, String side) {
    String _temp0 = intl.Intl.pluralLogic(
      greats,
      locale: localeName,
      other: '$greats× great-',
      one: 'Great-',
      zero: '',
    );
    String _temp1 = intl.Intl.selectLogic(sex, {
      'male': 'uncle',
      'female': 'aunt',
      'other': 'uncle/aunt',
    });
    return '$_temp0$_temp1';
  }

  @override
  String relNephewNiece(int greats, String sex) {
    String _temp0 = intl.Intl.pluralLogic(
      greats,
      locale: localeName,
      other: '$greats× great-grand-',
      one: 'Grand-',
      zero: '',
    );
    String _temp1 = intl.Intl.selectLogic(sex, {
      'male': 'nephew',
      'female': 'niece',
      'other': 'nephew/niece',
    });
    return '$_temp0$_temp1';
  }

  @override
  String relCousin(int degree, int removed, String sex) {
    String _temp0 = intl.Intl.pluralLogic(
      degree,
      locale: localeName,
      other: 'Distant',
      two: 'Second',
      one: 'First',
    );
    String _temp1 = intl.Intl.pluralLogic(
      removed,
      locale: localeName,
      other: ' $removed times removed',
      two: ' twice removed',
      one: ' once removed',
      zero: '',
    );
    return '$_temp0 cousin$_temp1';
  }

  @override
  String relStepParent(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'male': 'Stepfather',
      'female': 'Stepmother',
      'other': 'Step-parent',
    });
    return '$_temp0';
  }

  @override
  String relStepChild(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'male': 'Stepson',
      'female': 'Stepdaughter',
      'other': 'Stepchild',
    });
    return '$_temp0';
  }

  @override
  String relCoSpouse(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'female': 'Co-wife',
      'other': 'Co-spouse',
    });
    return '$_temp0';
  }

  @override
  String relParentInLaw(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'male': 'Father-in-law',
      'female': 'Mother-in-law',
      'other': 'Parent-in-law',
    });
    return '$_temp0';
  }

  @override
  String relChildInLaw(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'male': 'Son-in-law',
      'female': 'Daughter-in-law',
      'other': 'Child-in-law',
    });
    return '$_temp0';
  }

  @override
  String relSiblingInLaw(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'male': 'Brother-in-law',
      'female': 'Sister-in-law',
      'other': 'Sibling-in-law',
    });
    return '$_temp0';
  }

  @override
  String get relByMarriage => 'Related by marriage';

  @override
  String get relNone => 'No recorded relation';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get createYourAccount => 'Create your account';

  @override
  String get privateSpaceNote =>
      'A private space for the Bua family. New accounts are approved by a family admin.';

  @override
  String pendingGreeting(String name) {
    return 'Salamu alaikum, $name. A family admin will approve your account and link you to your place in the tree.';
  }

  @override
  String get claimHelp =>
      'Mention your parents or grandparents so the admin can find you quickly.';

  @override
  String get stepCreated => 'Account created';

  @override
  String get stepReview => 'An admin reviews and links you';

  @override
  String get stepExplore => 'Explore the family tree';

  @override
  String get startingFrom => 'Starting from';

  @override
  String get change => 'Change';

  @override
  String get findRelative => 'Find a relative';

  @override
  String get zoomIn => 'Zoom in';

  @override
  String get zoomOut => 'Zoom out';

  @override
  String get centreOnMe => 'Centre on me';

  @override
  String yourRelation(String relation) {
    return 'Your $relation';
  }

  @override
  String get sideFather => 'father’s side';

  @override
  String get sideMother => 'mother’s side';

  @override
  String get educationWork => 'Education & work';

  @override
  String get addEducation => 'Add education';

  @override
  String get addWork => 'Add work';

  @override
  String get addSkill => 'Add skill';

  @override
  String get sharedWithFamily => 'Shared with family';

  @override
  String get privateLabel => 'Private';

  @override
  String get addingTo => 'Adding to';

  @override
  String newPersonIs(String name) {
    return 'New person is $name’s…';
  }

  @override
  String get approvalBanner =>
      'An admin will review this before it appears in the tree. You’ll see it under More › My requests.';

  @override
  String get sendForApproval => 'Send for approval';

  @override
  String get approveAndLink => 'Approve & link';

  @override
  String get linkSomeoneElse => 'Link someone else';

  @override
  String get adminAlwaysOwn =>
      'Members can always edit their own photo, work and skills';

  @override
  String get adminAlwaysDirect => 'Admins always add and edit directly';

  @override
  String get privacyTitle => 'Privacy.';

  @override
  String get privacyNote =>
      'Only approved family members can open the app. Health details stay private unless the person shares them; admins can always see them.';

  @override
  String get adminRequestsAccounts => 'Admin: requests & accounts';

  @override
  String get viewMyProfile => 'View my profile';

  @override
  String get account => 'Account';

  @override
  String pendingCount(int count) {
    return '$count pending';
  }

  @override
  String get myRequestsHelp =>
      'Changes you suggest appear in the tree once a family admin approves them.';

  @override
  String get seeInTree => 'See in the tree';

  @override
  String get married => 'Married';

  @override
  String get navHome => 'Home';

  @override
  String get navEvents => 'Events';

  @override
  String greeting(String name) {
    return 'Salamu alaikum, $name';
  }

  @override
  String get birthdayToday => 'Birthday today';

  @override
  String turnsAge(String name, int age) {
    return '$name turns $age';
  }

  @override
  String get sendGreeting => 'Send a greeting';

  @override
  String get remembrance => 'Remembrance';

  @override
  String yearsSincePassed(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years since $name passed',
      one: '1 year since $name passed',
    );
    return '$_temp0';
  }

  @override
  String get addPrayer => 'Add a prayer';

  @override
  String get announcement => 'Announcement';

  @override
  String get pinned => 'Pinned';

  @override
  String fromAuthor(String name, String time) {
    return 'From $name · $time';
  }

  @override
  String get shareMomentPrompt => 'Share a moment with the family…';

  @override
  String get maShaAllah => 'Ma sha Allah';

  @override
  String commentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comments',
      one: '1 comment',
      zero: 'Comment',
    );
    return '$_temp0';
  }

  @override
  String addedPhotosTo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: 'a photo',
    );
    return 'Added $_temp0 to';
  }

  @override
  String get feedEmpty => 'No moments yet. Be the first to share one.';

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutes(int n) {
    return '${n}m';
  }

  @override
  String timeHours(int n) {
    return '${n}h';
  }

  @override
  String get timeYesterday => 'Yesterday';

  @override
  String timeDaysAgo(int n) {
    return '$n days ago';
  }

  @override
  String get postOptions => 'Post options';

  @override
  String get deletePost => 'Delete post';

  @override
  String get confirmDeletePost => 'Delete this post for everyone?';

  @override
  String get pinToHome => 'Pin to Home';

  @override
  String get unpin => 'Unpin';

  @override
  String get adminsOnly => 'Admins only';

  @override
  String get shareAMoment => 'Share a moment';

  @override
  String get post => 'Post';

  @override
  String onlyFamilyCanSee(String family) {
    return 'Only the $family family can see this';
  }

  @override
  String get whatsHappening => 'What\'s happening?';

  @override
  String get addPhotos => 'Add photos';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get whosInIt => 'Who\'s in it?';

  @override
  String get tagFamily => 'Tag family';

  @override
  String get untag => 'Remove tag';

  @override
  String get alsoAddToAlbum => 'Also add to album';

  @override
  String get dontAddToAlbum => 'Don\'t add to an album';

  @override
  String get dataSaverNote => 'Photos are resized before upload to save data.';

  @override
  String get postEmptyError => 'Write something or add a photo.';

  @override
  String get albums => 'Albums';

  @override
  String get newAlbum => 'New album';

  @override
  String get albumName => 'Album name';

  @override
  String get create => 'Create';

  @override
  String get photosOfYou => 'Photos of you';

  @override
  String photosTaggedIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos you\'re tagged in',
      one: '1 photo you\'re tagged in',
      zero: 'Photos you\'re tagged in appear here',
    );
    return '$_temp0';
  }

  @override
  String photoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
      zero: 'No photos yet',
    );
    return '$_temp0';
  }

  @override
  String get albumsEmpty =>
      'No albums yet. Start one for a wedding, Sallah or old family photos.';

  @override
  String get everyone => 'Everyone';

  @override
  String addedByRelatives(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count relatives',
      one: '1 relative',
    );
    return 'added by $_temp0';
  }

  @override
  String get noPhotos => 'No photos here yet.';

  @override
  String photoXofY(int x, int y) {
    return '$x of $y';
  }

  @override
  String get inThisPhoto => 'In this photo';

  @override
  String get tagSomeone => 'Tag someone';

  @override
  String addedBy(String name) {
    return 'Added by $name';
  }

  @override
  String memoriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count memories',
      one: '1 memory',
      zero: 'Share a memory',
    );
    return '$_temp0';
  }

  @override
  String get editDetails => 'Edit details';

  @override
  String get caption => 'Caption';

  @override
  String get yearTaken => 'Year taken';

  @override
  String get deletePhoto => 'Delete photo';

  @override
  String get confirmDeletePhoto => 'Delete this photo?';

  @override
  String get comments => 'Comments';

  @override
  String get writeComment => 'Write a comment…';

  @override
  String get noCommentsYet => 'No comments yet.';

  @override
  String get send => 'Send';

  @override
  String get newLabel => 'New';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get announcements => 'Announcements';

  @override
  String get past => 'Past';

  @override
  String get latestAnnouncements => 'Latest announcements';

  @override
  String get noUpcomingEvents => 'No upcoming events.';

  @override
  String get noPastEvents => 'No past events.';

  @override
  String get noAnnouncements => 'No announcements yet.';

  @override
  String get youreGoing => 'You\'re going';

  @override
  String get youSaidMaybe => 'You said maybe';

  @override
  String get youCantGo => 'You can\'t go';

  @override
  String get replyNeeded => 'Reply needed';

  @override
  String goingCount(int count) {
    return '$count going';
  }

  @override
  String maybeCount(int count) {
    return '$count maybe';
  }

  @override
  String eventCategory(String category) {
    String _temp0 = intl.Intl.selectLogic(category, {
      'naming': 'Naming ceremony',
      'wedding': 'Wedding',
      'meeting': 'Family meeting',
      'condolence': 'Condolence',
      'graduation': 'Graduation',
      'other': 'Event',
    });
    return '$_temp0';
  }

  @override
  String hostedBy(String name) {
    return 'Hosted by $name';
  }

  @override
  String get addToCalendar => 'Add to calendar';

  @override
  String get directions => 'Directions';

  @override
  String get areYouComing => 'Are you coming?';

  @override
  String get rsvpGoing => 'Going';

  @override
  String get rsvpMaybe => 'Maybe';

  @override
  String get rsvpNo => 'Can\'t go';

  @override
  String get bringingOthers => 'Bringing others with you';

  @override
  String get oneFewer => 'One fewer';

  @override
  String get oneMore => 'One more';

  @override
  String get seeAll => 'See all';

  @override
  String get wishes => 'Wishes';

  @override
  String get writeWish => 'Write a wish…';

  @override
  String get deleteEvent => 'Delete event';

  @override
  String get confirmDeleteEvent => 'Delete this event for everyone?';

  @override
  String get newPost => 'New post';

  @override
  String get event => 'Event';

  @override
  String get eventType => 'Type';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get place => 'Place';

  @override
  String get addressOrArea => 'Address or area';

  @override
  String get details => 'Details';

  @override
  String get askReply => 'Ask people to reply';

  @override
  String get askReplySub => 'Going · Maybe · Can\'t go';

  @override
  String get postEvent => 'Post event';

  @override
  String get postAnnouncement => 'Post announcement';

  @override
  String get announcementHint => 'Write the announcement…';

  @override
  String get titleRequired => 'Add a title.';

  @override
  String get family => 'Family';

  @override
  String get photos => 'Photos';

  @override
  String get notifications => 'Notifications';

  @override
  String get markAllRead => 'Mark all as read';

  @override
  String get noNotifications => 'You\'re all caught up.';

  @override
  String get today => 'Today';

  @override
  String get earlier => 'Earlier';

  @override
  String notifEvent(String title) {
    return 'New event: $title';
  }

  @override
  String notifBirthday(String name, int age) {
    return '$name\'s birthday today ($age)';
  }

  @override
  String notifEventReminder(String title) {
    return 'Tomorrow: $title';
  }

  @override
  String get notifTaggedPost => 'You were tagged in a moment';

  @override
  String get notifTaggedPhoto => 'You were tagged in a photo';

  @override
  String notifComment(String body) {
    return 'New comment: “$body”';
  }

  @override
  String get notificationsSms => 'Notifications & SMS';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get phoneHint => '0803 123 4567';

  @override
  String get phoneInvalid => 'Enter a valid phone number.';

  @override
  String get smsOptIn => 'Get SMS on this phone';

  @override
  String get smsOptInSub =>
      'Important family news by text message, even without data.';

  @override
  String get smsBirthdays => 'Birthday reminders';

  @override
  String get smsBirthdaysSub =>
      'A text in the morning when it\'s a relative\'s birthday.';

  @override
  String get smsEvents => 'Events and announcements';

  @override
  String get smsEventsSub =>
      'Events and announcements sent by admins, and a reminder the day before events you\'re going to.';

  @override
  String get inAppNote =>
      'You always see notifications in the app, under the bell on Home.';

  @override
  String get smsOffNote =>
      'SMS is not switched on for the family yet. An admin can turn it on in Admin › Settings.';

  @override
  String get smsTitle => 'SMS (Termii)';

  @override
  String get smsEnable => 'Send SMS to the family';

  @override
  String get smsEnableSub =>
      'Uses your Termii balance. Members choose what they receive.';

  @override
  String get senderId => 'Sender ID';

  @override
  String get senderIdHint => 'Registered with Termii, 3–11 letters or digits.';

  @override
  String get smsRoute => 'Route';

  @override
  String get routeGeneric => 'Generic';

  @override
  String get routeDnd =>
      'DND (also reaches DND numbers; Termii must activate it)';

  @override
  String get apiKey => 'Termii API key';

  @override
  String get apiKeySaved => 'Saved';

  @override
  String get apiKeyMissing => 'Not set';

  @override
  String get apiKeyNote =>
      'Find it in your Termii dashboard. It is stored encrypted and never shown again.';

  @override
  String get baseUrl => 'API base URL (optional)';

  @override
  String get baseUrlHint =>
      'Shown in your Termii dashboard. Leave empty for https://api.ng.termii.com';

  @override
  String get sendTestSms => 'Send a test SMS to me';

  @override
  String get testSmsSent => 'Test SMS sent. It should arrive within a minute.';

  @override
  String smsStats(int subscribers, int sent, int failed) {
    return '$subscribers subscribed · $sent sent this week · $failed failed';
  }

  @override
  String smsQueued(int count) {
    return '$count waiting to send';
  }

  @override
  String lastError(String error) {
    return 'Last error: $error';
  }

  @override
  String get smsSetupSteps =>
      '1. Get an API key and a sender ID from Termii. 2. Save them here. 3. Switch SMS on and send yourself a test.';

  @override
  String get notifyFamily => 'Notify the whole family';

  @override
  String get notifyFamilySub => 'In the app';

  @override
  String get alsoSms => 'Also send SMS';

  @override
  String get alsoSmsSub => 'Admins only · uses SMS credit';

  @override
  String get whoCanHelp => 'Who can help?';

  @override
  String get whoCanHelpSub => 'Skills and experience across the family';

  @override
  String get searchSkills => 'Search skills, jobs or studies';

  @override
  String helpCategory(String category) {
    String _temp0 = intl.Intl.selectLogic(category, {
      'health': 'Health',
      'law': 'Law',
      'trades': 'Trades',
      'teaching': 'Teaching',
      'business': 'Business',
      'engineering': 'Engineering',
      'tech': 'Tech',
      'islamic': 'Islamic studies',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String relativesIn(int count, String category) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count relatives in $category',
      one: '1 relative in $category',
      zero: 'No one in $category yet',
    );
    return '$_temp0';
  }

  @override
  String relativesMatching(int count, String query) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count relatives match “$query”',
      one: '1 relative matches “$query”',
      zero: 'No one matches “$query”',
    );
    return '$_temp0';
  }

  @override
  String relativesWithSkills(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count relatives with skills or work listed',
      one: '1 relative with skills or work listed',
      zero: 'No skills or work listed yet',
    );
    return '$_temp0';
  }

  @override
  String get helpEmptyNote =>
      'Add your work, studies and skills on your profile so relatives can find you.';

  @override
  String get contactNote =>
      'Call buttons appear only for people who share their contact with the family.';

  @override
  String callPerson(String name) {
    return 'Call $name';
  }

  @override
  String get profile => 'Profile';

  @override
  String get bloodDonors => 'Blood donors';

  @override
  String get requestBlood => 'Request blood';

  @override
  String get urgent => 'Urgent';

  @override
  String pintsFor(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pints for $name',
      one: '1 pint for $name',
    );
    return '$_temp0';
  }

  @override
  String askedBy(String name) {
    return 'asked by $name';
  }

  @override
  String get iCanDonate => 'I can donate';

  @override
  String get youOffered => 'You offered';

  @override
  String offersSoFar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count relatives have offered so far.',
      one: '1 relative has offered so far.',
      zero: 'No one has offered yet.',
    );
    return '$_temp0';
  }

  @override
  String get closeRequest => 'Close request';

  @override
  String get closed => 'Closed';

  @override
  String notCompatible(String group) {
    return 'Your blood group ($group) can\'t be given for this request.';
  }

  @override
  String get matchesFor => 'Matches for';

  @override
  String canReceiveFrom(String group, String groups) {
    return '$group (can receive $groups)';
  }

  @override
  String get noDonors =>
      'No donors with a matching blood group have joined yet.';

  @override
  String get onDonorList => 'You\'re on the donor list';

  @override
  String get changeInHealth => 'Change in your health details';

  @override
  String get joinDonorList => 'Join the donor list';

  @override
  String get joinDonorListSub =>
      'Add your blood group in your health details and tick “Blood donor”.';

  @override
  String get donorPrivacy =>
      'Only relatives who opted in appear here, showing just their blood group and town. Genotype and other health details are never shown.';

  @override
  String get bloodDonorOptIn => 'List me as a blood donor';

  @override
  String get bloodDonorOptInSub =>
      'Relatives see only your blood group and town.';

  @override
  String get bloodDonorLabel => 'Blood donor';

  @override
  String get bloodGroupNeeded => 'Blood group needed';

  @override
  String get units => 'Pints';

  @override
  String get patient => 'Who is it for?';

  @override
  String get patientHint => 'Pick from the family, or type a name';

  @override
  String get pickFromFamily => 'Pick from the family';

  @override
  String get hospital => 'Hospital';

  @override
  String get contactPhone => 'Phone to call';

  @override
  String get noteOptional => 'Note (optional)';

  @override
  String get bloodRequestSent =>
      'Request posted. Matching donors have been told.';

  @override
  String notifBloodRequest(String group, String patient, String hospital) {
    return '$group blood needed for $patient at $hospital';
  }

  @override
  String notifBloodOffer(String group) {
    return 'A relative can donate blood ($group)';
  }

  @override
  String get memorialPage => 'Memorial page';

  @override
  String get inLovingMemory => 'In loving memory';

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
      'male': 'His life',
      'female': 'Her life',
      'other': 'Their life',
    });
    return '$_temp0';
  }

  @override
  String get noLifeStory =>
      'No life story yet. Family can add it on the profile.';

  @override
  String get seeFullProfile => 'See full profile and family';

  @override
  String allPhotos(int count) {
    return 'All $count';
  }

  @override
  String prayersMemories(int count) {
    return 'Prayers & memories · $count';
  }

  @override
  String get addPrayerMemory => 'Add a prayer or memory…';

  @override
  String get noMemoriesYet => 'Be the first to share a prayer or memory.';

  @override
  String remindMeEvery(String date) {
    return 'Remind me every $date';
  }

  @override
  String get remindMeEverySub => 'A gentle remembrance notification';

  @override
  String notifRemembrance(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years since $name passed',
      one: '1 year since $name passed',
    );
    return '$_temp0';
  }

  @override
  String notifMemory(String name, String body) {
    return 'New memory of $name: “$body”';
  }

  @override
  String get howRelated => 'How are we related?';

  @override
  String get you => 'You';

  @override
  String get swap => 'Swap';

  @override
  String get pickSomeone => 'Pick someone';

  @override
  String relatedIsYour(String name) {
    return '$name is your';
  }

  @override
  String relatedIsOf(String name, String other) {
    return '$name is $other\'s';
  }

  @override
  String pathChildOf(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'male': 'son of',
      'female': 'daughter of',
      'other': 'child of',
    });
    return '$_temp0';
  }

  @override
  String pathParentOf(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'male': 'father of',
      'female': 'mother of',
      'other': 'parent of',
    });
    return '$_temp0';
  }

  @override
  String pathSpouseOf(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'male': 'husband of',
      'female': 'wife of',
      'other': 'spouse of',
    });
    return '$_temp0';
  }

  @override
  String pathShared(String relation) {
    return 'Shared $relation';
  }

  @override
  String youSuffix(String name) {
    return '$name (you)';
  }

  @override
  String get showBothInTree => 'Show in the tree';

  @override
  String get notConnected => 'No connection is recorded in the tree yet.';

  @override
  String get sameDistantRelative => 'Relative';

  @override
  String get tapToLoad => 'Tap to load photo';

  @override
  String get remindersTitle => 'Birthdays & remembrance';

  @override
  String todayDate(String date) {
    return 'Today · $date';
  }

  @override
  String get thisWeek => 'This week';

  @override
  String get comingUp => 'Coming up';

  @override
  String yearsMarried(String names, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years married',
      one: '1 year married',
    );
    return '$names · $_temp0';
  }

  @override
  String get kindBirthday => 'Birthday';

  @override
  String get kindWedding => 'Wedding anniversary';

  @override
  String get greet => 'Greet';

  @override
  String get pray => 'Pray';

  @override
  String get remindersNote =>
      'Remembrance dates come from recorded dates of death. Birthdays show only for living relatives.';

  @override
  String get nothingComingUp => 'Nothing in the next month.';

  @override
  String get editMyDetails => 'Edit my details';

  @override
  String get nameDatesNote => 'Name & dates:';

  @override
  String get askAnAdmin => 'ask an admin';

  @override
  String get aboutMe => 'About me';

  @override
  String get myStory => 'My story';

  @override
  String get whoSeesContact => 'Who can see my contact?';

  @override
  String get whoSeesHealth => 'Who can see my health details?';

  @override
  String get wholeFamily => 'Whole family';

  @override
  String get onlyMeAdmins => 'Only me & admins';

  @override
  String get notLinkedEdit =>
      'Your account isn\'t linked to your place in the tree yet. An admin can link it.';

  @override
  String get settingsScreen => 'Settings';

  @override
  String get languageHarshe => 'Language · Harshe';

  @override
  String get dataSaver => 'Data saver';

  @override
  String get tapToLoadPhotos => 'Load photos only when I tap them';

  @override
  String get tapToLoadPhotosSub => 'Saves mobile data on this phone';

  @override
  String get shrinkUploads => 'Shrink photos before upload';

  @override
  String get shrinkUploadsSub => 'Uses up to 80% less data';

  @override
  String get notifyMeAbout => 'Notify me about';

  @override
  String get notifEventsAnnouncements => 'Announcements & events';

  @override
  String get notifBirthdaysRemembrance => 'Birthdays & remembrance';

  @override
  String get notifTagged => 'When I\'m tagged in photos';

  @override
  String get notifCommentsMine => 'Comments on my posts';

  @override
  String get urgentBlood => 'Urgent blood requests';

  @override
  String get alwaysOn => 'Always on';

  @override
  String get privacyOfMyDetails => 'Privacy of my details';

  @override
  String get welfareFund => 'Welfare fund';

  @override
  String get fundBalance => 'Fund balance';

  @override
  String treasurerLine(String names, String time) {
    return 'Treasurer: $names · updated $time';
  }

  @override
  String get treasurer => 'Treasurer';

  @override
  String get makeTreasurer => 'Make treasurer';

  @override
  String get removeTreasurer => 'Remove as treasurer';

  @override
  String get contribute => 'Contribute';

  @override
  String get askForSupport => 'Ask for support';

  @override
  String get openCauses => 'Open causes';

  @override
  String raisedOf(String raised, String target) {
    return '$raised of $target';
  }

  @override
  String contributorsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contributors',
      one: '1 contributor',
      zero: 'No contributors yet',
    );
    return '$_temp0';
  }

  @override
  String closesOn(String date) {
    return 'closes $date';
  }

  @override
  String get fundNote =>
      'Money is never handled in the app. You pay the family account or the treasurer directly, record it here, and the treasurer confirms it.';

  @override
  String get howToPay => 'How to pay';

  @override
  String get bank => 'Bank';

  @override
  String get accountNumber => 'Account';

  @override
  String get accountName => 'Name';

  @override
  String get copyAccountNumber => 'Copy account number';

  @override
  String get copied => 'Copied';

  @override
  String get noAccountYet =>
      'The treasurer hasn\'t added the account details yet. You can still pay the treasurer in cash.';

  @override
  String get recordContribution => 'Record your contribution';

  @override
  String get amountNaira => 'Amount (₦)';

  @override
  String get payTransfer => 'Bank transfer';

  @override
  String get payCash => 'Cash to treasurer';

  @override
  String get payMobile => 'Mobile money';

  @override
  String get attachReceipt => 'Attach receipt (optional)';

  @override
  String get receiptAttached => 'Receipt attached';

  @override
  String get showMyName => 'Show my name on the contributors list';

  @override
  String get recordContributionButton => 'Record contribution';

  @override
  String get contributionNote =>
      'The treasurer confirms each contribution. Amounts are private to you and the committee.';

  @override
  String get contributionRecorded => 'Recorded. The treasurer will confirm it.';

  @override
  String get amountInvalid => 'Enter an amount.';

  @override
  String get generalFund => 'General fund';

  @override
  String get contributeToFund => 'Contribute to the fund';

  @override
  String get myContributions => 'My contributions';

  @override
  String get contribPending => 'Waiting for the treasurer';

  @override
  String get contribConfirmed => 'Confirmed';

  @override
  String get contribRejected => 'Not confirmed';

  @override
  String toConfirm(int count) {
    return 'To confirm · $count';
  }

  @override
  String get confirmAction => 'Confirm';

  @override
  String get notReceived => 'Not received';

  @override
  String get viewReceipt => 'Receipt';

  @override
  String get supportRequests => 'Support requests';

  @override
  String get openCause => 'Open';

  @override
  String get decline => 'Decline';

  @override
  String get closeCause => 'Close cause';

  @override
  String get newCause => 'New cause';

  @override
  String get causeTitle => 'What is it for?';

  @override
  String get targetAmount => 'Amount needed (₦)';

  @override
  String get closesOnLabel => 'Closes on (optional)';

  @override
  String get askSupportNote =>
      'Your request goes to the treasurer and admins only. If they open it, the family can contribute.';

  @override
  String get requestSent => 'Sent to the treasurer and admins.';

  @override
  String get recordPayout => 'Record support paid';

  @override
  String get forCause => 'For';

  @override
  String get editAccount => 'Edit account details';

  @override
  String get openingBalance => 'Money already in the fund (₦)';

  @override
  String get waitingReview => 'Waiting for review';

  @override
  String notifFundContribution(String amount) {
    return 'New contribution to confirm: $amount';
  }

  @override
  String notifFundConfirmed(String amount) {
    return 'Your contribution of $amount was confirmed. Thank you!';
  }

  @override
  String notifFundRequest(String title) {
    return 'Support requested: $title';
  }

  @override
  String get mentorsTitle => 'Mentors & scholarships';

  @override
  String get tabMentors => 'Mentors';

  @override
  String get tabStudents => 'Students';

  @override
  String get tabOpportunities => 'Opportunities';

  @override
  String get newOpportunity => 'New opportunity';

  @override
  String sharedBy(String name) {
    return 'Shared by $name';
  }

  @override
  String deadlineOn(String date) {
    return 'deadline $date';
  }

  @override
  String get offeringGuidance => 'Relatives offering guidance';

  @override
  String get lookingForHelp => 'Students looking for help';

  @override
  String get ask => 'Ask';

  @override
  String askMentorTitle(String name) {
    return 'Ask $name';
  }

  @override
  String get askMentorHint => 'What would you like help with?';

  @override
  String askSent(String name) {
    return 'Sent. $name will see your note.';
  }

  @override
  String get asksToYou => 'Asks to you';

  @override
  String get offerToMentor => 'Offer to mentor';

  @override
  String get editMentoring => 'Edit my mentoring';

  @override
  String get stopMentoring => 'Stop mentoring';

  @override
  String get mentorAreas => 'Areas you can help with';

  @override
  String get mentorAreasHint => 'e.g. Medicine · residency applications';

  @override
  String get imLookingForHelp => 'I\'m looking for help';

  @override
  String get editMyRequest => 'Edit my request';

  @override
  String get removeMyRequest => 'Remove my request';

  @override
  String get studyField => 'What are you studying?';

  @override
  String get whatHelp => 'What help are you looking for?';

  @override
  String get shareOpportunity => 'Share an opportunity';

  @override
  String get opportunityTitle => 'Title';

  @override
  String get link => 'Link (optional)';

  @override
  String get deadlineOptional => 'Deadline (optional)';

  @override
  String get open => 'Open';

  @override
  String get noMentorsYet => 'No one has offered to mentor yet.';

  @override
  String get noStudentsYet => 'No students are looking for help right now.';

  @override
  String get noOpportunitiesYet => 'No opportunities shared yet.';

  @override
  String get pollsTitle => 'Polls';

  @override
  String get newPoll => 'New poll';

  @override
  String closesDate(String date) {
    return 'closes $date';
  }

  @override
  String get youVoted => 'you voted';

  @override
  String get notVotedYet => 'not voted yet';

  @override
  String get vote => 'Vote';

  @override
  String get changeVote => 'Change my vote';

  @override
  String votedOf(int count, int eligible) {
    return '$count of $eligible members voted';
  }

  @override
  String get decided => 'Decided';

  @override
  String decidedLine(int percent, String date) {
    return '$percent% chose this · decided $date';
  }

  @override
  String get closePoll => 'Close poll';

  @override
  String get deletePoll => 'Delete poll';

  @override
  String get question => 'Question';

  @override
  String get pollContext => 'What is it for? (optional)';

  @override
  String get pollContextHint => 'e.g. For the family meeting';

  @override
  String get choices => 'Choices';

  @override
  String choiceN(int n) {
    return 'Choice $n';
  }

  @override
  String get addChoice => 'Add a choice';

  @override
  String get closesOnPoll => 'Voting closes';

  @override
  String get needTwoChoices => 'Add a question and at least two choices.';

  @override
  String get noPollsYet => 'No polls yet. Ask the family a question.';

  @override
  String get secretBallot =>
      'Votes are secret. You see the results after you vote or when the poll closes.';

  @override
  String notifMentorRequest(String body) {
    return 'Someone asked for your guidance: “$body”';
  }

  @override
  String notifOpportunity(String title) {
    return 'New opportunity: $title';
  }

  @override
  String notifPoll(String question) {
    return 'New poll: $question';
  }

  @override
  String get storiesTitle => 'Elders’ stories';

  @override
  String get storiesSubtitle =>
      'Voices of the family, kept for the next generation';

  @override
  String get nowPlaying => 'Now playing';

  @override
  String get listen => 'Listen';

  @override
  String get otherLanguage => 'Other';

  @override
  String get transcript => 'Transcript';

  @override
  String get noStoriesYet => 'No stories yet. Record the first one.';

  @override
  String get recordStory => 'Record an elder’s story';

  @override
  String get recordHint =>
      'Try asking: How did you meet? What was Kano like when you were young?';

  @override
  String get deleteStory => 'Delete story';

  @override
  String get deleteStoryConfirm => 'Delete this story and its recording?';

  @override
  String get newStory => 'New story';

  @override
  String get tapToRecord => 'Tap to start recording';

  @override
  String recordingNow(String time) {
    return 'Recording… $time';
  }

  @override
  String get tapToStop => 'Tap to stop';

  @override
  String recordedLength(String time) {
    return 'Recorded · $time';
  }

  @override
  String get recordAgain => 'Record again';

  @override
  String get chooseAudioFile =>
      'Or choose an audio file (cassette transfer, voice note)';

  @override
  String get micDenied =>
      'Allow the microphone in your phone’s settings to record.';

  @override
  String get storyTitle => 'What is the story about?';

  @override
  String get whoSpeaking => 'Who is speaking?';

  @override
  String get sourceNote => 'Where and when was it recorded? (optional)';

  @override
  String get sourceNoteHint =>
      'e.g. Recorded 1979 on cassette, digitised by Bello';

  @override
  String get transcriptOptional => 'Transcript (optional)';

  @override
  String get saveStory => 'Save story';

  @override
  String get uploading => 'Uploading…';

  @override
  String get needAudio => 'Record or choose a recording first.';

  @override
  String get needTitleSpeaker => 'Add a title and who is speaking.';

  @override
  String notifStory(String speaker, String title) {
    return 'New story from $speaker: $title';
  }

  @override
  String get dataTitle => 'Import, export & backup';

  @override
  String get dataSubtitle => 'Admins only · your data is never locked in';

  @override
  String get exportHeading => 'Export';

  @override
  String get exportGedcom => 'Family tree (GEDCOM)';

  @override
  String get exportGedcomSub => 'Opens in other genealogy apps';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get exportCsvSub => 'Everyone, with dates and places';

  @override
  String get exportPdf => 'Printable tree (PDF)';

  @override
  String get exportPdfSub => 'Poster size, for family gatherings';

  @override
  String get includeDetails => 'Include contact & health details';

  @override
  String savedFile(String file) {
    return 'Saved $file';
  }

  @override
  String get importHeading => 'Import';

  @override
  String get chooseImportFile => 'Choose a GEDCOM or CSV file';

  @override
  String get importReviewNote =>
      'You’ll review matches before anything is added';

  @override
  String get downloadTemplate => 'Download the spreadsheet template';

  @override
  String importError(String message) {
    return 'Couldn’t read this file: $message';
  }

  @override
  String get weeklyBackupOn => 'Weekly backup is on';

  @override
  String get weeklyBackupOff => 'Weekly backup is off';

  @override
  String lastBackup(String date) {
    return 'Last backup $date';
  }

  @override
  String get noBackupYet => 'No backup yet';

  @override
  String get download => 'Download';

  @override
  String get keepWeeklyBackup => 'Keep a weekly backup';

  @override
  String get backupNow => 'Back up now';

  @override
  String get backupDone => 'Backup saved';

  @override
  String get earlierBackups => 'Earlier backups';

  @override
  String get backupsKept => 'Backups from the last eight weeks are kept.';

  @override
  String get reviewImport => 'Review import';

  @override
  String importSummary(int added, int matched, int links) {
    String _temp0 = intl.Intl.pluralLogic(
      links,
      locale: localeName,
      other: '$links relationships',
      one: '1 relationship',
    );
    return '$added new · $matched already in the tree · $_temp0';
  }

  @override
  String get importNew => 'New';

  @override
  String sameAs(String name) {
    return 'Same as $name in the tree';
  }

  @override
  String get notSame => 'Not the same person';

  @override
  String get addToTree => 'Add to the tree';

  @override
  String importDone(int people, int links) {
    String _temp0 = intl.Intl.pluralLogic(
      people,
      locale: localeName,
      other: '$people people',
      one: '1 person',
    );
    String _temp1 = intl.Intl.pluralLogic(
      links,
      locale: localeName,
      other: '$links relationships',
      one: '1 relationship',
    );
    return 'Added $_temp0 and $_temp1.';
  }

  @override
  String importSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count relationships were',
      one: '1 relationship was',
    );
    return '$_temp0 skipped because they don’t fit the tree.';
  }

  @override
  String treePosterTitle(String family) {
    return 'The $family Family';
  }

  @override
  String treePosterSubtitle(int count, String date) {
    return '$count people · printed $date';
  }

  @override
  String get restoreTitle => 'Restore from a backup';

  @override
  String get restoreSubtitle => 'Bring back deleted or changed family data';

  @override
  String get restoreEllipsis => 'Restore…';

  @override
  String get chooseBackup => 'Choose a backup';

  @override
  String beforeLastRestore(String date) {
    return 'Before the last restore · $date';
  }

  @override
  String get backupFile => 'A backup file…';

  @override
  String backupFileChosen(String name) {
    return 'File: $name';
  }

  @override
  String get notABackup => 'This file is not a Bua Family backup.';

  @override
  String get undoChanges => 'Also undo changes made since';

  @override
  String get undoChangesSub =>
      'Edits made after the backup are changed back. Nothing is deleted either way.';

  @override
  String get restorePreview => 'What will happen';

  @override
  String get checkingBackup => 'Checking the backup…';

  @override
  String get restoreUpToDate =>
      'Nothing to restore: today\'s data already has everything in this backup.';

  @override
  String restoreGroup(String group) {
    String _temp0 = intl.Intl.selectLogic(group, {
      'tree': 'Family tree',
      'details': 'Work, studies, contact & health',
      'sharing': 'Posts & photos',
      'events': 'Events',
      'memories': 'Memories & stories',
      'support': 'Blood requests & welfare fund',
      'other': 'Mentorship & polls',
    });
    return '$_temp0';
  }

  @override
  String restoreCounts(int added, int updated) {
    return '$added to bring back · $updated to change back';
  }

  @override
  String restoreSkippedCount(int count) {
    return '$count can\'t go back';
  }

  @override
  String get restoreSafety =>
      'A copy of today\'s data is saved first, so you can undo this from “Before the last restore”.';

  @override
  String get restoreLimits =>
      'Accounts aren\'t restored: members sign in again and an admin links them. Photos, voice recordings and receipts are files; the backup has their details but not the files.';

  @override
  String get restoreButton => 'Restore';

  @override
  String get restoreConfirm => 'Restore this backup now?';

  @override
  String restoreDone(int added, int updated) {
    return 'Restored: $added brought back, $updated changed back.';
  }

  @override
  String get pushOnThisPhone => 'Notifications on this phone';

  @override
  String get pushInThisBrowser => 'Notifications in this browser';

  @override
  String get pushOnSub =>
      'New notifications appear here even when the app is closed.';

  @override
  String get pushOffSub =>
      'Get told about events, blood requests, polls and more, even when the app is closed.';

  @override
  String get pushBlocked =>
      'Notifications are blocked. Allow them for Bua Family in your phone or browser settings, then try again.';

  @override
  String get pushUnavailable =>
      'This version of the app can\'t receive notifications yet.';

  @override
  String get pushNotSetUp => 'An admin hasn\'t set up phone notifications yet.';

  @override
  String get pushTurnedOn => 'Notifications are on for this device.';

  @override
  String get pushFailed =>
      'Couldn\'t turn on notifications. Check your connection and try again.';

  @override
  String get pushPromptTitle => 'Get notified on this phone';

  @override
  String get pushPromptBody =>
      'Know straight away about blood requests, events and family news.';

  @override
  String get turnOn => 'Turn on';

  @override
  String get notNow => 'Not now';

  @override
  String get pushAdminTitle => 'Phone notifications';

  @override
  String get pushAdminSub =>
      'Send every notification to members\' phones and browsers (free, through Firebase).';

  @override
  String get pushSetupSteps =>
      '1. Create a free project at console.firebase.google.com. 2. In Project settings › Service accounts, choose “Generate new private key”. 3. Choose that file below. The app also needs your Firebase app settings (see the README).';

  @override
  String get firebaseKey => 'Firebase key';

  @override
  String firebaseKeySaved(String project) {
    return 'Saved · $project';
  }

  @override
  String get chooseKeyFile => 'Choose the key file (.json)';

  @override
  String pushStats(int members, int devices, int sent, int received) {
    return '$members members on $devices devices · $sent sent, $received received in browsers this week';
  }

  @override
  String get sendTestPush => 'Send me a test notification';

  @override
  String get testPushSent =>
      'Sent. It should arrive on every device where you turned notifications on.';

  @override
  String get notifTest =>
      'Test notification: notifications are working on this device.';

  @override
  String get addPhoto => 'Add photo';

  @override
  String get photoLabel => 'Photo';

  @override
  String notifAccountRequest(String name) {
    return 'New sign-up waiting for approval: $name';
  }

  @override
  String notifAccountNote(String name, String note) {
    return '$name says: “$note”';
  }

  @override
  String notifChangeAdd(String name, String person) {
    return '$name suggested adding $person to the tree';
  }

  @override
  String notifChangeEdit(String name, String person) {
    return '$name suggested a change to $person';
  }

  @override
  String get notifAccountApproved => 'Welcome! Your account has been approved.';

  @override
  String notifRequestApproved(String person) {
    return 'Your suggestion about $person was approved';
  }

  @override
  String notifRequestDeclined(String person) {
    return 'Your suggestion about $person was not accepted';
  }

  @override
  String get notifSomeone => 'someone';

  @override
  String get notifTheTree => 'the tree';

  @override
  String get pendingPushHint =>
      'Get a notification the moment an admin approves you.';

  @override
  String notifCommentBy(String name, String body) {
    return '$name commented: “$body”';
  }

  @override
  String notifCommentAlso(String name, String body) {
    return '$name also commented: “$body”';
  }

  @override
  String notifAccountClaim(String name, String person) {
    return '$name says they are $person in the tree';
  }

  @override
  String get postGone => 'This post was removed.';

  @override
  String get findMeInTree => 'Find yourself in the tree';

  @override
  String get findMeHint =>
      'Link your account to your place in the tree to get your own profile, photo and details.';

  @override
  String linkWaiting(String name) {
    return 'Waiting for an admin to link you to $name';
  }

  @override
  String get linkedNow => 'Linked. This is now your profile.';

  @override
  String get birthOrder => 'Birth order among siblings';

  @override
  String get birthOrderHint =>
      '1 for the first-born. Siblings are listed in this order.';

  @override
  String get birthOrderNone => 'Not set';

  @override
  String reqRemoveParentChild(String parent, String child) {
    return 'Remove $parent as a parent of $child';
  }

  @override
  String reqRemoveUnion(String a, String b) {
    return 'Remove the marriage of $a and $b';
  }

  @override
  String get removeRelationship => 'Remove relationship';

  @override
  String confirmRemoveParent(String parent, String child) {
    return 'Remove $parent as a parent of $child? Both stay in the tree.';
  }

  @override
  String confirmRemoveUnion(String a, String b) {
    return 'Remove the marriage between $a and $b? Both stay in the tree.';
  }

  @override
  String get relationshipRemoved => 'Relationship removed';

  @override
  String get checkTree => 'Check the tree';

  @override
  String get checkTreeHint => 'Links that look wrong, so you can fix them';

  @override
  String get treeLooksRight => 'Nothing looks wrong in the tree.';

  @override
  String problemMarriedInLine(String a, String b) {
    return '$a and $b are married, but one descends from the other';
  }

  @override
  String problemParentYounger(String a, String b) {
    return '$a is a parent of $b but is not at least 10 years older';
  }

  @override
  String problemBornAfterDeath(String a, String b) {
    return '$b was born more than a year after their parent $a died';
  }

  @override
  String problemSameBirthOrder(String a, String b) {
    return '$a and $b have the same birth order';
  }

  @override
  String get removeLink => 'Remove link';

  @override
  String get sortBy => 'Sort';

  @override
  String get sortName => 'Name (A–Z)';

  @override
  String get sortOldest => 'Oldest first';

  @override
  String get sortYoungest => 'Youngest first';

  @override
  String get sortFamily => 'Family order';

  @override
  String get helpEachOther => 'Help each other';

  @override
  String get openMenu => 'Open menu';

  @override
  String get updateAvailableTitle => 'A new version of the app is ready';

  @override
  String updateAvailableBody(String version) {
    return 'Version $version. Download it, then open the file to update.';
  }

  @override
  String get getAppTitle => 'Bua Family for Android';

  @override
  String get getAppSub => 'Install the family app on your Android phone.';

  @override
  String getAppVersion(String version, String date) {
    return 'Version $version · $date';
  }

  @override
  String get getAppSteps =>
      '1. Tap Download.\n2. Open the downloaded file.\n3. If your phone asks, allow installing apps from this source, then tap Install (or Update).';

  @override
  String get getAppLatest => 'You have the latest version.';

  @override
  String get getAppNone => 'The Android app hasn\'t been published yet.';

  @override
  String get getAppIphone =>
      'On an iPhone, use the website instead: open it in Safari, tap Share, then Add to Home Screen.';

  @override
  String get getTheApp => 'Get the Android app';

  @override
  String get whatsNew => 'What\'s new';

  @override
  String get androidAppAdmin => 'Android app';

  @override
  String androidPublished(String version, String date) {
    return 'Published $version · $date';
  }

  @override
  String get androidNotPublished =>
      'Not published yet. Build the APK on your computer, then publish it here.';

  @override
  String get publishVersion => 'Publish a new version';

  @override
  String get buildNumber => 'Build number';

  @override
  String get versionLabel => 'Version';

  @override
  String get whatsNewOptional => 'What\'s new (optional)';

  @override
  String get appPublished =>
      'Published. Members with the Android app have been notified.';

  @override
  String get shareAppLink => 'Download link to share';

  @override
  String notifAppUpdate(String version) {
    return 'A new version of the app is ready ($version). Tap to download.';
  }

  @override
  String get searchUsers => 'Search name, email, phone or person';

  @override
  String get filterWaiting => 'Waiting';

  @override
  String get filterActive => 'Active';

  @override
  String get filterSuspended => 'Suspended';

  @override
  String get filterAdmins => 'Admins';

  @override
  String get filterTreasurers => 'Treasurers';

  @override
  String get filterNotLinked => 'Not in the tree';

  @override
  String get filterNoPush => 'No notifications';

  @override
  String get filterInactive => 'Inactive 30 days';

  @override
  String usersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count accounts',
      one: '1 account',
    );
    return '$_temp0';
  }

  @override
  String get platformFilter => 'App used';

  @override
  String get platformAny => 'Any app';

  @override
  String get platformAndroid => 'Android app';

  @override
  String get platformWeb => 'Website';

  @override
  String get sortNewest => 'Newest';

  @override
  String get sortLastActive => 'Last active';

  @override
  String get sortMostActive => 'Most active';

  @override
  String get neverSeen => 'Not seen yet';

  @override
  String lastSeen(String when) {
    return 'Active $when';
  }

  @override
  String activeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Active on $count of the last 30 days',
      one: 'Active on 1 of the last 30 days',
      zero: 'No activity in the last 30 days',
    );
    return '$_temp0';
  }

  @override
  String postsAndComments(int posts, int comments) {
    return '$posts posts · $comments comments';
  }

  @override
  String get noPushDevices => 'Notifications not turned on';

  @override
  String pushOn(String devices) {
    return 'Notifications on: $devices';
  }

  @override
  String androidVersionOf(String version) {
    return 'Android app $version';
  }

  @override
  String joinedOn(String date) {
    return 'Joined $date';
  }

  @override
  String get emailTab => 'Email';

  @override
  String get phoneTab => 'Phone';

  @override
  String get yourNameNew => 'Your name (if you\'re new here)';

  @override
  String get sendCode => 'Send me a code';

  @override
  String codeSent(String phone) {
    return 'We sent a 6-digit code to $phone.';
  }

  @override
  String get enterCode => 'Code from the text message';

  @override
  String get resendCode => 'Send again';

  @override
  String resendIn(int seconds) {
    return 'Send again in ${seconds}s';
  }

  @override
  String get changeNumber => 'Change number';

  @override
  String get invalidPhone => 'Enter a valid phone number';

  @override
  String get inviteTitle => 'You\'re invited';

  @override
  String inviteBody(String inviter, String family) {
    return '$inviter invited you to the $family family app.';
  }

  @override
  String inviteBodyGeneric(String family) {
    return 'You\'re invited to the $family family app.';
  }

  @override
  String inviteFor(String person) {
    return 'This invite is for $person.';
  }

  @override
  String get inviteInvalid =>
      'This invite link has already been used or has expired. Ask a family admin for a new one.';

  @override
  String get joinWithInvite => 'Join the family';

  @override
  String get acceptInvite => 'Accept the invite';

  @override
  String get inviteAccepted => 'Welcome to the family app!';

  @override
  String get inviteSomeone => 'Invite someone';

  @override
  String get inviteSomeoneHint =>
      'Make a link to send on WhatsApp. Whoever joins with it is approved at once.';

  @override
  String get invitePerson => 'For a person in the tree (optional)';

  @override
  String get createInvite => 'Create the link';

  @override
  String get inviteReady => 'Link ready. It works once, for 30 days.';

  @override
  String get shareWhatsApp => 'Share on WhatsApp';

  @override
  String get copyLink => 'Copy link';

  @override
  String inviteMessage(String family, String link) {
    return 'Assalamu alaikum! Join the $family family app: $link';
  }

  @override
  String inviteMessageFor(String name, String family, String link) {
    return 'Assalamu alaikum $name! Join the $family family app: $link';
  }

  @override
  String get offlineSaved =>
      'You\'re offline. Showing what was saved on this phone.';

  @override
  String get metricsTitle => 'Family metrics';

  @override
  String get metricsSub => 'How the family is using the app';

  @override
  String get period7 => '7 days';

  @override
  String get period30 => '30 days';

  @override
  String get period90 => '90 days';

  @override
  String get period365 => '12 months';

  @override
  String get periodCustom => 'Custom…';

  @override
  String get byDay => 'Daily';

  @override
  String get byWeek => 'Weekly';

  @override
  String get byMonth => 'Monthly';

  @override
  String get allPlatforms => 'All apps';

  @override
  String get allBranches => 'All branches';

  @override
  String get comparePrevious => 'Compare with the period before';

  @override
  String get previousPeriod => 'Period before';

  @override
  String vsPrevious(String change) {
    return '$change vs period before';
  }

  @override
  String get noChange => 'Same as period before';

  @override
  String get newThisPeriod => 'New this period';

  @override
  String get customiseTiles => 'Choose metrics';

  @override
  String get customiseTilesHint => 'Pick what shows on your dashboard.';

  @override
  String get showTable => 'Table';

  @override
  String get showChart => 'Chart';

  @override
  String get breakdownBy => 'Split by';

  @override
  String get byBranch => 'Branch';

  @override
  String get byPlatform => 'App';

  @override
  String get byMember => 'Member';

  @override
  String get noBranch => 'No branch';

  @override
  String get unknownLabel => 'Unknown';

  @override
  String get snapshotTitle => 'Right now';

  @override
  String get funnelAccounts => 'Accounts';

  @override
  String get funnelApproved => 'Approved';

  @override
  String get funnelLinked => 'In the tree';

  @override
  String get funnelActive30 => 'Active in 30 days';

  @override
  String get funnelPush => 'Notifications on';

  @override
  String get funnelAndroid => 'Android app';

  @override
  String get treeQuality => 'The tree';

  @override
  String treePeople(int count, int living) {
    return '$count people · $living living';
  }

  @override
  String withPhotoPct(int pct) {
    return '$pct% have a photo';
  }

  @override
  String withBirthPct(int pct) {
    return '$pct% have a date of birth';
  }

  @override
  String withAccountPct(int pct) {
    return '$pct% have an account';
  }

  @override
  String get fundBalanceLabel => 'Welfare fund balance';

  @override
  String get openBloodLabel => 'Open blood requests';

  @override
  String get pendingSuggestionsLabel => 'Suggestions waiting';

  @override
  String get noDataYet => 'Nothing in this period yet.';

  @override
  String get mgPeople => 'People';

  @override
  String get mgTree => 'The tree';

  @override
  String get mgSharing => 'Sharing';

  @override
  String get mgEvents => 'Events & polls';

  @override
  String get mgHelping => 'Helping each other';

  @override
  String get mgReach => 'Reaching people';

  @override
  String get m_signups => 'Sign-ups';

  @override
  String get m_active_members => 'Active members';

  @override
  String get m_active_android => 'Active on Android';

  @override
  String get m_active_web => 'Active on the website';

  @override
  String get m_people_added => 'People added';

  @override
  String get m_relationships_added => 'Relationships added';

  @override
  String get m_suggestions => 'Suggestions sent';

  @override
  String get m_suggestions_reviewed => 'Suggestions reviewed';

  @override
  String get m_moments => 'Moments posted';

  @override
  String get m_announcements => 'Announcements';

  @override
  String get m_posting_members => 'Members who posted';

  @override
  String get m_photos => 'Photos';

  @override
  String get m_comments => 'Comments';

  @override
  String get m_likes => 'Ma sha Allah';

  @override
  String get m_stories => 'Stories recorded';

  @override
  String get m_memories => 'Memories written';

  @override
  String get m_events => 'Events created';

  @override
  String get m_rsvps => 'RSVPs';

  @override
  String get m_polls => 'Polls';

  @override
  String get m_votes => 'Votes';

  @override
  String get m_blood_requests => 'Blood requests';

  @override
  String get m_blood_offers => 'Offers to donate';

  @override
  String get m_contributions => 'Contributions recorded';

  @override
  String get m_money_in => 'Money confirmed in';

  @override
  String get m_money_out => 'Money paid out';

  @override
  String get m_causes => 'Causes opened';

  @override
  String get m_mentor_asks => 'Mentor requests';

  @override
  String get m_opportunities => 'Opportunities shared';

  @override
  String get m_notifications => 'Notifications sent';

  @override
  String get m_notifications_received => 'Notifications received';

  @override
  String get m_sms_sent => 'Text messages sent';

  @override
  String get storiesAdminOnly =>
      'Admins record the elders\' stories. If you have one to share, tell an admin.';

  @override
  String get aboutTitle => 'About the app';

  @override
  String get aboutSub => 'Version, features and who made it';

  @override
  String get aboutTagline =>
      'One family, one place: our tree, our news and our care for each other.';

  @override
  String aboutVersion(String version, String build) {
    return 'Version $version · build $build';
  }

  @override
  String get aboutOnWeb => 'Web app';

  @override
  String get aboutOnAndroid => 'Android app';

  @override
  String aboutLatestAndroid(String version) {
    return 'Newest Android app: $version';
  }

  @override
  String get aboutUpToDate => 'You have the newest version.';

  @override
  String get featuresTitle => 'What\'s in the app';

  @override
  String get fTree => 'Family tree';

  @override
  String get fTreeD =>
      'Everyone, with photos and birth order, and checks that keep it right.';

  @override
  String get fMembers => 'Members and profiles';

  @override
  String get fMembersD =>
      'Find anyone, call or message them, and keep your own details up to date.';

  @override
  String get fRelated => 'How are we related?';

  @override
  String get fRelatedD => 'The path between any two people in the family.';

  @override
  String get fSharing => 'Moments, albums and announcements';

  @override
  String get fSharingD =>
      'Share news and photos; comment, like and tag family.';

  @override
  String get fEvents => 'Events and reminders';

  @override
  String get fEventsD =>
      'Weddings, naming ceremonies and meetings, with RSVPs, birthdays and remembrance days.';

  @override
  String get fBlood => 'Blood donors';

  @override
  String get fBloodD =>
      'Ask for blood in an emergency and reach donors in the family at once.';

  @override
  String get fFund => 'Welfare fund';

  @override
  String get fFundD => 'Contributions, causes and payouts, open to the family.';

  @override
  String get fMentors => 'Mentorship and opportunities';

  @override
  String get fMentorsD =>
      'Ask an experienced relative for guidance; share jobs and scholarships.';

  @override
  String get fStories => 'Elders\' stories';

  @override
  String get fStoriesD =>
      'Voices of our elders, recorded and kept for the next generations.';

  @override
  String get fPolls => 'Polls';

  @override
  String get fPollsD => 'Decide together.';

  @override
  String get fMemorial => 'Memorial pages';

  @override
  String get fMemorialD =>
      'Remember those who have passed, with prayers and memories.';

  @override
  String get fReach => 'Notifications and SMS';

  @override
  String get fReachD =>
      'On the phone, on the web, and by SMS for those without data.';

  @override
  String get fOffline => 'Works offline';

  @override
  String get fOfflineD =>
      'What you have seen stays on your phone when the network drops.';

  @override
  String get fLanguages => 'English and Hausa';

  @override
  String get fLanguagesD => 'Switch any time in More.';

  @override
  String get fPrivate => 'Private to the family';

  @override
  String get fPrivateD =>
      'Only approved members can see anything. Admins approve every account.';

  @override
  String get developerTitle => 'Developer';

  @override
  String get developedBy => 'Designed and developed by';

  @override
  String get contactCall => 'Call';

  @override
  String get contactWhatsApp => 'WhatsApp';

  @override
  String get contactEmail => 'Email';

  @override
  String get contactWebsite => 'Website';

  @override
  String get licensesLabel => 'Open-source licences';

  @override
  String copyrightLine(String year, String company) {
    return '© $year $company. All rights reserved.';
  }

  @override
  String get aboutSettings => 'About page: developer';

  @override
  String get aboutSettingsHint =>
      'Shown on the About page to everyone in the family.';

  @override
  String get developerName => 'Developer\'s name';

  @override
  String get developerCompany => 'Company';

  @override
  String get developerWebsite => 'Website (https://…)';

  @override
  String notifMentorRequestFrom(String name, String body) {
    return '$name asked for your guidance: “$body”';
  }

  @override
  String notifMentorReply(String name, String body) {
    return '$name: “$body”';
  }

  @override
  String get yourAsks => 'Your asks';

  @override
  String get conversationTitle => 'Mentorship';

  @override
  String conversationWithMentor(String areas) {
    return 'Your mentor · $areas';
  }

  @override
  String get conversationWithStudent => 'Asked you for guidance';

  @override
  String get conversationPrivate =>
      'Only the two of you can see this conversation.';

  @override
  String get writeMessage => 'Write a message…';

  @override
  String get replyAction => 'Reply';

  @override
  String get conversationGone => 'This conversation was removed.';

  @override
  String get deleteConversation => 'Delete conversation';

  @override
  String get deleteConversationConfirm =>
      'Delete this conversation for both of you?';

  @override
  String youPrefix(String text) {
    return 'You: $text';
  }

  @override
  String get newMessages => 'New';

  @override
  String get activityTitle => 'Activity';

  @override
  String get activitySub => 'Who is online and what they did';

  @override
  String get tabOnline => 'Online';

  @override
  String get tabActivityLog => 'Activity log';

  @override
  String get onlineNow => 'Online now';

  @override
  String get earlierToday => 'Earlier';

  @override
  String get nobodyOnline => 'Nobody has the app open right now.';

  @override
  String onlineFor(String time) {
    return 'for $time';
  }

  @override
  String seenAgo(String time) {
    return 'last seen $time';
  }

  @override
  String minutesShort(int n) {
    return '$n min';
  }

  @override
  String hoursShort(int h, int m) {
    return '$h h $m min';
  }

  @override
  String onPage(String page) {
    return 'on $page';
  }

  @override
  String get platformAndroidShort => 'Android';

  @override
  String get platformWebShort => 'Web';

  @override
  String get logAll => 'All';

  @override
  String get logChanges => 'Changes';

  @override
  String get logPages => 'Pages';

  @override
  String get logSessions => 'Sign-ins';

  @override
  String get logAnyone => 'Anyone';

  @override
  String get logToday => 'Today';

  @override
  String get log7 => '7 days';

  @override
  String get log30 => '30 days';

  @override
  String get logAnyTime => 'Any time';

  @override
  String get logSearch => 'Search names, pages, titles…';

  @override
  String get logEmpty => 'Nothing here yet.';

  @override
  String get loadMore => 'Show more';

  @override
  String get logPrivacyNote =>
      'Only admins see this. Private conversations are logged without their content.';

  @override
  String get actOpenedApp => 'opened the app';

  @override
  String get actSignedIn => 'signed in';

  @override
  String get actSignedOut => 'signed out';

  @override
  String actViewed(String page) {
    return 'opened $page';
  }

  @override
  String actAdded(String thing) {
    return 'added $thing';
  }

  @override
  String actChanged(String thing) {
    return 'changed $thing';
  }

  @override
  String actRemoved(String thing) {
    return 'removed $thing';
  }

  @override
  String get actLiked => 'liked something';

  @override
  String get actUnliked => 'took back a like';

  @override
  String get actRsvp => 'answered an invitation';

  @override
  String get actVoted => 'voted in a poll';

  @override
  String get actReviewed => 'reviewed a suggestion';

  @override
  String get actAccount => 'changed an account';

  @override
  String get actSettings => 'changed the app settings';

  @override
  String get actMentorAsk => 'asked a mentor for guidance';

  @override
  String get actMentorMessage => 'sent a mentorship message';

  @override
  String get actConfirmed => 'confirmed a contribution';

  @override
  String get entPerson => 'a person';

  @override
  String get entRelationship => 'a relationship';

  @override
  String get entSuggestion => 'a suggestion';

  @override
  String get entAlbum => 'an album';

  @override
  String get entPost => 'a moment';

  @override
  String get entAnnouncement => 'an announcement';

  @override
  String get entPhoto => 'a photo';

  @override
  String get entEvent => 'an event';

  @override
  String get entComment => 'a comment';

  @override
  String get entBloodRequest => 'a blood request';

  @override
  String get entBloodOffer => 'an offer to donate blood';

  @override
  String get entMemory => 'a memory';

  @override
  String get entCause => 'a fund cause';

  @override
  String get entContribution => 'a contribution';

  @override
  String get entPayout => 'a payout';

  @override
  String get entMentor => 'an offer to mentor';

  @override
  String get entStudent => 'a request for guidance';

  @override
  String get entOpportunity => 'an opportunity';

  @override
  String get entPoll => 'a poll';

  @override
  String get entStory => 'an elder\'s story';

  @override
  String get entInvite => 'an invite link';

  @override
  String get entOther => 'something';

  @override
  String get pageHome => 'Home';

  @override
  String pagePerson(String name) {
    return '$name\'s page';
  }

  @override
  String get pageAPerson => 'a person\'s page';

  @override
  String get pageAnEvent => 'an event';

  @override
  String get pageAMoment => 'a moment';

  @override
  String get pageAnAlbum => 'an album';

  @override
  String get pageAPhoto => 'a photo';

  @override
  String get pageAConversation => 'a mentorship conversation';

  @override
  String get pageSignIn => 'sign-in';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get orWord => 'or';

  @override
  String get resetHowTitle => 'Reset your password';

  @override
  String get resetByEmail => 'Send a link to my email';

  @override
  String get resetByEmailHint => 'Enter your email above first.';

  @override
  String get resetByText => 'Send a code to my phone';

  @override
  String get resetByTextHint => 'The phone number saved on your profile';

  @override
  String get sendResetCode => 'Send code';

  @override
  String resetCodeSentTo(String phone) {
    return 'If $phone is on an account, a code is on its way. It works for 10 minutes.';
  }

  @override
  String get newPasswordLabel => 'New password (8 or more characters)';

  @override
  String get setNewPassword => 'Set new password';

  @override
  String get resetDone => 'Password changed. Welcome back!';

  @override
  String get resetSmsOff =>
      'Text messages are not set up yet. Use your email instead.';

  @override
  String get resetTooMany =>
      'Please wait a little before asking for another code.';

  @override
  String get resetWrongCode =>
      'That code isn\'t right. Check the text message.';

  @override
  String get resetExpired => 'That code has expired. Ask for a new one.';

  @override
  String get occIslamicNewYear => 'Islamic New Year';

  @override
  String get occAshura => 'Ashura';

  @override
  String get occMawlid => 'Mawlid';

  @override
  String get occRamadan => 'Ramadan begins';

  @override
  String get occLaylatAlQadr => 'Laylat al-Qadr (27th night)';

  @override
  String get occEidAlFitr => 'Eid al-Fitr';

  @override
  String get occArafah => 'Day of Arafah';

  @override
  String get occEidAlAdha => 'Eid al-Adha';

  @override
  String get greetEidFitr => 'Eid Mubarak! Barka da Sallah.';

  @override
  String get greetEidAdha => 'Eid Mubarak! Barka da Babbar Sallah.';

  @override
  String get greetRamadan => 'Ramadan Mubarak! May Allah accept our fasting.';

  @override
  String greetNewYear(int year) {
    return 'Happy Islamic New Year $year!';
  }

  @override
  String get eveEidFitr =>
      'Eid al-Fitr is expected tomorrow, if the moon is sighted.';

  @override
  String get eveEidAdha => 'Eid al-Adha is expected tomorrow.';

  @override
  String get eveRamadan =>
      'Ramadan is expected to begin tomorrow, if the moon is sighted.';

  @override
  String greetingFrom(String family) {
    return 'From all of us in the $family family';
  }

  @override
  String get shareGreeting => 'Share a greeting';

  @override
  String get islamicOccasions => 'Islamic occasions';

  @override
  String get moonNote =>
      'Dates follow the Islamic calendar and can move a day with the moon sighting.';

  @override
  String inDaysCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'in $n days',
      one: 'tomorrow',
      zero: 'today',
    );
    return '$_temp0';
  }

  @override
  String get hijriSettingsTitle => 'Islamic calendar';

  @override
  String get hijriAdjust => 'Moon sighting adjustment';

  @override
  String get hijriAdjustHint =>
      'If the new month was announced a day earlier than the app shows, add a day; a day later, take one away.';

  @override
  String hijriTodayIs(String date) {
    return 'Today in the app: $date';
  }

  @override
  String get islamicGreetingsToggle =>
      'Greet the family on Ramadan, the Eids and the new year';

  @override
  String get showHijriDates => 'Show Islamic dates';

  @override
  String get showHijriDatesHint => 'Next to dates, e.g. 21 Rabiʻ al-Thani 1448';

  @override
  String get hijriNoAdjust => 'No adjustment';

  @override
  String hijriDaysSigned(String sign, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days',
      one: '1 day',
    );
    return '$sign$_temp0';
  }

  @override
  String get duesTitle => 'Dues';

  @override
  String get myDues => 'My dues';

  @override
  String duesEvery(String amount, String per) {
    return '$amount $per';
  }

  @override
  String get perMonth => 'a month';

  @override
  String get perQuarter => 'every 3 months';

  @override
  String get perYear => 'a year';

  @override
  String youOwe(String amount) {
    return 'You owe $amount';
  }

  @override
  String owesAmount(String amount) {
    return 'Owes $amount';
  }

  @override
  String unpaidPeriods(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n periods unpaid',
      one: '1 period unpaid',
    );
    return '$_temp0';
  }

  @override
  String paidUpTo(String date) {
    return 'Paid up to $date';
  }

  @override
  String get paidUpNothingYet => 'Paid up';

  @override
  String get duesExempt => 'Exempt';

  @override
  String waitingConfirmation(String amount) {
    return '$amount waiting for confirmation';
  }

  @override
  String get payDues => 'Pay dues';

  @override
  String payDuesTitle(String title) {
    return 'Pay: $title';
  }

  @override
  String get myStatement => 'My statement (PDF)';

  @override
  String get fundReports => 'Reports';

  @override
  String get recordForMember => 'Record a payment for a member';

  @override
  String get newDuesPlan => 'New dues plan';

  @override
  String get editDuesPlan => 'Edit plan';

  @override
  String get planTitleLabel => 'Name (e.g. Monthly dues)';

  @override
  String get planPeriod => 'How often';

  @override
  String get periodMonthly => 'Monthly';

  @override
  String get periodQuarterly => 'Every 3 months';

  @override
  String get periodYearly => 'Yearly';

  @override
  String get planStarts => 'Starts';

  @override
  String get planActive => 'Active';

  @override
  String get planAutoRemind =>
      'Remind those who owe at the start of each period';

  @override
  String get noDuesPlans =>
      'No dues yet. Create a plan for regular contributions, e.g. ₦2,000 a month.';

  @override
  String get duesFilterAll => 'All';

  @override
  String get duesFilterOwing => 'Owing';

  @override
  String get duesFilterPaidUp => 'Paid up';

  @override
  String get duesFilterExempt => 'Exempt';

  @override
  String duesSummaryLine(int owing, int total, String owed) {
    return '$owing of $total owe · $owed outstanding';
  }

  @override
  String get remindOwing => 'Remind those who owe';

  @override
  String remindedCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n reminders sent',
      one: '1 reminder sent',
      zero: 'Nobody to remind',
    );
    return '$_temp0';
  }

  @override
  String get duesStartLabel => 'Dues start';

  @override
  String get exemptToggle => 'Exempt from this plan';

  @override
  String recordPaymentFrom(String name) {
    return 'Record a payment from $name';
  }

  @override
  String get paymentRecorded => 'Payment recorded.';

  @override
  String get chooseMember => 'Who paid?';

  @override
  String get forWhat => 'For';

  @override
  String notifDuesReminder(String title, String owed) {
    return '$title: you owe $owed. Tap to pay.';
  }

  @override
  String get reportTitle => 'Fund report';

  @override
  String get periodThisMonth => 'This month';

  @override
  String get periodLastMonth => 'Last month';

  @override
  String get periodThisYear => 'This year';

  @override
  String get periodLastYear => 'Last year';

  @override
  String get openingLabel => 'Opening balance';

  @override
  String get moneyIn => 'Money in';

  @override
  String get moneyOut => 'Money out';

  @override
  String get closingLabel => 'Closing balance';

  @override
  String get bySourceTitle => 'By cause and dues';

  @override
  String get monthByMonth => 'Month by month';

  @override
  String get transactionsTitle => 'All transactions';

  @override
  String get duesStandingTitle => 'Dues standing';

  @override
  String paymentsFrom(int p, int c) {
    String _temp0 = intl.Intl.pluralLogic(
      p,
      locale: localeName,
      other: '$p payments',
      one: '1 payment',
    );
    String _temp1 = intl.Intl.pluralLogic(
      c,
      locale: localeName,
      other: '$c members',
      one: '1 member',
    );
    return '$_temp0 from $_temp1';
  }

  @override
  String reportGenerated(String date) {
    return 'Generated $date';
  }

  @override
  String get reportCommitteeNote =>
      'Members see the totals. Names and amounts are shown to the committee only.';

  @override
  String get downloadPdf => 'PDF';

  @override
  String statementFor(String name) {
    return 'Statement for $name';
  }

  @override
  String get contributionsLabel => 'Contributions';

  @override
  String get statusConfirmedLabel => 'Confirmed';

  @override
  String get inOut => 'In';

  @override
  String get outLabel => 'Out';

  @override
  String get nothingInPeriod => 'No money in or out in this period.';

  @override
  String get searchByName => 'Search by name';

  @override
  String get paymentMethod => 'How it was paid';

  @override
  String get filterClaims => 'Claims';

  @override
  String get claimTitle => 'Says this is them in the tree';

  @override
  String get claimConfirm => 'Confirm & link';

  @override
  String get claimDecline => 'Decline';

  @override
  String get claimDeclineTitle => 'Decline this claim?';

  @override
  String get claimDeclineReason => 'Reason for them (optional)';

  @override
  String claimAlreadyLinked(String name) {
    return '$name\'s account is already linked to this person. Unlink it first if this claim is right.';
  }

  @override
  String get claimConfirmed => 'Linked. They\'ll be told.';

  @override
  String get claimDeclined => 'Declined. They\'ll be told.';

  @override
  String claimsOnPerson(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n people say this is them',
      one: 'Someone says this is them',
    );
    return '$_temp0';
  }

  @override
  String personFacts(String born, String parents) {
    return 'Born $born · $parents';
  }

  @override
  String childOf(String names) {
    return 'child of $names';
  }

  @override
  String notifClaimApproved(String person) {
    return 'You\'re now linked to $person in the family tree.';
  }

  @override
  String notifClaimDeclined(String person) {
    return 'Your request to be linked to $person was declined.';
  }

  @override
  String notifClaimDeclinedWhy(String person, String reason) {
    return 'Your request to be linked to $person was declined: “$reason”';
  }

  @override
  String get showDetails => 'Show details';

  @override
  String get hideDetails => 'Hide details';

  @override
  String get viewPhoto => 'View photo';

  @override
  String get changePhoto2 => 'Change photo';

  @override
  String get searchTitle => 'Search';

  @override
  String get searchEverything => 'Search people, moments, events, stories…';

  @override
  String get searchAll => 'All';

  @override
  String get kindPeople => 'People';

  @override
  String get kindPost => 'Moments';

  @override
  String get kindEvent => 'Events';

  @override
  String get kindAlbum => 'Albums';

  @override
  String get kindPhoto => 'Photos';

  @override
  String get kindStory => 'Elders\' stories';

  @override
  String get kindCause => 'Welfare fund';

  @override
  String get kindPoll => 'Polls';

  @override
  String get kindOpportunity => 'Opportunities';

  @override
  String get kindMemory => 'Memories';

  @override
  String get kindSkill => 'Skills';

  @override
  String get kindWork => 'Work';

  @override
  String get recentSearches => 'Recent searches';

  @override
  String get clearRecent => 'Clear';

  @override
  String searchNothing(String q) {
    return 'Nothing found for “$q”.';
  }

  @override
  String get searchTypeMore => 'Type at least 2 letters.';

  @override
  String get searchTips =>
      'Try a name, a place, a word from a moment, a skill like “nurse”, or an event.';

  @override
  String showAllCount(int n) {
    return 'Show all $n';
  }

  @override
  String get familyMakeup => 'Who is in the family';

  @override
  String get menLabel => 'Men';

  @override
  String get womenLabel => 'Women';

  @override
  String get sexNotSet => 'Not set';

  @override
  String get totalLabel => 'Total';

  @override
  String get bloodFamily => 'Blood family';

  @override
  String get marriedIn => 'Married in';

  @override
  String get notConnectedYet => 'Not connected yet';

  @override
  String livingMenWomen(int men, int women) {
    return 'Living: $men men · $women women';
  }

  @override
  String get familyMakeupHelp =>
      'Blood family: the founders and everyone born or adopted into the line. Married in: their husbands and wives who came from outside.';

  @override
  String get viewTree => 'Whole tree';

  @override
  String get viewFamilyLine => 'Family line';

  @override
  String childrenWithParent(String name) {
    return 'With $name';
  }

  @override
  String childCountShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count children',
      one: '1 child',
      zero: 'No children recorded',
    );
    return '$_temp0';
  }

  @override
  String grandchildrenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count grandchildren',
      one: '1 grandchild',
    );
    return '$_temp0';
  }

  @override
  String descendantsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count descendants',
      one: '1 descendant',
    );
    return '$_temp0';
  }

  @override
  String get openProfile => 'Open profile';

  @override
  String upTo(String name) {
    return 'Up to $name';
  }

  @override
  String get familyLineHint => 'Tap a child to see their family.';

  @override
  String get noChildrenYet => 'No children recorded yet.';

  @override
  String childrenHeading(int count) {
    return 'Children ($count)';
  }

  @override
  String parentsNames(String names) {
    return 'Parents: $names';
  }

  @override
  String get deleteMyAccount => 'Delete my account';

  @override
  String get deleteAccountTitle => 'Delete your account?';

  @override
  String get deleteAccountGone =>
      'Removed for good: your sign-in, phone and email, and what you shared: moments, comments, likes, photos you uploaded, memories, messages and requests.';

  @override
  String get deleteAccountKept =>
      'Kept for the family, without your name: your place in the family tree, albums and events you created, polls, elders\' stories you recorded, and welfare fund payments.';

  @override
  String get deleteAccountConfirm => 'I understand this can\'t be undone';

  @override
  String get deleteAccountOnlyAdmin =>
      'You are the only admin. Make someone else an admin first.';

  @override
  String get accountDeleted => 'Your account was deleted.';

  @override
  String get getOnPlay => 'Get it on Google Play';

  @override
  String get downloadApkInstead => 'Or download the app file (APK)';

  @override
  String get updateOnPlay => 'Update on Google Play';

  @override
  String get playStoreLink => 'Google Play link';

  @override
  String get playStoreLinkHelp =>
      'Once the app is on Google Play, paste its link here. The download page then sends people to Play.';

  @override
  String get playStoreLinkInvalid =>
      'Use the link from Google Play (https://play.google.com/…).';

  @override
  String get notSet => 'Not set';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String notifWeeklySummary(
    int active,
    int moments,
    int photos,
    String moneyIn,
  ) {
    return 'This week: $active active, $moments moments, $photos photos, $moneyIn in.';
  }

  @override
  String notifWeeklyWaiting(int count) {
    return '$count waiting for you.';
  }

  @override
  String notifAlertBlood(String group, String patient, int hours) {
    return 'No donor yet for $group blood for $patient ($hours h). Please call around.';
  }

  @override
  String notifAlertWaiting(int suggestions, int accounts) {
    return 'Waiting over 3 days: $suggestions suggestions, $accounts new accounts.';
  }

  @override
  String notifAlertFundLow(String balance, String threshold) {
    return 'The welfare fund is down to $balance, below $threshold.';
  }

  @override
  String get adminUpdatesTitle => 'Admin updates';

  @override
  String get weeklySummaryToggle => 'Weekly summary on Monday mornings';

  @override
  String get weeklySummaryHint =>
      'What happened in the week and what\'s waiting, for every admin.';

  @override
  String get fundAlertBelow => 'Warn when the fund is below';

  @override
  String get fundAlertHint =>
      'Admins and treasurers are told once each time the balance drops below this.';

  @override
  String get offLabel => 'Off';

  @override
  String get alertsAlwaysOn =>
      'Admins are also alerted when a blood request has no offer after 2 hours, and when suggestions or accounts wait over 3 days.';

  @override
  String get notifWeeklyForAdmins => 'Weekly summary (admins)';

  @override
  String get messagesTitle => 'Messages';

  @override
  String get newMessage => 'New message';

  @override
  String get noMessagesYet =>
      'No messages yet. Start a conversation with someone in the family.';

  @override
  String get sendMessage => 'Message';

  @override
  String get dmPrivate => 'Only the two of you can see these messages.';

  @override
  String get startConversation => 'Start the conversation.';

  @override
  String notifDirectMessage(String name, String body) {
    return '$name: “$body”';
  }

  @override
  String get noOtherMembers => 'No other family members have accounts yet.';

  @override
  String get messageWho => 'Message who?';

  @override
  String get conversationNotFound => 'This conversation isn\'t available.';

  @override
  String get familyBookSubtitle => 'Family book';

  @override
  String familyBookCover(String founder, int people, int generations) {
    return 'From $founder · $people people · $generations generations';
  }

  @override
  String generationHeading(int n) {
    return 'Generation $n';
  }

  @override
  String bookMarriedTo(String names) {
    return 'Married to $names';
  }

  @override
  String bookChildren(String names) {
    return 'Children: $names';
  }

  @override
  String bookBornIn(String place) {
    return 'Born in $place';
  }

  @override
  String bookBuriedIn(String place) {
    return 'Buried in $place';
  }

  @override
  String get bookAlsoInTree => 'Also in the family tree';

  @override
  String get bookIndex => 'Index of names';

  @override
  String bookMadeOn(String date) {
    return 'Made with the Bua Family app on $date';
  }

  @override
  String bookHowToRead(String founder) {
    return 'Everyone in the line of $founder, generation by generation. Each person has a number: their children add a number to it (1.2 is the second child of 1, 1.2.3 the third child of 1.2).';
  }

  @override
  String get familyBookAction => 'Family book (PDF)';

  @override
  String get familyBookHint =>
      'Everyone from the forefather down, generation by generation, with photos and life stories. Contact and health details are left out.';

  @override
  String get includePhotos => 'Include photos';

  @override
  String get includePhotosHint => 'Slower, and a bigger file.';

  @override
  String get makeBook => 'Make the book';

  @override
  String get makingBook => 'Making the family book…';

  @override
  String get whoCame => 'Who came';

  @override
  String whoCameCount(int count) {
    return 'Who came ($count)';
  }

  @override
  String get imHere => 'I\'m here';

  @override
  String get youCame => 'You\'re marked as here.';

  @override
  String get undoLabel => 'Undo';

  @override
  String get markWhoCame => 'Mark who came';

  @override
  String get noOneMarkedYet => 'No one marked yet.';

  @override
  String get eventPhotosHint => 'Share the photos from this day.';

  @override
  String get eventPhotosTitle => 'Photos from the day';

  @override
  String get shareLabel => 'Share';

  @override
  String get shareHint =>
      'The link shows a card on WhatsApp; only family members can open what\'s inside.';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get themeLabel => 'Colours';

  @override
  String get themeSystem => 'Auto';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get textSizeLabel => 'Text size';

  @override
  String get textNormal => 'Normal';

  @override
  String get textLarge => 'Large';

  @override
  String get textLarger => 'Larger';

  @override
  String get textSizeSample => 'This is how text will look.';

  @override
  String apkTooBig(String name, String size) {
    return '$name is $size MB, over the 50 MB limit. Build with the script: it makes a smaller file for each phone type.';
  }

  @override
  String get apkNeedMain =>
      'Also choose the 64-bit file (…-arm64.apk); most phones need it.';

  @override
  String get apkFilesHint =>
      'Choose both files the build makes: -arm64 (most phones) and -arm32 (older phones). Each phone gets the right one.';

  @override
  String get forOlderPhones => 'For older phones (32-bit)';

  @override
  String get messagesToggle => 'Private messages';

  @override
  String get messagesToggleHint =>
      'Members can message each other (and, later, chat in groups). Turned off, nobody can send or read messages, admins included; conversations are kept and come back when it is turned on again.';

  @override
  String get messagesTurnedOff =>
      'Messages are turned off by the family admins.';
}
