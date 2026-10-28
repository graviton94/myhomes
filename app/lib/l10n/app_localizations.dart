import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
    Locale('ko'),
  ];

  /// App name shown in the header and about screen.
  ///
  /// In en, this message translates to:
  /// **'Home Fairy'**
  String get appTitle;

  /// No description provided for @fairyName.
  ///
  /// In en, this message translates to:
  /// **'House Fairy'**
  String get fairyName;

  /// No description provided for @myHome.
  ///
  /// In en, this message translates to:
  /// **'My home'**
  String get myHome;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSpaces.
  ///
  /// In en, this message translates to:
  /// **'Spaces'**
  String get navSpaces;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navExpiry.
  ///
  /// In en, this message translates to:
  /// **'Use by'**
  String get navExpiry;

  /// No description provided for @navFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get navFamily;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi! I\'ll remember where everything is.'**
  String get homeGreeting;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'What are you looking for?'**
  String get searchHint;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s map your home'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Start with one room, like the living room or kitchen. Then add the drawers and shelves inside it.'**
  String get homeEmptyBody;

  /// No description provided for @addSpace.
  ///
  /// In en, this message translates to:
  /// **'Add a space'**
  String get addSpace;

  /// No description provided for @spacesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No spaces yet'**
  String get spacesEmptyTitle;

  /// No description provided for @spacesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Rooms you add will show up here with their storage spots.'**
  String get spacesEmptyBody;

  /// No description provided for @searchEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to search yet'**
  String get searchEmptyTitle;

  /// No description provided for @searchEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Once you add items, type a name and I\'ll show you exactly where it is.'**
  String get searchEmptyBody;

  /// No description provided for @expiryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing is about to expire'**
  String get expiryEmptyTitle;

  /// No description provided for @expiryEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add a use-by date to food or medicine and I\'ll remind you on D-3, D-1 and the day.'**
  String get expiryEmptyBody;

  /// No description provided for @familyEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Share your home'**
  String get familyEmptyTitle;

  /// No description provided for @familyEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Invite your family so everyone can find things and keep counts up to date.'**
  String get familyEmptyBody;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming in a later build.'**
  String get comingSoon;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Same as phone'**
  String get languageSystem;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'Same as phone'**
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

  /// No description provided for @designSample.
  ///
  /// In en, this message translates to:
  /// **'Design sample'**
  String get designSample;

  /// No description provided for @designSampleBody.
  ///
  /// In en, this message translates to:
  /// **'Colours, type and parts used across the app.'**
  String get designSampleBody;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @sampleColors.
  ///
  /// In en, this message translates to:
  /// **'Colours'**
  String get sampleColors;

  /// No description provided for @sampleType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get sampleType;

  /// No description provided for @sampleParts.
  ///
  /// In en, this message translates to:
  /// **'Parts'**
  String get sampleParts;

  /// No description provided for @sampleFairy.
  ///
  /// In en, this message translates to:
  /// **'House Fairy'**
  String get sampleFairy;

  /// No description provided for @sampleButtonPrimary.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get sampleButtonPrimary;

  /// No description provided for @sampleButtonSecondary.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get sampleButtonSecondary;

  /// No description provided for @sampleButtonText.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get sampleButtonText;

  /// No description provided for @sampleCategoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get sampleCategoryFood;

  /// No description provided for @sampleCategoryHousehold.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get sampleCategoryHousehold;

  /// No description provided for @sampleCategoryTools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get sampleCategoryTools;

  /// No description provided for @sampleCategoryMedicine.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get sampleCategoryMedicine;

  /// No description provided for @sampleSlotEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty slot'**
  String get sampleSlotEmpty;

  /// No description provided for @sampleSlotFilled.
  ///
  /// In en, this message translates to:
  /// **'AA batteries, 8'**
  String get sampleSlotFilled;

  /// No description provided for @sampleSlotSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get sampleSlotSelected;

  /// No description provided for @sampleSlotExpiring.
  ///
  /// In en, this message translates to:
  /// **'Milk, expiring soon'**
  String get sampleSlotExpiring;

  /// No description provided for @sampleSlotChosen.
  ///
  /// In en, this message translates to:
  /// **'4 of 8 chosen'**
  String get sampleSlotChosen;

  /// No description provided for @fairyHello.
  ///
  /// In en, this message translates to:
  /// **'Hello!'**
  String get fairyHello;

  /// No description provided for @fairyFound.
  ///
  /// In en, this message translates to:
  /// **'Found it!'**
  String get fairyFound;

  /// No description provided for @fairyCarry.
  ///
  /// In en, this message translates to:
  /// **'Heave-ho'**
  String get fairyCarry;

  /// No description provided for @fairyWorry.
  ///
  /// In en, this message translates to:
  /// **'Oh no'**
  String get fairyWorry;

  /// No description provided for @fairyCheer.
  ///
  /// In en, this message translates to:
  /// **'Well done'**
  String get fairyCheer;

  /// No description provided for @fairySleep.
  ///
  /// In en, this message translates to:
  /// **'Zzz'**
  String get fairySleep;

  /// No description provided for @expiryOverdue.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day over} other{{days} days over}}'**
  String expiryOverdue(int days);

  /// No description provided for @expiryToday.
  ///
  /// In en, this message translates to:
  /// **'Use today'**
  String get expiryToday;

  /// No description provided for @expiryTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Use by tomorrow'**
  String get expiryTomorrow;

  /// No description provided for @expiryDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'D-{days}'**
  String expiryDaysLeft(int days);

  /// No description provided for @expiryOk.
  ///
  /// In en, this message translates to:
  /// **'Fresh'**
  String get expiryOk;

  /// No description provided for @splashLoading.
  ///
  /// In en, this message translates to:
  /// **'Waking the fairy...'**
  String get splashLoading;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @pageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {total}'**
  String pageOf(int page, int total);

  /// No description provided for @intro1Title.
  ///
  /// In en, this message translates to:
  /// **'Ask, and find it'**
  String get intro1Title;

  /// No description provided for @intro1Body.
  ///
  /// In en, this message translates to:
  /// **'Type or say it in the one search box. The fairy finds it even when the name is a little different.'**
  String get intro1Body;

  /// No description provided for @intro2Title.
  ///
  /// In en, this message translates to:
  /// **'Put things away in one sentence'**
  String get intro2Title;

  /// No description provided for @intro2Body.
  ///
  /// In en, this message translates to:
  /// **'Pick a spot and write everything at once. Same names are added together.'**
  String get intro2Body;

  /// No description provided for @intro3Title.
  ///
  /// In en, this message translates to:
  /// **'Fill it in with your family'**
  String get intro3Title;

  /// No description provided for @intro3Body.
  ///
  /// In en, this message translates to:
  /// **'Sign in to invite your family. Each fills their own room and the whole home is done.'**
  String get intro3Body;

  /// No description provided for @loginTagline.
  ///
  /// In en, this message translates to:
  /// **'Your home, remembered by the fairy.'**
  String get loginTagline;

  /// No description provided for @loginKakao.
  ///
  /// In en, this message translates to:
  /// **'Login with Kakao'**
  String get loginKakao;

  /// No description provided for @loginNaver.
  ///
  /// In en, this message translates to:
  /// **'Log in with NAVER'**
  String get loginNaver;

  /// No description provided for @loginGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get loginGoogle;

  /// No description provided for @loginSoon.
  ///
  /// In en, this message translates to:
  /// **'Sign-in opens soon'**
  String get loginSoon;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @startWithoutAccount.
  ///
  /// In en, this message translates to:
  /// **'Start without an account'**
  String get startWithoutAccount;

  /// No description provided for @guestNote.
  ///
  /// In en, this message translates to:
  /// **'Everything stays on this phone. You can sign in later to share with family.'**
  String get guestNote;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

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

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @choose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get choose;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @increase.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get increase;

  /// No description provided for @decrease.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get decrease;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @actionMove.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get actionMove;

  /// No description provided for @actionTakeOut.
  ///
  /// In en, this message translates to:
  /// **'Take out'**
  String get actionTakeOut;

  /// No description provided for @makeStorageFirst.
  ///
  /// In en, this message translates to:
  /// **'Add a space and a storage spot first.'**
  String get makeStorageFirst;

  /// No description provided for @addWhere.
  ///
  /// In en, this message translates to:
  /// **'Add to which spot?'**
  String get addWhere;

  /// No description provided for @moveFromWhere.
  ///
  /// In en, this message translates to:
  /// **'Move from which spot?'**
  String get moveFromWhere;

  /// No description provided for @takeOutFromWhere.
  ///
  /// In en, this message translates to:
  /// **'Take out from which spot?'**
  String get takeOutFromWhere;

  /// No description provided for @eatFirst.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Use first · 1 item} other{Use first · {count} items}}'**
  String eatFirst(int count);

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Empty} =1{1 item} other{{count} items}}'**
  String itemsCount(int count);

  /// No description provided for @spaceSummary.
  ///
  /// In en, this message translates to:
  /// **'{storages, plural, =1{1 spot} other{{storages} spots}} · {items, plural, =1{1 item} other{{items} items}}'**
  String spaceSummary(int storages, int items);

  /// No description provided for @addStorage.
  ///
  /// In en, this message translates to:
  /// **'Add a storage spot'**
  String get addStorage;

  /// No description provided for @editStorage.
  ///
  /// In en, this message translates to:
  /// **'Edit storage spot'**
  String get editStorage;

  /// No description provided for @spaceNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name (e.g. Kitchen)'**
  String get spaceNameHint;

  /// No description provided for @storageNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name (e.g. Drawer 2)'**
  String get storageNameHint;

  /// No description provided for @spaceEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No storage spots yet'**
  String get spaceEmptyTitle;

  /// No description provided for @spaceEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add the drawers, shelves and boxes in this room.'**
  String get spaceEmptyBody;

  /// No description provided for @deleteSpaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteSpaceTitle(String name);

  /// No description provided for @deleteSpaceBody.
  ///
  /// In en, this message translates to:
  /// **'Every storage spot and item in this space will be deleted too.'**
  String get deleteSpaceBody;

  /// No description provided for @deleteStorageTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteStorageTitle(String name);

  /// No description provided for @deleteStorageBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{This spot is empty.} =1{The 1 item inside will be deleted too.} other{The {count} items inside will be deleted too.}}'**
  String deleteStorageBody(int count);

  /// No description provided for @noStorageYet.
  ///
  /// In en, this message translates to:
  /// **'No storage spots yet. Add one from a space.'**
  String get noStorageYet;

  /// No description provided for @recentPlaces.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recentPlaces;

  /// No description provided for @storageHint.
  ///
  /// In en, this message translates to:
  /// **'Tap an empty square to add, or an item to use or move it. Hold an item and drag it to another square to move it; hold and let go to pick several.'**
  String get storageHint;

  /// No description provided for @selectHint.
  ///
  /// In en, this message translates to:
  /// **'Tap items to pick them and set how many.'**
  String get selectHint;

  /// No description provided for @pickSeveral.
  ///
  /// In en, this message translates to:
  /// **'Pick several'**
  String get pickSeveral;

  /// No description provided for @pickItems.
  ///
  /// In en, this message translates to:
  /// **'Pick items'**
  String get pickItems;

  /// No description provided for @pickedSummary.
  ///
  /// In en, this message translates to:
  /// **'{kinds, plural, =1{1 kind} other{{kinds} kinds}} · {total} pcs'**
  String pickedSummary(int kinds, int total);

  /// No description provided for @moveToWhere.
  ///
  /// In en, this message translates to:
  /// **'Move to which spot?'**
  String get moveToWhere;

  /// No description provided for @movedTo.
  ///
  /// In en, this message translates to:
  /// **'Moved {count} to {name}'**
  String movedTo(int count, String name);

  /// No description provided for @tookOut.
  ///
  /// In en, this message translates to:
  /// **'Took out {count}'**
  String tookOut(int count);

  /// No description provided for @usedUp.
  ///
  /// In en, this message translates to:
  /// **'Used up'**
  String get usedUp;

  /// No description provided for @usedUpKinds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item used up} other{{count} items used up}}'**
  String usedUpKinds(int count);

  /// No description provided for @usedUpName.
  ///
  /// In en, this message translates to:
  /// **'{name} used up'**
  String usedUpName(String name);

  /// No description provided for @emptySlot.
  ///
  /// In en, this message translates to:
  /// **'Empty square'**
  String get emptySlot;

  /// No description provided for @slotLabel.
  ///
  /// In en, this message translates to:
  /// **'{name}, {count}'**
  String slotLabel(String name, int count);

  /// No description provided for @howMany.
  ///
  /// In en, this message translates to:
  /// **'How many {name}?'**
  String howMany(String name);

  /// No description provided for @youHave.
  ///
  /// In en, this message translates to:
  /// **'You have {count}.'**
  String youHave(int count);

  /// No description provided for @qtyOne.
  ///
  /// In en, this message translates to:
  /// **'1'**
  String get qtyOne;

  /// No description provided for @qtyHalf.
  ///
  /// In en, this message translates to:
  /// **'Half ({count})'**
  String qtyHalf(int count);

  /// No description provided for @qtyAll.
  ///
  /// In en, this message translates to:
  /// **'All ({count})'**
  String qtyAll(int count);

  /// No description provided for @deselect.
  ///
  /// In en, this message translates to:
  /// **'Deselect'**
  String get deselect;

  /// No description provided for @qtyShort.
  ///
  /// In en, this message translates to:
  /// **'×{count}'**
  String qtyShort(int count);

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add an item'**
  String get addItem;

  /// No description provided for @editItem.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get editItem;

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// No description provided for @itemName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get itemName;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get nameRequired;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @categoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get categoryFood;

  /// No description provided for @categoryHousehold.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get categoryHousehold;

  /// No description provided for @categoryTools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get categoryTools;

  /// No description provided for @categoryMedicine.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get categoryMedicine;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @useBy.
  ///
  /// In en, this message translates to:
  /// **'Use by'**
  String get useBy;

  /// No description provided for @dueNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get dueNone;

  /// No description provided for @dueDays.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String dueDays(int count);

  /// No description provided for @dueWeek.
  ///
  /// In en, this message translates to:
  /// **'1 week'**
  String get dueWeek;

  /// No description provided for @dueMonth.
  ///
  /// In en, this message translates to:
  /// **'1 month'**
  String get dueMonth;

  /// No description provided for @duePick.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get duePick;

  /// No description provided for @useByDate.
  ///
  /// In en, this message translates to:
  /// **'Use by {date}'**
  String useByDate(String date);

  /// No description provided for @place.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get place;

  /// No description provided for @putWhere.
  ///
  /// In en, this message translates to:
  /// **'Put it where?'**
  String get putWhere;

  /// No description provided for @chooseAPlace.
  ///
  /// In en, this message translates to:
  /// **'Choose a place'**
  String get chooseAPlace;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'Brand, size, who it belongs to...'**
  String get noteHint;

  /// No description provided for @saveAndNext.
  ///
  /// In en, this message translates to:
  /// **'Save & add next'**
  String get saveAndNext;

  /// No description provided for @addedName.
  ///
  /// In en, this message translates to:
  /// **'Added {name}'**
  String addedName(String name);

  /// No description provided for @deletedName.
  ///
  /// In en, this message translates to:
  /// **'Deleted {name}'**
  String deletedName(String name);

  /// No description provided for @recentItems.
  ///
  /// In en, this message translates to:
  /// **'Recent items'**
  String get recentItems;

  /// No description provided for @searchTip.
  ///
  /// In en, this message translates to:
  /// **'Tip: type Korean initials (ㄱㅇ) or a location code like LIV-A1.'**
  String get searchTip;

  /// No description provided for @noResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No \"{query}\" yet'**
  String noResultsTitle(String query);

  /// No description provided for @noResultsBody.
  ///
  /// In en, this message translates to:
  /// **'Check the spelling, or add it where you keep it.'**
  String get noResultsBody;

  /// No description provided for @resultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 result} other{{count} results}}'**
  String resultsCount(int count);

  /// No description provided for @groupOverdue.
  ///
  /// In en, this message translates to:
  /// **'Past the date'**
  String get groupOverdue;

  /// No description provided for @groupSoon.
  ///
  /// In en, this message translates to:
  /// **'Within 3 days'**
  String get groupSoon;

  /// No description provided for @groupLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get groupLater;

  /// No description provided for @askFairy.
  ///
  /// In en, this message translates to:
  /// **'Ask the House Fairy'**
  String get askFairy;

  /// No description provided for @askFairyWithBadge.
  ///
  /// In en, this message translates to:
  /// **'Ask the House Fairy, {count} things to check'**
  String askFairyWithBadge(int count);

  /// No description provided for @fairySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ask where things are'**
  String get fairySubtitle;

  /// No description provided for @askFairyHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Where are the batteries?'**
  String get askFairyHint;

  /// No description provided for @fairyGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi! Ask me where anything is.'**
  String get fairyGreeting;

  /// No description provided for @fairyGreetingUrgent.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Hi! 1 thing needs using soon.} other{Hi! {count} things need using soon.}}'**
  String fairyGreetingUrgent(int count);

  /// No description provided for @fairyFoundCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Found it! Here it is.} other{Found {count}! Here they are.}}'**
  String fairyFoundCount(int count);

  /// No description provided for @fairyNotFound.
  ///
  /// In en, this message translates to:
  /// **'I couldn\'t find \"{query}\". Is it saved under another name?'**
  String fairyNotFound(String query);

  /// No description provided for @chipThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Use this week'**
  String get chipThisWeek;

  /// No description provided for @chipRunningLow.
  ///
  /// In en, this message translates to:
  /// **'Running low'**
  String get chipRunningLow;

  /// No description provided for @chipHowTo.
  ///
  /// In en, this message translates to:
  /// **'How do I use this?'**
  String get chipHowTo;

  /// No description provided for @fairyThisWeek.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 thing to use this week.} other{{count} things to use this week.}}'**
  String fairyThisWeek(int count);

  /// No description provided for @fairyNothingThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Nothing is due this week.'**
  String get fairyNothingThisWeek;

  /// No description provided for @fairyLow.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 thing is down to its last one.} other{{count} things are down to their last one.}}'**
  String fairyLow(int count);

  /// No description provided for @fairyNothingLow.
  ///
  /// In en, this message translates to:
  /// **'Nothing is running low.'**
  String get fairyNothingLow;

  /// No description provided for @fairyHowTo.
  ///
  /// In en, this message translates to:
  /// **'Make a space (a room), add storage spots inside, then tap empty squares to add things. Long-press items to move several at once.'**
  String get fairyHowTo;

  /// No description provided for @goSee.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get goSee;

  /// No description provided for @dataSection.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get dataSection;

  /// No description provided for @showIntroAgain.
  ///
  /// In en, this message translates to:
  /// **'Show the intro again'**
  String get showIntroAgain;

  /// No description provided for @deleteAllData.
  ///
  /// In en, this message translates to:
  /// **'Delete all data on this phone'**
  String get deleteAllData;

  /// No description provided for @deleteAllBody.
  ///
  /// In en, this message translates to:
  /// **'Every space, storage spot and item on this phone will be deleted. This cannot be undone.'**
  String get deleteAllBody;

  /// No description provided for @allDeleted.
  ///
  /// In en, this message translates to:
  /// **'All data deleted'**
  String get allDeleted;

  /// No description provided for @editSpace.
  ///
  /// In en, this message translates to:
  /// **'Edit space'**
  String get editSpace;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get addPhoto;

  /// No description provided for @addPhotoOptional.
  ///
  /// In en, this message translates to:
  /// **'Add a photo (optional)'**
  String get addPhotoOptional;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changePhoto;

  /// No description provided for @icon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get icon;

  /// No description provided for @moreIcons.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreIcons;

  /// No description provided for @chooseIcon.
  ///
  /// In en, this message translates to:
  /// **'Choose an icon'**
  String get chooseIcon;

  /// No description provided for @iconGroupRooms.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get iconGroupRooms;

  /// No description provided for @iconGroupFurniture.
  ///
  /// In en, this message translates to:
  /// **'Furniture & storage'**
  String get iconGroupFurniture;

  /// No description provided for @iconGroupFood.
  ///
  /// In en, this message translates to:
  /// **'Food & drink'**
  String get iconGroupFood;

  /// No description provided for @iconGroupHousehold.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get iconGroupHousehold;

  /// No description provided for @iconGroupTools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get iconGroupTools;

  /// No description provided for @iconGroupHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get iconGroupHealth;

  /// No description provided for @iconGroupClothes.
  ///
  /// In en, this message translates to:
  /// **'Clothes & accessories'**
  String get iconGroupClothes;

  /// No description provided for @iconGroupDevices.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get iconGroupDevices;

  /// No description provided for @iconGroupPapers.
  ///
  /// In en, this message translates to:
  /// **'Papers & money'**
  String get iconGroupPapers;

  /// No description provided for @iconGroupHobby.
  ///
  /// In en, this message translates to:
  /// **'Hobbies & more'**
  String get iconGroupHobby;

  /// No description provided for @addSpaceShort.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get addSpaceShort;

  /// No description provided for @editSpaceNamed.
  ///
  /// In en, this message translates to:
  /// **'Edit {name}'**
  String editSpaceNamed(String name);

  /// No description provided for @deleteSpaceNamed.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}'**
  String deleteSpaceNamed(String name);

  /// No description provided for @moveHere.
  ///
  /// In en, this message translates to:
  /// **'Move here'**
  String get moveHere;

  /// No description provided for @openStorage.
  ///
  /// In en, this message translates to:
  /// **'Open on its own'**
  String get openStorage;

  /// No description provided for @boardMoveHint.
  ///
  /// In en, this message translates to:
  /// **'Tap “Move here” on a storage spot, or Move to pick any place.'**
  String get boardMoveHint;

  /// No description provided for @boardFirstStorageHint.
  ///
  /// In en, this message translates to:
  /// **'Add the drawers, shelves and boxes in this room. Their squares show up right here.'**
  String get boardFirstStorageHint;

  /// No description provided for @outsideHome.
  ///
  /// In en, this message translates to:
  /// **'Outside'**
  String get outsideHome;

  /// No description provided for @addOutside.
  ///
  /// In en, this message translates to:
  /// **'Add a place outside'**
  String get addOutside;

  /// No description provided for @addOutsideShort.
  ///
  /// In en, this message translates to:
  /// **'Outside'**
  String get addOutsideShort;

  /// No description provided for @outsideNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name (e.g. Car, Office, Lent out)'**
  String get outsideNameHint;

  /// No description provided for @outsideStorageHint.
  ///
  /// In en, this message translates to:
  /// **'Name (e.g. Trunk, Lent to Alex)'**
  String get outsideStorageHint;

  /// No description provided for @returnByOptional.
  ///
  /// In en, this message translates to:
  /// **'Back by (optional)'**
  String get returnByOptional;

  /// No description provided for @returnOverdue.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day late} other{{days} days late}}'**
  String returnOverdue(int days);

  /// No description provided for @returnToday.
  ///
  /// In en, this message translates to:
  /// **'Back today'**
  String get returnToday;

  /// No description provided for @returnDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'Back in {days}d'**
  String returnDaysLeft(int days);

  /// No description provided for @groupReturns.
  ///
  /// In en, this message translates to:
  /// **'To get back'**
  String get groupReturns;

  /// No description provided for @iconGroupFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get iconGroupFamily;

  /// No description provided for @iconGroupPets.
  ///
  /// In en, this message translates to:
  /// **'Pets'**
  String get iconGroupPets;

  /// No description provided for @hereNow.
  ///
  /// In en, this message translates to:
  /// **'Here now'**
  String get hereNow;

  /// No description provided for @newStorageHere.
  ///
  /// In en, this message translates to:
  /// **'New spot'**
  String get newStorageHere;

  /// No description provided for @deleteStorageNamed.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}'**
  String deleteStorageNamed(String name);

  /// No description provided for @dockHint.
  ///
  /// In en, this message translates to:
  /// **'Hold over a room to open it, or drop it on the room'**
  String get dockHint;

  /// No description provided for @dockNoOtherRooms.
  ///
  /// In en, this message translates to:
  /// **'Add another room or place to move things between them'**
  String get dockNoOtherRooms;

  /// No description provided for @smartApplied.
  ///
  /// In en, this message translates to:
  /// **'The fairy picked the category and icon. Change them if they are wrong.'**
  String get smartApplied;

  /// No description provided for @smartFound.
  ///
  /// In en, this message translates to:
  /// **'The fairy found it'**
  String get smartFound;

  /// No description provided for @smartMaybe.
  ///
  /// In en, this message translates to:
  /// **'Is it one of these?'**
  String get smartMaybe;

  /// No description provided for @smartSection.
  ///
  /// In en, this message translates to:
  /// **'Smart suggestions'**
  String get smartSection;

  /// No description provided for @smartSuggest.
  ///
  /// In en, this message translates to:
  /// **'Ask the fairy (uses the internet)'**
  String get smartSuggest;

  /// No description provided for @smartSuggestBody.
  ///
  /// In en, this message translates to:
  /// **'Item names are sent to suggest categories and icons and to find things by meaning. Off: suggestions come from the phone only.'**
  String get smartSuggestBody;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sign in. Please try again.'**
  String get loginFailed;

  /// No description provided for @loginWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}!'**
  String loginWelcome(String name);

  /// No description provided for @accountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSection;

  /// No description provided for @accountGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get accountGuest;

  /// No description provided for @accountGuestBody.
  ///
  /// In en, this message translates to:
  /// **'Everything stays on this phone.'**
  String get accountGuestBody;

  /// No description provided for @accountWith.
  ///
  /// In en, this message translates to:
  /// **'Signed in with {provider}'**
  String accountWith(String provider);

  /// No description provided for @providerKakao.
  ///
  /// In en, this message translates to:
  /// **'Kakao'**
  String get providerKakao;

  /// No description provided for @providerNaver.
  ///
  /// In en, this message translates to:
  /// **'Naver'**
  String get providerNaver;

  /// No description provided for @providerGoogle.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get providerGoogle;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutBody.
  ///
  /// In en, this message translates to:
  /// **'Things saved on this phone stay.'**
  String get signOutBody;

  /// No description provided for @signedOut.
  ///
  /// In en, this message translates to:
  /// **'Signed out. Things on this phone stay.'**
  String get signedOut;

  /// No description provided for @loginFailedWhy.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sign in ({reason}).'**
  String loginFailedWhy(String reason);

  /// No description provided for @sentenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Put away'**
  String get sentenceTitle;

  /// No description provided for @sentencePickOther.
  ///
  /// In en, this message translates to:
  /// **'Another place'**
  String get sentencePickOther;

  /// No description provided for @sentenceWhat.
  ///
  /// In en, this message translates to:
  /// **'What goes here? Separate names with commas or “and”.'**
  String get sentenceWhat;

  /// No description provided for @sentenceHint.
  ///
  /// In en, this message translates to:
  /// **'scissors, tape and AA batteries 4 pcs'**
  String get sentenceHint;

  /// No description provided for @sentenceVoice.
  ///
  /// In en, this message translates to:
  /// **'You can speak it with the keyboard mic too'**
  String get sentenceVoice;

  /// No description provided for @sentenceMerge.
  ///
  /// In en, this message translates to:
  /// **'Joins the {name} ×{have} already here: ×{total} in all'**
  String sentenceMerge(String name, int have, int total);

  /// No description provided for @sentenceSave.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Put away 1 thing} other{Put away {count} things}}'**
  String sentenceSave(int count);

  /// No description provided for @sentenceSaved.
  ///
  /// In en, this message translates to:
  /// **'Put {count} in {place}'**
  String sentenceSaved(int count, String place);

  /// No description provided for @sentenceDetails.
  ///
  /// In en, this message translates to:
  /// **'One at a time with photo or date'**
  String get sentenceDetails;

  /// No description provided for @sentenceNoPlace.
  ///
  /// In en, this message translates to:
  /// **'Choose where to put them first'**
  String get sentenceNoPlace;

  /// No description provided for @introDemoQuery.
  ///
  /// In en, this message translates to:
  /// **'Where are the batteries?'**
  String get introDemoQuery;

  /// No description provided for @introDemoItem.
  ///
  /// In en, this message translates to:
  /// **'AA batteries ×8'**
  String get introDemoItem;

  /// No description provided for @introDemoSentence.
  ///
  /// In en, this message translates to:
  /// **'scissors, tape and AA batteries 4 pcs'**
  String get introDemoSentence;

  /// No description provided for @introDemoFamily1.
  ///
  /// In en, this message translates to:
  /// **'Mom · Bedroom'**
  String get introDemoFamily1;

  /// No description provided for @introDemoFamily2.
  ///
  /// In en, this message translates to:
  /// **'Dad · Balcony'**
  String get introDemoFamily2;

  /// No description provided for @introDemoFamily3.
  ///
  /// In en, this message translates to:
  /// **'Jiwoo · Kids room'**
  String get introDemoFamily3;

  /// No description provided for @introDemoInvite.
  ///
  /// In en, this message translates to:
  /// **'+ Invite'**
  String get introDemoInvite;

  /// No description provided for @introDemoRoom.
  ///
  /// In en, this message translates to:
  /// **'Living room'**
  String get introDemoRoom;

  /// No description provided for @introDemoStorage.
  ///
  /// In en, this message translates to:
  /// **'TV stand'**
  String get introDemoStorage;

  /// No description provided for @introDemoSpot.
  ///
  /// In en, this message translates to:
  /// **'Left drawer'**
  String get introDemoSpot;

  /// No description provided for @loginNudgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to share with your family'**
  String get loginNudgeTitle;

  /// No description provided for @loginNudgeBody.
  ///
  /// In en, this message translates to:
  /// **'What you\'ve added stays as it is. You can also sign in later from Settings.'**
  String get loginNudgeBody;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @searchThinking.
  ///
  /// In en, this message translates to:
  /// **'Let me think about what that means.'**
  String get searchThinking;
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
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
