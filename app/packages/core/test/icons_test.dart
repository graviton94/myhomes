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
    expect(guessCategory('청바지'), ItemCategory.other);
    expect(guessCategory('무엇'), isNull);
  });
}
