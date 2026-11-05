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

  test('amounts, counts and step photos come with the recipe', () {
    final r = recipes.firstWhere((r) => r.id == 137);
    final tofu = r.ingredients.firstWhere((i) => i.key == '두부');
    expect(tofu.amount, '1모 (320g)');
    expect(tofu.count, 1);
    expect(r.ingredients.firstWhere((i) => i.name == '청양고추').count, 1); // 1/2개 rounds up
    expect(r.ingredients.firstWhere((i) => i.name == '돼지고기').count, isNull); // 100g
    expect(r.stepPhotos, hasLength(r.steps.length));
    expect(r.stepPhotos.first, startsWith('https://www.foodsafetykorea.go.kr/uploadimg/'));
    expect(const Ingredient('계란', '계란', amount: '2개').count, 2);
    expect(const Ingredient('양파', '양파', amount: '½개').count, 1);
  });

  test('cooking takes out only what was used', () {
    var n = 0;
    final ctx = Ctx(newId: () => 'c${n++}', now: () => DateTime(2026, 11, 5));
    final s = addSpace(const HomeData(), ctx, '주방');
    final f = addContainer(s.data, ctx, spaceId: s.value.id, name: '냉장고');
    var d = f.data;
    for (final (name, qty) in [('두부', 2), ('김치', 1), ('계란', 3), ('대파', 1)]) {
      d = addItem(d, ctx, containerId: f.value.id, name: name, category: ItemCategory.food, qty: qty).data;
    }
    Item item(String name) => d.items.firstWhere((i) => i.name == name);
    // First guesses from the recipe's amounts.
    expect(guessCookPick(const Ingredient('두부', '두부', amount: '1모 (320g)'), item('두부')).take, 1);
    expect(guessCookPick(const Ingredient('김치', '김치', amount: '140g'), item('김치')).use, CookUse.some);
    expect(guessCookPick(const Ingredient('두부', '두부', amount: '50g'), item('두부')).take, 0); // a weight: opened, none out
    expect(guessCookPick(const Ingredient('계란', '계란', amount: '3개'), item('계란')).use, CookUse.all);

    final r = cook(d, ctx, {
      item('두부').id: const CookPick(CookUse.some, 1),
      item('김치').id: const CookPick(CookUse.some, 0),
      item('계란').id: const CookPick(CookUse.all, 0),
      item('대파').id: const CookPick(CookUse.none, 0),
    });
    final left = {for (final i in r.data.items) i.name: i.qty};
    expect(left, {'두부': 1, '김치': 1, '대파': 1});
    expect(r.value, ['계란']);
    final logs = r.data.log.take(3).toList();
    expect(logs.map((e) => e.batchId).toSet(), hasLength(1));
    expect({for (final e in logs) e.itemName: e.type}, {'두부': LogType.use, '김치': LogType.use, '계란': LogType.usedUp});
  });
}
