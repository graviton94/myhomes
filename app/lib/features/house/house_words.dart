import '../../l10n/app_localizations.dart';

/// A template room's name in the user's language.
String roomName(AppLocalizations l, String key) => switch (key) {
  'bedroom2' => l.roomBedroom2,
  'bedroom3' => l.roomBedroom3,
  'master' => l.roomMaster,
  'bath' => l.roomBath,
  'masterBath' => l.roomMasterBath,
  'entrance' => l.roomEntrance,
  'kitchen' => l.roomKitchen,
  'dressroom' => l.roomDressroom,
  'living' => l.roomLiving,
  'balcony' => l.roomBalcony,
  'utility' => l.roomUtility,
  _ => l.roomRoom,
};

(String, String) templateWords(AppLocalizations l, String id) => switch (id) {
  'apt84' => (l.tplApt84, l.tplApt84Body),
  'apt84bay4' => (l.tplApt84bay4, l.tplApt84bay4Body),
  'apt84tower' => (l.tplApt84tower, l.tplApt84towerBody),
  'apt59' => (l.tplApt59, l.tplApt59Body),
  'villa2' => (l.tplVilla2, l.tplVilla2Body),
  _ => (l.tplStudio, l.tplStudioBody),
};
