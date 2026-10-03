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
  String get phoneHint => 'e.g. 0803 123 4567';

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
}
