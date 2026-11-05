import 'dart:convert';
import 'dart:io';

import 'package:homefairy_core/homefairy_core.dart';
import 'package:test/test.dart';

void main() {
  final recipes = recipesFromJson(jsonDecode(File('../../assets/recipes.json').readAsStringSync()) as Map<String, Object?>);

  test('the public recipes load with ingredients and steps', () {
    expect(recipes.length, greaterThan(1000));
    final r = recipes.firstWhere((r) => r.name == '새우 두부 계란찜');
    expect(r.ingredients.map((i) => i.key), containsAll(['연두부', '칵테일새우', '계란', '생크림', '시금치']));
    expect(r.ingredients.firstWhere((i) => i.key == '설탕').staple, isTrue);
    expect(r.steps.first, startsWith('손질된 새우를'));
    expect(r.photo, startsWith('https://'));
  });

  test('home names match recipe ingredients without one-letter accidents', () {
    Ingredient ing(String k) => Ingredient(k, k);
    expect(sameFood('서울우유', ing('우유')), isTrue);
    expect(sameFood('토마토', ing('방울토마토')), isTrue);
    expect(sameFood('계란', ing('달걀')), isTrue);
    expect(sameFood('파', ing('파프리카')), isFalse);
    expect(sameFood('파', ing('대파')), isTrue);
    expect(sameFood('우유식빵', ing('우유')), isTrue); // a known gap: names holding another food
  });

  test('suggestions use what is at home and what needs eating first', () {
    var n = 0;
    final now = DateTime(2026, 11, 5);
    final ctx = Ctx(newId: () => 'r${n++}', now: () => now);
    final s = addSpace(const HomeData(), ctx, '주방');
    final f = addContainer(s.data, ctx, spaceId: s.value.id, name: '냉장고');
    var d = f.data;
    for (final (name, days) in [('두부', 1), ('계란 10구', 20), ('새우', 2), ('시금치', 3), ('양파', 30), ('대파', 10)]) {
      d = addItem(
        d,
        ctx,
        containerId: f.value.id,
        name: name,
        category: ItemCategory.food,
        expiresOn: now.add(Duration(days: days)),
      ).data;
    }
    d = addItem(d, ctx, containerId: f.value.id, name: '가위', category: ItemCategory.tools).data;
    final got = suggestRecipes(d, recipes, now);
    expect(got, isNotEmpty);
    expect(got.length, lessThanOrEqualTo(5));
    for (final m in got) {
      expect(m.missing.length, lessThanOrEqualTo(2));
      expect(m.uses.values.every((i) => i.category == ItemCategory.food), isTrue);
    }
    // The tofu and shrimp are due soon: the best ones use them.
    expect(got.first.urgent(now), isNotEmpty);
    expect(suggestRecipes(const HomeData(), recipes, now), isEmpty);
  });
}
