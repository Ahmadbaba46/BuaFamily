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
  /// **'Spreadsheet (CSV)'**
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
