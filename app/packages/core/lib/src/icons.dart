/// Icon keys for spaces, storage spots and items, and suggestions from a name.
///
/// Keys are plain strings so the data file stays free of Flutter; the app maps
/// each key to a drawn icon.
library;

import 'model.dart';

/// Picker groups in display order. Every key appears exactly once.
const Map<String, List<String>> iconGroups = {
  'rooms': [
    'home', 'living', 'kitchen', 'dining', 'bedroom', 'kids', 'bathroom', 'laundry', 'entrance', //
    'balcony', 'study', 'office', 'storeroom', 'garage', 'garden', 'car', 'school', 'store', 'family_home',
  ],
  'furniture': [
    'drawer', 'shelf', 'cabinet', 'wardrobe', 'fridge', 'freezer', 'box', 'basket', 'bag', 'desk', //
    'table', 'bed', 'tv', 'safe', 'sink', 'first_aid_box',
  ],
  'food': [
    'drink', 'water', 'coffee', 'tea', 'wine', 'beer', 'liquor', 'egg', 'rice', 'noodles', //
    'bread', 'cookie', 'cake', 'icecream', 'vegetable', 'fish', 'meat', 'soup', 'snack', 'can',
  ],
  'household': [
    'cleaning', 'soap', 'sanitizer', 'tissue', 'laundry_soap', 'trash', 'lightbulb', 'battery', //
    'plug', 'cable', 'umbrella', 'shower', 'fan', 'candle',
  ],
  'tools': [
    'scissors', 'tape', 'ruler', 'wrench', 'hammer', 'toolbox', 'saw', 'paint', 'flashlight', //
    'key', 'lock', 'pin', 'plumbing', 'electric',
  ],
  'health': ['pill', 'syrup', 'bandage', 'syringe', 'thermometer', 'mask', 'vitamin', 'heart'],
  'clothes': [
    '👕', '👔', '👖', '🩳', '👗', '🧥', 'coat', 'shirt', '🧦', '🧤', '🧣', '🩲', '👙', //
    '👟', '👞', '👠', '👢', '🩴', '🧢', '👒', '👓', '🕶', '👜', '👛', '💼', 'backpack', 'watch', 'jewelry', 'iron',
  ],
  'family': ['dad', 'mom', 'boy', 'girl', 'grandpa', 'grandma', 'baby', 'family', 'person'],
  'pets': ['pet', '🐶', '🐱', '🐟', '🐦', '🐹', '🐰', '🐢', '🦎', 'pet_food'],
  'devices': [
    'phone', 'laptop', 'headphones', 'camera', 'game', 'speaker', 'printer', 'router', //
    'keyboard', 'mouse', 'usb', 'memory_card',
  ],
  'papers': ['document', 'book', 'pen', 'mail', 'photo', 'receipt', 'id_card', 'card', 'money', 'gift'],
  'hobby': [
    'toy', 'puzzle', 'ball', 'tennis', 'fitness', 'bike', 'music', 'art', 'plant', //
    'suitcase', 'beach', 'party', 'star', 'heart_fav', 'other',
  ],
};

/// Keys drawn as a picture character (clothes and pets have few line icons).
bool isPictureIcon(String key) => key.runes.first > 0x2000;

/// Every icon key, in picker order.
final List<String> iconKeys = [for (final g in iconGroups.values) ...g];

/// What a name is for, so suggestions start from the right kind of icon.
enum IconKind { space, outside, storage, item }

/// Lower-case words (Korean and English) that point at icon keys. Longer
/// words win when several match, so "냉동실" beats "실".
const Map<String, List<String>> _words = {
  // rooms
  '거실': ['living', 'tv'], 'living': ['living', 'tv'],
  '주방': ['kitchen', 'fridge'], '부엌': ['kitchen', 'fridge'], 'kitchen': ['kitchen', 'fridge'],
  '식탁': ['dining', 'table'], 'dining': ['dining', 'table'],
  '침실': ['bedroom', 'bed'], '안방': ['bedroom', 'bed'], 'bedroom': ['bedroom', 'bed'], '침대': ['bed'],
  '아이방': ['kids', 'toy'], '키즈': ['kids', 'toy'], 'kid': ['kids', 'toy'],
  '욕실': ['bathroom', 'shower'], '화장실': ['bathroom', 'tissue'], 'bath': ['bathroom', 'shower'],
  '세탁': ['laundry', 'laundry_soap'], '다용도실': ['laundry', 'storeroom'], 'laundry': ['laundry', 'laundry_soap'],
  '현관': ['entrance', '👟'], 'entr': ['entrance', '👟'], 'hall': ['entrance'],
  '베란다': ['balcony', 'plant'], '발코니': ['balcony', 'plant'], 'balcony': ['balcony', 'plant'],
  '서재': ['study', 'book'], '공부': ['study', 'desk'], 'study': ['study', 'book'],
  '사무': ['office', 'document'], 'office': ['office', 'document'],
  '창고': ['storeroom', 'box'], 'storage': ['storeroom', 'box'],
  '차고': ['garage', 'car'], 'garage': ['garage', 'car'], '자동차': ['car'], '트렁크': ['car', 'box'], 'car ': ['car'],
  '정원': ['garden', 'plant'], '마당': ['garden', 'plant'], 'garden': ['garden', 'plant'],
  // outside
  '회사': ['office'], '학교': ['school'], 'school': ['school'], '가게': ['store'], '매장': ['store'], 'shop': ['store'],
  '본가': ['family_home'], '친정': ['family_home'], '시댁': ['family_home'], '부모님': ['family_home'], 
  '빌려': ['person'], '대여': ['person'], 'lent': ['person'], 'loan': ['person'], 'friend': ['person'], '친구': ['person'],
  // furniture
  '서랍': ['drawer'], 'drawer': ['drawer'],
  '선반': ['shelf'], 'shelf': ['shelf'], '책장': ['shelf', 'book'], 'bookcase': ['shelf', 'book'],
  '수납장': ['cabinet'], '찬장': ['cabinet', 'can'], '장식장': ['cabinet'], 'cabinet': ['cabinet'], 'cupboard': ['cabinet'],
  '옷장': ['wardrobe', 'shirt'], '드레스룸': ['wardrobe', 'shirt'], 'closet': ['wardrobe', 'shirt'], 'wardrobe': ['wardrobe', 'shirt'],
  '냉장': ['fridge'], 'fridge': ['fridge'], 'refrigerator': ['fridge'],
  '냉동': ['freezer', 'icecream'], 'freezer': ['freezer', 'icecream'],
  '상자': ['box'], '박스': ['box'], 'box': ['box'], '통': ['box'],
  '바구니': ['basket'], 'basket': ['basket'],
  '가방': ['bag', 'backpack'], 'bag': ['bag', 'backpack'], '파우치': ['bag'],
  '책상': ['desk'], 'desk': ['desk'], '테이블': ['table'], 'table': ['table'],
  'tv': ['tv'], '티비': ['tv'],
  '금고': ['safe', 'lock'], 'safe': ['safe', 'lock'],
  '싱크': ['sink'], '세면대': ['sink', 'soap'], 'sink': ['sink'],
  '구급': ['first_aid_box', 'bandage'],
  '구급상자': ['first_aid_box', 'bandage'], 'first aid': ['first_aid_box', 'bandage'], '약통': ['first_aid_box', 'pill'],
  '신발': ['👟'], 'shoe': ['👟'],
  // food
  '우유': ['drink'], 'milk': ['drink'], '주스': ['drink'], 'juice': ['drink'], '음료': ['drink'], 'soda': ['drink'], '콜라': ['drink'],
  '생수': ['water'], 'water': ['water'],
  '커피': ['coffee'], 'coffee': ['coffee'], '녹차': ['tea'], '홍차': ['tea'], 'tea': ['tea'],
  '와인': ['wine'], 'wine': ['wine'], '맥주': ['beer'], 'beer': ['beer'], '소주': ['liquor'], '위스키': ['liquor'], '술': ['liquor'],
  '계란': ['egg'], '달걀': ['egg'], 'egg': ['egg'],
  '쌀': ['rice'], '밥': ['rice'], 'rice': ['rice'],
  '라면': ['noodles'], '국수': ['noodles'], '파스타': ['noodles'], 'noodle': ['noodles'], 'pasta': ['noodles'], 'ramen': ['noodles'],
  '빵': ['bread'], 'bread': ['bread'], '과자': ['snack', 'cookie'], '쿠키': ['cookie'], 'cookie': ['cookie'], 'snack': ['snack'],
  '케이크': ['cake'], 'cake': ['cake'], '아이스크림': ['icecream'], 'ice cream': ['icecream'],
  '채소': ['vegetable'], '야채': ['vegetable'], '과일': ['vegetable'], 'vegetable': ['vegetable'], 'fruit': ['vegetable'],
  '생선': ['fish'], 'fish': ['fish'], '고기': ['meat'], 'meat': ['meat'],
  '국': ['soup'], 'soup': ['soup'], '캔': ['can'], '통조림': ['can'], '참치': ['can', 'fish'], 'can ': ['can'],
  // household
  '세제': ['laundry_soap', 'cleaning'], 'detergent': ['laundry_soap', 'cleaning'],
  '청소': ['cleaning'], 'clean': ['cleaning'], '걸레': ['cleaning'],
  '비누': ['soap'], 'soap': ['soap'], '샴푸': ['soap', 'shower'], 'shampoo': ['soap', 'shower'], '소독': ['sanitizer'],
  '휴지': ['tissue'], '물티슈': ['tissue'], 'tissue': ['tissue'], '키친타월': ['tissue'],
  '쓰레기': ['trash'], 'trash': ['trash'], '봉투': ['trash', 'bag'],
  '전구': ['lightbulb'], 'bulb': ['lightbulb'], '건전지': ['battery'], '배터리': ['battery'], 'batter': ['battery'],
  '충전': ['plug', 'cable'], 'charger': ['plug', 'cable'], '케이블': ['cable'], 'cable': ['cable'], '멀티탭': ['plug'],
  '우산': ['umbrella'], 'umbrella': ['umbrella'], '선풍기': ['fan'], 'fan': ['fan'], '초': ['candle'], 'candle': ['candle'],
  // tools
  '가위': ['scissors'], 'scissor': ['scissors'], '테이프': ['tape'], 'tape': ['tape'], '줄자': ['ruler'], '자 ': ['ruler'], 'ruler': ['ruler'],
  '공구': ['toolbox', 'wrench'], 'tool': ['toolbox', 'wrench'], '드라이버': ['wrench'], '렌치': ['wrench'], 'wrench': ['wrench'],
  '망치': ['hammer'], 'hammer': ['hammer'], '톱': ['saw'], 'saw': ['saw'], '페인트': ['paint'], 'paint': ['paint'],
  '손전등': ['flashlight'], '랜턴': ['flashlight'], 'flashlight': ['flashlight'],
  '열쇠': ['key'], '키 ': ['key'], 'key': ['key'], '자물쇠': ['lock'], 'lock': ['lock'],
  '압정': ['pin'], '못': ['pin'], 'nail': ['pin'], 'pin': ['pin'], '배관': ['plumbing'], '전기': ['electric'],
  // health
  '약': ['pill'], 'medicine': ['pill'], 'pill': ['pill'], '감기': ['pill', 'thermometer'], '진통': ['pill'],
  '시럽': ['syrup'], 'syrup': ['syrup'], '밴드': ['bandage'], '반창고': ['bandage'], '연고': ['bandage'], 'band': ['bandage'],
  '주사': ['syringe'], '체온계': ['thermometer'], 'thermometer': ['thermometer'], '마스크': ['mask'], 'mask': ['mask'],
  '비타민': ['vitamin'], '영양제': ['vitamin'], 'vitamin': ['vitamin'], '혈압': ['heart'],
  // clothes
  '옷': ['👕', 'shirt'], '셔츠': ['👔', '👕'], '티셔츠': ['👕'], 't-shirt': ['👕'], 'shirt': ['👕', '👔'], 'cloth': ['👕', 'shirt'], '바지': ['👖'], '청바지': ['👖'], 'pants': ['👖'], 'jeans': ['👖'], '반바지': ['🩳'], 'shorts': ['🩳'], '치마': ['👗'], '원피스': ['👗'], '드레스': ['👗'], 'dress': ['👗'], 'skirt': ['👗'], '정장': ['👔', '💼'], '넥타이': ['👔'], 'suit': ['👔'], 'tie ': ['👔'], '양말': ['🧦'], 'sock': ['🧦'], '장갑': ['🧤'], 'glove': ['🧤'], '목도리': ['🧣'], '스카프': ['🧣'], 'scarf': ['🧣'], '속옷': ['🩲'], 'underwear': ['🩲'], '수영복': ['👙'], 'swim': ['👙'], '운동화': ['👟'], 'sneaker': ['👟'], '구두': ['👞', '👠'], '하이힐': ['👠'], 'heel': ['👠'], '부츠': ['👢'], 'boot': ['👢'], '슬리퍼': ['🩴'], '샌들': ['🩴'], 'slipper': ['🩴'], 'sandal': ['🩴'], '핸드백': ['👜'], 'handbag': ['👜'], 'purse': ['👛'], '지갑': ['👛'], 'wallet': ['👛'], '서류가방': ['💼'], '다리미': ['iron'], 'iron': ['iron'],
  '외투': ['coat'], '패딩': ['coat'], '코트': ['coat'], 'coat': ['coat'], 'jacket': ['coat'],
  '시계': ['watch'], 'watch': ['watch'], '반지': ['jewelry'], '목걸이': ['jewelry'], '귀걸이': ['jewelry'], 'jewel': ['jewelry'],
  '백팩': ['backpack'], 'backpack': ['backpack'], '안경': ['👓'], 'glasses': ['👓'], '선글라스': ['🕶'], 'sunglass': ['🕶'], '모자': ['🧢', '👒'], 'hat': ['🧢', '👒'], 'cap': ['🧢'],
  // devices
  '휴대폰': ['phone'], '핸드폰': ['phone'], '폰': ['phone'], 'phone': ['phone'],
  '노트북': ['laptop'],
  'laptop': ['laptop'],
  '이어폰': ['headphones'],
  '헤드폰': ['headphones'],
  'headphone': ['headphones'],
  'earphone': ['headphones'],
  '카메라': ['camera'], 'camera': ['camera'], '게임': ['game'], 'game': ['game'], '스피커': ['speaker'], 'speaker': ['speaker'],
  '프린터': ['printer'], 'printer': ['printer'], '공유기': ['router'], 'router': ['router'],
  '키보드': ['keyboard'], 'keyboard': ['keyboard'], '마우스': ['mouse'], 'mouse': ['mouse'], 'usb': ['usb'], '메모리': ['memory_card'],
  // papers
  '서류': ['document'], '문서': ['document'], '계약': ['document'], 'document': ['document'], 'paper': ['document'],
  '책': ['book'], 'book': ['book'], '펜': ['pen'], '연필': ['pen'], 'pen': ['pen'], '편지': ['mail'], 'mail': ['mail'],
  '사진': ['photo'], 'photo': ['photo'], '영수증': ['receipt'], 'receipt': ['receipt'],
  '여권': ['id_card'], 'passport': ['id_card'], '신분증': ['id_card'], '카드': ['card'], 'card': ['card'],
  '현금': ['money'], '돈': ['money'], 'cash': ['money'], 'money': ['money'], '선물': ['gift'], 'gift': ['gift'],
  // hobby
  '장난감': ['toy'], 'toy': ['toy'], '퍼즐': ['puzzle'], '레고': ['puzzle', 'toy'], 'puzzle': ['puzzle'], 'lego': ['puzzle'],
  '축구': ['ball'], '농구': ['ball'], 'ball': ['ball'], '테니스': ['tennis'], '배드민턴': ['tennis'], 'tennis': ['tennis'],
  '운동': ['fitness'], '덤벨': ['fitness'], '요가': ['fitness'], 'gym': ['fitness'], 'fitness': ['fitness'],
  '자전거': ['bike'], 'bike': ['bike'], '악기': ['music'], '기타 ': ['music'], 'music': ['music'], '그림': ['art'], '물감': ['art'],
  '강아지': ['🐶', 'pet'], '개 ': ['🐶'], 'dog': ['🐶', 'pet'], 'puppy': ['🐶'], '고양이': ['🐱', 'pet'], 'cat ': ['🐱'], 'kitten': ['🐱'], '반려': ['pet', '🐶', '🐱'], 'pet': ['pet'], '사료': ['pet_food', 'pet'], '간식': ['snack', 'pet_food'], '물고기': ['🐟'], '어항': ['🐟'], '열대어': ['🐟'], '새장': ['🐦'], '앵무': ['🐦'], 'bird': ['🐦'], '햄스터': ['🐹'], 'hamster': ['🐹'], '토끼': ['🐰'], 'rabbit': ['🐰'], '거북': ['🐢'], 'turtle': ['🐢'], '도마뱀': ['🦎'], '파충류': ['🦎'],
  '화분': ['plant'],
  '식물': ['plant'],
  'plant': ['plant'],
  '캐리어': ['suitcase'],
  '여행': ['suitcase'],
  'suitcase': ['suitcase'],
  'travel': ['suitcase'],
  '캠핑': ['beach', 'flashlight'], '파티': ['party'], 'party': ['party'], '기저귀': ['baby'], '아기': ['baby'], 'baby': ['baby'], '분유': ['baby'], '아빠': ['dad'], '남편': ['dad'], 'dad': ['dad'], '엄마': ['mom'], '아내': ['mom'], 'mom': ['mom'], '아들': ['boy'], 'son': ['boy'], '딸': ['girl'], 'daughter': ['girl'], '할아버지': ['grandpa'], 'grandpa': ['grandpa'], '할머니': ['grandma', 'family_home'], 'grandma': ['grandma'], '가족': ['family'], 'family': ['family'], '누나': ['girl'], '언니': ['girl'], '형': ['boy'], '오빠': ['boy'],
};

const Map<IconKind, List<String>> _defaults = {
  IconKind.space: ['home', 'living', 'kitchen', 'bedroom', 'bathroom', 'entrance'],
  IconKind.outside: ['car', 'office', 'person', 'family_home', 'school', 'suitcase'],
  IconKind.storage: ['drawer', 'shelf', 'box', 'cabinet', 'basket', 'wardrobe'],
  IconKind.item: [],
};

const Map<ItemCategory, List<String>> _categoryDefaults = {
  ItemCategory.food: ['drink', 'egg', 'can', 'snack', 'vegetable', 'rice'],
  ItemCategory.household: ['cleaning', 'tissue', 'battery', 'lightbulb', 'soap', 'trash'],
  ItemCategory.tools: ['toolbox', 'scissors', 'tape', 'wrench', 'flashlight', 'key'],
  ItemCategory.medicine: ['pill', 'bandage', 'syrup', 'thermometer', 'mask', 'vitamin'],
  ItemCategory.other: ['document', 'gift', 'toy', 'phone', 'cable', 'other'],
};

/// Icons whose words appear in [name], best match first. Empty when nothing
/// in the name is recognised.
List<String> iconsFromName(String name) {
  final n = ' ${name.trim().toLowerCase()} ';
  if (n.trim().isEmpty) return const [];
  final hits = _words.keys.where(n.contains).toList()..sort((a, b) => b.trim().length.compareTo(a.trim().length));
  final out = <String>[];
  for (final w in hits) {
    for (final k in _words[w]!) {
      if (!out.contains(k)) out.add(k);
    }
  }
  return out;
}

/// Up to [limit] icons to offer for [name]: name matches first, then sensible
/// defaults for the kind (and the item's category).
List<String> suggestIcons(String name, IconKind kind, {ItemCategory? category, int limit = 6}) {
  final out = [...iconsFromName(name)];
  final fill = [...?_defaults[kind], if (kind == IconKind.item) ...?_categoryDefaults[category ?? ItemCategory.other]];
  for (final k in fill) {
    if (out.length >= limit) break;
    if (!out.contains(k)) out.add(k);
  }
  return out.take(limit).toList();
}
