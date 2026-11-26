import 'package:homefairy_core/homefairy_core.dart';
import 'package:test/test.dart';

void main() {
  test('every icon key is unique and every suggestion is a known key', () {
    expect(iconKeys.toSet().length, iconKeys.length);
    for (final name in ['주방', '냉장고', '서랍1', '건전지', 'AA batteries', '우유', '아이방 장난감', '구급상자']) {
      for (final kind in IconKind.values) {
        expect(suggestIcons(name, kind).every(isIconKey), isTrue, reason: '$name $kind');
      }
    }
  });

  test('names point at matching icons first', () {
    expect(wordIcons('냉장고').first, 'fridge');
    expect(wordIcons('냉동실').first, 'freezer');
    expect(wordIcons('서랍1').first, 'drawer');
    expect(wordIcons('AA batteries').first, 'battery');
    expect(wordIcons('우유').first, 'drink');
    expect(wordIcons('Kitchen').first, 'kitchen');
    expect(wordIcons('구급상자').first, 'first_aid_box');
    expect(wordIcons('무엇'), isEmpty);
    expect(wordIcons('청바지').first, 'pants');
    expect(wordIcons('반팔 티').first, 'tshirt');
    expect(wordIcons('반바지').first, 'shorts');
    expect(wordIcons('양말').first, 'socks');
    expect(wordIcons('원피스').first, 'dress');
    expect(wordIcons('강아지 사료'), containsAll(['dog', 'pet_food']));
    expect(wordIcons('고양이').first, 'cat');
    expect(wordIcons('햄스터').first, 'hamster');
    expect(wordIcons('앵무새').first, 'bird');
    expect(wordIcons('아빠 공구').contains('dad'), isTrue);
  });

  test('suggestions are filled with defaults for the kind', () {
    expect(suggestIcons('', IconKind.space), ['home', 'living', 'kitchen', 'bedroom', 'bathroom', 'entrance']);
    final s = suggestIcons('서랍', IconKind.storage);
    expect(s, contains('drawer'));
    expect(s.length, 6);
    expect(suggestIcons('', IconKind.item, category: ItemCategory.medicine).first, 'pill');
  });

  test('category guesses follow the best icon', () {
    expect(guessCategory('우유'), ItemCategory.food);
    expect(guessCategory('AA 건전지'), ItemCategory.household);
    expect(guessCategory('가위'), ItemCategory.tools);
    expect(guessCategory('감기약'), ItemCategory.medicine);
    expect(guessCategory('청바지'), ItemCategory.clothes);
    expect(guessCategory('아이패드'), ItemCategory.electronics);
    expect(guessCategory('보조배터리'), ItemCategory.electronics);
    expect(guessCategory('여권'), ItemCategory.papers);
    expect(guessCategory('텐트'), ItemCategory.hobby);
    expect(guessCategory('기저귀'), ItemCategory.kids);
    expect(guessCategory('고양이 모래'), ItemCategory.pets);
    expect(guessCategory('무엇'), isNull);
  });

  test('short words only match where they mean the thing', () {
    expect(wordIcons('초코파이'), isNot(contains('candle')));
    expect(wordIcons('치약').first, 'toothpaste');
    expect(wordIcons('감기약').first, 'pill');
    expect(wordIcons('약속'), isEmpty);
    expect(wordIcons('모자').first, 'hat');
    expect(wordIcons('자').first, 'ruler');
    expect(wordIcons('소파'), isNot(contains('vegetable')));
    expect(wordIcons('카펫'), isNot(contains('pet')));
    expect(wordIcons('open box'), isNot(contains('pen')));
  });

  test('the last word of a name says what it is', () {
    expect(wordIcons('냉동 새우').first, 'fish');
    expect(wordIcons('강아지 사료').first, 'pet_food');
    expect(wordIcons('자전거 자물쇠').first, 'lock');
  });

  test('stored categories: unknown names and old "other" items', () {
    Item read(String? category, String? icon) => Item.fromJson({
      'id': 'i',
      'containerId': 'c',
      'slot': 0,
      'name': 'x',
      'category': ?category,
      'icon': ?icon,
      'updatedAt': '2026-01-01T00:00:00.000',
    });
    expect(read('pets', null).category, ItemCategory.pets);
    expect(read('someday', null).category, ItemCategory.other);
    expect(read('other', 'dog').category, ItemCategory.pets);
    expect(read('other', null).category, ItemCategory.other);
    expect(read('food', 'dog').category, ItemCategory.food);
  });

  test('icon search finds by any word for it', () {
    expect(searchIcons('우산'), contains('umbrella'));
    expect(searchIcons('비'), contains('umbrella')); // 비옷, 우비
    expect(searchIcons('tooth'), containsAll(['toothbrush', 'toothpaste']));
    expect(searchIcons('냉동 새우'), contains('fish'));
    expect(searchIcons('   '), isEmpty);
    expect(searchIcons('쀍쀍'), isEmpty);
    expect(searchIcons('약').every(isIconKey), isTrue);
  });

  // The ordered pictograms (user request): a name finds its own picture first.
  test('names find their ordered pictogram first', () {
    expect(pictogramNames.length, 1470);
    expect(iconsFromName('냉장고').first, 'p0125');
    expect(pictogramNames[iconsFromName('김치냉장고').first], '김치냉장고'); // the longer name wins
    expect(pictogramNames[iconsFromName('냉동 새우').first], '냉동새우');
    expect(iconsFromName('우유').map((k) => pictogramNames[k]), contains('우유'));
    expect(wordIconFor('p0117', '신발장'), wordIcons('신발장').first); // usual things stay keyed by words
    expect(isIconKey('p3049'), isTrue);
    // Aliases and English (the filled alias sheets).
    expect(pictogramNames[iconsFromName('딤채').first], '김치냉장고');
    expect(pictogramNames[iconsFromName('kimchi fridge').first], '김치냉장고');
    expect(pictogramNames[iconsFromName('My AirPods').first], '무선이어폰');
    expect(pictogramNames[iconsFromName('쿠쿠 밥솥').first], '전기밥솥');
    expect(iconsFromName('pancake'), isNot(contains(iconsFromName('pan').firstOrNull))); // whole words only
    expect(searchIcons('fridge').map((k) => pictogramNames[k]), contains('냉장고'));
    expect(isIconKey('p3050'), isFalse);
  });
}
