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
    expect(iconsFromName('청바지').first, '👖');
    expect(iconsFromName('양말').first, '🧦');
    expect(iconsFromName('강아지 사료'), containsAll(['🐶', 'pet_food']));
    expect(iconsFromName('고양이').first, '🐱');
    expect(iconsFromName('아빠 공구').contains('dad'), isTrue);
    expect(isPictureIcon('👕'), isTrue);
    expect(isPictureIcon('shirt'), isFalse);
  });

  test('suggestions are filled with defaults for the kind', () {
    expect(suggestIcons('', IconKind.space), ['home', 'living', 'kitchen', 'bedroom', 'bathroom', 'entrance']);
    final s = suggestIcons('서랍', IconKind.storage);
    expect(s.first, 'drawer');
    expect(s.length, 6);
    expect(suggestIcons('', IconKind.item, category: ItemCategory.medicine).first, 'pill');
  });
}
