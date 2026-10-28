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
  String get searchHint => 'What are you looking for?';

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
  String get intro1Title => 'Ask, and find it';

  @override
  String get intro1Body =>
      'Type or say it in the one search box. The fairy finds it even when the name is a little different.';

  @override
  String get intro2Title => 'Put things away in one sentence';

  @override
  String get intro2Body =>
      'Pick a spot and write everything at once. Same names are added together.';

  @override
  String get intro3Title => 'Fill it in with your family';

  @override
  String get intro3Body =>
      'Sign in to invite your family. Each fills their own room and the whole home is done.';

  @override
  String get loginTagline => 'Your home, remembered by the fairy.';

  @override
  String get loginKakao => 'Login with Kakao';

  @override
  String get loginNaver => 'Log in with NAVER';

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

  @override
  String get smartApplied =>
      'The fairy picked the category and icon. Change them if they are wrong.';

  @override
  String get smartFound => 'The fairy found it';

  @override
  String get smartMaybe => 'Is it one of these?';

  @override
  String get loginFailed => 'Couldn\'t sign in. Please try again.';

  @override
  String loginWelcome(String name) {
    return 'Welcome, $name!';
  }

  @override
  String get accountSection => 'Account';

  @override
  String get accountGuest => 'Guest';

  @override
  String get accountGuestBody => 'Everything stays on this phone.';

  @override
  String accountWith(String provider) {
    return 'Signed in with $provider';
  }

  @override
  String get providerKakao => 'Kakao';

  @override
  String get providerNaver => 'Naver';

  @override
  String get providerGoogle => 'Google';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutBody => 'Things saved on this phone stay.';

  @override
  String get signedOut => 'Signed out. Things on this phone stay.';

  @override
  String loginFailedWhy(String reason) {
    return 'Couldn\'t sign in ($reason).';
  }

  @override
  String get sentenceTitle => 'Put away';

  @override
  String get sentencePickOther => 'Another place';

  @override
  String get sentenceWhat =>
      'What goes here? Separate names with commas or “and”.';

  @override
  String get sentenceHint => 'scissors, tape and AA batteries 4 pcs';

  @override
  String get sentenceVoice => 'You can speak it with the keyboard mic too';

  @override
  String sentenceMerge(String name, int have, int total) {
    return 'Joins the $name ×$have already here: ×$total in all';
  }

  @override
  String sentenceSave(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Put away $count things',
      one: 'Put away 1 thing',
    );
    return '$_temp0';
  }

  @override
  String sentenceSaved(int count, String place) {
    return 'Put $count in $place';
  }

  @override
  String get sentenceDetails => 'One at a time with photo or date';

  @override
  String get sentenceNoPlace => 'Choose where to put them first';

  @override
  String get introDemoQuery => 'Where are the batteries?';

  @override
  String get introDemoItem => 'AA batteries ×8';

  @override
  String get introDemoSentence => 'scissors, tape and AA batteries 4 pcs';

  @override
  String get introDemoFamily1 => 'Mom · Bedroom';

  @override
  String get introDemoFamily2 => 'Dad · Balcony';

  @override
  String get introDemoFamily3 => 'Jiwoo · Kids room';

  @override
  String get introDemoInvite => '+ Invite';

  @override
  String get introDemoRoom => 'Living room';

  @override
  String get introDemoStorage => 'TV stand';

  @override
  String get introDemoSpot => 'Left drawer';

  @override
  String get loginNudgeTitle => 'Sign in to share with your family';

  @override
  String get loginNudgeBody =>
      'What you\'ve added stays as it is. You can also sign in later from Settings.';

  @override
  String get later => 'Later';

  @override
  String get searchThinking => 'Let me think about what that means.';

  @override
  String get kindTitle => 'What kind of storage?';

  @override
  String get kindFurniture => 'Furniture';

  @override
  String get kindFurnitureBody =>
      'Stays put, like a fridge, wardrobe or TV stand. Split into shelves and drawers.';

  @override
  String get kindBox => 'Box';

  @override
  String get kindBoxBody =>
      'Moved as a whole, like a box, basket or toolbox. Gets a number to write on it.';

  @override
  String get kindSpot => 'Spot';

  @override
  String get kindSpotBody =>
      'Just a place, like under the sofa, by the door or the car boot.';

  @override
  String get furnitureNameHint => 'e.g. TV stand';

  @override
  String get boxNameHint => 'What\'s in it (e.g. camping gear)';

  @override
  String get sectionsTitle => 'Shelves and drawers';

  @override
  String get sectionsHint => 'Top to bottom, separated by commas';

  @override
  String get sectionsDefault => 'Top shelf, Middle shelf, Bottom shelf';

  @override
  String boxName(int number) {
    return 'Box $number';
  }

  @override
  String boxNamed(int number, String name) {
    return 'Box $number · $name';
  }

  @override
  String get moveBox => 'Move the whole box';

  @override
  String get moveBoxWhere => 'Where does the box go?';

  @override
  String floorOf(String room) {
    return '$room floor';
  }

  @override
  String boxMoved(String box, String place) {
    return 'Moved $box to $place';
  }

  @override
  String get addBoxHere => 'Box';

  @override
  String boxesInside(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count boxes',
      one: '1 box',
    );
    return '$_temp0';
  }

  @override
  String get touchToStart => 'Touch to start';

  @override
  String get leaveGuest => 'Sign in instead';

  @override
  String get leaveGuestBody =>
      'Go to the login screen. Things on this phone stay.';

  @override
  String get navMap => 'Map';

  @override
  String get navPut => 'Put away';

  @override
  String changeAdd(String what, String place) {
    return 'Put away $what · $place';
  }

  @override
  String changeMove(String what, String place) {
    return 'Moved $what · $place';
  }

  @override
  String changeUse(String what, String place) {
    return 'Took out $what · $place';
  }

  @override
  String changeUsedUp(String what) {
    return 'Used up $what';
  }

  @override
  String changeEdit(String what) {
    return 'Edited $what';
  }

  @override
  String changeRemove(String what) {
    return 'Deleted $what';
  }

  @override
  String changeWhatMore(String first, int count) {
    return '$first and $count more';
  }

  @override
  String get agoNow => 'just now';

  @override
  String agoMinutes(int n) {
    return '$n min ago';
  }

  @override
  String agoHours(int n) {
    return '$n h ago';
  }

  @override
  String agoDays(int n) {
    return '$n d ago';
  }

  @override
  String get noChangesYet => 'Changes you make show up here.';

  @override
  String get mapOutside => 'Outside the home';

  @override
  String get mapEmptyRoom => 'No storage yet';

  @override
  String mapHits(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matches',
      one: '1 match',
    );
    return '$_temp0';
  }

  @override
  String get roomBedroom2 => 'Bedroom 2';

  @override
  String get roomBedroom3 => 'Bedroom 3';

  @override
  String get roomMaster => 'Main bedroom';

  @override
  String get roomBath => 'Bathroom';

  @override
  String get roomMasterBath => 'En-suite';

  @override
  String get roomEntrance => 'Entrance';

  @override
  String get roomKitchen => 'Kitchen';

  @override
  String get roomDressroom => 'Dressing room';

  @override
  String get roomLiving => 'Living room';

  @override
  String get roomBalcony => 'Balcony';

  @override
  String get roomUtility => 'Utility room';

  @override
  String get roomRoom => 'Room';

  @override
  String get tplApt84 => '84 type, 3-bay';

  @override
  String get tplApt84Body => '2 bedrooms, living, main bedroom face south';

  @override
  String get tplApt84bay4 => '84 type, 4-bay';

  @override
  String get tplApt84bay4Body => '3 bedrooms and living face south';

  @override
  String get tplApt84tower => '84 type, tower';

  @override
  String get tplApt84towerBody => 'Corner living room, windows on two sides';

  @override
  String get tplApt59 => '59 type';

  @override
  String get tplApt59Body => '3 rooms, 2 bathrooms';

  @override
  String get tplVilla2 => 'Two-room villa';

  @override
  String get tplVilla2Body => '2 rooms, living and kitchen together';

  @override
  String get tplStudio => 'Studio';

  @override
  String get tplStudioBody => 'Bathroom and kitchen by the door';

  @override
  String get houseSetupTitle => 'What shape is your home?';

  @override
  String get houseSetupBody =>
      'Start from the closest shape. The bottom (balcony) faces south. Names and sizes can change on the next screen.';

  @override
  String get houseBlank => 'Start from empty squares';

  @override
  String get houseNoMap => 'Keep the list without a map';

  @override
  String get houseUseThis => 'Start with this shape';

  @override
  String get houseEditTitle => 'Fit our home';

  @override
  String get houseEditHint =>
      'Drag a block to move it; drag the dot at its corner to resize. One square = 0.5 m.';

  @override
  String get houseDone => 'Done';

  @override
  String get houseAddRoom => 'Room';

  @override
  String get houseRename => 'Rename';

  @override
  String get houseTakeOff => 'Take off the map';

  @override
  String get houseTapBlock => 'Tap a block to pick it';

  @override
  String get mapSetup => 'Set our home\'s shape';

  @override
  String get mapSetupBody =>
      'Pick a floor plan\nand the map looks like your home';

  @override
  String get mapEdit => 'Edit shape';

  @override
  String get mapUnplaced => 'Rooms not on the map yet';

  @override
  String get aiToWordSearch => 'Switching from AI search to word search.';

  @override
  String get aiQuotaSubscribe =>
      'This month\'s fairy credits are used up. Plus has ten times as many.';

  @override
  String get featuresSection => 'Extras';

  @override
  String get featureExpiry => 'Use-by dates';

  @override
  String get featureExpiryBody =>
      'Reminders for use-by dates\n3 days and 1 day before, and on the day, at 9 am';

  @override
  String get featureReturns => 'Get lent things back';

  @override
  String get featureReturnsBody =>
      'Return dates for places outside home\nwith reminders as the day comes';

  @override
  String get featureLowStock => 'Running low';

  @override
  String get featureLowStockBody =>
      'Set a minimum amount\nBelow it, things go on the shopping list';

  @override
  String get notifyOff =>
      'Notifications are off. Turn them on for Home Fairy in the phone\'s settings.';

  @override
  String get notifyChannel => 'Dates';

  @override
  String get notifyChannelBody => 'Use-by and return dates';

  @override
  String notifyExpiry(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days left to use it',
      one: 'Use it by tomorrow',
      zero: 'Use it today',
    );
    return '$_temp0';
  }

  @override
  String notifyReturn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Get it back in $days days',
      one: 'Get it back tomorrow',
      zero: 'Get it back today',
    );
    return '$_temp0';
  }

  @override
  String getBackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'To get back · $count',
      one: 'To get back · 1',
    );
    return '$_temp0';
  }

  @override
  String runningLow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Running low · $count',
      one: 'Running low · 1',
    );
    return '$_temp0';
  }

  @override
  String get shoppingTitle => 'Shopping list';

  @override
  String get shoppingEmptyTitle => 'Nothing running low';

  @override
  String get shoppingEmptyBody =>
      'Set a minimum amount on things\nyou keep in stock, like tissues or rice';

  @override
  String shoppingNeed(int qty, int min) {
    return '$qty left\nKeep $min';
  }

  @override
  String get shoppingRefill => 'Refilled';

  @override
  String shoppingRefilled(String name, int qty) {
    return '$name: back to $qty';
  }

  @override
  String get minQty => 'Keep at least';

  @override
  String get minQtyHint => 'Below this, it goes on the shopping list.';

  @override
  String get minQtyNone => 'Not set';

  @override
  String get minQtySet => 'Set';

  @override
  String get familyGuestTitle => 'Share with your family';

  @override
  String get familyGuestBody =>
      'Sign in and make our home\nYour family sees the same map\nand adds and finds things with you';

  @override
  String get familyAloneBody =>
      'Make our home and invite your family\nor join with a code you were sent';

  @override
  String get familyCreate => 'Make our home';

  @override
  String get familyJoin => 'Join with a code';

  @override
  String get familyDefaultName => 'Our home';

  @override
  String get familyUploadTitle => 'Bring this phone\'s things too?';

  @override
  String familyUploadBody(int spaces, int items) {
    return '$spaces spaces and $items items go in\nFamily sees them, and they stay on this phone';
  }

  @override
  String get familyUploadYes => 'Bring them and start';

  @override
  String get familyUploadNo => 'Start empty';

  @override
  String familyHeader(String name, int count, int limit) {
    return '$name · $count of $limit';
  }

  @override
  String get familyMe => 'Me';

  @override
  String get familyOwner => 'Made this home';

  @override
  String get familySomeone => 'Family';

  @override
  String get familyInviteSection => 'Invite family';

  @override
  String get familyInviteMake => 'Make an invite code';

  @override
  String familyInviteValid(String time) {
    return 'Works until $time';
  }

  @override
  String get familyInviteSend => 'Send the code';

  @override
  String familyInviteMessage(String code) {
    return 'Join our home in Home Fairy. In the Family tab, tap Join with a code and enter $code.';
  }

  @override
  String get familyCopied => 'Code copied';

  @override
  String get familyFull => 'Free homes hold 2 people.';

  @override
  String get familyLeave => 'Leave our home';

  @override
  String get familyLeaveBody =>
      'This phone goes back to its own things\nThe home stays with your family\nand is deleted when nobody is left';

  @override
  String get familyLeaveAction => 'Leave';

  @override
  String get familyJoinHint => '6-digit code';

  @override
  String get familyJoinGo => 'Join';

  @override
  String get familyJoinBody =>
      'Enter the code your family sent\nIt works for 24 hours';

  @override
  String get familyAlreadyTitle => 'Leave your current home?';

  @override
  String get familyAlreadyBody => 'You can be in one home at a time.';

  @override
  String get familyAlreadyAction => 'Leave and join';

  @override
  String get familyProblemFull =>
      'That home is full. Free homes hold 2 people.';

  @override
  String get familyProblemNotFound => 'That code is wrong or has expired.';

  @override
  String get familyProblemOffline =>
      'Couldn\'t reach the server. Check the connection and try again.';

  @override
  String get familyProblemOther => 'That didn\'t work. Try again.';

  @override
  String get syncSaved => 'All saved';

  @override
  String get syncSaving => 'Saving';

  @override
  String get syncOffline => 'Offline, saved on this phone';

  @override
  String changeBy(String name, String change) {
    return '$name · $change';
  }

  @override
  String get featureFamilyAlerts => 'Family alerts';

  @override
  String get featureFamilyAlertsBody =>
      'When family adds, moves or uses things\nyou get a notification';

  @override
  String get featureFamilyAlertsNeedsHome =>
      'Join our home in the Family tab\nto switch this on';

  @override
  String get notifyFamilyChannel => 'Family';

  @override
  String get notifyFamilyChannelBody => 'What family changed in our home';

  @override
  String roomEditTitle(String room) {
    return '$room: furniture';
  }

  @override
  String get roomEditHint =>
      'Drag to move, drag the dot to resize. One square is 0.5 m.';

  @override
  String get roomTapToPlace => 'Tap one to put it on the floor';

  @override
  String get roomAllPlaced => 'Everything in this room is placed.';

  @override
  String get roomPlaceFurniture => 'Place furniture';

  @override
  String get planPhoto => 'Floor plan photo';

  @override
  String get planPhotoHide => 'Hide the photo';

  @override
  String get planPhotoShow => 'Show the photo';

  @override
  String get planPhotoChange => 'Pick another photo';

  @override
  String get planPhotoRemove => 'Remove the photo';

  @override
  String get planPhotoSize => 'Photo size';

  @override
  String get discard => 'Threw away';

  @override
  String discardedName(String name) {
    return '$name thrown away';
  }

  @override
  String changeDiscard(String what) {
    return 'Threw away $what';
  }

  @override
  String get reportOpen => 'This month\'s report';

  @override
  String reportTitle(String month) {
    return '$month at our home';
  }

  @override
  String get reportAdded => 'Put in';

  @override
  String get reportUsed => 'Used';

  @override
  String get reportDiscarded => 'Thrown away';

  @override
  String get reportTopUsed => 'Used most';

  @override
  String get reportThrownOut => 'Thrown away';

  @override
  String get reportByMember => 'Changes by family';

  @override
  String reportTimes(int count) {
    return '$count times';
  }

  @override
  String get reportEmpty => 'Nothing recorded this month yet';

  @override
  String get reportShare => 'Share as PDF';

  @override
  String reportFooter(String date) {
    return 'Home Fairy · made $date';
  }

  @override
  String get reportPrev => 'Previous month';

  @override
  String get reportNext => 'Next month';

  @override
  String get barcodeAdd => 'Scan a barcode';

  @override
  String get barcodeTitle => 'Scan a barcode';

  @override
  String get barcodeHint =>
      'Hold the barcode inside the frame\nFood names come in by themselves';

  @override
  String barcodeKnown(int qty, String place) {
    return '$qty in our home already\n$place';
  }

  @override
  String get barcodeOneMore => 'One more';

  @override
  String barcodeAdded(String name, int qty) {
    return '$name: $qty now';
  }

  @override
  String get barcodeLooking => 'Looking up the barcode';

  @override
  String get barcodeUnknown => 'Not in the food list. Type the name.';

  @override
  String widgetUseFirst(int count) {
    return 'Use first $count';
  }

  @override
  String widgetToBuy(int count) {
    return 'To buy $count';
  }

  @override
  String widgetGetBack(int count) {
    return 'Get back $count';
  }

  @override
  String widgetSummary(int items, int spaces) {
    return '$items things in $spaces places';
  }

  @override
  String get familyMergeTitle => 'Bring this phone\'s things into our home';

  @override
  String familyMergeBody(int spaces, int items) {
    return '$spaces spaces and $items items on this phone\nSame-named rooms and places become one';
  }

  @override
  String get familyMergeAction => 'Merge';

  @override
  String familyMerged(int count) {
    return '$count things came into our home';
  }

  @override
  String itemChangedElsewhere(int qty) {
    return 'Family just changed this\nNow $qty of it';
  }

  @override
  String get itemGoneElsewhere =>
      'Family just took this out\nSaving puts nothing back';

  @override
  String get itemReload => 'Load theirs';

  @override
  String get familyAlertsNow => 'Right away';

  @override
  String get familyAlertsDaily => 'Once, 8:30 pm';

  @override
  String get creditsTitle => 'Fairy credits';

  @override
  String creditsBody(int left, int limit, String whose) {
    return '$left of $limit left this month ($whose)\nAI search 1 · receipt 3 · photo 5';
  }

  @override
  String get creditsShared => 'shared by our home';

  @override
  String get creditsMine => 'just you';
}
