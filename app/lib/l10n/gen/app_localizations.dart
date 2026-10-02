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
