import 'package:homefairy_core/homefairy_core.dart';
import 'package:test/test.dart';

void main() {
  test('every icon key is unique and every suggestion is a known key', () {
    expect(iconKeys.toSet().length, iconKeys.length);
    for (final name in ['주방', '냉장고', '서랍1', '건전지', 'AA batteries', '우유', '아이방 장난감', '구급상자']) {
      for (final kind in IconKind.values) {
        expect(suggestIcons(name, kind).every(iconKeys.contains), isTrue, reason: '$name $kind');
      }
    }
  });

  test('names point at matching icons first', () {
    expect(iconsFromName('냉장고').first, 'fridge');
    expect(iconsFromName('냉동실').first, 'freezer');
    expect(iconsFromName('서랍1').first, 'drawer');
    expect(iconsFromName('AA batteries').first, 'battery');
    expect(iconsFromName('우유').first, 'drink');
    expect(iconsFromName('Kitchen').first, 'kitchen');
    expect(iconsFromName('구급상자').first, 'first_aid_box');
    expect(iconsFromName('무엇'), isEmpty);
    expect(iconsFromName('청바지').first, 'pants');
    expect(iconsFromName('반팔 티').first, 'tshirt');
    expect(iconsFromName('반바지').first, 'shorts');
    expect(iconsFromName('양말').first, 'socks');
    expect(iconsFromName('원피스').first, 'dress');
    expect(iconsFromName('강아지 사료'), containsAll(['dog', 'pet_food']));
    expect(iconsFromName('고양이').first, 'cat');
    expect(iconsFromName('햄스터').first, 'hamster');
    expect(iconsFromName('앵무새').first, 'bird');
    expect(iconsFromName('아빠 공구').contains('dad'), isTrue);
  });

  test('suggestions are filled with defaults for the kind', () {
    expect(suggestIcons('', IconKind.space), ['home', 'living', 'kitchen', 'bedroom', 'bathroom', 'entrance']);
    final s = suggestIcons('서랍', IconKind.storage);
    expect(s.first, 'drawer');
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
    expect(iconsFromName('초코파이'), isNot(contains('candle')));
    expect(iconsFromName('치약').first, 'toothpaste');
    expect(iconsFromName('감기약').first, 'pill');
    expect(iconsFromName('약속'), isEmpty);
    expect(iconsFromName('모자').first, 'hat');
    expect(iconsFromName('자').first, 'ruler');
    expect(iconsFromName('소파'), isNot(contains('vegetable')));
    expect(iconsFromName('카펫'), isNot(contains('pet')));
    expect(iconsFromName('open box'), isNot(contains('pen')));
  });

  test('the last word of a name says what it is', () {
    expect(iconsFromName('냉동 새우').first, 'fish');
    expect(iconsFromName('강아지 사료').first, 'pet_food');
    expect(iconsFromName('자전거 자물쇠').first, 'lock');
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
    expect(searchIcons('우산').first, 'umbrella');
    expect(searchIcons('비'), contains('umbrella')); // 비옷, 우비
    expect(searchIcons('tooth'), containsAll(['toothbrush', 'toothpaste']));
    expect(searchIcons('냉동 새우').first, 'fish');
    expect(searchIcons('   '), isEmpty);
    expect(searchIcons('쀍쀍'), isEmpty);
    expect(searchIcons('약').every(iconKeys.contains), isTrue);
  });
}
