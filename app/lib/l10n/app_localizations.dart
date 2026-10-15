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

  /// No description provided for @quickAdd.
  ///
  /// In en, this message translates to:
  /// **'Snap & add'**
  String get quickAdd;

  /// No description provided for @quickMove.
  ///
  /// In en, this message translates to:
  /// **'Pick & move'**
  String get quickMove;

  /// No description provided for @quickUse.
  ///
  /// In en, this message translates to:
  /// **'Take out'**
  String get quickUse;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Find an item (e.g. scissors)'**
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
