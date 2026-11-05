// The public recipes (assets/recipes.json, built by tool/build_recipes.py)
// and what the home's food can make. Matching runs on the phone.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homefairy_core/homefairy_core.dart';

import 'home_store.dart';

/// All recipes, decoded off the main thread (about 1 MB of JSON).
final recipesProvider = FutureProvider<List<Recipe>>((ref) async {
  final text = await rootBundle.loadString('assets/recipes.json');
  return compute(parseRecipes, text);
});

List<Recipe> parseRecipes(String text) => recipesFromJson(jsonDecode(text) as Map<String, Object?>);

/// What the food at home makes, best first (empty while the recipes load).
final cookIdeasProvider = Provider<List<RecipeMatch>>((ref) {
  final recipes = ref.watch(recipesProvider).value;
  final d = ref.watch(homeProvider).value;
  if (recipes == null || d == null) return const [];
  return suggestRecipes(d, recipes, DateTime.now(), limit: 80);
});

/// The five fixed filters on the list.
enum RecipeKind {
  all({}),
  side({'반찬'}),
  soup({'국&찌개'}),
  meal({'밥', '일품'}),
  dessert({'후식'});

  const RecipeKind(this.kinds);

  /// The source's RCP_PAT2 values it shows (all: every one).
  final Set<String> kinds;

  bool has(Recipe r) => kinds.isEmpty || kinds.contains(r.kind);
}
