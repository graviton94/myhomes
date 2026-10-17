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

  @override
  String get splashLoading => 'Waking the fairy...';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get started';

  @override
  String pageOf(int page, int total) {
    return 'Page $page of $total';
  }

  @override
  String get intro1Title => 'Find anything in seconds';

  @override
  String get intro1Body =>
      'Ask \"where are the batteries?\" and see the exact drawer and square.';

  @override
  String get intro2Title => 'Move things like a game inventory';

  @override
  String get intro2Body =>
      'Pick several items, choose how many, and move them in one go.';

  @override
  String get intro3Title => 'Use it before it expires';

  @override
  String get intro3Body =>
      'Add a use-by date and the fairy reminds you on D-3, D-1 and the day.';

  @override
  String get loginTagline => 'Your home, remembered by the fairy.';

  @override
  String get loginKakao => 'Continue with Kakao';

  @override
  String get loginNaver => 'Continue with Naver';

  @override
  String get loginGoogle => 'Continue with Google';

  @override
  String get loginSoon => 'Sign-in opens soon';

  @override
  String get or => 'or';

  @override
  String get startWithoutAccount => 'Start without an account';

  @override
  String get guestNote =>
      'Everything stays on this phone. You can sign in later to share with family.';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get more => 'More';

  @override
  String get close => 'Close';

  @override
  String get clear => 'Clear';

  @override
  String get undo => 'Undo';

  @override
  String get change => 'Change';

  @override
  String get choose => 'Choose';

  @override
  String get seeAll => 'See all';

  @override
  String get send => 'Send';

  @override
  String get increase => 'More';

  @override
  String get decrease => 'Less';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionMove => 'Move';

  @override
  String get actionTakeOut => 'Take out';

  @override
  String get makeStorageFirst => 'Add a space and a storage spot first.';

  @override
  String get addWhere => 'Add to which spot?';

  @override
  String get moveFromWhere => 'Move from which spot?';

  @override
  String get takeOutFromWhere => 'Take out from which spot?';

  @override
  String eatFirst(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Use first · $count items',
      one: 'Use first · 1 item',
    );
    return '$_temp0';
  }

  @override
  String itemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'Empty',
    );
    return '$_temp0';
  }

  @override
  String spaceSummary(int storages, int items) {
    String _temp0 = intl.Intl.pluralLogic(
      storages,
      locale: localeName,
      other: '$storages spots',
      one: '1 spot',
    );
    String _temp1 = intl.Intl.pluralLogic(
      items,
      locale: localeName,
      other: '$items items',
      one: '1 item',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get addStorage => 'Add a storage spot';

  @override
  String get editStorage => 'Edit storage spot';

  @override
  String get spaceNameHint => 'Name (e.g. Kitchen)';

  @override
  String get storageNameHint => 'Name (e.g. Drawer 2)';

  @override
  String get spaceEmptyTitle => 'No storage spots yet';

  @override
  String get spaceEmptyBody =>
      'Add the drawers, shelves and boxes in this room.';

  @override
  String deleteSpaceTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get deleteSpaceBody =>
      'Every storage spot and item in this space will be deleted too.';

  @override
  String deleteStorageTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String deleteStorageBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'The $count items inside will be deleted too.',
      one: 'The 1 item inside will be deleted too.',
      zero: 'This spot is empty.',
    );
    return '$_temp0';
  }

  @override
  String get noStorageYet => 'No storage spots yet. Add one from a space.';

  @override
  String get recentPlaces => 'Recent';

  @override
  String get storageHint =>
      'Tap an empty square to add, or an item to use or move it. Hold an item and drag it to another square to move it; hold and let go to pick several.';

  @override
  String get selectHint => 'Tap items to pick them and set how many.';

  @override
  String get pickSeveral => 'Pick several';

  @override
  String get pickItems => 'Pick items';

  @override
  String pickedSummary(int kinds, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      kinds,
      locale: localeName,
      other: '$kinds kinds',
      one: '1 kind',
    );
    return '$_temp0 · $total pcs';
  }

  @override
  String get moveToWhere => 'Move to which spot?';

  @override
  String movedTo(int count, String name) {
    return 'Moved $count to $name';
  }

  @override
  String tookOut(int count) {
    return 'Took out $count';
  }

  @override
  String get usedUp => 'Used up';

  @override
  String usedUpKinds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items used up',
      one: '1 item used up',
    );
    return '$_temp0';
  }

  @override
  String usedUpName(String name) {
    return '$name used up';
  }

  @override
  String get emptySlot => 'Empty square';

  @override
  String slotLabel(String name, int count) {
    return '$name, $count';
  }

  @override
  String howMany(String name) {
    return 'How many $name?';
  }

  @override
  String youHave(int count) {
    return 'You have $count.';
  }

  @override
  String get qtyOne => '1';

  @override
  String qtyHalf(int count) {
    return 'Half ($count)';
  }

  @override
  String qtyAll(int count) {
    return 'All ($count)';
  }

  @override
  String get deselect => 'Deselect';

  @override
  String qtyShort(int count) {
    return '×$count';
  }

  @override
  String get addItem => 'Add an item';

  @override
  String get editItem => 'Edit item';

  @override
  String get photo => 'Photo';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get itemName => 'Name';

  @override
  String get nameRequired => 'Please enter a name';

  @override
  String get category => 'Category';

  @override
  String get categoryFood => 'Food';

  @override
  String get categoryHousehold => 'Household';

  @override
  String get categoryTools => 'Tools';

  @override
  String get categoryMedicine => 'Medicine';

  @override
  String get categoryOther => 'Other';

  @override
  String get quantity => 'Quantity';

  @override
  String get useBy => 'Use by';

  @override
  String get dueNone => 'None';

  @override
  String dueDays(int count) {
    return '$count days';
  }

  @override
  String get dueWeek => '1 week';

  @override
  String get dueMonth => '1 month';

  @override
  String get duePick => 'Pick a date';

  @override
  String useByDate(String date) {
    return 'Use by $date';
  }

  @override
  String get place => 'Place';

  @override
  String get putWhere => 'Put it where?';

  @override
  String get chooseAPlace => 'Choose a place';

  @override
  String get note => 'Note';

  @override
  String get noteHint => 'Brand, size, who it belongs to...';

  @override
  String get saveAndNext => 'Save & add next';

  @override
  String addedName(String name) {
    return 'Added $name';
  }

  @override
  String deletedName(String name) {
    return 'Deleted $name';
  }

  @override
  String get recentItems => 'Recent items';

  @override
  String get searchTip =>
      'Tip: type Korean initials (ㄱㅇ) or a location code like LIV-A1.';

  @override
  String noResultsTitle(String query) {
    return 'No \"$query\" yet';
  }

  @override
  String get noResultsBody =>
      'Check the spelling, or add it where you keep it.';

  @override
  String resultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
    );
    return '$_temp0';
  }

  @override
  String get groupOverdue => 'Past the date';

  @override
  String get groupSoon => 'Within 3 days';

  @override
  String get groupLater => 'Later';

  @override
  String get askFairy => 'Ask the House Fairy';

  @override
  String askFairyWithBadge(int count) {
    return 'Ask the House Fairy, $count things to check';
  }

  @override
  String get fairySubtitle => 'Ask where things are';

  @override
  String get askFairyHint => 'e.g. Where are the batteries?';

  @override
  String get fairyGreeting => 'Hi! Ask me where anything is.';

  @override
  String fairyGreetingUrgent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hi! $count things need using soon.',
      one: 'Hi! 1 thing needs using soon.',
    );
    return '$_temp0';
  }

  @override
  String fairyFoundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Found $count! Here they are.',
      one: 'Found it! Here it is.',
    );
    return '$_temp0';
  }

  @override
  String fairyNotFound(String query) {
    return 'I couldn\'t find \"$query\". Is it saved under another name?';
  }

  @override
  String get chipThisWeek => 'Use this week';

  @override
  String get chipRunningLow => 'Running low';

  @override
  String get chipHowTo => 'How do I use this?';

  @override
  String fairyThisWeek(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count things to use this week.',
      one: '1 thing to use this week.',
    );
    return '$_temp0';
  }

  @override
  String get fairyNothingThisWeek => 'Nothing is due this week.';

  @override
  String fairyLow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count things are down to their last one.',
      one: '1 thing is down to its last one.',
    );
    return '$_temp0';
  }

  @override
  String get fairyNothingLow => 'Nothing is running low.';

  @override
  String get fairyHowTo =>
      'Make a space (a room), add storage spots inside, then tap empty squares to add things. Long-press items to move several at once.';

  @override
  String get goSee => 'Go';

  @override
  String get dataSection => 'Data';

  @override
  String get showIntroAgain => 'Show the intro again';

  @override
  String get deleteAllData => 'Delete all data on this phone';

  @override
  String get deleteAllBody =>
      'Every space, storage spot and item on this phone will be deleted. This cannot be undone.';

  @override
  String get allDeleted => 'All data deleted';

  @override
  String get editSpace => 'Edit space';

  @override
  String get addPhoto => 'Add a photo';

  @override
  String get addPhotoOptional => 'Add a photo (optional)';

  @override
  String get changePhoto => 'Change';

  @override
  String get icon => 'Icon';

  @override
  String get moreIcons => 'More';

  @override
  String get chooseIcon => 'Choose an icon';

  @override
  String get iconGroupRooms => 'Rooms';

  @override
  String get iconGroupFurniture => 'Furniture & storage';

  @override
  String get iconGroupFood => 'Food & drink';

  @override
  String get iconGroupHousehold => 'Household';

  @override
  String get iconGroupTools => 'Tools';

  @override
  String get iconGroupHealth => 'Health';

  @override
  String get iconGroupClothes => 'Clothes & accessories';

  @override
  String get iconGroupDevices => 'Devices';

  @override
  String get iconGroupPapers => 'Papers & money';

  @override
  String get iconGroupHobby => 'Hobbies & more';

  @override
  String get addSpaceShort => 'Room';

  @override
  String editSpaceNamed(String name) {
    return 'Edit $name';
  }

  @override
  String deleteSpaceNamed(String name) {
    return 'Delete $name';
  }

  @override
  String get moveHere => 'Move here';

  @override
  String get openStorage => 'Open on its own';

  @override
  String get boardMoveHint =>
      'Tap “Move here” on a storage spot, or Move to pick any place.';

  @override
  String get boardFirstStorageHint =>
      'Add the drawers, shelves and boxes in this room. Their squares show up right here.';

  @override
  String get outsideHome => 'Outside';

  @override
  String get addOutside => 'Add a place outside';

  @override
  String get addOutsideShort => 'Outside';

  @override
  String get outsideNameHint => 'Name (e.g. Car, Office, Lent out)';

  @override
  String get outsideStorageHint => 'Name (e.g. Trunk, Lent to Alex)';

  @override
  String get returnByOptional => 'Back by (optional)';

  @override
  String returnOverdue(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days late',
      one: '1 day late',
    );
    return '$_temp0';
  }

  @override
  String get returnToday => 'Back today';

  @override
  String returnDaysLeft(int days) {
    return 'Back in ${days}d';
  }

  @override
  String get groupReturns => 'To get back';

  @override
  String get iconGroupFamily => 'Family';

  @override
  String get iconGroupPets => 'Pets';

  @override
  String get hereNow => 'Here now';

  @override
  String get newStorageHere => 'New spot';

  @override
  String deleteStorageNamed(String name) {
    return 'Delete $name';
  }

  @override
  String get dockHint => 'Hold over a room to open it, or drop it on the room';

  @override
  String get dockNoOtherRooms =>
      'Add another room or place to move things between them';
}
