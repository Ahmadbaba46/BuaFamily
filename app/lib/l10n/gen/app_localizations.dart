import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ha.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ha'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Bua Family'**
  String get appTitle;

  /// No description provided for @navTree.
  ///
  /// In en, this message translates to:
  /// **'Tree'**
  String get navTree;

  /// No description provided for @navMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get navMembers;

  /// No description provided for @navAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get navAdmin;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUp;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get displayName;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get haveAccount;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'New here? Create an account'**
  String get noAccount;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @resetPasswordSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent.'**
  String get resetPasswordSent;

  /// No description provided for @checkEmailToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Check your email to confirm your account, then sign in.'**
  String get checkEmailToConfirm;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get invalidEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get passwordTooShort;

  /// No description provided for @welcomeTagline.
  ///
  /// In en, this message translates to:
  /// **'Our tree, our moments, our family.'**
  String get welcomeTagline;

  /// No description provided for @pendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval'**
  String get pendingTitle;

  /// No description provided for @pendingBody.
  ///
  /// In en, this message translates to:
  /// **'A family admin needs to approve your account. Tell them who you are so they can link you to your place in the tree.'**
  String get pendingBody;

  /// No description provided for @claimNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Who are you in the family?'**
  String get claimNoteLabel;

  /// No description provided for @claimNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Aisha, daughter of Musa Bua of Kano'**
  String get claimNoteHint;

  /// No description provided for @suspendedTitle.
  ///
  /// In en, this message translates to:
  /// **'Account suspended'**
  String get suspendedTitle;

  /// No description provided for @suspendedBody.
  ///
  /// In en, this message translates to:
  /// **'Your account has been suspended. Please contact a family admin.'**
  String get suspendedBody;

  /// No description provided for @checkAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get checkAgain;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong: {error}'**
  String errorGeneric(String error);

  /// No description provided for @notConfigured.
  ///
  /// In en, this message translates to:
  /// **'The app is not connected to a server yet. Build it with SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY.'**
  String get notConfigured;

  /// No description provided for @treeEmpty.
  ///
  /// In en, this message translates to:
  /// **'No one is in the family tree yet.'**
  String get treeEmpty;

  /// No description provided for @addFirstPerson.
  ///
  /// In en, this message translates to:
  /// **'Add the first person'**
  String get addFirstPerson;

  /// No description provided for @chooseRoot.
  ///
  /// In en, this message translates to:
  /// **'Start tree from…'**
  String get chooseRoot;

  /// No description provided for @fitToScreen.
  ///
  /// In en, this message translates to:
  /// **'Fit to screen'**
  String get fitToScreen;

  /// No description provided for @expandAll.
  ///
  /// In en, this message translates to:
  /// **'Expand all'**
  String get expandAll;

  /// No description provided for @collapseDeep.
  ///
  /// In en, this message translates to:
  /// **'Collapse lower generations'**
  String get collapseDeep;

  /// No description provided for @hiddenCount.
  ///
  /// In en, this message translates to:
  /// **'+{count}'**
  String hiddenCount(int count);

  /// No description provided for @shownElsewhere.
  ///
  /// In en, this message translates to:
  /// **'Shown elsewhere in the tree'**
  String get shownElsewhere;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, place or branch'**
  String get searchHint;

  /// No description provided for @peopleCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person} other{{count} people}}'**
  String peopleCount(int count);

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No one found'**
  String get noResults;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterLiving.
  ///
  /// In en, this message translates to:
  /// **'Living'**
  String get filterLiving;

  /// No description provided for @filterDeceased.
  ///
  /// In en, this message translates to:
  /// **'Deceased'**
  String get filterDeceased;

  /// No description provided for @lateLabel.
  ///
  /// In en, this message translates to:
  /// **'{sex, select, female{Late} other{Late}}'**
  String lateLabel(String sex);

  /// No description provided for @born.
  ///
  /// In en, this message translates to:
  /// **'Born'**
  String get born;

  /// No description provided for @died.
  ///
  /// In en, this message translates to:
  /// **'Died'**
  String get died;

  /// No description provided for @buried.
  ///
  /// In en, this message translates to:
  /// **'Buried at'**
  String get buried;

  /// No description provided for @branch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get branch;

  /// No description provided for @thisIsYou.
  ///
  /// In en, this message translates to:
  /// **'This is you'**
  String get thisIsYou;

  /// No description provided for @relationshipToYou.
  ///
  /// In en, this message translates to:
  /// **'Relationship to you'**
  String get relationshipToYou;

  /// No description provided for @sectionFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get sectionFamily;

  /// No description provided for @parents.
  ///
  /// In en, this message translates to:
  /// **'Parents'**
  String get parents;

  /// No description provided for @spouses.
  ///
  /// In en, this message translates to:
  /// **'Spouses'**
  String get spouses;

  /// No description provided for @children.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get children;

  /// No description provided for @siblings.
  ///
  /// In en, this message translates to:
  /// **'Siblings'**
  String get siblings;

  /// No description provided for @sectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get sectionAbout;

  /// No description provided for @education.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get education;

  /// No description provided for @work.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get work;

  /// No description provided for @skills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get skills;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @health.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get health;

  /// No description provided for @nothingYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing added yet'**
  String get nothingYet;

  /// No description provided for @addRelative.
  ///
  /// In en, this message translates to:
  /// **'Add relative'**
  String get addRelative;

  /// No description provided for @linkExisting.
  ///
  /// In en, this message translates to:
  /// **'Link someone already in the tree'**
  String get linkExisting;

  /// No description provided for @editPerson.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get editPerson;

  /// No description provided for @suggestEdit.
  ///
  /// In en, this message translates to:
  /// **'Suggest an edit'**
  String get suggestEdit;

  /// No description provided for @deletePerson.
  ///
  /// In en, this message translates to:
  /// **'Remove from tree'**
  String get deletePerson;

  /// No description provided for @confirmDeletePerson.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} and all their links from the tree? This cannot be undone.'**
  String confirmDeletePerson(String name);

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhoto;

  /// No description provided for @viewInTree.
  ///
  /// In en, this message translates to:
  /// **'View in tree'**
  String get viewInTree;

  /// No description provided for @thisIsMe.
  ///
  /// In en, this message translates to:
  /// **'This is me'**
  String get thisIsMe;

  /// No description provided for @thisIsMeSent.
  ///
  /// In en, this message translates to:
  /// **'Sent. An admin will confirm and link your account.'**
  String get thisIsMeSent;

  /// No description provided for @addFather.
  ///
  /// In en, this message translates to:
  /// **'Father'**
  String get addFather;

  /// No description provided for @addMother.
  ///
  /// In en, this message translates to:
  /// **'Mother'**
  String get addMother;

  /// No description provided for @addSpouse.
  ///
  /// In en, this message translates to:
  /// **'Spouse'**
  String get addSpouse;

  /// No description provided for @addSon.
  ///
  /// In en, this message translates to:
  /// **'Son'**
  String get addSon;

  /// No description provided for @addDaughter.
  ///
  /// In en, this message translates to:
  /// **'Daughter'**
  String get addDaughter;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title (e.g. Alhaji, Hajiya, Dr)'**
  String get title;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @middleName.
  ///
  /// In en, this message translates to:
  /// **'Middle name'**
  String get middleName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Surname / family name'**
  String get lastName;

  /// No description provided for @nickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname (lakabi)'**
  String get nickname;

  /// No description provided for @sex.
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get sex;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @birthDate.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get birthDate;

  /// No description provided for @dateApprox.
  ///
  /// In en, this message translates to:
  /// **'Approximate (year only)'**
  String get dateApprox;

  /// No description provided for @birthPlace.
  ///
  /// In en, this message translates to:
  /// **'Place of birth'**
  String get birthPlace;

  /// No description provided for @isLiving.
  ///
  /// In en, this message translates to:
  /// **'Living'**
  String get isLiving;

  /// No description provided for @deathDate.
  ///
  /// In en, this message translates to:
  /// **'Date of death'**
  String get deathDate;

  /// No description provided for @deathPlace.
  ///
  /// In en, this message translates to:
  /// **'Place of death'**
  String get deathPlace;

  /// No description provided for @burialPlace.
  ///
  /// In en, this message translates to:
  /// **'Place of burial'**
  String get burialPlace;

  /// No description provided for @biography.
  ///
  /// In en, this message translates to:
  /// **'Life story / biography'**
  String get biography;

  /// No description provided for @otherParent.
  ///
  /// In en, this message translates to:
  /// **'Other parent'**
  String get otherParent;

  /// No description provided for @otherParentUnknown.
  ///
  /// In en, this message translates to:
  /// **'Not recorded'**
  String get otherParentUnknown;

  /// No description provided for @relationKind.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get relationKind;

  /// No description provided for @kindBiological.
  ///
  /// In en, this message translates to:
  /// **'Biological'**
  String get kindBiological;

  /// No description provided for @kindAdopted.
  ///
  /// In en, this message translates to:
  /// **'Adopted'**
  String get kindAdopted;

  /// No description provided for @kindFoster.
  ///
  /// In en, this message translates to:
  /// **'Foster'**
  String get kindFoster;

  /// No description provided for @kindStep.
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get kindStep;

  /// No description provided for @unionStatus.
  ///
  /// In en, this message translates to:
  /// **'Marriage status'**
  String get unionStatus;

  /// No description provided for @statusMarried.
  ///
  /// In en, this message translates to:
  /// **'Married'**
  String get statusMarried;

  /// No description provided for @statusDivorced.
  ///
  /// In en, this message translates to:
  /// **'Divorced'**
  String get statusDivorced;

  /// No description provided for @statusWidowed.
  ///
  /// In en, this message translates to:
  /// **'Widowed'**
  String get statusWidowed;

  /// No description provided for @statusSeparated.
  ///
  /// In en, this message translates to:
  /// **'Separated'**
  String get statusSeparated;

  /// No description provided for @pickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick date'**
  String get pickDate;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @newPersonTitle.
  ///
  /// In en, this message translates to:
  /// **'Add {relation}'**
  String newPersonTitle(String relation);

  /// No description provided for @newPerson.
  ///
  /// In en, this message translates to:
  /// **'Add person'**
  String get newPerson;

  /// No description provided for @ofPerson.
  ///
  /// In en, this message translates to:
  /// **'of {name}'**
  String ofPerson(String name);

  /// No description provided for @selectPerson.
  ///
  /// In en, this message translates to:
  /// **'Select a person'**
  String get selectPerson;

  /// No description provided for @relationIs.
  ///
  /// In en, this message translates to:
  /// **'{name} is the…'**
  String relationIs(String name);

  /// No description provided for @relationParentOf.
  ///
  /// In en, this message translates to:
  /// **'Parent of this person'**
  String get relationParentOf;

  /// No description provided for @relationChildOf.
  ///
  /// In en, this message translates to:
  /// **'Child of this person'**
  String get relationChildOf;

  /// No description provided for @relationSpouseOf.
  ///
  /// In en, this message translates to:
  /// **'Spouse of this person'**
  String get relationSpouseOf;

  /// No description provided for @sentForApproval.
  ///
  /// In en, this message translates to:
  /// **'Sent to the admins for approval'**
  String get sentForApproval;

  /// No description provided for @coreChangesSent.
  ///
  /// In en, this message translates to:
  /// **'Name, date and life-status changes were sent to the admins for approval.'**
  String get coreChangesSent;

  /// No description provided for @contributionsOff.
  ///
  /// In en, this message translates to:
  /// **'Adding relatives is currently turned off by the admins.'**
  String get contributionsOff;

  /// No description provided for @requestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requestsTitle;

  /// No description provided for @pendingRequests.
  ///
  /// In en, this message translates to:
  /// **'Pending requests'**
  String get pendingRequests;

  /// No description provided for @myRequests.
  ///
  /// In en, this message translates to:
  /// **'My requests'**
  String get myRequests;

  /// No description provided for @noRequests.
  ///
  /// In en, this message translates to:
  /// **'No requests'**
  String get noRequests;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @rejectReason.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get rejectReason;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get statusApproved;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @requestedBy.
  ///
  /// In en, this message translates to:
  /// **'Requested by {name}'**
  String requestedBy(String name);

  /// No description provided for @reqCreatePerson.
  ///
  /// In en, this message translates to:
  /// **'Add {name}'**
  String reqCreatePerson(String name);

  /// No description provided for @reqRelation.
  ///
  /// In en, this message translates to:
  /// **'as {relation} of {other}'**
  String reqRelation(String relation, String other);

  /// No description provided for @reqUpdatePerson.
  ///
  /// In en, this message translates to:
  /// **'Update details of {name}'**
  String reqUpdatePerson(String name);

  /// No description provided for @reqAddParentChild.
  ///
  /// In en, this message translates to:
  /// **'{parent} is a parent of {child}'**
  String reqAddParentChild(String parent, String child);

  /// No description provided for @reqAddUnion.
  ///
  /// In en, this message translates to:
  /// **'{a} and {b} are married'**
  String reqAddUnion(String a, String b);

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// No description provided for @accountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accountsTitle;

  /// No description provided for @pendingAccounts.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval'**
  String get pendingAccounts;

  /// No description provided for @activeAccounts.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeAccounts;

  /// No description provided for @suspendedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get suspendedAccounts;

  /// No description provided for @activate.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get activate;

  /// No description provided for @suspend.
  ///
  /// In en, this message translates to:
  /// **'Suspend'**
  String get suspend;

  /// No description provided for @makeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Make admin'**
  String get makeAdmin;

  /// No description provided for @makeMember.
  ///
  /// In en, this message translates to:
  /// **'Remove admin'**
  String get makeMember;

  /// No description provided for @linkToPerson.
  ///
  /// In en, this message translates to:
  /// **'Link to person'**
  String get linkToPerson;

  /// No description provided for @linkedTo.
  ///
  /// In en, this message translates to:
  /// **'Linked to {name}'**
  String linkedTo(String name);

  /// No description provided for @notLinked.
  ///
  /// In en, this message translates to:
  /// **'Not linked to anyone in the tree'**
  String get notLinked;

  /// No description provided for @wantsToBe.
  ///
  /// In en, this message translates to:
  /// **'Says they are: {name}'**
  String wantsToBe(String name);

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @roleMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get roleMember;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @familyName.
  ///
  /// In en, this message translates to:
  /// **'Family name'**
  String get familyName;

  /// No description provided for @memberContributions.
  ///
  /// In en, this message translates to:
  /// **'Members can add relatives'**
  String get memberContributions;

  /// No description provided for @memberContributionsHelp.
  ///
  /// In en, this message translates to:
  /// **'When on, members can propose new people and relationships. Admins approve each one before it appears in the tree.'**
  String get memberContributionsHelp;

  /// No description provided for @treeRoot.
  ///
  /// In en, this message translates to:
  /// **'Tree starts from'**
  String get treeRoot;

  /// No description provided for @treeRootAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic (eldest ancestor)'**
  String get treeRootAuto;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hausa.
  ///
  /// In en, this message translates to:
  /// **'Hausa'**
  String get hausa;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get myProfile;

  /// No description provided for @institution.
  ///
  /// In en, this message translates to:
  /// **'School / institution'**
  String get institution;

  /// No description provided for @qualification.
  ///
  /// In en, this message translates to:
  /// **'Qualification'**
  String get qualification;

  /// No description provided for @field.
  ///
  /// In en, this message translates to:
  /// **'Field of study'**
  String get field;

  /// No description provided for @startYear.
  ///
  /// In en, this message translates to:
  /// **'Start year'**
  String get startYear;

  /// No description provided for @endYear.
  ///
  /// In en, this message translates to:
  /// **'End year'**
  String get endYear;

  /// No description provided for @jobTitle.
  ///
  /// In en, this message translates to:
  /// **'Occupation / job title'**
  String get jobTitle;

  /// No description provided for @organization.
  ///
  /// In en, this message translates to:
  /// **'Organisation / business'**
  String get organization;

  /// No description provided for @industry.
  ///
  /// In en, this message translates to:
  /// **'Industry'**
  String get industry;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @currentJob.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentJob;

  /// No description provided for @skill.
  ///
  /// In en, this message translates to:
  /// **'Skill'**
  String get skill;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City / town'**
  String get city;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @visibleTo.
  ///
  /// In en, this message translates to:
  /// **'Who can see this'**
  String get visibleTo;

  /// No description provided for @visibleFamily.
  ///
  /// In en, this message translates to:
  /// **'The whole family'**
  String get visibleFamily;

  /// No description provided for @visiblePrivate.
  ///
  /// In en, this message translates to:
  /// **'Only this person and admins'**
  String get visiblePrivate;

  /// No description provided for @bloodGroup.
  ///
  /// In en, this message translates to:
  /// **'Blood group'**
  String get bloodGroup;

  /// No description provided for @genotype.
  ///
  /// In en, this message translates to:
  /// **'Genotype'**
  String get genotype;

  /// No description provided for @conditions.
  ///
  /// In en, this message translates to:
  /// **'Known hereditary or chronic conditions'**
  String get conditions;

  /// No description provided for @healthPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Health details are private unless you choose to share them with the family.'**
  String get healthPrivacyNote;

  /// No description provided for @relSelf.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get relSelf;

  /// No description provided for @relSpouse.
  ///
  /// In en, this message translates to:
  /// **'{sex, select, male{Husband} female{Wife} other{Spouse}}'**
  String relSpouse(String sex);

  /// No description provided for @relParent.
  ///
  /// In en, this message translates to:
  /// **'{sex, select, male{Father} female{Mother} other{Parent}}'**
  String relParent(String sex);

  /// No description provided for @relChild.
  ///
  /// In en, this message translates to:
  /// **'{sex, select, male{Son} female{Daughter} other{Child}}'**
  String relChild(String sex);

  /// No description provided for @relSibling.
  ///
  /// In en, this message translates to:
  /// **'{sex, select, male{Brother} female{Sister} other{Sibling}}'**
  String relSibling(String sex);

  /// No description provided for @relHalfSibling.
  ///
  /// In en, this message translates to:
  /// **'{sex, select, male{Half-brother} female{Half-sister} other{Half-sibling}} ({via, select, male{same father} female{same mother} other{one shared parent}})'**
  String relHalfSibling(String sex, String via);

  /// No description provided for @relGrandparent.
  ///
  /// In en, this message translates to:
  /// **'{greats, plural, =0{Grand} =1{Great-grand} =2{Great-great-grand} other{{greats}× great-grand}}{sex, select, male{father} female{mother} other{parent}}'**
  String relGrandparent(int greats, String sex);

  /// No description provided for @relGrandchild.
  ///
  /// In en, this message translates to:
  /// **'{greats, plural, =0{Grand} =1{Great-grand} =2{Great-great-grand} other{{greats}× great-grand}}{sex, select, male{son} female{daughter} other{child}}'**
  String relGrandchild(int greats, String sex);

  /// No description provided for @relUncleAunt.
  ///
  /// In en, this message translates to:
  /// **'{greats, plural, =0{} =1{Great-} other{{greats}× great-}}{sex, select, male{uncle} female{aunt} other{uncle/aunt}}'**
  String relUncleAunt(int greats, String sex, String side);

  /// No description provided for @relNephewNiece.
  ///
  /// In en, this message translates to:
  /// **'{greats, plural, =0{} =1{Grand-} other{{greats}× great-grand-}}{sex, select, male{nephew} female{niece} other{nephew/niece}}'**
  String relNephewNiece(int greats, String sex);

  /// No description provided for @relCousin.
  ///
  /// In en, this message translates to:
  /// **'{degree, plural, =1{First} =2{Second} other{Distant}} cousin{removed, plural, =0{} =1{ once removed} =2{ twice removed} other{ {removed} times removed}}'**
  String relCousin(int degree, int removed, String sex);

  /// No description provided for @relStepParent.
  ///
  /// In en, this message translates to:
  /// **'{sex, select, male{Stepfather} female{Stepmother} other{Step-parent}}'**
  String relStepParent(String sex);

  /// No description provided for @relStepChild.
  ///
  /// In en, this message translates to:
  /// **'{sex, select, male{Stepson} female{Stepdaughter} other{Stepchild}}'**
  String relStepChild(String sex);

  /// No description provided for @relCoSpouse.
  ///
  /// In en, this message translates to:
  /// **'{sex, select, female{Co-wife} other{Co-spouse}}'**
  String relCoSpouse(String sex);

  /// No description provided for @relParentInLaw.
  ///
  /// In en, this message translates to:
  /// **'{sex, select, male{Father-in-law} female{Mother-in-law} other{Parent-in-law}}'**
  String relParentInLaw(String sex);

  /// No description provided for @relChildInLaw.
  ///
  /// In en, this message translates to:
  /// **'{sex, select, male{Son-in-law} female{Daughter-in-law} other{Child-in-law}}'**
  String relChildInLaw(String sex);

  /// No description provided for @relSiblingInLaw.
  ///
  /// In en, this message translates to:
  /// **'{sex, select, male{Brother-in-law} female{Sister-in-law} other{Sibling-in-law}}'**
  String relSiblingInLaw(String sex);

  /// No description provided for @relByMarriage.
  ///
  /// In en, this message translates to:
  /// **'Related by marriage'**
  String get relByMarriage;

  /// No description provided for @relNone.
  ///
  /// In en, this message translates to:
  /// **'No recorded relation'**
  String get relNone;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @createYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createYourAccount;

  /// No description provided for @privateSpaceNote.
  ///
  /// In en, this message translates to:
  /// **'A private space for the Bua family. New accounts are approved by a family admin.'**
  String get privateSpaceNote;

  /// No description provided for @pendingGreeting.
  ///
  /// In en, this message translates to:
  /// **'Salamu alaikum, {name}. A family admin will approve your account and link you to your place in the tree.'**
  String pendingGreeting(String name);

  /// No description provided for @claimHelp.
  ///
  /// In en, this message translates to:
  /// **'Mention your parents or grandparents so the admin can find you quickly.'**
  String get claimHelp;

  /// No description provided for @stepCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created'**
  String get stepCreated;

  /// No description provided for @stepReview.
  ///
  /// In en, this message translates to:
  /// **'An admin reviews and links you'**
  String get stepReview;

  /// No description provided for @stepExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore the family tree'**
  String get stepExplore;

  /// No description provided for @startingFrom.
  ///
  /// In en, this message translates to:
  /// **'Starting from'**
  String get startingFrom;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @findRelative.
  ///
  /// In en, this message translates to:
  /// **'Find a relative'**
  String get findRelative;

  /// No description provided for @zoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get zoomIn;

  /// No description provided for @zoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get zoomOut;

  /// No description provided for @centreOnMe.
  ///
  /// In en, this message translates to:
  /// **'Centre on me'**
  String get centreOnMe;

  /// No description provided for @yourRelation.
  ///
  /// In en, this message translates to:
  /// **'Your {relation}'**
  String yourRelation(String relation);

  /// No description provided for @sideFather.
  ///
  /// In en, this message translates to:
  /// **'father’s side'**
  String get sideFather;

  /// No description provided for @sideMother.
  ///
  /// In en, this message translates to:
  /// **'mother’s side'**
  String get sideMother;

  /// No description provided for @educationWork.
  ///
  /// In en, this message translates to:
  /// **'Education & work'**
  String get educationWork;

  /// No description provided for @addEducation.
  ///
  /// In en, this message translates to:
  /// **'Add education'**
  String get addEducation;

  /// No description provided for @addWork.
  ///
  /// In en, this message translates to:
  /// **'Add work'**
  String get addWork;

  /// No description provided for @addSkill.
  ///
  /// In en, this message translates to:
  /// **'Add skill'**
  String get addSkill;

  /// No description provided for @sharedWithFamily.
  ///
  /// In en, this message translates to:
  /// **'Shared with family'**
  String get sharedWithFamily;

  /// No description provided for @privateLabel.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get privateLabel;

  /// No description provided for @addingTo.
  ///
  /// In en, this message translates to:
  /// **'Adding to'**
  String get addingTo;

  /// No description provided for @newPersonIs.
  ///
  /// In en, this message translates to:
  /// **'New person is {name}’s…'**
  String newPersonIs(String name);

  /// No description provided for @approvalBanner.
  ///
  /// In en, this message translates to:
  /// **'An admin will review this before it appears in the tree. You’ll see it under More › My requests.'**
  String get approvalBanner;

  /// No description provided for @sendForApproval.
  ///
  /// In en, this message translates to:
  /// **'Send for approval'**
  String get sendForApproval;

  /// No description provided for @approveAndLink.
  ///
  /// In en, this message translates to:
  /// **'Approve & link'**
  String get approveAndLink;

  /// No description provided for @linkSomeoneElse.
  ///
  /// In en, this message translates to:
  /// **'Link someone else'**
  String get linkSomeoneElse;

  /// No description provided for @adminAlwaysOwn.
  ///
  /// In en, this message translates to:
  /// **'Members can always edit their own photo, work and skills'**
  String get adminAlwaysOwn;

  /// No description provided for @adminAlwaysDirect.
  ///
  /// In en, this message translates to:
  /// **'Admins always add and edit directly'**
  String get adminAlwaysDirect;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy.'**
  String get privacyTitle;

  /// No description provided for @privacyNote.
  ///
  /// In en, this message translates to:
  /// **'Only approved family members can open the app. Health details stay private unless the person shares them; admins can always see them.'**
  String get privacyNote;

  /// No description provided for @adminRequestsAccounts.
  ///
  /// In en, this message translates to:
  /// **'Admin: requests & accounts'**
  String get adminRequestsAccounts;

  /// No description provided for @viewMyProfile.
  ///
  /// In en, this message translates to:
  /// **'View my profile'**
  String get viewMyProfile;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @pendingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String pendingCount(int count);

  /// No description provided for @myRequestsHelp.
  ///
  /// In en, this message translates to:
  /// **'Changes you suggest appear in the tree once a family admin approves them.'**
  String get myRequestsHelp;

  /// No description provided for @seeInTree.
  ///
  /// In en, this message translates to:
  /// **'See in the tree'**
  String get seeInTree;

  /// No description provided for @married.
  ///
  /// In en, this message translates to:
  /// **'Married'**
  String get married;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get navEvents;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'Salamu alaikum, {name}'**
  String greeting(String name);

  /// No description provided for @birthdayToday.
  ///
  /// In en, this message translates to:
  /// **'Birthday today'**
  String get birthdayToday;

  /// No description provided for @turnsAge.
  ///
  /// In en, this message translates to:
  /// **'{name} turns {age}'**
  String turnsAge(String name, int age);

  /// No description provided for @sendGreeting.
  ///
  /// In en, this message translates to:
  /// **'Send a greeting'**
  String get sendGreeting;

  /// No description provided for @remembrance.
  ///
  /// In en, this message translates to:
  /// **'Remembrance'**
  String get remembrance;

  /// No description provided for @yearsSincePassed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 year since {name} passed} other{{count} years since {name} passed}}'**
  String yearsSincePassed(int count, String name);

  /// No description provided for @addPrayer.
  ///
  /// In en, this message translates to:
  /// **'Add a prayer'**
  String get addPrayer;

  /// No description provided for @announcement.
  ///
  /// In en, this message translates to:
  /// **'Announcement'**
  String get announcement;

  /// No description provided for @pinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get pinned;

  /// No description provided for @fromAuthor.
  ///
  /// In en, this message translates to:
  /// **'From {name} · {time}'**
  String fromAuthor(String name, String time);

  /// No description provided for @shareMomentPrompt.
  ///
  /// In en, this message translates to:
  /// **'Share a moment with the family…'**
  String get shareMomentPrompt;

  /// No description provided for @maShaAllah.
  ///
  /// In en, this message translates to:
  /// **'Ma sha Allah'**
  String get maShaAllah;

  /// No description provided for @commentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Comment} =1{1 comment} other{{count} comments}}'**
  String commentsCount(int count);

  /// No description provided for @addedPhotosTo.
  ///
  /// In en, this message translates to:
  /// **'Added {count, plural, =1{a photo} other{{count} photos}} to'**
  String addedPhotosTo(int count);

  /// No description provided for @feedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No moments yet. Be the first to share one.'**
  String get feedEmpty;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{n}m'**
  String timeMinutes(int n);

  /// No description provided for @timeHours.
  ///
  /// In en, this message translates to:
  /// **'{n}h'**
  String timeHours(int n);

  /// No description provided for @timeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get timeYesterday;

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{n} days ago'**
  String timeDaysAgo(int n);

  /// No description provided for @postOptions.
  ///
  /// In en, this message translates to:
  /// **'Post options'**
  String get postOptions;

  /// No description provided for @deletePost.
  ///
  /// In en, this message translates to:
  /// **'Delete post'**
  String get deletePost;

  /// No description provided for @confirmDeletePost.
  ///
  /// In en, this message translates to:
  /// **'Delete this post for everyone?'**
  String get confirmDeletePost;

  /// No description provided for @pinToHome.
  ///
  /// In en, this message translates to:
  /// **'Pin to Home'**
  String get pinToHome;

  /// No description provided for @unpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get unpin;

  /// No description provided for @adminsOnly.
  ///
  /// In en, this message translates to:
  /// **'Admins only'**
  String get adminsOnly;

  /// No description provided for @shareAMoment.
  ///
  /// In en, this message translates to:
  /// **'Share a moment'**
  String get shareAMoment;

  /// No description provided for @post.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get post;

  /// No description provided for @onlyFamilyCanSee.
  ///
  /// In en, this message translates to:
  /// **'Only the {family} family can see this'**
  String onlyFamilyCanSee(String family);

  /// No description provided for @whatsHappening.
  ///
  /// In en, this message translates to:
  /// **'What\'s happening?'**
  String get whatsHappening;

  /// No description provided for @addPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add photos'**
  String get addPhotos;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// No description provided for @whosInIt.
  ///
  /// In en, this message translates to:
  /// **'Who\'s in it?'**
  String get whosInIt;

  /// No description provided for @tagFamily.
  ///
  /// In en, this message translates to:
  /// **'Tag family'**
  String get tagFamily;

  /// No description provided for @untag.
  ///
  /// In en, this message translates to:
  /// **'Remove tag'**
  String get untag;

  /// No description provided for @alsoAddToAlbum.
  ///
  /// In en, this message translates to:
  /// **'Also add to album'**
  String get alsoAddToAlbum;

  /// No description provided for @dontAddToAlbum.
  ///
  /// In en, this message translates to:
  /// **'Don\'t add to an album'**
  String get dontAddToAlbum;

  /// No description provided for @dataSaverNote.
  ///
  /// In en, this message translates to:
  /// **'Photos are resized before upload to save data.'**
  String get dataSaverNote;

  /// No description provided for @postEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Write something or add a photo.'**
  String get postEmptyError;

  /// No description provided for @albums.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get albums;

  /// No description provided for @newAlbum.
  ///
  /// In en, this message translates to:
  /// **'New album'**
  String get newAlbum;

  /// No description provided for @albumName.
  ///
  /// In en, this message translates to:
  /// **'Album name'**
  String get albumName;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @photosOfYou.
  ///
  /// In en, this message translates to:
  /// **'Photos of you'**
  String get photosOfYou;

  /// No description provided for @photosTaggedIn.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Photos you\'re tagged in appear here} =1{1 photo you\'re tagged in} other{{count} photos you\'re tagged in}}'**
  String photosTaggedIn(int count);

  /// No description provided for @photoCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No photos yet} =1{1 photo} other{{count} photos}}'**
  String photoCount(int count);

  /// No description provided for @albumsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No albums yet. Start one for a wedding, Sallah or old family photos.'**
  String get albumsEmpty;

  /// No description provided for @everyone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get everyone;

  /// No description provided for @addedByRelatives.
  ///
  /// In en, this message translates to:
  /// **'added by {count, plural, =1{1 relative} other{{count} relatives}}'**
  String addedByRelatives(int count);

  /// No description provided for @noPhotos.
  ///
  /// In en, this message translates to:
  /// **'No photos here yet.'**
  String get noPhotos;

  /// No description provided for @photoXofY.
  ///
  /// In en, this message translates to:
  /// **'{x} of {y}'**
  String photoXofY(int x, int y);

  /// No description provided for @inThisPhoto.
  ///
  /// In en, this message translates to:
  /// **'In this photo'**
  String get inThisPhoto;

  /// No description provided for @tagSomeone.
  ///
  /// In en, this message translates to:
  /// **'Tag someone'**
  String get tagSomeone;

  /// No description provided for @addedBy.
  ///
  /// In en, this message translates to:
  /// **'Added by {name}'**
  String addedBy(String name);

  /// No description provided for @memoriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Share a memory} =1{1 memory} other{{count} memories}}'**
  String memoriesCount(int count);

  /// No description provided for @editDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get editDetails;

  /// No description provided for @caption.
  ///
  /// In en, this message translates to:
  /// **'Caption'**
  String get caption;

  /// No description provided for @yearTaken.
  ///
  /// In en, this message translates to:
  /// **'Year taken'**
  String get yearTaken;

  /// No description provided for @deletePhoto.
  ///
  /// In en, this message translates to:
  /// **'Delete photo'**
  String get deletePhoto;

  /// No description provided for @confirmDeletePhoto.
  ///
  /// In en, this message translates to:
  /// **'Delete this photo?'**
  String get confirmDeletePhoto;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @writeComment.
  ///
  /// In en, this message translates to:
  /// **'Write a comment…'**
  String get writeComment;

  /// No description provided for @noCommentsYet.
  ///
  /// In en, this message translates to:
  /// **'No comments yet.'**
  String get noCommentsYet;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @newLabel.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newLabel;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @announcements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get announcements;

  /// No description provided for @past.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get past;

  /// No description provided for @latestAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Latest announcements'**
  String get latestAnnouncements;

  /// No description provided for @noUpcomingEvents.
  ///
  /// In en, this message translates to:
  /// **'No upcoming events.'**
  String get noUpcomingEvents;

  /// No description provided for @noPastEvents.
  ///
  /// In en, this message translates to:
  /// **'No past events.'**
  String get noPastEvents;

  /// No description provided for @noAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'No announcements yet.'**
  String get noAnnouncements;

  /// No description provided for @youreGoing.
  ///
  /// In en, this message translates to:
  /// **'You\'re going'**
  String get youreGoing;

  /// No description provided for @youSaidMaybe.
  ///
  /// In en, this message translates to:
  /// **'You said maybe'**
  String get youSaidMaybe;

  /// No description provided for @youCantGo.
  ///
  /// In en, this message translates to:
  /// **'You can\'t go'**
  String get youCantGo;

  /// No description provided for @replyNeeded.
  ///
  /// In en, this message translates to:
  /// **'Reply needed'**
  String get replyNeeded;

  /// No description provided for @goingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} going'**
  String goingCount(int count);

  /// No description provided for @maybeCount.
  ///
  /// In en, this message translates to:
  /// **'{count} maybe'**
  String maybeCount(int count);

  /// No description provided for @eventCategory.
  ///
  /// In en, this message translates to:
  /// **'{category, select, naming{Naming ceremony} wedding{Wedding} meeting{Family meeting} condolence{Condolence} graduation{Graduation} other{Event}}'**
  String eventCategory(String category);

  /// No description provided for @hostedBy.
  ///
  /// In en, this message translates to:
  /// **'Hosted by {name}'**
  String hostedBy(String name);

  /// No description provided for @addToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Add to calendar'**
  String get addToCalendar;

  /// No description provided for @directions.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get directions;

  /// No description provided for @areYouComing.
  ///
  /// In en, this message translates to:
  /// **'Are you coming?'**
  String get areYouComing;

  /// No description provided for @rsvpGoing.
  ///
  /// In en, this message translates to:
  /// **'Going'**
  String get rsvpGoing;

  /// No description provided for @rsvpMaybe.
  ///
  /// In en, this message translates to:
  /// **'Maybe'**
  String get rsvpMaybe;

  /// No description provided for @rsvpNo.
  ///
  /// In en, this message translates to:
  /// **'Can\'t go'**
  String get rsvpNo;

  /// No description provided for @bringingOthers.
  ///
  /// In en, this message translates to:
  /// **'Bringing others with you'**
  String get bringingOthers;

  /// No description provided for @oneFewer.
  ///
  /// In en, this message translates to:
  /// **'One fewer'**
  String get oneFewer;

  /// No description provided for @oneMore.
  ///
  /// In en, this message translates to:
  /// **'One more'**
  String get oneMore;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @wishes.
  ///
  /// In en, this message translates to:
  /// **'Wishes'**
  String get wishes;

  /// No description provided for @writeWish.
  ///
  /// In en, this message translates to:
  /// **'Write a wish…'**
  String get writeWish;

  /// No description provided for @deleteEvent.
  ///
  /// In en, this message translates to:
  /// **'Delete event'**
  String get deleteEvent;

  /// No description provided for @confirmDeleteEvent.
  ///
  /// In en, this message translates to:
  /// **'Delete this event for everyone?'**
  String get confirmDeleteEvent;

  /// No description provided for @newPost.
  ///
  /// In en, this message translates to:
  /// **'New post'**
  String get newPost;

  /// No description provided for @event.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get event;

  /// No description provided for @eventType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get eventType;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @place.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get place;

  /// No description provided for @addressOrArea.
  ///
  /// In en, this message translates to:
  /// **'Address or area'**
  String get addressOrArea;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @askReply.
  ///
  /// In en, this message translates to:
  /// **'Ask people to reply'**
  String get askReply;

  /// No description provided for @askReplySub.
  ///
  /// In en, this message translates to:
  /// **'Going · Maybe · Can\'t go'**
  String get askReplySub;

  /// No description provided for @postEvent.
  ///
  /// In en, this message translates to:
  /// **'Post event'**
  String get postEvent;

  /// No description provided for @postAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Post announcement'**
  String get postAnnouncement;

  /// No description provided for @announcementHint.
  ///
  /// In en, this message translates to:
  /// **'Write the announcement…'**
  String get announcementHint;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Add a title.'**
  String get titleRequired;

  /// No description provided for @family.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get family;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllRead;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up.'**
  String get noNotifications;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @earlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get earlier;

  /// No description provided for @notifEvent.
  ///
  /// In en, this message translates to:
  /// **'New event: {title}'**
  String notifEvent(String title);

  /// No description provided for @notifBirthday.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s birthday today ({age})'**
  String notifBirthday(String name, int age);

  /// No description provided for @notifEventReminder.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow: {title}'**
  String notifEventReminder(String title);

  /// No description provided for @notifTaggedPost.
  ///
  /// In en, this message translates to:
  /// **'You were tagged in a moment'**
  String get notifTaggedPost;

  /// No description provided for @notifTaggedPhoto.
  ///
  /// In en, this message translates to:
  /// **'You were tagged in a photo'**
  String get notifTaggedPhoto;

  /// No description provided for @notifComment.
  ///
  /// In en, this message translates to:
  /// **'New comment: “{body}”'**
  String notifComment(String body);

  /// No description provided for @notificationsSms.
  ///
  /// In en, this message translates to:
  /// **'Notifications & SMS'**
  String get notificationsSms;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'0803 123 4567'**
  String get phoneHint;

  /// No description provided for @phoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number.'**
  String get phoneInvalid;

  /// No description provided for @smsOptIn.
  ///
  /// In en, this message translates to:
  /// **'Get SMS on this phone'**
  String get smsOptIn;

  /// No description provided for @smsOptInSub.
  ///
  /// In en, this message translates to:
  /// **'Important family news by text message, even without data.'**
  String get smsOptInSub;

  /// No description provided for @smsBirthdays.
  ///
  /// In en, this message translates to:
  /// **'Birthday reminders'**
  String get smsBirthdays;

  /// No description provided for @smsBirthdaysSub.
  ///
  /// In en, this message translates to:
  /// **'A text in the morning when it\'s a relative\'s birthday.'**
  String get smsBirthdaysSub;

  /// No description provided for @smsEvents.
  ///
  /// In en, this message translates to:
  /// **'Events and announcements'**
  String get smsEvents;

  /// No description provided for @smsEventsSub.
  ///
  /// In en, this message translates to:
  /// **'Events and announcements sent by admins, and a reminder the day before events you\'re going to.'**
  String get smsEventsSub;

  /// No description provided for @inAppNote.
  ///
  /// In en, this message translates to:
  /// **'You always see notifications in the app, under the bell on Home.'**
  String get inAppNote;

  /// No description provided for @smsOffNote.
  ///
  /// In en, this message translates to:
  /// **'SMS is not switched on for the family yet. An admin can turn it on in Admin › Settings.'**
  String get smsOffNote;

  /// No description provided for @smsTitle.
  ///
  /// In en, this message translates to:
  /// **'SMS (Termii)'**
  String get smsTitle;

  /// No description provided for @smsEnable.
  ///
  /// In en, this message translates to:
  /// **'Send SMS to the family'**
  String get smsEnable;

  /// No description provided for @smsEnableSub.
  ///
  /// In en, this message translates to:
  /// **'Uses your Termii balance. Members choose what they receive.'**
  String get smsEnableSub;

  /// No description provided for @senderId.
  ///
  /// In en, this message translates to:
  /// **'Sender ID'**
  String get senderId;

  /// No description provided for @senderIdHint.
  ///
  /// In en, this message translates to:
  /// **'Registered with Termii, 3–11 letters or digits.'**
  String get senderIdHint;

  /// No description provided for @smsRoute.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get smsRoute;

  /// No description provided for @routeGeneric.
  ///
  /// In en, this message translates to:
  /// **'Generic'**
  String get routeGeneric;

  /// No description provided for @routeDnd.
  ///
  /// In en, this message translates to:
  /// **'DND (also reaches DND numbers; Termii must activate it)'**
  String get routeDnd;

  /// No description provided for @apiKey.
  ///
  /// In en, this message translates to:
  /// **'Termii API key'**
  String get apiKey;

  /// No description provided for @apiKeySaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get apiKeySaved;

  /// No description provided for @apiKeyMissing.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get apiKeyMissing;

  /// No description provided for @apiKeyNote.
  ///
  /// In en, this message translates to:
  /// **'Find it in your Termii dashboard. It is stored encrypted and never shown again.'**
  String get apiKeyNote;

  /// No description provided for @baseUrl.
  ///
  /// In en, this message translates to:
  /// **'API base URL (optional)'**
  String get baseUrl;

  /// No description provided for @baseUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Shown in your Termii dashboard. Leave empty for https://api.ng.termii.com'**
  String get baseUrlHint;

  /// No description provided for @sendTestSms.
  ///
  /// In en, this message translates to:
  /// **'Send a test SMS to me'**
  String get sendTestSms;

  /// No description provided for @testSmsSent.
  ///
  /// In en, this message translates to:
  /// **'Test SMS sent. It should arrive within a minute.'**
  String get testSmsSent;

  /// No description provided for @smsStats.
  ///
  /// In en, this message translates to:
  /// **'{subscribers} subscribed · {sent} sent this week · {failed} failed'**
  String smsStats(int subscribers, int sent, int failed);

  /// No description provided for @smsQueued.
  ///
  /// In en, this message translates to:
  /// **'{count} waiting to send'**
  String smsQueued(int count);

  /// No description provided for @lastError.
  ///
  /// In en, this message translates to:
  /// **'Last error: {error}'**
  String lastError(String error);

  /// No description provided for @smsSetupSteps.
  ///
  /// In en, this message translates to:
  /// **'1. Get an API key and a sender ID from Termii. 2. Save them here. 3. Switch SMS on and send yourself a test.'**
  String get smsSetupSteps;

  /// No description provided for @notifyFamily.
  ///
  /// In en, this message translates to:
  /// **'Notify the whole family'**
  String get notifyFamily;

  /// No description provided for @notifyFamilySub.
  ///
  /// In en, this message translates to:
  /// **'In the app'**
  String get notifyFamilySub;

  /// No description provided for @alsoSms.
  ///
  /// In en, this message translates to:
  /// **'Also send SMS'**
  String get alsoSms;

  /// No description provided for @alsoSmsSub.
  ///
  /// In en, this message translates to:
  /// **'Admins only · uses SMS credit'**
  String get alsoSmsSub;

  /// No description provided for @whoCanHelp.
  ///
  /// In en, this message translates to:
  /// **'Who can help?'**
  String get whoCanHelp;

  /// No description provided for @whoCanHelpSub.
  ///
  /// In en, this message translates to:
  /// **'Skills and experience across the family'**
  String get whoCanHelpSub;

  /// No description provided for @searchSkills.
  ///
  /// In en, this message translates to:
  /// **'Search skills, jobs or studies'**
  String get searchSkills;

  /// No description provided for @helpCategory.
  ///
  /// In en, this message translates to:
  /// **'{category, select, health{Health} law{Law} trades{Trades} teaching{Teaching} business{Business} engineering{Engineering} tech{Tech} islamic{Islamic studies} other{Other}}'**
  String helpCategory(String category);

  /// No description provided for @relativesIn.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No one in {category} yet} =1{1 relative in {category}} other{{count} relatives in {category}}}'**
  String relativesIn(int count, String category);

  /// No description provided for @relativesMatching.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No one matches “{query}”} =1{1 relative matches “{query}”} other{{count} relatives match “{query}”}}'**
  String relativesMatching(int count, String query);

  /// No description provided for @relativesWithSkills.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No skills or work listed yet} =1{1 relative with skills or work listed} other{{count} relatives with skills or work listed}}'**
  String relativesWithSkills(int count);

  /// No description provided for @helpEmptyNote.
  ///
  /// In en, this message translates to:
  /// **'Add your work, studies and skills on your profile so relatives can find you.'**
  String get helpEmptyNote;

  /// No description provided for @contactNote.
  ///
  /// In en, this message translates to:
  /// **'Call buttons appear only for people who share their contact with the family.'**
  String get contactNote;

  /// No description provided for @callPerson.
  ///
  /// In en, this message translates to:
  /// **'Call {name}'**
  String callPerson(String name);

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @bloodDonors.
  ///
  /// In en, this message translates to:
  /// **'Blood donors'**
  String get bloodDonors;

  /// No description provided for @requestBlood.
  ///
  /// In en, this message translates to:
  /// **'Request blood'**
  String get requestBlood;

  /// No description provided for @urgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgent;

  /// No description provided for @pintsFor.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 pint for {name}} other{{count} pints for {name}}}'**
  String pintsFor(int count, String name);

  /// No description provided for @askedBy.
  ///
  /// In en, this message translates to:
  /// **'asked by {name}'**
  String askedBy(String name);

  /// No description provided for @iCanDonate.
  ///
  /// In en, this message translates to:
  /// **'I can donate'**
  String get iCanDonate;

  /// No description provided for @youOffered.
  ///
  /// In en, this message translates to:
  /// **'You offered'**
  String get youOffered;

  /// No description provided for @offersSoFar.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No one has offered yet.} =1{1 relative has offered so far.} other{{count} relatives have offered so far.}}'**
  String offersSoFar(int count);

  /// No description provided for @closeRequest.
  ///
  /// In en, this message translates to:
  /// **'Close request'**
  String get closeRequest;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @notCompatible.
  ///
  /// In en, this message translates to:
  /// **'Your blood group ({group}) can\'t be given for this request.'**
  String notCompatible(String group);

  /// No description provided for @matchesFor.
  ///
  /// In en, this message translates to:
  /// **'Matches for'**
  String get matchesFor;

  /// No description provided for @canReceiveFrom.
  ///
  /// In en, this message translates to:
  /// **'{group} (can receive {groups})'**
  String canReceiveFrom(String group, String groups);

  /// No description provided for @noDonors.
  ///
  /// In en, this message translates to:
  /// **'No donors with a matching blood group have joined yet.'**
  String get noDonors;

  /// No description provided for @onDonorList.
  ///
  /// In en, this message translates to:
  /// **'You\'re on the donor list'**
  String get onDonorList;

  /// No description provided for @changeInHealth.
  ///
  /// In en, this message translates to:
  /// **'Change in your health details'**
  String get changeInHealth;

  /// No description provided for @joinDonorList.
  ///
  /// In en, this message translates to:
  /// **'Join the donor list'**
  String get joinDonorList;

  /// No description provided for @joinDonorListSub.
  ///
  /// In en, this message translates to:
  /// **'Add your blood group in your health details and tick “Blood donor”.'**
  String get joinDonorListSub;

  /// No description provided for @donorPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Only relatives who opted in appear here, showing just their blood group and town. Genotype and other health details are never shown.'**
  String get donorPrivacy;

  /// No description provided for @bloodDonorOptIn.
  ///
  /// In en, this message translates to:
  /// **'List me as a blood donor'**
  String get bloodDonorOptIn;

  /// No description provided for @bloodDonorOptInSub.
  ///
  /// In en, this message translates to:
  /// **'Relatives see only your blood group and town.'**
  String get bloodDonorOptInSub;

  /// No description provided for @bloodDonorLabel.
  ///
  /// In en, this message translates to:
  /// **'Blood donor'**
  String get bloodDonorLabel;

  /// No description provided for @bloodGroupNeeded.
  ///
  /// In en, this message translates to:
  /// **'Blood group needed'**
  String get bloodGroupNeeded;

  /// No description provided for @units.
  ///
  /// In en, this message translates to:
  /// **'Pints'**
  String get units;

  /// No description provided for @patient.
  ///
  /// In en, this message translates to:
  /// **'Who is it for?'**
  String get patient;

  /// No description provided for @patientHint.
  ///
  /// In en, this message translates to:
  /// **'Pick from the family, or type a name'**
  String get patientHint;

  /// No description provided for @pickFromFamily.
  ///
  /// In en, this message translates to:
  /// **'Pick from the family'**
  String get pickFromFamily;

  /// No description provided for @hospital.
  ///
  /// In en, this message translates to:
  /// **'Hospital'**
  String get hospital;

  /// No description provided for @contactPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone to call'**
  String get contactPhone;

  /// No description provided for @noteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteOptional;

  /// No description provided for @bloodRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Request posted. Matching donors have been told.'**
  String get bloodRequestSent;

  /// No description provided for @notifBloodRequest.
  ///
  /// In en, this message translates to:
  /// **'{group} blood needed for {patient} at {hospital}'**
  String notifBloodRequest(String group, String patient, String hospital);

  /// No description provided for @notifBloodOffer.
  ///
  /// In en, this message translates to:
  /// **'A relative can donate blood ({group})'**
  String notifBloodOffer(String group);

  /// No description provided for @memorialPage.
  ///
  /// In en, this message translates to:
  /// **'Memorial page'**
  String get memorialPage;

  /// No description provided for @inLovingMemory.
  ///
  /// In en, this message translates to:
  /// **'In loving memory'**
  String get inLovingMemory;

  /// No description provided for @memorialPrayer.
  ///
  /// In en, this message translates to:
  /// **'{sex, select, female{Allah ya jikanta da rahama} other{Allah ya jikansa da rahama}}'**
  String memorialPrayer(String sex);

  /// No description provided for @lifeOf.
  ///
  /// In en, this message translates to:
  /// **'{sex, select, male{His life} female{Her life} other{Their life}}'**
  String lifeOf(String sex);

  /// No description provided for @noLifeStory.
  ///
  /// In en, this message translates to:
  /// **'No life story yet. Family can add it on the profile.'**
  String get noLifeStory;

  /// No description provided for @seeFullProfile.
  ///
  /// In en, this message translates to:
  /// **'See full profile and family'**
  String get seeFullProfile;

  /// No description provided for @allPhotos.
  ///
  /// In en, this message translates to:
  /// **'All {count}'**
  String allPhotos(int count);

  /// No description provided for @prayersMemories.
  ///
  /// In en, this message translates to:
  /// **'Prayers & memories · {count}'**
  String prayersMemories(int count);

  /// No description provided for @addPrayerMemory.
  ///
  /// In en, this message translates to:
  /// **'Add a prayer or memory…'**
  String get addPrayerMemory;

  /// No description provided for @noMemoriesYet.
  ///
  /// In en, this message translates to:
  /// **'Be the first to share a prayer or memory.'**
  String get noMemoriesYet;

  /// No description provided for @remindMeEvery.
  ///
  /// In en, this message translates to:
  /// **'Remind me every {date}'**
  String remindMeEvery(String date);

  /// No description provided for @remindMeEverySub.
  ///
  /// In en, this message translates to:
  /// **'A gentle remembrance notification'**
  String get remindMeEverySub;

  /// No description provided for @notifRemembrance.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 year since {name} passed} other{{count} years since {name} passed}}'**
  String notifRemembrance(int count, String name);

  /// No description provided for @notifMemory.
  ///
  /// In en, this message translates to:
  /// **'New memory of {name}: “{body}”'**
  String notifMemory(String name, String body);

  /// No description provided for @howRelated.
  ///
  /// In en, this message translates to:
  /// **'How are we related?'**
  String get howRelated;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @swap.
  ///
  /// In en, this message translates to:
  /// **'Swap'**
  String get swap;

  /// No description provided for @pickSomeone.
  ///
  /// In en, this message translates to:
  /// **'Pick someone'**
  String get pickSomeone;

  /// No description provided for @relatedIsYour.
  ///
  /// In en, this message translates to:
  /// **'{name} is your'**
  String relatedIsYour(String name);

  /// No description provided for @relatedIsOf.
  ///
  /// In en, this message translates to:
  /// **'{name} is {other}\'s'**
  String relatedIsOf(String name, String other);

  /// No description provided for @pathChildOf.
  ///
  /// In en, this message translates to:
  /// **'{sex, select, male{son of} female{daughter of} other{child of}}'**
  String pathChildOf(String sex);

  /// No description provided for @pathParentOf.
  ///
  /// In en, this message translates to:
  /// **'{sex, select, male{father of} female{mother of} other{parent of}}'**
  String pathParentOf(String sex);

  /// No description provided for @pathSpouseOf.
  ///
  /// In en, this message translates to:
  /// **'{sex, select, male{husband of} female{wife of} other{spouse of}}'**
  String pathSpouseOf(String sex);

  /// No description provided for @pathShared.
  ///
  /// In en, this message translates to:
  /// **'Shared {relation}'**
  String pathShared(String relation);

  /// No description provided for @youSuffix.
  ///
  /// In en, this message translates to:
  /// **'{name} (you)'**
  String youSuffix(String name);

  /// No description provided for @showBothInTree.
  ///
  /// In en, this message translates to:
  /// **'Show in the tree'**
  String get showBothInTree;

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'No connection is recorded in the tree yet.'**
  String get notConnected;

  /// No description provided for @sameDistantRelative.
  ///
  /// In en, this message translates to:
  /// **'Relative'**
  String get sameDistantRelative;

  /// No description provided for @tapToLoad.
  ///
  /// In en, this message translates to:
  /// **'Tap to load photo'**
  String get tapToLoad;

  /// No description provided for @remindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Birthdays & remembrance'**
  String get remindersTitle;

  /// No description provided for @todayDate.
  ///
  /// In en, this message translates to:
  /// **'Today · {date}'**
  String todayDate(String date);

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @comingUp.
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get comingUp;

  /// No description provided for @yearsMarried.
  ///
  /// In en, this message translates to:
  /// **'{names} · {count, plural, =1{1 year married} other{{count} years married}}'**
  String yearsMarried(String names, int count);

  /// No description provided for @kindBirthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get kindBirthday;

  /// No description provided for @kindWedding.
  ///
  /// In en, this message translates to:
  /// **'Wedding anniversary'**
  String get kindWedding;

  /// No description provided for @greet.
  ///
  /// In en, this message translates to:
  /// **'Greet'**
  String get greet;

  /// No description provided for @pray.
  ///
  /// In en, this message translates to:
  /// **'Pray'**
  String get pray;

  /// No description provided for @remindersNote.
  ///
  /// In en, this message translates to:
  /// **'Remembrance dates come from recorded dates of death. Birthdays show only for living relatives.'**
  String get remindersNote;

  /// No description provided for @nothingComingUp.
  ///
  /// In en, this message translates to:
  /// **'Nothing in the next month.'**
  String get nothingComingUp;

  /// No description provided for @editMyDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit my details'**
  String get editMyDetails;

  /// No description provided for @nameDatesNote.
  ///
  /// In en, this message translates to:
  /// **'Name & dates:'**
  String get nameDatesNote;

  /// No description provided for @askAnAdmin.
  ///
  /// In en, this message translates to:
  /// **'ask an admin'**
  String get askAnAdmin;

  /// No description provided for @aboutMe.
  ///
  /// In en, this message translates to:
  /// **'About me'**
  String get aboutMe;

  /// No description provided for @myStory.
  ///
  /// In en, this message translates to:
  /// **'My story'**
  String get myStory;

  /// No description provided for @whoSeesContact.
  ///
  /// In en, this message translates to:
  /// **'Who can see my contact?'**
  String get whoSeesContact;

  /// No description provided for @whoSeesHealth.
  ///
  /// In en, this message translates to:
  /// **'Who can see my health details?'**
  String get whoSeesHealth;

  /// No description provided for @wholeFamily.
  ///
  /// In en, this message translates to:
  /// **'Whole family'**
  String get wholeFamily;

  /// No description provided for @onlyMeAdmins.
  ///
  /// In en, this message translates to:
  /// **'Only me & admins'**
  String get onlyMeAdmins;

  /// No description provided for @notLinkedEdit.
  ///
  /// In en, this message translates to:
  /// **'Your account isn\'t linked to your place in the tree yet. An admin can link it.'**
  String get notLinkedEdit;

  /// No description provided for @settingsScreen.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsScreen;

  /// No description provided for @languageHarshe.
  ///
  /// In en, this message translates to:
  /// **'Language · Harshe'**
  String get languageHarshe;

  /// No description provided for @dataSaver.
  ///
  /// In en, this message translates to:
  /// **'Data saver'**
  String get dataSaver;

  /// No description provided for @tapToLoadPhotos.
  ///
  /// In en, this message translates to:
  /// **'Load photos only when I tap them'**
  String get tapToLoadPhotos;

  /// No description provided for @tapToLoadPhotosSub.
  ///
  /// In en, this message translates to:
  /// **'Saves mobile data on this phone'**
  String get tapToLoadPhotosSub;

  /// No description provided for @shrinkUploads.
  ///
  /// In en, this message translates to:
  /// **'Shrink photos before upload'**
  String get shrinkUploads;

  /// No description provided for @shrinkUploadsSub.
  ///
  /// In en, this message translates to:
  /// **'Uses up to 80% less data'**
  String get shrinkUploadsSub;

  /// No description provided for @notifyMeAbout.
  ///
  /// In en, this message translates to:
  /// **'Notify me about'**
  String get notifyMeAbout;

  /// No description provided for @notifEventsAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Announcements & events'**
  String get notifEventsAnnouncements;

  /// No description provided for @notifBirthdaysRemembrance.
  ///
  /// In en, this message translates to:
  /// **'Birthdays & remembrance'**
  String get notifBirthdaysRemembrance;

  /// No description provided for @notifTagged.
  ///
  /// In en, this message translates to:
  /// **'When I\'m tagged in photos'**
  String get notifTagged;

  /// No description provided for @notifCommentsMine.
  ///
  /// In en, this message translates to:
  /// **'Comments on my posts'**
  String get notifCommentsMine;

  /// No description provided for @urgentBlood.
  ///
  /// In en, this message translates to:
  /// **'Urgent blood requests'**
  String get urgentBlood;

  /// No description provided for @alwaysOn.
  ///
  /// In en, this message translates to:
  /// **'Always on'**
  String get alwaysOn;

  /// No description provided for @privacyOfMyDetails.
  ///
  /// In en, this message translates to:
  /// **'Privacy of my details'**
  String get privacyOfMyDetails;

  /// No description provided for @welfareFund.
  ///
  /// In en, this message translates to:
  /// **'Welfare fund'**
  String get welfareFund;

  /// No description provided for @fundBalance.
  ///
  /// In en, this message translates to:
  /// **'Fund balance'**
  String get fundBalance;

  /// No description provided for @treasurerLine.
  ///
  /// In en, this message translates to:
  /// **'Treasurer: {names} · updated {time}'**
  String treasurerLine(String names, String time);

  /// No description provided for @treasurer.
  ///
  /// In en, this message translates to:
  /// **'Treasurer'**
  String get treasurer;

  /// No description provided for @makeTreasurer.
  ///
  /// In en, this message translates to:
  /// **'Make treasurer'**
  String get makeTreasurer;

  /// No description provided for @removeTreasurer.
  ///
  /// In en, this message translates to:
  /// **'Remove as treasurer'**
  String get removeTreasurer;

  /// No description provided for @contribute.
  ///
  /// In en, this message translates to:
  /// **'Contribute'**
  String get contribute;

  /// No description provided for @askForSupport.
  ///
  /// In en, this message translates to:
  /// **'Ask for support'**
  String get askForSupport;

  /// No description provided for @openCauses.
  ///
  /// In en, this message translates to:
  /// **'Open causes'**
  String get openCauses;

  /// No description provided for @raisedOf.
  ///
  /// In en, this message translates to:
  /// **'{raised} of {target}'**
  String raisedOf(String raised, String target);

  /// No description provided for @contributorsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No contributors yet} =1{1 contributor} other{{count} contributors}}'**
  String contributorsCount(int count);

  /// No description provided for @closesOn.
  ///
  /// In en, this message translates to:
  /// **'closes {date}'**
  String closesOn(String date);

  /// No description provided for @fundNote.
  ///
  /// In en, this message translates to:
  /// **'Money is never handled in the app. You pay the family account or the treasurer directly, record it here, and the treasurer confirms it.'**
  String get fundNote;

  /// No description provided for @howToPay.
  ///
  /// In en, this message translates to:
  /// **'How to pay'**
  String get howToPay;

  /// No description provided for @bank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get bank;

  /// No description provided for @accountNumber.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountNumber;

  /// No description provided for @accountName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get accountName;

  /// No description provided for @copyAccountNumber.
  ///
  /// In en, this message translates to:
  /// **'Copy account number'**
  String get copyAccountNumber;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @noAccountYet.
  ///
  /// In en, this message translates to:
  /// **'The treasurer hasn\'t added the account details yet. You can still pay the treasurer in cash.'**
  String get noAccountYet;

  /// No description provided for @recordContribution.
  ///
  /// In en, this message translates to:
  /// **'Record your contribution'**
  String get recordContribution;

  /// No description provided for @amountNaira.
  ///
  /// In en, this message translates to:
  /// **'Amount (₦)'**
  String get amountNaira;

  /// No description provided for @payTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get payTransfer;

  /// No description provided for @payCash.
  ///
  /// In en, this message translates to:
  /// **'Cash to treasurer'**
  String get payCash;

  /// No description provided for @payMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile money'**
  String get payMobile;

  /// No description provided for @attachReceipt.
  ///
  /// In en, this message translates to:
  /// **'Attach receipt (optional)'**
  String get attachReceipt;

  /// No description provided for @receiptAttached.
  ///
  /// In en, this message translates to:
  /// **'Receipt attached'**
  String get receiptAttached;

  /// No description provided for @showMyName.
  ///
  /// In en, this message translates to:
  /// **'Show my name on the contributors list'**
  String get showMyName;

  /// No description provided for @recordContributionButton.
  ///
  /// In en, this message translates to:
  /// **'Record contribution'**
  String get recordContributionButton;

  /// No description provided for @contributionNote.
  ///
  /// In en, this message translates to:
  /// **'The treasurer confirms each contribution. Amounts are private to you and the committee.'**
  String get contributionNote;

  /// No description provided for @contributionRecorded.
  ///
  /// In en, this message translates to:
  /// **'Recorded. The treasurer will confirm it.'**
  String get contributionRecorded;

  /// No description provided for @amountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount.'**
  String get amountInvalid;

  /// No description provided for @generalFund.
  ///
  /// In en, this message translates to:
  /// **'General fund'**
  String get generalFund;

  /// No description provided for @contributeToFund.
  ///
  /// In en, this message translates to:
  /// **'Contribute to the fund'**
  String get contributeToFund;

  /// No description provided for @myContributions.
  ///
  /// In en, this message translates to:
  /// **'My contributions'**
  String get myContributions;

  /// No description provided for @contribPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the treasurer'**
  String get contribPending;

  /// No description provided for @contribConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get contribConfirmed;

  /// No description provided for @contribRejected.
  ///
  /// In en, this message translates to:
  /// **'Not confirmed'**
  String get contribRejected;

  /// No description provided for @toConfirm.
  ///
  /// In en, this message translates to:
  /// **'To confirm · {count}'**
  String toConfirm(int count);

  /// No description provided for @confirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmAction;

  /// No description provided for @notReceived.
  ///
  /// In en, this message translates to:
  /// **'Not received'**
  String get notReceived;

  /// No description provided for @viewReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get viewReceipt;

  /// No description provided for @supportRequests.
  ///
  /// In en, this message translates to:
  /// **'Support requests'**
  String get supportRequests;

  /// No description provided for @openCause.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openCause;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @closeCause.
  ///
  /// In en, this message translates to:
  /// **'Close cause'**
  String get closeCause;

  /// No description provided for @newCause.
  ///
  /// In en, this message translates to:
  /// **'New cause'**
  String get newCause;

  /// No description provided for @causeTitle.
  ///
  /// In en, this message translates to:
  /// **'What is it for?'**
  String get causeTitle;

  /// No description provided for @targetAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount needed (₦)'**
  String get targetAmount;

  /// No description provided for @closesOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Closes on (optional)'**
  String get closesOnLabel;

  /// No description provided for @askSupportNote.
  ///
  /// In en, this message translates to:
  /// **'Your request goes to the treasurer and admins only. If they open it, the family can contribute.'**
  String get askSupportNote;

  /// No description provided for @requestSent.
  ///
  /// In en, this message translates to:
  /// **'Sent to the treasurer and admins.'**
  String get requestSent;

  /// No description provided for @recordPayout.
  ///
  /// In en, this message translates to:
  /// **'Record support paid'**
  String get recordPayout;

  /// No description provided for @forCause.
  ///
  /// In en, this message translates to:
  /// **'For'**
  String get forCause;

  /// No description provided for @editAccount.
  ///
  /// In en, this message translates to:
  /// **'Edit account details'**
  String get editAccount;

  /// No description provided for @openingBalance.
  ///
  /// In en, this message translates to:
  /// **'Money already in the fund (₦)'**
  String get openingBalance;

  /// No description provided for @waitingReview.
  ///
  /// In en, this message translates to:
  /// **'Waiting for review'**
  String get waitingReview;

  /// No description provided for @notifFundContribution.
  ///
  /// In en, this message translates to:
  /// **'New contribution to confirm: {amount}'**
  String notifFundContribution(String amount);

  /// No description provided for @notifFundConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Your contribution of {amount} was confirmed. Thank you!'**
  String notifFundConfirmed(String amount);

  /// No description provided for @notifFundRequest.
  ///
  /// In en, this message translates to:
  /// **'Support requested: {title}'**
  String notifFundRequest(String title);

  /// No description provided for @mentorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Mentors & scholarships'**
  String get mentorsTitle;

  /// No description provided for @tabMentors.
  ///
  /// In en, this message translates to:
  /// **'Mentors'**
  String get tabMentors;

  /// No description provided for @tabStudents.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get tabStudents;

  /// No description provided for @tabOpportunities.
  ///
  /// In en, this message translates to:
  /// **'Opportunities'**
  String get tabOpportunities;

  /// No description provided for @newOpportunity.
  ///
  /// In en, this message translates to:
  /// **'New opportunity'**
  String get newOpportunity;

  /// No description provided for @sharedBy.
  ///
  /// In en, this message translates to:
  /// **'Shared by {name}'**
  String sharedBy(String name);

  /// No description provided for @deadlineOn.
  ///
  /// In en, this message translates to:
  /// **'deadline {date}'**
  String deadlineOn(String date);

  /// No description provided for @offeringGuidance.
  ///
  /// In en, this message translates to:
  /// **'Relatives offering guidance'**
  String get offeringGuidance;

  /// No description provided for @lookingForHelp.
  ///
  /// In en, this message translates to:
  /// **'Students looking for help'**
  String get lookingForHelp;

  /// No description provided for @ask.
  ///
  /// In en, this message translates to:
  /// **'Ask'**
  String get ask;

  /// No description provided for @askMentorTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask {name}'**
  String askMentorTitle(String name);

  /// No description provided for @askMentorHint.
  ///
  /// In en, this message translates to:
  /// **'What would you like help with?'**
  String get askMentorHint;

  /// No description provided for @askSent.
  ///
  /// In en, this message translates to:
  /// **'Sent. {name} will see your note.'**
  String askSent(String name);

  /// No description provided for @asksToYou.
  ///
  /// In en, this message translates to:
  /// **'Asks to you'**
  String get asksToYou;

  /// No description provided for @offerToMentor.
  ///
  /// In en, this message translates to:
  /// **'Offer to mentor'**
  String get offerToMentor;

  /// No description provided for @editMentoring.
  ///
  /// In en, this message translates to:
  /// **'Edit my mentoring'**
  String get editMentoring;

  /// No description provided for @stopMentoring.
  ///
  /// In en, this message translates to:
  /// **'Stop mentoring'**
  String get stopMentoring;

  /// No description provided for @mentorAreas.
  ///
  /// In en, this message translates to:
  /// **'Areas you can help with'**
  String get mentorAreas;

  /// No description provided for @mentorAreasHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Medicine · residency applications'**
  String get mentorAreasHint;

  /// No description provided for @imLookingForHelp.
  ///
  /// In en, this message translates to:
  /// **'I\'m looking for help'**
  String get imLookingForHelp;

  /// No description provided for @editMyRequest.
  ///
  /// In en, this message translates to:
  /// **'Edit my request'**
  String get editMyRequest;

  /// No description provided for @removeMyRequest.
  ///
  /// In en, this message translates to:
  /// **'Remove my request'**
  String get removeMyRequest;

  /// No description provided for @studyField.
  ///
  /// In en, this message translates to:
  /// **'What are you studying?'**
  String get studyField;

  /// No description provided for @whatHelp.
  ///
  /// In en, this message translates to:
  /// **'What help are you looking for?'**
  String get whatHelp;

  /// No description provided for @shareOpportunity.
  ///
  /// In en, this message translates to:
  /// **'Share an opportunity'**
  String get shareOpportunity;

  /// No description provided for @opportunityTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get opportunityTitle;

  /// No description provided for @link.
  ///
  /// In en, this message translates to:
  /// **'Link (optional)'**
  String get link;

  /// No description provided for @deadlineOptional.
  ///
  /// In en, this message translates to:
  /// **'Deadline (optional)'**
  String get deadlineOptional;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @noMentorsYet.
  ///
  /// In en, this message translates to:
  /// **'No one has offered to mentor yet.'**
  String get noMentorsYet;

  /// No description provided for @noStudentsYet.
  ///
  /// In en, this message translates to:
  /// **'No students are looking for help right now.'**
  String get noStudentsYet;

  /// No description provided for @noOpportunitiesYet.
  ///
  /// In en, this message translates to:
  /// **'No opportunities shared yet.'**
  String get noOpportunitiesYet;

  /// No description provided for @pollsTitle.
  ///
  /// In en, this message translates to:
  /// **'Polls'**
  String get pollsTitle;

  /// No description provided for @newPoll.
  ///
  /// In en, this message translates to:
  /// **'New poll'**
  String get newPoll;

  /// No description provided for @closesDate.
  ///
  /// In en, this message translates to:
  /// **'closes {date}'**
  String closesDate(String date);

  /// No description provided for @youVoted.
  ///
  /// In en, this message translates to:
  /// **'you voted'**
  String get youVoted;

  /// No description provided for @notVotedYet.
  ///
  /// In en, this message translates to:
  /// **'not voted yet'**
  String get notVotedYet;

  /// No description provided for @vote.
  ///
  /// In en, this message translates to:
  /// **'Vote'**
  String get vote;

  /// No description provided for @changeVote.
  ///
  /// In en, this message translates to:
  /// **'Change my vote'**
  String get changeVote;

  /// No description provided for @votedOf.
  ///
  /// In en, this message translates to:
  /// **'{count} of {eligible} members voted'**
  String votedOf(int count, int eligible);

  /// No description provided for @decided.
  ///
  /// In en, this message translates to:
  /// **'Decided'**
  String get decided;

  /// No description provided for @decidedLine.
  ///
  /// In en, this message translates to:
  /// **'{percent}% chose this · decided {date}'**
  String decidedLine(int percent, String date);

  /// No description provided for @closePoll.
  ///
  /// In en, this message translates to:
  /// **'Close poll'**
  String get closePoll;

  /// No description provided for @deletePoll.
  ///
  /// In en, this message translates to:
  /// **'Delete poll'**
  String get deletePoll;

  /// No description provided for @question.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get question;

  /// No description provided for @pollContext.
  ///
  /// In en, this message translates to:
  /// **'What is it for? (optional)'**
  String get pollContext;

  /// No description provided for @pollContextHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. For the family meeting'**
  String get pollContextHint;

  /// No description provided for @choices.
  ///
  /// In en, this message translates to:
  /// **'Choices'**
  String get choices;

  /// No description provided for @choiceN.
  ///
  /// In en, this message translates to:
  /// **'Choice {n}'**
  String choiceN(int n);

  /// No description provided for @addChoice.
  ///
  /// In en, this message translates to:
  /// **'Add a choice'**
  String get addChoice;

  /// No description provided for @closesOnPoll.
  ///
  /// In en, this message translates to:
  /// **'Voting closes'**
  String get closesOnPoll;

  /// No description provided for @needTwoChoices.
  ///
  /// In en, this message translates to:
  /// **'Add a question and at least two choices.'**
  String get needTwoChoices;

  /// No description provided for @noPollsYet.
  ///
  /// In en, this message translates to:
  /// **'No polls yet. Ask the family a question.'**
  String get noPollsYet;

  /// No description provided for @secretBallot.
  ///
  /// In en, this message translates to:
  /// **'Votes are secret. You see the results after you vote or when the poll closes.'**
  String get secretBallot;

  /// No description provided for @notifMentorRequest.
  ///
  /// In en, this message translates to:
  /// **'Someone asked for your guidance: “{body}”'**
  String notifMentorRequest(String body);

  /// No description provided for @notifOpportunity.
  ///
  /// In en, this message translates to:
  /// **'New opportunity: {title}'**
  String notifOpportunity(String title);

  /// No description provided for @notifPoll.
  ///
  /// In en, this message translates to:
  /// **'New poll: {question}'**
  String notifPoll(String question);

  /// No description provided for @storiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Elders’ stories'**
  String get storiesTitle;

  /// No description provided for @storiesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Voices of the family, kept for the next generation'**
  String get storiesSubtitle;

  /// No description provided for @nowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get nowPlaying;

  /// No description provided for @listen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get listen;

  /// No description provided for @otherLanguage.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherLanguage;

  /// No description provided for @transcript.
  ///
  /// In en, this message translates to:
  /// **'Transcript'**
  String get transcript;

  /// No description provided for @noStoriesYet.
  ///
  /// In en, this message translates to:
  /// **'No stories yet. Record the first one.'**
  String get noStoriesYet;

  /// No description provided for @recordStory.
  ///
  /// In en, this message translates to:
  /// **'Record an elder’s story'**
  String get recordStory;

  /// No description provided for @recordHint.
  ///
  /// In en, this message translates to:
  /// **'Try asking: How did you meet? What was Kano like when you were young?'**
  String get recordHint;

  /// No description provided for @deleteStory.
  ///
  /// In en, this message translates to:
  /// **'Delete story'**
  String get deleteStory;

  /// No description provided for @deleteStoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this story and its recording?'**
  String get deleteStoryConfirm;

  /// No description provided for @newStory.
  ///
  /// In en, this message translates to:
  /// **'New story'**
  String get newStory;

  /// No description provided for @tapToRecord.
  ///
  /// In en, this message translates to:
  /// **'Tap to start recording'**
  String get tapToRecord;

  /// No description provided for @recordingNow.
  ///
  /// In en, this message translates to:
  /// **'Recording… {time}'**
  String recordingNow(String time);

  /// No description provided for @tapToStop.
  ///
  /// In en, this message translates to:
  /// **'Tap to stop'**
  String get tapToStop;

  /// No description provided for @recordedLength.
  ///
  /// In en, this message translates to:
  /// **'Recorded · {time}'**
  String recordedLength(String time);

  /// No description provided for @recordAgain.
  ///
  /// In en, this message translates to:
  /// **'Record again'**
  String get recordAgain;

  /// No description provided for @chooseAudioFile.
  ///
  /// In en, this message translates to:
  /// **'Or choose an audio file (cassette transfer, voice note)'**
  String get chooseAudioFile;

  /// No description provided for @micDenied.
  ///
  /// In en, this message translates to:
  /// **'Allow the microphone in your phone’s settings to record.'**
  String get micDenied;

  /// No description provided for @storyTitle.
  ///
  /// In en, this message translates to:
  /// **'What is the story about?'**
  String get storyTitle;

  /// No description provided for @whoSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Who is speaking?'**
  String get whoSpeaking;

  /// No description provided for @sourceNote.
  ///
  /// In en, this message translates to:
  /// **'Where and when was it recorded? (optional)'**
  String get sourceNote;

  /// No description provided for @sourceNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Recorded 1979 on cassette, digitised by Bello'**
  String get sourceNoteHint;

  /// No description provided for @transcriptOptional.
  ///
  /// In en, this message translates to:
  /// **'Transcript (optional)'**
  String get transcriptOptional;

  /// No description provided for @saveStory.
  ///
  /// In en, this message translates to:
  /// **'Save story'**
  String get saveStory;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get uploading;

  /// No description provided for @needAudio.
  ///
  /// In en, this message translates to:
  /// **'Record or choose a recording first.'**
  String get needAudio;

  /// No description provided for @needTitleSpeaker.
  ///
  /// In en, this message translates to:
  /// **'Add a title and who is speaking.'**
  String get needTitleSpeaker;

  /// No description provided for @notifStory.
  ///
  /// In en, this message translates to:
  /// **'New story from {speaker}: {title}'**
  String notifStory(String speaker, String title);

  /// No description provided for @dataTitle.
  ///
  /// In en, this message translates to:
  /// **'Import, export & backup'**
  String get dataTitle;

  /// No description provided for @dataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Admins only · your data is never locked in'**
  String get dataSubtitle;

  /// No description provided for @exportHeading.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportHeading;

  /// No description provided for @exportGedcom.
  ///
  /// In en, this message translates to:
  /// **'Family tree (GEDCOM)'**
  String get exportGedcom;

  /// No description provided for @exportGedcomSub.
  ///
  /// In en, this message translates to:
  /// **'Opens in other genealogy apps'**
  String get exportGedcomSub;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @exportCsvSub.
  ///
  /// In en, this message translates to:
  /// **'Everyone, with dates and places'**
  String get exportCsvSub;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Printable tree (PDF)'**
  String get exportPdf;

  /// No description provided for @exportPdfSub.
  ///
  /// In en, this message translates to:
  /// **'Poster size, for family gatherings'**
  String get exportPdfSub;

  /// No description provided for @includeDetails.
  ///
  /// In en, this message translates to:
  /// **'Include contact & health details'**
  String get includeDetails;

  /// No description provided for @savedFile.
  ///
  /// In en, this message translates to:
  /// **'Saved {file}'**
  String savedFile(String file);

  /// No description provided for @importHeading.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importHeading;

  /// No description provided for @chooseImportFile.
  ///
  /// In en, this message translates to:
  /// **'Choose a GEDCOM or CSV file'**
  String get chooseImportFile;

  /// No description provided for @importReviewNote.
  ///
  /// In en, this message translates to:
  /// **'You’ll review matches before anything is added'**
  String get importReviewNote;

  /// No description provided for @downloadTemplate.
  ///
  /// In en, this message translates to:
  /// **'Download the spreadsheet template'**
  String get downloadTemplate;

  /// No description provided for @importError.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t read this file: {message}'**
  String importError(String message);

  /// No description provided for @weeklyBackupOn.
  ///
  /// In en, this message translates to:
  /// **'Weekly backup is on'**
  String get weeklyBackupOn;

  /// No description provided for @weeklyBackupOff.
  ///
  /// In en, this message translates to:
  /// **'Weekly backup is off'**
  String get weeklyBackupOff;

  /// No description provided for @lastBackup.
  ///
  /// In en, this message translates to:
  /// **'Last backup {date}'**
  String lastBackup(String date);

  /// No description provided for @noBackupYet.
  ///
  /// In en, this message translates to:
  /// **'No backup yet'**
  String get noBackupYet;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @keepWeeklyBackup.
  ///
  /// In en, this message translates to:
  /// **'Keep a weekly backup'**
  String get keepWeeklyBackup;

  /// No description provided for @backupNow.
  ///
  /// In en, this message translates to:
  /// **'Back up now'**
  String get backupNow;

  /// No description provided for @backupDone.
  ///
  /// In en, this message translates to:
  /// **'Backup saved'**
  String get backupDone;

  /// No description provided for @earlierBackups.
  ///
  /// In en, this message translates to:
  /// **'Earlier backups'**
  String get earlierBackups;

  /// No description provided for @backupsKept.
  ///
  /// In en, this message translates to:
  /// **'Backups from the last eight weeks are kept.'**
  String get backupsKept;

  /// No description provided for @reviewImport.
  ///
  /// In en, this message translates to:
  /// **'Review import'**
  String get reviewImport;

  /// No description provided for @importSummary.
  ///
  /// In en, this message translates to:
  /// **'{added} new · {matched} already in the tree · {links, plural, =1{1 relationship} other{{links} relationships}}'**
  String importSummary(int added, int matched, int links);

  /// No description provided for @importNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get importNew;

  /// No description provided for @sameAs.
  ///
  /// In en, this message translates to:
  /// **'Same as {name} in the tree'**
  String sameAs(String name);

  /// No description provided for @notSame.
  ///
  /// In en, this message translates to:
  /// **'Not the same person'**
  String get notSame;

  /// No description provided for @addToTree.
  ///
  /// In en, this message translates to:
  /// **'Add to the tree'**
  String get addToTree;

  /// No description provided for @importDone.
  ///
  /// In en, this message translates to:
  /// **'Added {people, plural, =1{1 person} other{{people} people}} and {links, plural, =1{1 relationship} other{{links} relationships}}.'**
  String importDone(int people, int links);

  /// No description provided for @importSkipped.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 relationship was} other{{count} relationships were}} skipped because they don’t fit the tree.'**
  String importSkipped(int count);

  /// No description provided for @treePosterTitle.
  ///
  /// In en, this message translates to:
  /// **'The {family} Family'**
  String treePosterTitle(String family);

  /// No description provided for @treePosterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} people · printed {date}'**
  String treePosterSubtitle(int count, String date);

  /// No description provided for @restoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore from a backup'**
  String get restoreTitle;

  /// No description provided for @restoreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bring back deleted or changed family data'**
  String get restoreSubtitle;

  /// No description provided for @restoreEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Restore…'**
  String get restoreEllipsis;

  /// No description provided for @chooseBackup.
  ///
  /// In en, this message translates to:
  /// **'Choose a backup'**
  String get chooseBackup;

  /// No description provided for @beforeLastRestore.
  ///
  /// In en, this message translates to:
  /// **'Before the last restore · {date}'**
  String beforeLastRestore(String date);

  /// No description provided for @backupFile.
  ///
  /// In en, this message translates to:
  /// **'A backup file…'**
  String get backupFile;

  /// No description provided for @backupFileChosen.
  ///
  /// In en, this message translates to:
  /// **'File: {name}'**
  String backupFileChosen(String name);

  /// No description provided for @notABackup.
  ///
  /// In en, this message translates to:
  /// **'This file is not a Bua Family backup.'**
  String get notABackup;

  /// No description provided for @undoChanges.
  ///
  /// In en, this message translates to:
  /// **'Also undo changes made since'**
  String get undoChanges;

  /// No description provided for @undoChangesSub.
  ///
  /// In en, this message translates to:
  /// **'Edits made after the backup are changed back. Nothing is deleted either way.'**
  String get undoChangesSub;

  /// No description provided for @restorePreview.
  ///
  /// In en, this message translates to:
  /// **'What will happen'**
  String get restorePreview;

  /// No description provided for @checkingBackup.
  ///
  /// In en, this message translates to:
  /// **'Checking the backup…'**
  String get checkingBackup;

  /// No description provided for @restoreUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Nothing to restore: today\'s data already has everything in this backup.'**
  String get restoreUpToDate;

  /// No description provided for @restoreGroup.
  ///
  /// In en, this message translates to:
  /// **'{group, select, tree{Family tree} details{Work, studies, contact & health} sharing{Posts & photos} events{Events} memories{Memories & stories} support{Blood requests & welfare fund} other{Mentorship & polls}}'**
  String restoreGroup(String group);

  /// No description provided for @restoreCounts.
  ///
  /// In en, this message translates to:
  /// **'{added} to bring back · {updated} to change back'**
  String restoreCounts(int added, int updated);

  /// No description provided for @restoreSkippedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} can\'t go back'**
  String restoreSkippedCount(int count);

  /// No description provided for @restoreSafety.
  ///
  /// In en, this message translates to:
  /// **'A copy of today\'s data is saved first, so you can undo this from “Before the last restore”.'**
  String get restoreSafety;

  /// No description provided for @restoreLimits.
  ///
  /// In en, this message translates to:
  /// **'Accounts aren\'t restored: members sign in again and an admin links them. Photos, voice recordings and receipts are files; the backup has their details but not the files.'**
  String get restoreLimits;

  /// No description provided for @restoreButton.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreButton;

  /// No description provided for @restoreConfirm.
  ///
  /// In en, this message translates to:
  /// **'Restore this backup now?'**
  String get restoreConfirm;

  /// No description provided for @restoreDone.
  ///
  /// In en, this message translates to:
  /// **'Restored: {added} brought back, {updated} changed back.'**
  String restoreDone(int added, int updated);

  /// No description provided for @pushOnThisPhone.
  ///
  /// In en, this message translates to:
  /// **'Notifications on this phone'**
  String get pushOnThisPhone;

  /// No description provided for @pushInThisBrowser.
  ///
  /// In en, this message translates to:
  /// **'Notifications in this browser'**
  String get pushInThisBrowser;

  /// No description provided for @pushOnSub.
  ///
  /// In en, this message translates to:
  /// **'New notifications appear here even when the app is closed.'**
  String get pushOnSub;

  /// No description provided for @pushOffSub.
  ///
  /// In en, this message translates to:
  /// **'Get told about events, blood requests, polls and more, even when the app is closed.'**
  String get pushOffSub;

  /// No description provided for @pushBlocked.
  ///
  /// In en, this message translates to:
  /// **'Notifications are blocked. Allow them for Bua Family in your phone or browser settings, then try again.'**
  String get pushBlocked;

  /// No description provided for @pushUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This version of the app can\'t receive notifications yet.'**
  String get pushUnavailable;

  /// No description provided for @pushNotSetUp.
  ///
  /// In en, this message translates to:
  /// **'An admin hasn\'t set up phone notifications yet.'**
  String get pushNotSetUp;

  /// No description provided for @pushTurnedOn.
  ///
  /// In en, this message translates to:
  /// **'Notifications are on for this device.'**
  String get pushTurnedOn;

  /// No description provided for @pushFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t turn on notifications. Check your connection and try again.'**
  String get pushFailed;

  /// No description provided for @pushPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Get notified on this phone'**
  String get pushPromptTitle;

  /// No description provided for @pushPromptBody.
  ///
  /// In en, this message translates to:
  /// **'Know straight away about blood requests, events and family news.'**
  String get pushPromptBody;

  /// No description provided for @turnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get turnOn;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @pushAdminTitle.
  ///
  /// In en, this message translates to:
  /// **'Phone notifications'**
  String get pushAdminTitle;

  /// No description provided for @pushAdminSub.
  ///
  /// In en, this message translates to:
  /// **'Send every notification to members\' phones and browsers (free, through Firebase).'**
  String get pushAdminSub;

  /// No description provided for @pushSetupSteps.
  ///
  /// In en, this message translates to:
  /// **'1. Create a free project at console.firebase.google.com. 2. In Project settings › Service accounts, choose “Generate new private key”. 3. Choose that file below. The app also needs your Firebase app settings (see the README).'**
  String get pushSetupSteps;

  /// No description provided for @firebaseKey.
  ///
  /// In en, this message translates to:
  /// **'Firebase key'**
  String get firebaseKey;

  /// No description provided for @firebaseKeySaved.
  ///
  /// In en, this message translates to:
  /// **'Saved · {project}'**
  String firebaseKeySaved(String project);

  /// No description provided for @chooseKeyFile.
  ///
  /// In en, this message translates to:
  /// **'Choose the key file (.json)'**
  String get chooseKeyFile;

  /// No description provided for @pushStats.
  ///
  /// In en, this message translates to:
  /// **'{members} members on {devices} devices · {sent} sent, {received} received in browsers this week'**
  String pushStats(int members, int devices, int sent, int received);

  /// No description provided for @sendTestPush.
  ///
  /// In en, this message translates to:
  /// **'Send me a test notification'**
  String get sendTestPush;

  /// No description provided for @testPushSent.
  ///
  /// In en, this message translates to:
  /// **'Sent. It should arrive on every device where you turned notifications on.'**
  String get testPushSent;

  /// No description provided for @notifTest.
  ///
  /// In en, this message translates to:
  /// **'Test notification: notifications are working on this device.'**
  String get notifTest;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhoto;

  /// No description provided for @photoLabel.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photoLabel;

  /// No description provided for @notifAccountRequest.
  ///
  /// In en, this message translates to:
  /// **'New sign-up waiting for approval: {name}'**
  String notifAccountRequest(String name);

  /// No description provided for @notifAccountNote.
  ///
  /// In en, this message translates to:
  /// **'{name} says: “{note}”'**
  String notifAccountNote(String name, String note);

  /// No description provided for @notifChangeAdd.
  ///
  /// In en, this message translates to:
  /// **'{name} suggested adding {person} to the tree'**
  String notifChangeAdd(String name, String person);

  /// No description provided for @notifChangeEdit.
  ///
  /// In en, this message translates to:
  /// **'{name} suggested a change to {person}'**
  String notifChangeEdit(String name, String person);

  /// No description provided for @notifAccountApproved.
  ///
  /// In en, this message translates to:
  /// **'Welcome! Your account has been approved.'**
  String get notifAccountApproved;

  /// No description provided for @notifRequestApproved.
  ///
  /// In en, this message translates to:
  /// **'Your suggestion about {person} was approved'**
  String notifRequestApproved(String person);

  /// No description provided for @notifRequestDeclined.
  ///
  /// In en, this message translates to:
  /// **'Your suggestion about {person} was not accepted'**
  String notifRequestDeclined(String person);

  /// No description provided for @notifSomeone.
  ///
  /// In en, this message translates to:
  /// **'someone'**
  String get notifSomeone;

  /// No description provided for @notifTheTree.
  ///
  /// In en, this message translates to:
  /// **'the tree'**
  String get notifTheTree;

  /// No description provided for @pendingPushHint.
  ///
  /// In en, this message translates to:
  /// **'Get a notification the moment an admin approves you.'**
  String get pendingPushHint;

  /// No description provided for @notifCommentBy.
  ///
  /// In en, this message translates to:
  /// **'{name} commented: “{body}”'**
  String notifCommentBy(String name, String body);

  /// No description provided for @notifCommentAlso.
  ///
  /// In en, this message translates to:
  /// **'{name} also commented: “{body}”'**
  String notifCommentAlso(String name, String body);

  /// No description provided for @notifAccountClaim.
  ///
  /// In en, this message translates to:
  /// **'{name} says they are {person} in the tree'**
  String notifAccountClaim(String name, String person);

  /// No description provided for @postGone.
  ///
  /// In en, this message translates to:
  /// **'This post was removed.'**
  String get postGone;

  /// No description provided for @findMeInTree.
  ///
  /// In en, this message translates to:
  /// **'Find yourself in the tree'**
  String get findMeInTree;

  /// No description provided for @findMeHint.
  ///
  /// In en, this message translates to:
  /// **'Link your account to your place in the tree to get your own profile, photo and details.'**
  String get findMeHint;

  /// No description provided for @linkWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for an admin to link you to {name}'**
  String linkWaiting(String name);

  /// No description provided for @linkedNow.
  ///
  /// In en, this message translates to:
  /// **'Linked. This is now your profile.'**
  String get linkedNow;

  /// No description provided for @birthOrder.
  ///
  /// In en, this message translates to:
  /// **'Birth order among siblings'**
  String get birthOrder;

  /// No description provided for @birthOrderHint.
  ///
  /// In en, this message translates to:
  /// **'1 for the first-born. Siblings are listed in this order.'**
  String get birthOrderHint;

  /// No description provided for @birthOrderNone.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get birthOrderNone;

  /// No description provided for @reqRemoveParentChild.
  ///
  /// In en, this message translates to:
  /// **'Remove {parent} as a parent of {child}'**
  String reqRemoveParentChild(String parent, String child);

  /// No description provided for @reqRemoveUnion.
  ///
  /// In en, this message translates to:
  /// **'Remove the marriage of {a} and {b}'**
  String reqRemoveUnion(String a, String b);

  /// No description provided for @removeRelationship.
  ///
  /// In en, this message translates to:
  /// **'Remove relationship'**
  String get removeRelationship;

  /// No description provided for @confirmRemoveParent.
  ///
  /// In en, this message translates to:
  /// **'Remove {parent} as a parent of {child}? Both stay in the tree.'**
  String confirmRemoveParent(String parent, String child);

  /// No description provided for @confirmRemoveUnion.
  ///
  /// In en, this message translates to:
  /// **'Remove the marriage between {a} and {b}? Both stay in the tree.'**
  String confirmRemoveUnion(String a, String b);

  /// No description provided for @relationshipRemoved.
  ///
  /// In en, this message translates to:
  /// **'Relationship removed'**
  String get relationshipRemoved;

  /// No description provided for @checkTree.
  ///
  /// In en, this message translates to:
  /// **'Check the tree'**
  String get checkTree;

  /// No description provided for @checkTreeHint.
  ///
  /// In en, this message translates to:
  /// **'Links that look wrong, so you can fix them'**
  String get checkTreeHint;

  /// No description provided for @treeLooksRight.
  ///
  /// In en, this message translates to:
  /// **'Nothing looks wrong in the tree.'**
  String get treeLooksRight;

  /// No description provided for @problemMarriedInLine.
  ///
  /// In en, this message translates to:
  /// **'{a} and {b} are married, but one descends from the other'**
  String problemMarriedInLine(String a, String b);

  /// No description provided for @problemParentYounger.
  ///
  /// In en, this message translates to:
  /// **'{a} is a parent of {b} but is not at least 10 years older'**
  String problemParentYounger(String a, String b);

  /// No description provided for @problemBornAfterDeath.
  ///
  /// In en, this message translates to:
  /// **'{b} was born more than a year after their parent {a} died'**
  String problemBornAfterDeath(String a, String b);

  /// No description provided for @problemSameBirthOrder.
  ///
  /// In en, this message translates to:
  /// **'{a} and {b} have the same birth order'**
  String problemSameBirthOrder(String a, String b);

  /// No description provided for @removeLink.
  ///
  /// In en, this message translates to:
  /// **'Remove link'**
  String get removeLink;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sortBy;

  /// No description provided for @sortName.
  ///
  /// In en, this message translates to:
  /// **'Name (A–Z)'**
  String get sortName;

  /// No description provided for @sortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get sortOldest;

  /// No description provided for @sortYoungest.
  ///
  /// In en, this message translates to:
  /// **'Youngest first'**
  String get sortYoungest;

  /// No description provided for @sortFamily.
  ///
  /// In en, this message translates to:
  /// **'Family order'**
  String get sortFamily;

  /// No description provided for @helpEachOther.
  ///
  /// In en, this message translates to:
  /// **'Help each other'**
  String get helpEachOther;

  /// No description provided for @openMenu.
  ///
  /// In en, this message translates to:
  /// **'Open menu'**
  String get openMenu;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'A new version of the app is ready'**
  String get updateAvailableTitle;

  /// No description provided for @updateAvailableBody.
  ///
  /// In en, this message translates to:
  /// **'Version {version}. Download it, then open the file to update.'**
  String updateAvailableBody(String version);

  /// No description provided for @getAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Bua Family for Android'**
  String get getAppTitle;

  /// No description provided for @getAppSub.
  ///
  /// In en, this message translates to:
  /// **'Install the family app on your Android phone.'**
  String get getAppSub;

  /// No description provided for @getAppVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version} · {date}'**
  String getAppVersion(String version, String date);

  /// No description provided for @getAppSteps.
  ///
  /// In en, this message translates to:
  /// **'1. Tap Download.\n2. Open the downloaded file.\n3. If your phone asks, allow installing apps from this source, then tap Install (or Update).'**
  String get getAppSteps;

  /// No description provided for @getAppLatest.
  ///
  /// In en, this message translates to:
  /// **'You have the latest version.'**
  String get getAppLatest;

  /// No description provided for @getAppNone.
  ///
  /// In en, this message translates to:
  /// **'The Android app hasn\'t been published yet.'**
  String get getAppNone;

  /// No description provided for @getAppIphone.
  ///
  /// In en, this message translates to:
  /// **'On an iPhone, use the website instead: open it in Safari, tap Share, then Add to Home Screen.'**
  String get getAppIphone;

  /// No description provided for @getTheApp.
  ///
  /// In en, this message translates to:
  /// **'Get the Android app'**
  String get getTheApp;

  /// No description provided for @whatsNew.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get whatsNew;

  /// No description provided for @androidAppAdmin.
  ///
  /// In en, this message translates to:
  /// **'Android app'**
  String get androidAppAdmin;

  /// No description provided for @androidPublished.
  ///
  /// In en, this message translates to:
  /// **'Published {version} · {date}'**
  String androidPublished(String version, String date);

  /// No description provided for @androidNotPublished.
  ///
  /// In en, this message translates to:
  /// **'Not published yet. Build the APK on your computer, then publish it here.'**
  String get androidNotPublished;

  /// No description provided for @publishVersion.
  ///
  /// In en, this message translates to:
  /// **'Publish a new version'**
  String get publishVersion;

  /// No description provided for @buildNumber.
  ///
  /// In en, this message translates to:
  /// **'Build number'**
  String get buildNumber;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get versionLabel;

  /// No description provided for @whatsNewOptional.
  ///
  /// In en, this message translates to:
  /// **'What\'s new (optional)'**
  String get whatsNewOptional;

  /// No description provided for @appPublished.
  ///
  /// In en, this message translates to:
  /// **'Published. Members with the Android app have been notified.'**
  String get appPublished;

  /// No description provided for @shareAppLink.
  ///
  /// In en, this message translates to:
  /// **'Download link to share'**
  String get shareAppLink;

  /// No description provided for @notifAppUpdate.
  ///
  /// In en, this message translates to:
  /// **'A new version of the app is ready ({version}). Tap to download.'**
  String notifAppUpdate(String version);

  /// No description provided for @searchUsers.
  ///
  /// In en, this message translates to:
  /// **'Search name, email, phone or person'**
  String get searchUsers;

  /// No description provided for @filterWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get filterWaiting;

  /// No description provided for @filterActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get filterActive;

  /// No description provided for @filterSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get filterSuspended;

  /// No description provided for @filterAdmins.
  ///
  /// In en, this message translates to:
  /// **'Admins'**
  String get filterAdmins;

  /// No description provided for @filterTreasurers.
  ///
  /// In en, this message translates to:
  /// **'Treasurers'**
  String get filterTreasurers;

  /// No description provided for @filterNotLinked.
  ///
  /// In en, this message translates to:
  /// **'Not in the tree'**
  String get filterNotLinked;

  /// No description provided for @filterNoPush.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get filterNoPush;

  /// No description provided for @filterInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive 30 days'**
  String get filterInactive;

  /// No description provided for @usersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 account} other{{count} accounts}}'**
  String usersCount(int count);

  /// No description provided for @platformFilter.
  ///
  /// In en, this message translates to:
  /// **'App used'**
  String get platformFilter;

  /// No description provided for @platformAny.
  ///
  /// In en, this message translates to:
  /// **'Any app'**
  String get platformAny;

  /// No description provided for @platformAndroid.
  ///
  /// In en, this message translates to:
  /// **'Android app'**
  String get platformAndroid;

  /// No description provided for @platformWeb.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get platformWeb;

  /// No description provided for @sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get sortNewest;

  /// No description provided for @sortLastActive.
  ///
  /// In en, this message translates to:
  /// **'Last active'**
  String get sortLastActive;

  /// No description provided for @sortMostActive.
  ///
  /// In en, this message translates to:
  /// **'Most active'**
  String get sortMostActive;

  /// No description provided for @neverSeen.
  ///
  /// In en, this message translates to:
  /// **'Not seen yet'**
  String get neverSeen;

  /// No description provided for @lastSeen.
  ///
  /// In en, this message translates to:
  /// **'Active {when}'**
  String lastSeen(String when);

  /// No description provided for @activeDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No activity in the last 30 days} =1{Active on 1 of the last 30 days} other{Active on {count} of the last 30 days}}'**
  String activeDays(int count);

  /// No description provided for @postsAndComments.
  ///
  /// In en, this message translates to:
  /// **'{posts} posts · {comments} comments'**
  String postsAndComments(int posts, int comments);

  /// No description provided for @noPushDevices.
  ///
  /// In en, this message translates to:
  /// **'Notifications not turned on'**
  String get noPushDevices;

  /// No description provided for @pushOn.
  ///
  /// In en, this message translates to:
  /// **'Notifications on: {devices}'**
  String pushOn(String devices);

  /// No description provided for @androidVersionOf.
  ///
  /// In en, this message translates to:
  /// **'Android app {version}'**
  String androidVersionOf(String version);

  /// No description provided for @joinedOn.
  ///
  /// In en, this message translates to:
  /// **'Joined {date}'**
  String joinedOn(String date);

  /// No description provided for @emailTab.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailTab;

  /// No description provided for @phoneTab.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneTab;

  /// No description provided for @yourNameNew.
  ///
  /// In en, this message translates to:
  /// **'Your name (if you\'re new here)'**
  String get yourNameNew;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send me a code'**
  String get sendCode;

  /// No description provided for @codeSent.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {phone}.'**
  String codeSent(String phone);

  /// No description provided for @enterCode.
  ///
  /// In en, this message translates to:
  /// **'Code from the text message'**
  String get enterCode;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Send again'**
  String get resendCode;

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'Send again in {seconds}s'**
  String resendIn(int seconds);

  /// No description provided for @changeNumber.
  ///
  /// In en, this message translates to:
  /// **'Change number'**
  String get changeNumber;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number'**
  String get invalidPhone;

  /// No description provided for @inviteTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re invited'**
  String get inviteTitle;

  /// No description provided for @inviteBody.
  ///
  /// In en, this message translates to:
  /// **'{inviter} invited you to the {family} family app.'**
  String inviteBody(String inviter, String family);

  /// No description provided for @inviteBodyGeneric.
  ///
  /// In en, this message translates to:
  /// **'You\'re invited to the {family} family app.'**
  String inviteBodyGeneric(String family);

  /// No description provided for @inviteFor.
  ///
  /// In en, this message translates to:
  /// **'This invite is for {person}.'**
  String inviteFor(String person);

  /// No description provided for @inviteInvalid.
  ///
  /// In en, this message translates to:
  /// **'This invite link has already been used or has expired. Ask a family admin for a new one.'**
  String get inviteInvalid;

  /// No description provided for @joinWithInvite.
  ///
  /// In en, this message translates to:
  /// **'Join the family'**
  String get joinWithInvite;

  /// No description provided for @acceptInvite.
  ///
  /// In en, this message translates to:
  /// **'Accept the invite'**
  String get acceptInvite;

  /// No description provided for @inviteAccepted.
  ///
  /// In en, this message translates to:
  /// **'Welcome to the family app!'**
  String get inviteAccepted;

  /// No description provided for @inviteSomeone.
  ///
  /// In en, this message translates to:
  /// **'Invite someone'**
  String get inviteSomeone;

  /// No description provided for @inviteSomeoneHint.
  ///
  /// In en, this message translates to:
  /// **'Make a link to send on WhatsApp. Whoever joins with it is approved at once.'**
  String get inviteSomeoneHint;

  /// No description provided for @invitePerson.
  ///
  /// In en, this message translates to:
  /// **'For a person in the tree (optional)'**
  String get invitePerson;

  /// No description provided for @createInvite.
  ///
  /// In en, this message translates to:
  /// **'Create the link'**
  String get createInvite;

  /// No description provided for @inviteReady.
  ///
  /// In en, this message translates to:
  /// **'Link ready. It works once, for 30 days.'**
  String get inviteReady;

  /// No description provided for @shareWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Share on WhatsApp'**
  String get shareWhatsApp;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLink;

  /// No description provided for @inviteMessage.
  ///
  /// In en, this message translates to:
  /// **'Assalamu alaikum! Join the {family} family app: {link}'**
  String inviteMessage(String family, String link);

  /// No description provided for @inviteMessageFor.
  ///
  /// In en, this message translates to:
  /// **'Assalamu alaikum {name}! Join the {family} family app: {link}'**
  String inviteMessageFor(String name, String family, String link);

  /// No description provided for @offlineSaved.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Showing what was saved on this phone.'**
  String get offlineSaved;

  /// No description provided for @metricsTitle.
  ///
  /// In en, this message translates to:
  /// **'Family metrics'**
  String get metricsTitle;

  /// No description provided for @metricsSub.
  ///
  /// In en, this message translates to:
  /// **'How the family is using the app'**
  String get metricsSub;

  /// No description provided for @period7.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get period7;

  /// No description provided for @period30.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get period30;

  /// No description provided for @period90.
  ///
  /// In en, this message translates to:
  /// **'90 days'**
  String get period90;

  /// No description provided for @period365.
  ///
  /// In en, this message translates to:
  /// **'12 months'**
  String get period365;

  /// No description provided for @periodCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get periodCustom;

  /// No description provided for @byDay.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get byDay;

  /// No description provided for @byWeek.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get byWeek;

  /// No description provided for @byMonth.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get byMonth;

  /// No description provided for @allPlatforms.
  ///
  /// In en, this message translates to:
  /// **'All apps'**
  String get allPlatforms;

  /// No description provided for @allBranches.
  ///
  /// In en, this message translates to:
  /// **'All branches'**
  String get allBranches;

  /// No description provided for @comparePrevious.
  ///
  /// In en, this message translates to:
  /// **'Compare with the period before'**
  String get comparePrevious;

  /// No description provided for @previousPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period before'**
  String get previousPeriod;

  /// No description provided for @vsPrevious.
  ///
  /// In en, this message translates to:
  /// **'{change} vs period before'**
  String vsPrevious(String change);

  /// No description provided for @noChange.
  ///
  /// In en, this message translates to:
  /// **'Same as period before'**
  String get noChange;

  /// No description provided for @newThisPeriod.
  ///
  /// In en, this message translates to:
  /// **'New this period'**
  String get newThisPeriod;

  /// No description provided for @customiseTiles.
  ///
  /// In en, this message translates to:
  /// **'Choose metrics'**
  String get customiseTiles;

  /// No description provided for @customiseTilesHint.
  ///
  /// In en, this message translates to:
  /// **'Pick what shows on your dashboard.'**
  String get customiseTilesHint;

  /// No description provided for @showTable.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get showTable;

  /// No description provided for @showChart.
  ///
  /// In en, this message translates to:
  /// **'Chart'**
  String get showChart;

  /// No description provided for @breakdownBy.
  ///
  /// In en, this message translates to:
  /// **'Split by'**
  String get breakdownBy;

  /// No description provided for @byBranch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get byBranch;

  /// No description provided for @byPlatform.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get byPlatform;

  /// No description provided for @byMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get byMember;

  /// No description provided for @noBranch.
  ///
  /// In en, this message translates to:
  /// **'No branch'**
  String get noBranch;

  /// No description provided for @unknownLabel.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownLabel;

  /// No description provided for @snapshotTitle.
  ///
  /// In en, this message translates to:
  /// **'Right now'**
  String get snapshotTitle;

  /// No description provided for @funnelAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get funnelAccounts;

  /// No description provided for @funnelApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get funnelApproved;

  /// No description provided for @funnelLinked.
  ///
  /// In en, this message translates to:
  /// **'In the tree'**
  String get funnelLinked;

  /// No description provided for @funnelActive30.
  ///
  /// In en, this message translates to:
  /// **'Active in 30 days'**
  String get funnelActive30;

  /// No description provided for @funnelPush.
  ///
  /// In en, this message translates to:
  /// **'Notifications on'**
  String get funnelPush;

  /// No description provided for @funnelAndroid.
  ///
  /// In en, this message translates to:
  /// **'Android app'**
  String get funnelAndroid;

  /// No description provided for @treeQuality.
  ///
  /// In en, this message translates to:
  /// **'The tree'**
  String get treeQuality;

  /// No description provided for @treePeople.
  ///
  /// In en, this message translates to:
  /// **'{count} people · {living} living'**
  String treePeople(int count, int living);

  /// No description provided for @withPhotoPct.
  ///
  /// In en, this message translates to:
  /// **'{pct}% have a photo'**
  String withPhotoPct(int pct);

  /// No description provided for @withBirthPct.
  ///
  /// In en, this message translates to:
  /// **'{pct}% have a date of birth'**
  String withBirthPct(int pct);

  /// No description provided for @withAccountPct.
  ///
  /// In en, this message translates to:
  /// **'{pct}% have an account'**
  String withAccountPct(int pct);

  /// No description provided for @fundBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Welfare fund balance'**
  String get fundBalanceLabel;

  /// No description provided for @openBloodLabel.
  ///
  /// In en, this message translates to:
  /// **'Open blood requests'**
  String get openBloodLabel;

  /// No description provided for @pendingSuggestionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Suggestions waiting'**
  String get pendingSuggestionsLabel;

  /// No description provided for @noDataYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing in this period yet.'**
  String get noDataYet;

  /// No description provided for @mgPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get mgPeople;

  /// No description provided for @mgTree.
  ///
  /// In en, this message translates to:
  /// **'The tree'**
  String get mgTree;

  /// No description provided for @mgSharing.
  ///
  /// In en, this message translates to:
  /// **'Sharing'**
  String get mgSharing;

  /// No description provided for @mgEvents.
  ///
  /// In en, this message translates to:
  /// **'Events & polls'**
  String get mgEvents;

  /// No description provided for @mgHelping.
  ///
  /// In en, this message translates to:
  /// **'Helping each other'**
  String get mgHelping;

  /// No description provided for @mgReach.
  ///
  /// In en, this message translates to:
  /// **'Reaching people'**
  String get mgReach;

  /// No description provided for @m_signups.
  ///
  /// In en, this message translates to:
  /// **'Sign-ups'**
  String get m_signups;

  /// No description provided for @m_active_members.
  ///
  /// In en, this message translates to:
  /// **'Active members'**
  String get m_active_members;

  /// No description provided for @m_active_android.
  ///
  /// In en, this message translates to:
  /// **'Active on Android'**
  String get m_active_android;

  /// No description provided for @m_active_web.
  ///
  /// In en, this message translates to:
  /// **'Active on the website'**
  String get m_active_web;

  /// No description provided for @m_people_added.
  ///
  /// In en, this message translates to:
  /// **'People added'**
  String get m_people_added;

  /// No description provided for @m_relationships_added.
  ///
  /// In en, this message translates to:
  /// **'Relationships added'**
  String get m_relationships_added;

  /// No description provided for @m_suggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions sent'**
  String get m_suggestions;

  /// No description provided for @m_suggestions_reviewed.
  ///
  /// In en, this message translates to:
  /// **'Suggestions reviewed'**
  String get m_suggestions_reviewed;

  /// No description provided for @m_moments.
  ///
  /// In en, this message translates to:
  /// **'Moments posted'**
  String get m_moments;

  /// No description provided for @m_announcements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get m_announcements;

  /// No description provided for @m_posting_members.
  ///
  /// In en, this message translates to:
  /// **'Members who posted'**
  String get m_posting_members;

  /// No description provided for @m_photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get m_photos;

  /// No description provided for @m_comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get m_comments;

  /// No description provided for @m_likes.
  ///
  /// In en, this message translates to:
  /// **'Ma sha Allah'**
  String get m_likes;

  /// No description provided for @m_stories.
  ///
  /// In en, this message translates to:
  /// **'Stories recorded'**
  String get m_stories;

  /// No description provided for @m_memories.
  ///
  /// In en, this message translates to:
  /// **'Memories written'**
  String get m_memories;

  /// No description provided for @m_events.
  ///
  /// In en, this message translates to:
  /// **'Events created'**
  String get m_events;

  /// No description provided for @m_rsvps.
  ///
  /// In en, this message translates to:
  /// **'RSVPs'**
  String get m_rsvps;

  /// No description provided for @m_polls.
  ///
  /// In en, this message translates to:
  /// **'Polls'**
  String get m_polls;

  /// No description provided for @m_votes.
  ///
  /// In en, this message translates to:
  /// **'Votes'**
  String get m_votes;

  /// No description provided for @m_blood_requests.
  ///
  /// In en, this message translates to:
  /// **'Blood requests'**
  String get m_blood_requests;

  /// No description provided for @m_blood_offers.
  ///
  /// In en, this message translates to:
  /// **'Offers to donate'**
  String get m_blood_offers;

  /// No description provided for @m_contributions.
  ///
  /// In en, this message translates to:
  /// **'Contributions recorded'**
  String get m_contributions;

  /// No description provided for @m_money_in.
  ///
  /// In en, this message translates to:
  /// **'Money confirmed in'**
  String get m_money_in;

  /// No description provided for @m_money_out.
  ///
  /// In en, this message translates to:
  /// **'Money paid out'**
  String get m_money_out;

  /// No description provided for @m_causes.
  ///
  /// In en, this message translates to:
  /// **'Causes opened'**
  String get m_causes;

  /// No description provided for @m_mentor_asks.
  ///
  /// In en, this message translates to:
  /// **'Mentor requests'**
  String get m_mentor_asks;

  /// No description provided for @m_opportunities.
  ///
  /// In en, this message translates to:
  /// **'Opportunities shared'**
  String get m_opportunities;

  /// No description provided for @m_notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications sent'**
  String get m_notifications;

  /// No description provided for @m_notifications_received.
  ///
  /// In en, this message translates to:
  /// **'Notifications received'**
  String get m_notifications_received;

  /// No description provided for @m_sms_sent.
  ///
  /// In en, this message translates to:
  /// **'Text messages sent'**
  String get m_sms_sent;

  /// No description provided for @storiesAdminOnly.
  ///
  /// In en, this message translates to:
  /// **'Admins record the elders\' stories. If you have one to share, tell an admin.'**
  String get storiesAdminOnly;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About the app'**
  String get aboutTitle;

  /// No description provided for @aboutSub.
  ///
  /// In en, this message translates to:
  /// **'Version, features and who made it'**
  String get aboutSub;

  /// No description provided for @aboutTagline.
  ///
  /// In en, this message translates to:
  /// **'One family, one place: our tree, our news and our care for each other.'**
  String get aboutTagline;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version} · build {build}'**
  String aboutVersion(String version, String build);

  /// No description provided for @aboutOnWeb.
  ///
  /// In en, this message translates to:
  /// **'Web app'**
  String get aboutOnWeb;

  /// No description provided for @aboutOnAndroid.
  ///
  /// In en, this message translates to:
  /// **'Android app'**
  String get aboutOnAndroid;

  /// No description provided for @aboutLatestAndroid.
  ///
  /// In en, this message translates to:
  /// **'Newest Android app: {version}'**
  String aboutLatestAndroid(String version);

  /// No description provided for @aboutUpToDate.
  ///
  /// In en, this message translates to:
  /// **'You have the newest version.'**
  String get aboutUpToDate;

  /// No description provided for @featuresTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s in the app'**
  String get featuresTitle;

  /// No description provided for @fTree.
  ///
  /// In en, this message translates to:
  /// **'Family tree'**
  String get fTree;

  /// No description provided for @fTreeD.
  ///
  /// In en, this message translates to:
  /// **'Everyone, with photos and birth order, and checks that keep it right.'**
  String get fTreeD;

  /// No description provided for @fMembers.
  ///
  /// In en, this message translates to:
  /// **'Members and profiles'**
  String get fMembers;

  /// No description provided for @fMembersD.
  ///
  /// In en, this message translates to:
  /// **'Find anyone, call or message them, and keep your own details up to date.'**
  String get fMembersD;

  /// No description provided for @fRelated.
  ///
  /// In en, this message translates to:
  /// **'How are we related?'**
  String get fRelated;

  /// No description provided for @fRelatedD.
  ///
  /// In en, this message translates to:
  /// **'The path between any two people in the family.'**
  String get fRelatedD;

  /// No description provided for @fSharing.
  ///
  /// In en, this message translates to:
  /// **'Moments, albums and announcements'**
  String get fSharing;

  /// No description provided for @fSharingD.
  ///
  /// In en, this message translates to:
  /// **'Share news and photos; comment, like and tag family.'**
  String get fSharingD;

  /// No description provided for @fEvents.
  ///
  /// In en, this message translates to:
  /// **'Events and reminders'**
  String get fEvents;

  /// No description provided for @fEventsD.
  ///
  /// In en, this message translates to:
  /// **'Weddings, naming ceremonies and meetings, with RSVPs, birthdays and remembrance days.'**
  String get fEventsD;

  /// No description provided for @fBlood.
  ///
  /// In en, this message translates to:
  /// **'Blood donors'**
  String get fBlood;

  /// No description provided for @fBloodD.
  ///
  /// In en, this message translates to:
  /// **'Ask for blood in an emergency and reach donors in the family at once.'**
  String get fBloodD;

  /// No description provided for @fFund.
  ///
  /// In en, this message translates to:
  /// **'Welfare fund'**
  String get fFund;

  /// No description provided for @fFundD.
  ///
  /// In en, this message translates to:
  /// **'Contributions, causes and payouts, open to the family.'**
  String get fFundD;

  /// No description provided for @fMentors.
  ///
  /// In en, this message translates to:
  /// **'Mentorship and opportunities'**
  String get fMentors;

  /// No description provided for @fMentorsD.
  ///
  /// In en, this message translates to:
  /// **'Ask an experienced relative for guidance; share jobs and scholarships.'**
  String get fMentorsD;

  /// No description provided for @fStories.
  ///
  /// In en, this message translates to:
  /// **'Elders\' stories'**
  String get fStories;

  /// No description provided for @fStoriesD.
  ///
  /// In en, this message translates to:
  /// **'Voices of our elders, recorded and kept for the next generations.'**
  String get fStoriesD;

  /// No description provided for @fPolls.
  ///
  /// In en, this message translates to:
  /// **'Polls'**
  String get fPolls;

  /// No description provided for @fPollsD.
  ///
  /// In en, this message translates to:
  /// **'Decide together.'**
  String get fPollsD;

  /// No description provided for @fMemorial.
  ///
  /// In en, this message translates to:
  /// **'Memorial pages'**
  String get fMemorial;

  /// No description provided for @fMemorialD.
  ///
  /// In en, this message translates to:
  /// **'Remember those who have passed, with prayers and memories.'**
  String get fMemorialD;

  /// No description provided for @fReach.
  ///
  /// In en, this message translates to:
  /// **'Notifications and SMS'**
  String get fReach;

  /// No description provided for @fReachD.
  ///
  /// In en, this message translates to:
  /// **'On the phone, on the web, and by SMS for those without data.'**
  String get fReachD;

  /// No description provided for @fOffline.
  ///
  /// In en, this message translates to:
  /// **'Works offline'**
  String get fOffline;

  /// No description provided for @fOfflineD.
  ///
  /// In en, this message translates to:
  /// **'What you have seen stays on your phone when the network drops.'**
  String get fOfflineD;

  /// No description provided for @fLanguages.
  ///
  /// In en, this message translates to:
  /// **'English and Hausa'**
  String get fLanguages;

  /// No description provided for @fLanguagesD.
  ///
  /// In en, this message translates to:
  /// **'Switch any time in More.'**
  String get fLanguagesD;

  /// No description provided for @fPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private to the family'**
  String get fPrivate;

  /// No description provided for @fPrivateD.
  ///
  /// In en, this message translates to:
  /// **'Only approved members can see anything. Admins approve every account.'**
  String get fPrivateD;

  /// No description provided for @developerTitle.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developerTitle;

  /// No description provided for @developedBy.
  ///
  /// In en, this message translates to:
  /// **'Designed and developed by'**
  String get developedBy;

  /// No description provided for @contactCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get contactCall;

  /// No description provided for @contactWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get contactWhatsApp;

  /// No description provided for @contactEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get contactEmail;

  /// No description provided for @contactWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get contactWebsite;

  /// No description provided for @licensesLabel.
  ///
  /// In en, this message translates to:
  /// **'Open-source licences'**
  String get licensesLabel;

  /// No description provided for @copyrightLine.
  ///
  /// In en, this message translates to:
  /// **'© {year} {company}. All rights reserved.'**
  String copyrightLine(String year, String company);

  /// No description provided for @aboutSettings.
  ///
  /// In en, this message translates to:
  /// **'About page: developer'**
  String get aboutSettings;

  /// No description provided for @aboutSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'Shown on the About page to everyone in the family.'**
  String get aboutSettingsHint;

  /// No description provided for @developerName.
  ///
  /// In en, this message translates to:
  /// **'Developer\'s name'**
  String get developerName;

  /// No description provided for @developerCompany.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get developerCompany;

  /// No description provided for @developerWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website (https://…)'**
  String get developerWebsite;

  /// No description provided for @notifMentorRequestFrom.
  ///
  /// In en, this message translates to:
  /// **'{name} asked for your guidance: “{body}”'**
  String notifMentorRequestFrom(String name, String body);

  /// No description provided for @notifMentorReply.
  ///
  /// In en, this message translates to:
  /// **'{name}: “{body}”'**
  String notifMentorReply(String name, String body);

  /// No description provided for @yourAsks.
  ///
  /// In en, this message translates to:
  /// **'Your asks'**
  String get yourAsks;

  /// No description provided for @conversationTitle.
  ///
  /// In en, this message translates to:
  /// **'Mentorship'**
  String get conversationTitle;

  /// No description provided for @conversationWithMentor.
  ///
  /// In en, this message translates to:
  /// **'Your mentor · {areas}'**
  String conversationWithMentor(String areas);

  /// No description provided for @conversationWithStudent.
  ///
  /// In en, this message translates to:
  /// **'Asked you for guidance'**
  String get conversationWithStudent;

  /// No description provided for @conversationPrivate.
  ///
  /// In en, this message translates to:
  /// **'Only the two of you can see this conversation.'**
  String get conversationPrivate;

  /// No description provided for @writeMessage.
  ///
  /// In en, this message translates to:
  /// **'Write a message…'**
  String get writeMessage;

  /// No description provided for @replyAction.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get replyAction;

  /// No description provided for @conversationGone.
  ///
  /// In en, this message translates to:
  /// **'This conversation was removed.'**
  String get conversationGone;

  /// No description provided for @deleteConversation.
  ///
  /// In en, this message translates to:
  /// **'Delete conversation'**
  String get deleteConversation;

  /// No description provided for @deleteConversationConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this conversation for both of you?'**
  String get deleteConversationConfirm;

  /// No description provided for @youPrefix.
  ///
  /// In en, this message translates to:
  /// **'You: {text}'**
  String youPrefix(String text);

  /// No description provided for @newMessages.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newMessages;

  /// No description provided for @activityTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityTitle;

  /// No description provided for @activitySub.
  ///
  /// In en, this message translates to:
  /// **'Who is online and what they did'**
  String get activitySub;

  /// No description provided for @tabOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get tabOnline;

  /// No description provided for @tabActivityLog.
  ///
  /// In en, this message translates to:
  /// **'Activity log'**
  String get tabActivityLog;

  /// No description provided for @onlineNow.
  ///
  /// In en, this message translates to:
  /// **'Online now'**
  String get onlineNow;

  /// No description provided for @earlierToday.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get earlierToday;

  /// No description provided for @nobodyOnline.
  ///
  /// In en, this message translates to:
  /// **'Nobody has the app open right now.'**
  String get nobodyOnline;

  /// No description provided for @onlineFor.
  ///
  /// In en, this message translates to:
  /// **'for {time}'**
  String onlineFor(String time);

  /// No description provided for @seenAgo.
  ///
  /// In en, this message translates to:
  /// **'last seen {time}'**
  String seenAgo(String time);

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String minutesShort(int n);

  /// No description provided for @hoursShort.
  ///
  /// In en, this message translates to:
  /// **'{h} h {m} min'**
  String hoursShort(int h, int m);

  /// No description provided for @onPage.
  ///
  /// In en, this message translates to:
  /// **'on {page}'**
  String onPage(String page);

  /// No description provided for @platformAndroidShort.
  ///
  /// In en, this message translates to:
  /// **'Android'**
  String get platformAndroidShort;

  /// No description provided for @platformWebShort.
  ///
  /// In en, this message translates to:
  /// **'Web'**
  String get platformWebShort;

  /// No description provided for @logAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get logAll;

  /// No description provided for @logChanges.
  ///
  /// In en, this message translates to:
  /// **'Changes'**
  String get logChanges;

  /// No description provided for @logPages.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get logPages;

  /// No description provided for @logSessions.
  ///
  /// In en, this message translates to:
  /// **'Sign-ins'**
  String get logSessions;

  /// No description provided for @logAnyone.
  ///
  /// In en, this message translates to:
  /// **'Anyone'**
  String get logAnyone;

  /// No description provided for @logToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get logToday;

  /// No description provided for @log7.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get log7;

  /// No description provided for @log30.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get log30;

  /// No description provided for @logAnyTime.
  ///
  /// In en, this message translates to:
  /// **'Any time'**
  String get logAnyTime;

  /// No description provided for @logSearch.
  ///
  /// In en, this message translates to:
  /// **'Search names, pages, titles…'**
  String get logSearch;

  /// No description provided for @logEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet.'**
  String get logEmpty;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get loadMore;

  /// No description provided for @logPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Only admins see this. Private conversations are logged without their content.'**
  String get logPrivacyNote;

  /// No description provided for @actOpenedApp.
  ///
  /// In en, this message translates to:
  /// **'opened the app'**
  String get actOpenedApp;

  /// No description provided for @actSignedIn.
  ///
  /// In en, this message translates to:
  /// **'signed in'**
  String get actSignedIn;

  /// No description provided for @actSignedOut.
  ///
  /// In en, this message translates to:
  /// **'signed out'**
  String get actSignedOut;

  /// No description provided for @actViewed.
  ///
  /// In en, this message translates to:
  /// **'opened {page}'**
  String actViewed(String page);

  /// No description provided for @actAdded.
  ///
  /// In en, this message translates to:
  /// **'added {thing}'**
  String actAdded(String thing);

  /// No description provided for @actChanged.
  ///
  /// In en, this message translates to:
  /// **'changed {thing}'**
  String actChanged(String thing);

  /// No description provided for @actRemoved.
  ///
  /// In en, this message translates to:
  /// **'removed {thing}'**
  String actRemoved(String thing);

  /// No description provided for @actLiked.
  ///
  /// In en, this message translates to:
  /// **'liked something'**
  String get actLiked;

  /// No description provided for @actUnliked.
  ///
  /// In en, this message translates to:
  /// **'took back a like'**
  String get actUnliked;

  /// No description provided for @actRsvp.
  ///
  /// In en, this message translates to:
  /// **'answered an invitation'**
  String get actRsvp;

  /// No description provided for @actVoted.
  ///
  /// In en, this message translates to:
  /// **'voted in a poll'**
  String get actVoted;

  /// No description provided for @actReviewed.
  ///
  /// In en, this message translates to:
  /// **'reviewed a suggestion'**
  String get actReviewed;

  /// No description provided for @actAccount.
  ///
  /// In en, this message translates to:
  /// **'changed an account'**
  String get actAccount;

  /// No description provided for @actSettings.
  ///
  /// In en, this message translates to:
  /// **'changed the app settings'**
  String get actSettings;

  /// No description provided for @actMentorAsk.
  ///
  /// In en, this message translates to:
  /// **'asked a mentor for guidance'**
  String get actMentorAsk;

  /// No description provided for @actMentorMessage.
  ///
  /// In en, this message translates to:
  /// **'sent a mentorship message'**
  String get actMentorMessage;

  /// No description provided for @actConfirmed.
  ///
  /// In en, this message translates to:
  /// **'confirmed a contribution'**
  String get actConfirmed;

  /// No description provided for @entPerson.
  ///
  /// In en, this message translates to:
  /// **'a person'**
  String get entPerson;

  /// No description provided for @entRelationship.
  ///
  /// In en, this message translates to:
  /// **'a relationship'**
  String get entRelationship;

  /// No description provided for @entSuggestion.
  ///
  /// In en, this message translates to:
  /// **'a suggestion'**
  String get entSuggestion;

  /// No description provided for @entAlbum.
  ///
  /// In en, this message translates to:
  /// **'an album'**
  String get entAlbum;

  /// No description provided for @entPost.
  ///
  /// In en, this message translates to:
  /// **'a moment'**
  String get entPost;

  /// No description provided for @entAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'an announcement'**
  String get entAnnouncement;

  /// No description provided for @entPhoto.
  ///
  /// In en, this message translates to:
  /// **'a photo'**
  String get entPhoto;

  /// No description provided for @entEvent.
  ///
  /// In en, this message translates to:
  /// **'an event'**
  String get entEvent;

  /// No description provided for @entComment.
  ///
  /// In en, this message translates to:
  /// **'a comment'**
  String get entComment;

  /// No description provided for @entBloodRequest.
  ///
  /// In en, this message translates to:
  /// **'a blood request'**
  String get entBloodRequest;

  /// No description provided for @entBloodOffer.
  ///
  /// In en, this message translates to:
  /// **'an offer to donate blood'**
  String get entBloodOffer;

  /// No description provided for @entMemory.
  ///
  /// In en, this message translates to:
  /// **'a memory'**
  String get entMemory;

  /// No description provided for @entCause.
  ///
  /// In en, this message translates to:
  /// **'a fund cause'**
  String get entCause;

  /// No description provided for @entContribution.
  ///
  /// In en, this message translates to:
  /// **'a contribution'**
  String get entContribution;

  /// No description provided for @entPayout.
  ///
  /// In en, this message translates to:
  /// **'a payout'**
  String get entPayout;

  /// No description provided for @entMentor.
  ///
  /// In en, this message translates to:
  /// **'an offer to mentor'**
  String get entMentor;

  /// No description provided for @entStudent.
  ///
  /// In en, this message translates to:
  /// **'a request for guidance'**
  String get entStudent;

  /// No description provided for @entOpportunity.
  ///
  /// In en, this message translates to:
  /// **'an opportunity'**
  String get entOpportunity;

  /// No description provided for @entPoll.
  ///
  /// In en, this message translates to:
  /// **'a poll'**
  String get entPoll;

  /// No description provided for @entStory.
  ///
  /// In en, this message translates to:
  /// **'an elder\'s story'**
  String get entStory;

  /// No description provided for @entInvite.
  ///
  /// In en, this message translates to:
  /// **'an invite link'**
  String get entInvite;

  /// No description provided for @entOther.
  ///
  /// In en, this message translates to:
  /// **'something'**
  String get entOther;

  /// No description provided for @pageHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get pageHome;

  /// No description provided for @pagePerson.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s page'**
  String pagePerson(String name);

  /// No description provided for @pageAPerson.
  ///
  /// In en, this message translates to:
  /// **'a person\'s page'**
  String get pageAPerson;

  /// No description provided for @pageAnEvent.
  ///
  /// In en, this message translates to:
  /// **'an event'**
  String get pageAnEvent;

  /// No description provided for @pageAMoment.
  ///
  /// In en, this message translates to:
  /// **'a moment'**
  String get pageAMoment;

  /// No description provided for @pageAnAlbum.
  ///
  /// In en, this message translates to:
  /// **'an album'**
  String get pageAnAlbum;

  /// No description provided for @pageAPhoto.
  ///
  /// In en, this message translates to:
  /// **'a photo'**
  String get pageAPhoto;

  /// No description provided for @pageAConversation.
  ///
  /// In en, this message translates to:
  /// **'a mentorship conversation'**
  String get pageAConversation;

  /// No description provided for @pageSignIn.
  ///
  /// In en, this message translates to:
  /// **'sign-in'**
  String get pageSignIn;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @orWord.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orWord;

  /// No description provided for @resetHowTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get resetHowTitle;

  /// No description provided for @resetByEmail.
  ///
  /// In en, this message translates to:
  /// **'Send a link to my email'**
  String get resetByEmail;

  /// No description provided for @resetByEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email above first.'**
  String get resetByEmailHint;

  /// No description provided for @resetByText.
  ///
  /// In en, this message translates to:
  /// **'Send a code to my phone'**
  String get resetByText;

  /// No description provided for @resetByTextHint.
  ///
  /// In en, this message translates to:
  /// **'The phone number saved on your profile'**
  String get resetByTextHint;

  /// No description provided for @sendResetCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendResetCode;

  /// No description provided for @resetCodeSentTo.
  ///
  /// In en, this message translates to:
  /// **'If {phone} is on an account, a code is on its way. It works for 10 minutes.'**
  String resetCodeSentTo(String phone);

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password (8 or more characters)'**
  String get newPasswordLabel;

  /// No description provided for @setNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Set new password'**
  String get setNewPassword;

  /// No description provided for @resetDone.
  ///
  /// In en, this message translates to:
  /// **'Password changed. Welcome back!'**
  String get resetDone;

  /// No description provided for @resetSmsOff.
  ///
  /// In en, this message translates to:
  /// **'Text messages are not set up yet. Use your email instead.'**
  String get resetSmsOff;

  /// No description provided for @resetTooMany.
  ///
  /// In en, this message translates to:
  /// **'Please wait a little before asking for another code.'**
  String get resetTooMany;

  /// No description provided for @resetWrongCode.
  ///
  /// In en, this message translates to:
  /// **'That code isn\'t right. Check the text message.'**
  String get resetWrongCode;

  /// No description provided for @resetExpired.
  ///
  /// In en, this message translates to:
  /// **'That code has expired. Ask for a new one.'**
  String get resetExpired;

  /// No description provided for @occIslamicNewYear.
  ///
  /// In en, this message translates to:
  /// **'Islamic New Year'**
  String get occIslamicNewYear;

  /// No description provided for @occAshura.
  ///
  /// In en, this message translates to:
  /// **'Ashura'**
  String get occAshura;

  /// No description provided for @occMawlid.
  ///
  /// In en, this message translates to:
  /// **'Mawlid'**
  String get occMawlid;

  /// No description provided for @occRamadan.
  ///
  /// In en, this message translates to:
  /// **'Ramadan begins'**
  String get occRamadan;

  /// No description provided for @occLaylatAlQadr.
  ///
  /// In en, this message translates to:
  /// **'Laylat al-Qadr (27th night)'**
  String get occLaylatAlQadr;

  /// No description provided for @occEidAlFitr.
  ///
  /// In en, this message translates to:
  /// **'Eid al-Fitr'**
  String get occEidAlFitr;

  /// No description provided for @occArafah.
  ///
  /// In en, this message translates to:
  /// **'Day of Arafah'**
  String get occArafah;

  /// No description provided for @occEidAlAdha.
  ///
  /// In en, this message translates to:
  /// **'Eid al-Adha'**
  String get occEidAlAdha;

  /// No description provided for @greetEidFitr.
  ///
  /// In en, this message translates to:
  /// **'Eid Mubarak! Barka da Sallah.'**
  String get greetEidFitr;

  /// No description provided for @greetEidAdha.
  ///
  /// In en, this message translates to:
  /// **'Eid Mubarak! Barka da Babbar Sallah.'**
  String get greetEidAdha;

  /// No description provided for @greetRamadan.
  ///
  /// In en, this message translates to:
  /// **'Ramadan Mubarak! May Allah accept our fasting.'**
  String get greetRamadan;

  /// No description provided for @greetNewYear.
  ///
  /// In en, this message translates to:
  /// **'Happy Islamic New Year {year}!'**
  String greetNewYear(int year);

  /// No description provided for @eveEidFitr.
  ///
  /// In en, this message translates to:
  /// **'Eid al-Fitr is expected tomorrow, if the moon is sighted.'**
  String get eveEidFitr;

  /// No description provided for @eveEidAdha.
  ///
  /// In en, this message translates to:
  /// **'Eid al-Adha is expected tomorrow.'**
  String get eveEidAdha;

  /// No description provided for @eveRamadan.
  ///
  /// In en, this message translates to:
  /// **'Ramadan is expected to begin tomorrow, if the moon is sighted.'**
  String get eveRamadan;

  /// No description provided for @greetingFrom.
  ///
  /// In en, this message translates to:
  /// **'From all of us in the {family} family'**
  String greetingFrom(String family);

  /// No description provided for @shareGreeting.
  ///
  /// In en, this message translates to:
  /// **'Share a greeting'**
  String get shareGreeting;

  /// No description provided for @islamicOccasions.
  ///
  /// In en, this message translates to:
  /// **'Islamic occasions'**
  String get islamicOccasions;

  /// No description provided for @moonNote.
  ///
  /// In en, this message translates to:
  /// **'Dates follow the Islamic calendar and can move a day with the moon sighting.'**
  String get moonNote;

  /// No description provided for @inDaysCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{today} =1{tomorrow} other{in {n} days}}'**
  String inDaysCount(int n);

  /// No description provided for @hijriSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Islamic calendar'**
  String get hijriSettingsTitle;

  /// No description provided for @hijriAdjust.
  ///
  /// In en, this message translates to:
  /// **'Moon sighting adjustment'**
  String get hijriAdjust;

  /// No description provided for @hijriAdjustHint.
  ///
  /// In en, this message translates to:
  /// **'If the new month was announced a day earlier than the app shows, add a day; a day later, take one away.'**
  String get hijriAdjustHint;

  /// No description provided for @hijriTodayIs.
  ///
  /// In en, this message translates to:
  /// **'Today in the app: {date}'**
  String hijriTodayIs(String date);

  /// No description provided for @islamicGreetingsToggle.
  ///
  /// In en, this message translates to:
  /// **'Greet the family on Ramadan, the Eids and the new year'**
  String get islamicGreetingsToggle;

  /// No description provided for @showHijriDates.
  ///
  /// In en, this message translates to:
  /// **'Show Islamic dates'**
  String get showHijriDates;

  /// No description provided for @showHijriDatesHint.
  ///
  /// In en, this message translates to:
  /// **'Next to dates, e.g. 21 Rabiʻ al-Thani 1448'**
  String get showHijriDatesHint;

  /// No description provided for @hijriNoAdjust.
  ///
  /// In en, this message translates to:
  /// **'No adjustment'**
  String get hijriNoAdjust;

  /// No description provided for @hijriDaysSigned.
  ///
  /// In en, this message translates to:
  /// **'{sign}{n, plural, =1{1 day} other{{n} days}}'**
  String hijriDaysSigned(String sign, int n);

  /// No description provided for @duesTitle.
  ///
  /// In en, this message translates to:
  /// **'Dues'**
  String get duesTitle;

  /// No description provided for @myDues.
  ///
  /// In en, this message translates to:
  /// **'My dues'**
  String get myDues;

  /// No description provided for @duesEvery.
  ///
  /// In en, this message translates to:
  /// **'{amount} {per}'**
  String duesEvery(String amount, String per);

  /// No description provided for @perMonth.
  ///
  /// In en, this message translates to:
  /// **'a month'**
  String get perMonth;

  /// No description provided for @perQuarter.
  ///
  /// In en, this message translates to:
  /// **'every 3 months'**
  String get perQuarter;

  /// No description provided for @perYear.
  ///
  /// In en, this message translates to:
  /// **'a year'**
  String get perYear;

  /// No description provided for @youOwe.
  ///
  /// In en, this message translates to:
  /// **'You owe {amount}'**
  String youOwe(String amount);

  /// No description provided for @owesAmount.
  ///
  /// In en, this message translates to:
  /// **'Owes {amount}'**
  String owesAmount(String amount);

  /// No description provided for @unpaidPeriods.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 period unpaid} other{{n} periods unpaid}}'**
  String unpaidPeriods(int n);

  /// No description provided for @paidUpTo.
  ///
  /// In en, this message translates to:
  /// **'Paid up to {date}'**
  String paidUpTo(String date);

  /// No description provided for @paidUpNothingYet.
  ///
  /// In en, this message translates to:
  /// **'Paid up'**
  String get paidUpNothingYet;

  /// No description provided for @duesExempt.
  ///
  /// In en, this message translates to:
  /// **'Exempt'**
  String get duesExempt;

  /// No description provided for @waitingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'{amount} waiting for confirmation'**
  String waitingConfirmation(String amount);

  /// No description provided for @payDues.
  ///
  /// In en, this message translates to:
  /// **'Pay dues'**
  String get payDues;

  /// No description provided for @payDuesTitle.
  ///
  /// In en, this message translates to:
  /// **'Pay: {title}'**
  String payDuesTitle(String title);

  /// No description provided for @myStatement.
  ///
  /// In en, this message translates to:
  /// **'My statement (PDF)'**
  String get myStatement;

  /// No description provided for @fundReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get fundReports;

  /// No description provided for @recordForMember.
  ///
  /// In en, this message translates to:
  /// **'Record a payment for a member'**
  String get recordForMember;

  /// No description provided for @newDuesPlan.
  ///
  /// In en, this message translates to:
  /// **'New dues plan'**
  String get newDuesPlan;

  /// No description provided for @editDuesPlan.
  ///
  /// In en, this message translates to:
  /// **'Edit plan'**
  String get editDuesPlan;

  /// No description provided for @planTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Name (e.g. Monthly dues)'**
  String get planTitleLabel;

  /// No description provided for @planPeriod.
  ///
  /// In en, this message translates to:
  /// **'How often'**
  String get planPeriod;

  /// No description provided for @periodMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get periodMonthly;

  /// No description provided for @periodQuarterly.
  ///
  /// In en, this message translates to:
  /// **'Every 3 months'**
  String get periodQuarterly;

  /// No description provided for @periodYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get periodYearly;

  /// No description provided for @planStarts.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get planStarts;

  /// No description provided for @planActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get planActive;

  /// No description provided for @planAutoRemind.
  ///
  /// In en, this message translates to:
  /// **'Remind those who owe at the start of each period'**
  String get planAutoRemind;

  /// No description provided for @noDuesPlans.
  ///
  /// In en, this message translates to:
  /// **'No dues yet. Create a plan for regular contributions, e.g. ₦2,000 a month.'**
  String get noDuesPlans;

  /// No description provided for @duesFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get duesFilterAll;

  /// No description provided for @duesFilterOwing.
  ///
  /// In en, this message translates to:
  /// **'Owing'**
  String get duesFilterOwing;

  /// No description provided for @duesFilterPaidUp.
  ///
  /// In en, this message translates to:
  /// **'Paid up'**
  String get duesFilterPaidUp;

  /// No description provided for @duesFilterExempt.
  ///
  /// In en, this message translates to:
  /// **'Exempt'**
  String get duesFilterExempt;

  /// No description provided for @duesSummaryLine.
  ///
  /// In en, this message translates to:
  /// **'{owing} of {total} owe · {owed} outstanding'**
  String duesSummaryLine(int owing, int total, String owed);

  /// No description provided for @remindOwing.
  ///
  /// In en, this message translates to:
  /// **'Remind those who owe'**
  String get remindOwing;

  /// No description provided for @remindedCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{Nobody to remind} =1{1 reminder sent} other{{n} reminders sent}}'**
  String remindedCount(int n);

  /// No description provided for @duesStartLabel.
  ///
  /// In en, this message translates to:
  /// **'Dues start'**
  String get duesStartLabel;

  /// No description provided for @exemptToggle.
  ///
  /// In en, this message translates to:
  /// **'Exempt from this plan'**
  String get exemptToggle;

  /// No description provided for @recordPaymentFrom.
  ///
  /// In en, this message translates to:
  /// **'Record a payment from {name}'**
  String recordPaymentFrom(String name);

  /// No description provided for @paymentRecorded.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded.'**
  String get paymentRecorded;

  /// No description provided for @chooseMember.
  ///
  /// In en, this message translates to:
  /// **'Who paid?'**
  String get chooseMember;

  /// No description provided for @forWhat.
  ///
  /// In en, this message translates to:
  /// **'For'**
  String get forWhat;

  /// No description provided for @notifDuesReminder.
  ///
  /// In en, this message translates to:
  /// **'{title}: you owe {owed}. Tap to pay.'**
  String notifDuesReminder(String title, String owed);

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Fund report'**
  String get reportTitle;

  /// No description provided for @periodThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get periodThisMonth;

  /// No description provided for @periodLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get periodLastMonth;

  /// No description provided for @periodThisYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get periodThisYear;

  /// No description provided for @periodLastYear.
  ///
  /// In en, this message translates to:
  /// **'Last year'**
  String get periodLastYear;

  /// No description provided for @openingLabel.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get openingLabel;

  /// No description provided for @moneyIn.
  ///
  /// In en, this message translates to:
  /// **'Money in'**
  String get moneyIn;

  /// No description provided for @moneyOut.
  ///
  /// In en, this message translates to:
  /// **'Money out'**
  String get moneyOut;

  /// No description provided for @closingLabel.
  ///
  /// In en, this message translates to:
  /// **'Closing balance'**
  String get closingLabel;

  /// No description provided for @bySourceTitle.
  ///
  /// In en, this message translates to:
  /// **'By cause and dues'**
  String get bySourceTitle;

  /// No description provided for @monthByMonth.
  ///
  /// In en, this message translates to:
  /// **'Month by month'**
  String get monthByMonth;

  /// No description provided for @transactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'All transactions'**
  String get transactionsTitle;

  /// No description provided for @duesStandingTitle.
  ///
  /// In en, this message translates to:
  /// **'Dues standing'**
  String get duesStandingTitle;

  /// No description provided for @paymentsFrom.
  ///
  /// In en, this message translates to:
  /// **'{p, plural, =1{1 payment} other{{p} payments}} from {c, plural, =1{1 member} other{{c} members}}'**
  String paymentsFrom(int p, int c);

  /// No description provided for @reportGenerated.
  ///
  /// In en, this message translates to:
  /// **'Generated {date}'**
  String reportGenerated(String date);

  /// No description provided for @reportCommitteeNote.
  ///
  /// In en, this message translates to:
  /// **'Members see the totals. Names and amounts are shown to the committee only.'**
  String get reportCommitteeNote;

  /// No description provided for @downloadPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get downloadPdf;

  /// No description provided for @statementFor.
  ///
  /// In en, this message translates to:
  /// **'Statement for {name}'**
  String statementFor(String name);

  /// No description provided for @contributionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Contributions'**
  String get contributionsLabel;

  /// No description provided for @statusConfirmedLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get statusConfirmedLabel;

  /// No description provided for @inOut.
  ///
  /// In en, this message translates to:
  /// **'In'**
  String get inOut;

  /// No description provided for @outLabel.
  ///
  /// In en, this message translates to:
  /// **'Out'**
  String get outLabel;

  /// No description provided for @nothingInPeriod.
  ///
  /// In en, this message translates to:
  /// **'No money in or out in this period.'**
  String get nothingInPeriod;

  /// No description provided for @searchByName.
  ///
  /// In en, this message translates to:
  /// **'Search by name'**
  String get searchByName;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'How it was paid'**
  String get paymentMethod;

  /// No description provided for @filterClaims.
  ///
  /// In en, this message translates to:
  /// **'Claims'**
  String get filterClaims;

  /// No description provided for @claimTitle.
  ///
  /// In en, this message translates to:
  /// **'Says this is them in the tree'**
  String get claimTitle;

  /// No description provided for @claimConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm & link'**
  String get claimConfirm;

  /// No description provided for @claimDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get claimDecline;

  /// No description provided for @claimDeclineTitle.
  ///
  /// In en, this message translates to:
  /// **'Decline this claim?'**
  String get claimDeclineTitle;

  /// No description provided for @claimDeclineReason.
  ///
  /// In en, this message translates to:
  /// **'Reason for them (optional)'**
  String get claimDeclineReason;

  /// No description provided for @claimAlreadyLinked.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s account is already linked to this person. Unlink it first if this claim is right.'**
  String claimAlreadyLinked(String name);

  /// No description provided for @claimConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Linked. They\'ll be told.'**
  String get claimConfirmed;

  /// No description provided for @claimDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined. They\'ll be told.'**
  String get claimDeclined;

  /// No description provided for @claimsOnPerson.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Someone says this is them} other{{n} people say this is them}}'**
  String claimsOnPerson(int n);

  /// No description provided for @personFacts.
  ///
  /// In en, this message translates to:
  /// **'Born {born} · {parents}'**
  String personFacts(String born, String parents);

  /// No description provided for @childOf.
  ///
  /// In en, this message translates to:
  /// **'child of {names}'**
  String childOf(String names);

  /// No description provided for @notifClaimApproved.
  ///
  /// In en, this message translates to:
  /// **'You\'re now linked to {person} in the family tree.'**
  String notifClaimApproved(String person);

  /// No description provided for @notifClaimDeclined.
  ///
  /// In en, this message translates to:
  /// **'Your request to be linked to {person} was declined.'**
  String notifClaimDeclined(String person);

  /// No description provided for @notifClaimDeclinedWhy.
  ///
  /// In en, this message translates to:
  /// **'Your request to be linked to {person} was declined: “{reason}”'**
  String notifClaimDeclinedWhy(String person, String reason);

  /// No description provided for @showDetails.
  ///
  /// In en, this message translates to:
  /// **'Show details'**
  String get showDetails;

  /// No description provided for @hideDetails.
  ///
  /// In en, this message translates to:
  /// **'Hide details'**
  String get hideDetails;

  /// No description provided for @viewPhoto.
  ///
  /// In en, this message translates to:
  /// **'View photo'**
  String get viewPhoto;

  /// No description provided for @changePhoto2.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhoto2;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @searchEverything.
  ///
  /// In en, this message translates to:
  /// **'Search people, moments, events, stories…'**
  String get searchEverything;

  /// No description provided for @searchAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get searchAll;

  /// No description provided for @kindPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get kindPeople;

  /// No description provided for @kindPost.
  ///
  /// In en, this message translates to:
  /// **'Moments'**
  String get kindPost;

  /// No description provided for @kindEvent.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get kindEvent;

  /// No description provided for @kindAlbum.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get kindAlbum;

  /// No description provided for @kindPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get kindPhoto;

  /// No description provided for @kindStory.
  ///
  /// In en, this message translates to:
  /// **'Elders\' stories'**
  String get kindStory;

  /// No description provided for @kindCause.
  ///
  /// In en, this message translates to:
  /// **'Welfare fund'**
  String get kindCause;

  /// No description provided for @kindPoll.
  ///
  /// In en, this message translates to:
  /// **'Polls'**
  String get kindPoll;

  /// No description provided for @kindOpportunity.
  ///
  /// In en, this message translates to:
  /// **'Opportunities'**
  String get kindOpportunity;

  /// No description provided for @kindMemory.
  ///
  /// In en, this message translates to:
  /// **'Memories'**
  String get kindMemory;

  /// No description provided for @kindSkill.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get kindSkill;

  /// No description provided for @kindWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get kindWork;

  /// No description provided for @recentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get recentSearches;

  /// No description provided for @clearRecent.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearRecent;

  /// No description provided for @searchNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing found for “{q}”.'**
  String searchNothing(String q);

  /// No description provided for @searchTypeMore.
  ///
  /// In en, this message translates to:
  /// **'Type at least 2 letters.'**
  String get searchTypeMore;

  /// No description provided for @searchTips.
  ///
  /// In en, this message translates to:
  /// **'Try a name, a place, a word from a moment, a skill like “nurse”, or an event.'**
  String get searchTips;

  /// No description provided for @showAllCount.
  ///
  /// In en, this message translates to:
  /// **'Show all {n}'**
  String showAllCount(int n);

  /// No description provided for @familyMakeup.
  ///
  /// In en, this message translates to:
  /// **'Who is in the family'**
  String get familyMakeup;

  /// No description provided for @menLabel.
  ///
  /// In en, this message translates to:
  /// **'Men'**
  String get menLabel;

  /// No description provided for @womenLabel.
  ///
  /// In en, this message translates to:
  /// **'Women'**
  String get womenLabel;

  /// No description provided for @sexNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get sexNotSet;

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @bloodFamily.
  ///
  /// In en, this message translates to:
  /// **'Blood family'**
  String get bloodFamily;

  /// No description provided for @marriedIn.
  ///
  /// In en, this message translates to:
  /// **'Married in'**
  String get marriedIn;

  /// No description provided for @notConnectedYet.
  ///
  /// In en, this message translates to:
  /// **'Not connected yet'**
  String get notConnectedYet;

  /// No description provided for @livingMenWomen.
  ///
  /// In en, this message translates to:
  /// **'Living: {men} men · {women} women'**
  String livingMenWomen(int men, int women);

  /// No description provided for @familyMakeupHelp.
  ///
  /// In en, this message translates to:
  /// **'Blood family: the founders and everyone born or adopted into the line. Married in: their husbands and wives who came from outside.'**
  String get familyMakeupHelp;

  /// No description provided for @viewTree.
  ///
  /// In en, this message translates to:
  /// **'Whole tree'**
  String get viewTree;

  /// No description provided for @viewFamilyLine.
  ///
  /// In en, this message translates to:
  /// **'Family line'**
  String get viewFamilyLine;

  /// No description provided for @childrenWithParent.
  ///
  /// In en, this message translates to:
  /// **'With {name}'**
  String childrenWithParent(String name);

  /// No description provided for @childCountShort.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No children recorded} =1{1 child} other{{count} children}}'**
  String childCountShort(int count);

  /// No description provided for @grandchildrenCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 grandchild} other{{count} grandchildren}}'**
  String grandchildrenCount(int count);

  /// No description provided for @descendantsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 descendant} other{{count} descendants}}'**
  String descendantsCount(int count);

  /// No description provided for @openProfile.
  ///
  /// In en, this message translates to:
  /// **'Open profile'**
  String get openProfile;

  /// No description provided for @upTo.
  ///
  /// In en, this message translates to:
  /// **'Up to {name}'**
  String upTo(String name);

  /// No description provided for @familyLineHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a child to see their family.'**
  String get familyLineHint;

  /// No description provided for @noChildrenYet.
  ///
  /// In en, this message translates to:
  /// **'No children recorded yet.'**
  String get noChildrenYet;

  /// No description provided for @childrenHeading.
  ///
  /// In en, this message translates to:
  /// **'Children ({count})'**
  String childrenHeading(int count);

  /// No description provided for @parentsNames.
  ///
  /// In en, this message translates to:
  /// **'Parents: {names}'**
  String parentsNames(String names);

  /// No description provided for @deleteMyAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteMyAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountGone.
  ///
  /// In en, this message translates to:
  /// **'Removed for good: your sign-in, phone and email, and what you shared: moments, comments, likes, photos you uploaded, memories, messages and requests.'**
  String get deleteAccountGone;

  /// No description provided for @deleteAccountKept.
  ///
  /// In en, this message translates to:
  /// **'Kept for the family, without your name: your place in the family tree, albums and events you created, polls, elders\' stories you recorded, and welfare fund payments.'**
  String get deleteAccountKept;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'I understand this can\'t be undone'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteAccountOnlyAdmin.
  ///
  /// In en, this message translates to:
  /// **'You are the only admin. Make someone else an admin first.'**
  String get deleteAccountOnlyAdmin;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Your account was deleted.'**
  String get accountDeleted;

  /// No description provided for @getOnPlay.
  ///
  /// In en, this message translates to:
  /// **'Get it on Google Play'**
  String get getOnPlay;

  /// No description provided for @downloadApkInstead.
  ///
  /// In en, this message translates to:
  /// **'Or download the app file (APK)'**
  String get downloadApkInstead;

  /// No description provided for @updateOnPlay.
  ///
  /// In en, this message translates to:
  /// **'Update on Google Play'**
  String get updateOnPlay;

  /// No description provided for @playStoreLink.
  ///
  /// In en, this message translates to:
  /// **'Google Play link'**
  String get playStoreLink;

  /// No description provided for @playStoreLinkHelp.
  ///
  /// In en, this message translates to:
  /// **'Once the app is on Google Play, paste its link here. The download page then sends people to Play.'**
  String get playStoreLinkHelp;

  /// No description provided for @playStoreLinkInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use the link from Google Play (https://play.google.com/…).'**
  String get playStoreLinkInvalid;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @notifWeeklySummary.
  ///
  /// In en, this message translates to:
  /// **'This week: {active} active, {moments} moments, {photos} photos, {moneyIn} in.'**
  String notifWeeklySummary(
    int active,
    int moments,
    int photos,
    String moneyIn,
  );

  /// No description provided for @notifWeeklyWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count} waiting for you.'**
  String notifWeeklyWaiting(int count);

  /// No description provided for @notifAlertBlood.
  ///
  /// In en, this message translates to:
  /// **'No donor yet for {group} blood for {patient} ({hours} h). Please call around.'**
  String notifAlertBlood(String group, String patient, int hours);

  /// No description provided for @notifAlertWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting over 3 days: {suggestions} suggestions, {accounts} new accounts.'**
  String notifAlertWaiting(int suggestions, int accounts);

  /// No description provided for @notifAlertFundLow.
  ///
  /// In en, this message translates to:
  /// **'The welfare fund is down to {balance}, below {threshold}.'**
  String notifAlertFundLow(String balance, String threshold);

  /// No description provided for @adminUpdatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin updates'**
  String get adminUpdatesTitle;

  /// No description provided for @weeklySummaryToggle.
  ///
  /// In en, this message translates to:
  /// **'Weekly summary on Monday mornings'**
  String get weeklySummaryToggle;

  /// No description provided for @weeklySummaryHint.
  ///
  /// In en, this message translates to:
  /// **'What happened in the week and what\'s waiting, for every admin.'**
  String get weeklySummaryHint;

  /// No description provided for @fundAlertBelow.
  ///
  /// In en, this message translates to:
  /// **'Warn when the fund is below'**
  String get fundAlertBelow;

  /// No description provided for @fundAlertHint.
  ///
  /// In en, this message translates to:
  /// **'Admins and treasurers are told once each time the balance drops below this.'**
  String get fundAlertHint;

  /// No description provided for @offLabel.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get offLabel;

  /// No description provided for @alertsAlwaysOn.
  ///
  /// In en, this message translates to:
  /// **'Admins are also alerted when a blood request has no offer after 2 hours, and when suggestions or accounts wait over 3 days.'**
  String get alertsAlwaysOn;

  /// No description provided for @notifWeeklyForAdmins.
  ///
  /// In en, this message translates to:
  /// **'Weekly summary (admins)'**
  String get notifWeeklyForAdmins;

  /// No description provided for @messagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messagesTitle;

  /// No description provided for @newMessage.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get newMessage;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet. Start a conversation with someone in the family.'**
  String get noMessagesYet;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get sendMessage;

  /// No description provided for @dmPrivate.
  ///
  /// In en, this message translates to:
  /// **'Only the two of you can see these messages.'**
  String get dmPrivate;

  /// No description provided for @startConversation.
  ///
  /// In en, this message translates to:
  /// **'Start the conversation.'**
  String get startConversation;

  /// No description provided for @notifDirectMessage.
  ///
  /// In en, this message translates to:
  /// **'{name}: “{body}”'**
  String notifDirectMessage(String name, String body);

  /// No description provided for @noOtherMembers.
  ///
  /// In en, this message translates to:
  /// **'No other family members have accounts yet.'**
  String get noOtherMembers;

  /// No description provided for @messageWho.
  ///
  /// In en, this message translates to:
  /// **'Message who?'**
  String get messageWho;

  /// No description provided for @conversationNotFound.
  ///
  /// In en, this message translates to:
  /// **'This conversation isn\'t available.'**
  String get conversationNotFound;

  /// No description provided for @familyBookSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Family book'**
  String get familyBookSubtitle;

  /// No description provided for @familyBookCover.
  ///
  /// In en, this message translates to:
  /// **'From {founder} · {people} people · {generations} generations'**
  String familyBookCover(String founder, int people, int generations);

  /// No description provided for @generationHeading.
  ///
  /// In en, this message translates to:
  /// **'Generation {n}'**
  String generationHeading(int n);

  /// No description provided for @bookMarriedTo.
  ///
  /// In en, this message translates to:
  /// **'Married to {names}'**
  String bookMarriedTo(String names);

  /// No description provided for @bookChildren.
  ///
  /// In en, this message translates to:
  /// **'Children: {names}'**
  String bookChildren(String names);

  /// No description provided for @bookBornIn.
  ///
  /// In en, this message translates to:
  /// **'Born in {place}'**
  String bookBornIn(String place);

  /// No description provided for @bookBuriedIn.
  ///
  /// In en, this message translates to:
  /// **'Buried in {place}'**
  String bookBuriedIn(String place);

  /// No description provided for @bookAlsoInTree.
  ///
  /// In en, this message translates to:
  /// **'Also in the family tree'**
  String get bookAlsoInTree;

  /// No description provided for @bookIndex.
  ///
  /// In en, this message translates to:
  /// **'Index of names'**
  String get bookIndex;

  /// No description provided for @bookMadeOn.
  ///
  /// In en, this message translates to:
  /// **'Made with the Bua Family app on {date}'**
  String bookMadeOn(String date);

  /// No description provided for @bookHowToRead.
  ///
  /// In en, this message translates to:
  /// **'Everyone in the line of {founder}, generation by generation. Each person has a number: their children add a number to it (1.2 is the second child of 1, 1.2.3 the third child of 1.2).'**
  String bookHowToRead(String founder);

  /// No description provided for @familyBookAction.
  ///
  /// In en, this message translates to:
  /// **'Family book (PDF)'**
  String get familyBookAction;

  /// No description provided for @familyBookHint.
  ///
  /// In en, this message translates to:
  /// **'Everyone from the forefather down, generation by generation, with photos and life stories. Contact and health details are left out.'**
  String get familyBookHint;

  /// No description provided for @includePhotos.
  ///
  /// In en, this message translates to:
  /// **'Include photos'**
  String get includePhotos;

  /// No description provided for @includePhotosHint.
  ///
  /// In en, this message translates to:
  /// **'Slower, and a bigger file.'**
  String get includePhotosHint;

  /// No description provided for @makeBook.
  ///
  /// In en, this message translates to:
  /// **'Make the book'**
  String get makeBook;

  /// No description provided for @makingBook.
  ///
  /// In en, this message translates to:
  /// **'Making the family book…'**
  String get makingBook;

  /// No description provided for @whoCame.
  ///
  /// In en, this message translates to:
  /// **'Who came'**
  String get whoCame;

  /// No description provided for @whoCameCount.
  ///
  /// In en, this message translates to:
  /// **'Who came ({count})'**
  String whoCameCount(int count);

  /// No description provided for @imHere.
  ///
  /// In en, this message translates to:
  /// **'I\'m here'**
  String get imHere;

  /// No description provided for @youCame.
  ///
  /// In en, this message translates to:
  /// **'You\'re marked as here.'**
  String get youCame;

  /// No description provided for @undoLabel.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undoLabel;

  /// No description provided for @markWhoCame.
  ///
  /// In en, this message translates to:
  /// **'Mark who came'**
  String get markWhoCame;

  /// No description provided for @noOneMarkedYet.
  ///
  /// In en, this message translates to:
  /// **'No one marked yet.'**
  String get noOneMarkedYet;

  /// No description provided for @eventPhotosHint.
  ///
  /// In en, this message translates to:
  /// **'Share the photos from this day.'**
  String get eventPhotosHint;

  /// No description provided for @eventPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Photos from the day'**
  String get eventPhotosTitle;

  /// No description provided for @shareLabel.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareLabel;

  /// No description provided for @shareHint.
  ///
  /// In en, this message translates to:
  /// **'The link shows a card on WhatsApp; only family members can open what\'s inside.'**
  String get shareHint;

  /// No description provided for @appearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// No description provided for @themeLabel.
  ///
  /// In en, this message translates to:
  /// **'Colours'**
  String get themeLabel;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @textSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSizeLabel;

  /// No description provided for @textNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get textNormal;

  /// No description provided for @textLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get textLarge;

  /// No description provided for @textLarger.
  ///
  /// In en, this message translates to:
  /// **'Larger'**
  String get textLarger;

  /// No description provided for @textSizeSample.
  ///
  /// In en, this message translates to:
  /// **'This is how text will look.'**
  String get textSizeSample;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ha'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ha':
      return AppLocalizationsHa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
