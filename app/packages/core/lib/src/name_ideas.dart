/// Name ideas while typing (user request: fewer names typed by hand).
///
/// Nothing here is guessed by a model and nothing leaves the phone: ideas
/// come from the person's own names, short lists of what usually goes in a
/// room or a storage spot (below), and the app's word list. Before anything
/// is typed only the short list shows; as letters come, every pool is
/// searched (initials work: "ㅊㅅ" finds 칫솔).
library;

import 'hangul.dart';
import 'model.dart';
import 'words.dart';

/// What usually stands in a room, by the room's icon key. Korean, English.
const Map<String, (List<String>, List<String>)> roomStorageIdeas = {
  'living': (
    ['TV장', '거실장', '소파 옆', '수납장', '책장', '협탁', '선반', '바구니'],
    ['TV stand', 'Sideboard', 'By the sofa', 'Cabinet', 'Bookcase', 'Side table', 'Shelf', 'Basket'],
  ),
  'kitchen': (
    ['냉장고', '냉동실', '싱크대 위', '싱크대 아래', '찬장', '팬트리', '김치냉장고', '식탁'],
    ['Fridge', 'Freezer', 'Upper cabinet', 'Under the sink', 'Cupboard', 'Pantry', 'Kimchi fridge', 'Dining table'],
  ),
  'dining': (['식탁', '찬장', '장식장', '선반'], ['Dining table', 'Cupboard', 'Display cabinet', 'Shelf']),
  'bedroom': (
    ['옷장', '서랍장', '협탁', '화장대', '침대 밑', '행거', '수납함', '책상'],
    ['Wardrobe', 'Chest of drawers', 'Nightstand', 'Vanity', 'Under the bed', 'Clothes rail', 'Storage box', 'Desk'],
  ),
  'kids': (['장난감 정리함', '옷장', '책장', '서랍장', '책상', '기저귀 선반'], ['Toy box', 'Wardrobe', 'Bookcase', 'Chest of drawers', 'Desk', 'Nappy shelf']),
  'bathroom': (['욕실장', '세면대 아래', '수건장', '선반', '바구니'], ['Bathroom cabinet', 'Under the basin', 'Towel cupboard', 'Shelf', 'Basket']),
  'laundry': (['세탁기 위 선반', '수납장', '세제 선반', '바구니', '청소도구함'], ['Shelf over the washer', 'Cabinet', 'Detergent shelf', 'Basket', 'Cleaning closet']),
  'entrance': (['신발장', '현관 수납장', '우산꽂이', '선반'], ['Shoe cabinet', 'Hall cupboard', 'Umbrella stand', 'Shelf']),
  'balcony': (['베란다 선반', '수납장', '창고', '화분 선반', '리빙박스'], ['Balcony shelf', 'Cabinet', 'Store', 'Plant shelf', 'Storage box']),
  'study': (['책상', '책장', '서랍장', '서류함', '선반'], ['Desk', 'Bookcase', 'Drawers', 'File box', 'Shelf']),
  'office': (['책상', '서랍', '사물함', '선반'], ['Desk', 'Drawer', 'Locker', 'Shelf']),
  'storeroom': (['선반', '리빙박스', '수납장', '공구함', '상자'], ['Shelf', 'Storage box', 'Cabinet', 'Toolbox', 'Box']),
  'garage': (['공구함', '선반', '수납장', '상자'], ['Toolbox', 'Shelf', 'Cabinet', 'Box']),
  'car': (['트렁크', '글러브박스', '콘솔박스', '뒷좌석'], ['Boot', 'Glovebox', 'Centre console', 'Back seat']),
};

/// Rooms a home usually has, for adding one.
const roomIdeas = (
  ['거실', '주방', '안방', '작은방', '아이방', '욕실', '드레스룸', '다용도실', '현관', '베란다', '서재', '창고'],
  ['Living room', 'Kitchen', 'Bedroom', 'Small bedroom', 'Kids room', 'Bathroom', 'Dressing room', 'Utility room', 'Entrance', 'Balcony', 'Study', 'Storeroom'],
);

/// What usually goes in a storage spot, by the spot's icon key.
const Map<String, (List<String>, List<String>)> storageItemIdeas = {
  'fridge': (
    ['우유', '계란', '두부', '김치', '요거트', '버터', '치즈', '대파', '양파', '당근', '사과', '음료수'],
    ['Milk', 'Eggs', 'Tofu', 'Kimchi', 'Yogurt', 'Butter', 'Cheese', 'Spring onion', 'Onion', 'Carrot', 'Apples', 'Drinks'],
  ),
  'freezer': (
    ['만두', '얼음', '냉동 새우', '아이스크림', '냉동밥', '고기', '생선', '떡'],
    ['Dumplings', 'Ice', 'Frozen prawns', 'Ice cream', 'Frozen rice', 'Meat', 'Fish', 'Rice cakes'],
  ),
  'sink': (
    ['주방세제', '수세미', '고무장갑', '행주', '랩', '지퍼백', '쓰레기봉투', '키친타월'],
    ['Dish soap', 'Scrubber', 'Rubber gloves', 'Dish cloth', 'Cling film', 'Zip bags', 'Bin bags', 'Paper towels'],
  ),
  'cabinet': (
    ['휴지', '건전지', '전구', '테이프', '가위', '상비약', '마스크', '충전기'],
    ['Tissues', 'Batteries', 'Light bulbs', 'Tape', 'Scissors', 'Medicine', 'Masks', 'Charger'],
  ),
  'drawer': (
    ['가위', '테이프', '건전지', '볼펜', '충전기', '이어폰', '여권', '보증서'],
    ['Scissors', 'Tape', 'Batteries', 'Pen', 'Charger', 'Earphones', 'Passport', 'Warranty cards'],
  ),
  'shelf': (['책', '앨범', '보드게임', '화분', '공구', '전구'], ['Books', 'Albums', 'Board games', 'Plant pot', 'Tools', 'Light bulbs']),
  'wardrobe': (['겨울 패딩', '코트', '정장', '이불', '여름옷', '가방', '모자', '목도리'], ['Winter coat', 'Coat', 'Suit', 'Duvet', 'Summer clothes', 'Bags', 'Hats', 'Scarf']),
  'box': (
    ['크리스마스 장식', '캠핑 용품', '아기 옷', '추억 상자', '여분 이불', '케이블'],
    ['Christmas decorations', 'Camping gear', 'Baby clothes', 'Keepsakes', 'Spare bedding', 'Cables'],
  ),
  'desk': (['노트북', '충전기', '볼펜', '메모지', '스테이플러', '이어폰'], ['Laptop', 'Charger', 'Pen', 'Notepad', 'Stapler', 'Earphones']),
  'table': (['리모컨', '충전기', '안경', '열쇠', '영수증'], ['Remote', 'Charger', 'Glasses', 'Keys', 'Receipts']),
  'bed': (['여분 이불', '베개', '여름 이불', '전기장판'], ['Spare bedding', 'Pillow', 'Summer duvet', 'Electric blanket']),
  'first_aid_box': (
    ['해열제', '소화제', '밴드', '연고', '감기약', '파스', '체온계', '소독약'],
    ['Paracetamol', 'Antacid', 'Plasters', 'Ointment', 'Cold medicine', 'Pain patches', 'Thermometer', 'Antiseptic'],
  ),
  'basket': (['빨래', '수건', '장난감', '양말'], ['Laundry', 'Towels', 'Toys', 'Socks']),
  'bag': (['지갑', '보조배터리', '우산', '물티슈'], ['Wallet', 'Power bank', 'Umbrella', 'Wet wipes']),
  'safe': (['여권', '현금', '귀금속', '계약서', '도장'], ['Passport', 'Cash', 'Jewellery', 'Contracts', 'Seal']),
  'tv': (['리모컨', '셋톱박스', 'HDMI 케이블'], ['Remote', 'Set-top box', 'HDMI cable']),
};

/// The words the app knows for things (not rooms or furniture), as a pool
/// to search while typing.
List<String> thingWords({required bool ko}) => _thingWords[ko] ??= [
  for (final e in iconTerms.entries)
    if (!_placeKeys.contains(e.key))
      for (final t in e.value.split('|'))
        if (t.isNotEmpty && !t.startsWith('=') && _isKorean(t) == ko && t.length > 1) t,
];

final _thingWords = <bool, List<String>>{};

const _placeKeys = {
  'home', 'living', 'kitchen', 'dining', 'bedroom', 'kids', 'bathroom', 'laundry', 'entrance', 'balcony', 'study', 'office', //
  'storeroom', 'garage', 'garden', 'car', 'school', 'store', 'family_home', 'drawer', 'shelf', 'cabinet', 'wardrobe', 'fridge', //
  'freezer', 'box', 'basket', 'bag', 'desk', 'table', 'bed', 'safe', 'sink', 'first_aid_box',
};

bool _isKorean(String s) => RegExp('[가-힣]').hasMatch(s);

/// Up to [limit] names to offer while [typed] is being written.
///
/// [mine] are the person's own names (most used first), [usual] the short
/// list for where this is (shown before anything is typed), [pool] more
/// names searched only once something is typed. Names in [skip] (already
/// there) are left out, and nothing is offered twice or equal to [typed].
List<String> nameIdeas({
  required String typed,
  List<String> mine = const [],
  List<String> usual = const [],
  List<String> pool = const [],
  Iterable<String> skip = const [],
  int limit = 6,
}) {
  final q = cleanText(typed);
  final seen = {for (final s in skip) _key(s), if (q.isNotEmpty) _key(q)};
  final out = <String>[];
  void take(Iterable<String> names, bool Function(String) ok) {
    for (final n in names) {
      if (out.length >= limit) return;
      final name = cleanText(n);
      if (name.isEmpty || !ok(name) || !seen.add(_key(name))) continue;
      out.add(name);
    }
  }

  if (q.isEmpty) {
    take(usual, (_) => true);
    take(mine, (_) => true);
    return out;
  }
  // The whole name first (also by initials: ㅊㅅ is 칫솔 before 청소기),
  // then names that start with it, then names with it anywhere.
  final k = _key(q);
  bool whole(String n) => _key(n) == k || initialsOf(_key(n)) == k;
  bool starts(String n) => _key(n).startsWith(k) || initialsOf(_key(n)).startsWith(k);
  bool has(String n) => matchesQuery(n, q);
  for (final test in [whole, starts, has]) {
    take(mine, test);
    take(usual, test);
    take(pool, test);
  }
  return out;
}

String _key(String s) => s.toLowerCase().replaceAll(RegExp(r'\s+'), '');

/// The person's own thing names, most used first (things now at home count
/// most, then what the history mentions).
List<String> myThingNames(HomeData d) {
  final count = <String, int>{};
  for (final i in d.items) {
    count[i.name] = (count[i.name] ?? 0) + 3;
  }
  for (final e in d.log.take(300)) {
    if (e.itemName.isNotEmpty) count[e.itemName] = (count[e.itemName] ?? 0) + 1;
  }
  for (final b in d.toBuy) {
    count[b.name] = (count[b.name] ?? 0) + 1;
  }
  return (count.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).map((e) => e.key).toList();
}

/// [name], or with the next free number when the home already has one
/// ("작은방" → "작은방 2", "소파 옆 2" → "소파 옆 3"). Rooms and storage
/// spots can repeat; the number tells them apart.
String numberedName(String name, Iterable<String> taken) {
  final base = cleanText(name).replaceFirst(RegExp(r'\s+\d+$'), '');
  final used = {for (final t in taken) _key(t)};
  if (!used.contains(_key(base))) return base;
  var n = 2;
  while (used.contains(_key('$base $n'))) {
    n++;
  }
  return '$base $n';
}

/// Ideas for a new room or storage spot: like [nameIdeas], but names already
/// there are offered again with the next number instead of left out.
List<String> placeIdeas({required String typed, required List<String> usual, required Iterable<String> taken, int limit = 6}) => [
  for (final n in nameIdeas(typed: typed, usual: usual, limit: limit)) numberedName(n, taken),
];
