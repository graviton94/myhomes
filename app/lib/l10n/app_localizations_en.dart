// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Home Fairy';

  @override
  String get fairyName => 'House Fairy';

  @override
  String get myHome => 'My home';

  @override
  String get navHome => 'Home';

  @override
  String get navSpaces => 'Spaces';

  @override
  String get navSearch => 'Search';

  @override
  String get navExpiry => 'Use by';

  @override
  String get navFamily => 'Family';

  @override
  String get homeGreeting => 'Hi! I\'ll remember where everything is.';

  @override
  String get quickAdd => 'Snap & add';

  @override
  String get quickMove => 'Pick & move';

  @override
  String get quickUse => 'Take out';

  @override
  String get searchHint => 'Find an item (e.g. scissors)';

  @override
  String get homeEmptyTitle => 'Let\'s map your home';

  @override
  String get homeEmptyBody =>
      'Start with one room, like the living room or kitchen. Then add the drawers and shelves inside it.';

  @override
  String get addSpace => 'Add a space';

  @override
  String get spacesEmptyTitle => 'No spaces yet';

  @override
  String get spacesEmptyBody =>
      'Rooms you add will show up here with their storage spots.';

  @override
  String get searchEmptyTitle => 'Nothing to search yet';

  @override
  String get searchEmptyBody =>
      'Once you add items, type a name and I\'ll show you exactly where it is.';

  @override
  String get expiryEmptyTitle => 'Nothing is about to expire';

  @override
  String get expiryEmptyBody =>
      'Add a use-by date to food or medicine and I\'ll remind you on D-3, D-1 and the day.';

  @override
  String get familyEmptyTitle => 'Share your home';

  @override
  String get familyEmptyBody =>
      'Invite your family so everyone can find things and keep counts up to date.';

  @override
  String get comingSoon => 'Coming in a later build.';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'Same as phone';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'Same as phone';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get designSample => 'Design sample';

  @override
  String get designSampleBody => 'Colours, type and parts used across the app.';

  @override
  String get about => 'About';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get sampleColors => 'Colours';

  @override
  String get sampleType => 'Type';

  @override
  String get sampleParts => 'Parts';

  @override
  String get sampleFairy => 'House Fairy';

  @override
  String get sampleButtonPrimary => 'Move';

  @override
  String get sampleButtonSecondary => 'Edit';

  @override
  String get sampleButtonText => 'Cancel';

  @override
  String get sampleCategoryFood => 'Food';

  @override
  String get sampleCategoryHousehold => 'Household';

  @override
  String get sampleCategoryTools => 'Tools';

  @override
  String get sampleCategoryMedicine => 'Medicine';

  @override
  String get sampleSlotEmpty => 'Empty slot';

  @override
  String get sampleSlotFilled => 'AA batteries, 8';

  @override
  String get sampleSlotSelected => 'Selected';

  @override
  String get sampleSlotExpiring => 'Milk, expiring soon';

  @override
  String get sampleSlotChosen => '4 of 8 chosen';

  @override
  String get fairyHello => 'Hello!';

  @override
  String get fairyFound => 'Found it!';

  @override
  String get fairyCarry => 'Heave-ho';

  @override
  String get fairyWorry => 'Oh no';

  @override
  String get fairyCheer => 'Well done';

  @override
  String get fairySleep => 'Zzz';

  @override
  String expiryOverdue(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days over',
      one: '1 day over',
    );
    return '$_temp0';
  }

  @override
  String get expiryToday => 'Use today';

  @override
  String get expiryTomorrow => 'Use by tomorrow';

  @override
  String expiryDaysLeft(int days) {
    return 'D-$days';
  }

  @override
  String get expiryOk => 'Fresh';
}
