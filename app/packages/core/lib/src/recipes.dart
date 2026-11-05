/// "냉장고 재료로 뭐 해 먹지?": public recipes (식품안전나라 COOKRCP01,
/// assets/recipes.json from tool/build_recipes.py) matched against the food
/// in the home. Code does the matching; nothing is generated.
library;

import 'expiry.dart';
import 'model.dart';
import 'ops.dart' show CookPick, CookUse;
import 'receipt.dart' show nameCandidates;

class Ingredient {
  const Ingredient(this.name, this.key, {this.staple = false, this.amount});

  /// As the recipe writes it ("다진 마늘").
  final String name;

  /// Plain name for matching ("마늘").
  final String key;

  /// Most kitchens have it (salt, oil, soy sauce): never counted as missing.
  final bool staple;

  /// As the recipe writes it ("1모 (320g)", "1/2개"), if given.
  final String? amount;

  /// How many things the amount is, when it counts things ("2개" → 2,
  /// "1/2개" → 1, "1모 (320g)" → 1); null for weights and spoons.
  int? get count {
    final m = RegExp(r'^\s*(\d+(?:\.\d+)?)?\s*(?:(\d+)/(\d+)|([½⅓¼⅔¾]))?\s*(개|모|마리|알|장|쪽|송이|뿌리|줄기|봉지|봉|팩|캔|통|단)').firstMatch(amount ?? '');
    if (m == null || (m.group(1) == null && m.group(2) == null && m.group(4) == null)) return null;
    var n = double.tryParse(m.group(1) ?? '') ?? 0;
    if (m.group(2) != null) n += int.parse(m.group(2)!) / int.parse(m.group(3)!);
    if (m.group(4) != null) n += const {'½': .5, '⅓': 1 / 3, '¼': .25, '⅔': 2 / 3, '¾': .75}[m.group(4)]!;
    return n <= 0 ? null : n.ceil();
  }
}

class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.kind,
    required this.way,
    this.kcal,
    this.photo,
    required this.ingredients,
    required this.steps,
    this.tip,
    this.stepPhotos = const [],
  });

  final int id;
  final String name;

  /// 반찬, 일품, 밥, 국&찌개, 후식, 기타.
  final String kind;

  /// 볶기, 끓이기, 찌기 ...
  final String way;
  final int? kcal;
  final String? photo;
  final List<Ingredient> ingredients;
  final List<String> steps;
  final String? tip;

  /// A photo for each step, where the source has one (same length as [steps] or empty).
  final List<String?> stepPhotos;

  /// The step photos' common address (recipes.json stores the rest).
  static const photoBase = 'https://www.foodsafetykorea.go.kr/uploadimg/';

  static Recipe fromJson(Map<String, Object?> j) => Recipe(
    id: (j['id'] as num).toInt(),
    name: j['name'] as String,
    kind: j['kind'] as String? ?? '',
    way: j['way'] as String? ?? '',
    kcal: (j['kcal'] as num?)?.toInt(),
    photo: j['photo'] as String?,
    ingredients: [
      for (final i in (j['ing'] as List? ?? const []))
        if (i is Map) Ingredient(i['n'] as String, i['k'] as String, staple: i['s'] == true, amount: i['a'] as String?),
    ],
    steps: [for (final s in (j['steps'] as List? ?? const [])) s as String],
    tip: j['tip'] as String?,
    stepPhotos: [for (final p in (j['si'] as List? ?? const [])) p is String ? '$photoBase$p' : null],
  );
}

List<Recipe> recipesFromJson(Map<String, Object?> j) => [
  for (final r in (j['recipes'] as List? ?? const []))
    if (r is Map) Recipe.fromJson(r.cast<String, Object?>()),
];

const _same = {'달걀': '계란', '대파': '파', '쪽파': '파', '실파': '파', '쇠고기': '소고기', '한우': '소고기', '모짜렐라': '모차렐라', '모짜렐라치즈': '모차렐라치즈'};

String _key(String s) {
  var k = s.toLowerCase().replaceAll(RegExp(r'[^가-힣a-z]'), '');
  for (final e in _same.entries) {
    k = k.replaceAll(e.key, e.value);
  }
  return k;
}

/// The plain name of a thing in the home, for matching ("서울우유 1L" → 서울우유).
String foodKey(Item i) => _key(nameCandidates(i.name).last);

/// Whether the home's [itemKey] is the recipe's [ing]: the same, the item's
/// name holds it ("서울우유" has "우유"), or the ingredient ends with the
/// item's name ("방울토마토" for 토마토). One-letter names only match exactly.
bool sameFood(String itemKey, Ingredient ing) {
  final k = _key(ing.key);
  if (itemKey.isEmpty || k.isEmpty) return false;
  if (itemKey == k) return true;
  if (k.length >= 2 && itemKey.contains(k)) return true;
  return itemKey.length >= 2 && k.endsWith(itemKey);
}

/// One suggestion: the recipe, the home's things it uses, what is missing.
class RecipeMatch {
  const RecipeMatch(this.recipe, this.uses, this.missing, this.score);

  final Recipe recipe;

  /// Ingredient → the home's thing for it.
  final Map<Ingredient, Item> uses;
  final List<Ingredient> missing;
  final double score;

  /// Things it uses that should be eaten soon (date within 3 days).
  List<Item> urgent(DateTime today) => [
    for (final i in uses.values)
      if (i.expiresOn != null && expiryStatus(today: today, expiresOn: i.expiresOn!).daysLeft <= 3) i,
  ];
}

/// What to cook from the food in [d]: recipes that use at least two of its
/// things (one when the recipe needs only one or two) and miss at most two,
/// best first: more of the recipe at home, and things that need eating soon.
List<RecipeMatch> suggestRecipes(HomeData d, List<Recipe> recipes, DateTime now, {int limit = 5, String? kind}) {
  final food = _food(d);
  if (food.isEmpty) return const [];
  final out = <RecipeMatch>[];
  for (final r in recipes) {
    if (kind != null && r.kind != kind) continue;
    final m = _match(r, food, now);
    if (m == null) continue;
    final needed = m.uses.length + m.missing.length;
    final enough = m.uses.length >= 2 || (m.uses.length == 1 && needed <= 2);
    if (!enough || m.missing.length > 2) continue;
    out.add(m);
  }
  out.sort((a, b) => b.score.compareTo(a.score));
  return out.take(limit).toList();
}

/// [r] against the food in [d], whatever it scores (for the recipe screen).
RecipeMatch matchRecipe(HomeData d, Recipe r, DateTime now) =>
    _match(r, _food(d), now) ??
    RecipeMatch(r, const {}, [
      for (final i in r.ingredients)
        if (!i.staple) i,
    ], 0);

List<(Item, String)> _food(HomeData d) => [
  for (final i in d.items)
    if (i.category == ItemCategory.food && i.qty > 0) (i, foodKey(i)),
];

RecipeMatch? _match(Recipe r, List<(Item, String)> food, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final needed = r.ingredients.where((i) => !i.staple).toList();
  if (needed.isEmpty) return null;
  final uses = <Ingredient, Item>{};
  final missing = <Ingredient>[];
  for (final ing in needed) {
    final hit = food.where((f) => sameFood(f.$2, ing)).map((f) => f.$1).toList()
      ..sort((a, b) => (a.expiresOn ?? DateTime(9999)).compareTo(b.expiresOn ?? DateTime(9999)));
    hit.isEmpty ? missing.add(ing) : uses[ing] = hit.first;
  }
  final soon = uses.values.where((i) => i.expiresOn != null && expiryStatus(today: today, expiresOn: i.expiresOn!).daysLeft <= 3).length;
  return RecipeMatch(r, uses, missing, uses.length / needed.length + soon * 0.6 - missing.length * 0.15);
}

/// The first guess, from the recipe's amount: a counted amount takes that
/// many ("1모" of 2 → 1, all of them → 다 씀); a weight or spoon ("5g")
/// takes none out: the opened one stays, and the use is noted.
CookPick guessCookPick(Ingredient ing, Item item) {
  if (item.qty <= 1) return const CookPick(CookUse.some, 0);
  final n = ing.count;
  if (n == null) return const CookPick(CookUse.some, 0);
  if (n >= item.qty) return const CookPick(CookUse.all, 0);
  return CookPick(CookUse.some, n);
}
