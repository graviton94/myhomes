// Prints what the recipe suggestions would be for a sample fridge.
//   dart run tool/try_recipes.dart
import 'dart:convert';
import 'dart:io';

import 'package:homefairy_core/homefairy_core.dart';

void main() {
  final recipes = recipesFromJson(jsonDecode(File('../../assets/recipes.json').readAsStringSync()) as Map<String, Object?>);
  var n = 0;
  final now = DateTime(2026, 11, 5);
  final ctx = Ctx(newId: () => 'x${n++}', now: () => now);
  final s = addSpace(const HomeData(), ctx, '주방');
  final f = addContainer(s.data, ctx, spaceId: s.value.id, name: '냉장고');
  var d = f.data;
  for (final (name, days) in [
    ('서울우유 1L', 2),
    ('계란 30구', 12),
    ('두부', 1),
    ('양파', 20),
    ('대파', 6),
    ('당근', 9),
    ('감자', 25),
    ('돼지고기 앞다리살', 2),
    ('애호박', 3),
    ('김치', 30),
    ('사과', 8),
    ('요거트', 1),
  ]) {
    d = addItem(
      d,
      ctx,
      containerId: f.value.id,
      name: name,
      category: ItemCategory.food,
      expiresOn: now.add(Duration(days: days)),
    ).data;
  }
  for (final m in suggestRecipes(d, recipes, now, limit: 8)) {
    print('${m.recipe.name} [${m.recipe.kind}] score ${m.score.toStringAsFixed(2)}');
    print('   uses: ${m.uses.entries.map((e) => '${e.key.name}←${e.value.name}').join(', ')}');
    print('   missing: ${m.missing.map((i) => i.name).join(', ')} · urgent: ${m.urgent(now).map((i) => i.name).join(', ')}');
  }
}
