import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy/data/home_store.dart';
import 'package:homefairy/data/recipes.dart';
import 'package:homefairy/features/recipes/recipe_screen.dart';
import 'package:homefairy/features/recipes/recipes_screen.dart';
import 'package:homefairy_core/homefairy_core.dart';

import 'helpers.dart';

void main() {
  setUpAll(loadAppFonts);
  const ko = {'language': 'ko'};

  testWidgets('the list shows dishes from the food at home, under fixed filters', (tester) async {
    final c = await pumpApp(tester, location: '/recipes', prefs: ko, home: sampleHome(ko: true));
    final ideas = c.read(cookIdeasProvider);
    expect(ideas, isNotEmpty);
    expect(find.byType(RecipeCard), findsWidgets);
    expect(find.byKey(const ValueKey('recipe-kind-all')), findsOneWidget);
    // A filter keeps only its kind.
    await tester.tap(find.byKey(const ValueKey('recipe-kind-soup')));
    await tester.pumpAndSettle();
    final soups = ideas.where((m) => m.recipe.kind == '국&찌개').length;
    expect(find.byType(RecipeCard), soups == 0 ? findsNothing : findsWidgets);
  });

  testWidgets('a recipe shows amounts and every step; cooking takes out only what was used', (tester) async {
    final c = await pumpApp(tester, location: '/recipes', prefs: ko, home: sampleHome(ko: true));
    final m = c.read(cookIdeasProvider).firstWhere((m) => m.uses.values.any((i) => i.qty > 1));
    await tester.pumpWidget(const SizedBox());
    final c2 = await pumpApp(tester, location: '/recipe/${m.recipe.id}', prefs: ko, home: sampleHome(ko: true));
    expect(find.byType(RecipeScreen), findsOneWidget);
    // Every step is there, in full.
    await tester.scrollUntilVisible(find.byKey(ValueKey('step-${m.recipe.steps.length}')), 300, scrollable: find.byType(Scrollable).first);
    expect(find.textContaining(keepWords(m.recipe.steps.last).substring(0, 4)), findsWidgets);

    final before = {for (final i in c2.read(homeProvider).requireValue.items) i.id: i.qty};
    await tester.tap(find.byKey(const ValueKey('recipe-cooked')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cook-done')), findsOneWidget);
    // Everything to "안 씀" except the first thing with several, which loses one.
    final several = m.uses.values.firstWhere((i) => i.qty > 1);
    // "조금" keeps the recipe's guess when it already was the choice; then − + sets one.
    final guess = [
      for (final e in m.uses.entries)
        if (e.value.id == several.id) guessCookPick(e.key, e.value),
    ].last;
    for (final i in {for (final i in m.uses.values) i.id: i}.values) {
      final seg = find.byKey(ValueKey('cook-${i.id}'));
      await tester.ensureVisible(seg);
      await tester.tap(find.descendant(of: seg, matching: find.text(keepWords(i.id == several.id ? '조금' : '안 씀'))));
      await tester.pumpAndSettle();
    }
    // Set the stepper to 1 from wherever it started.
    final start = guess.use == CookUse.some ? guess.take : 0;
    final stepper = find.byKey(ValueKey('cook-take-${several.id}'));
    await tester.ensureVisible(stepper);
    for (var n = start; n != 1; n += n < 1 ? 1 : -1) {
      await tester.tap(find.descendant(of: stepper, matching: find.byIcon(n < 1 ? Icons.add_rounded : Icons.remove_rounded)));
      await tester.pumpAndSettle();
    }
    const take = 1;
    await tester.ensureVisible(find.byKey(const ValueKey('cook-done')));
    await tester.tap(find.byKey(const ValueKey('cook-done')));
    await tester.pumpAndSettle();
    final after = {for (final i in c2.read(homeProvider).requireValue.items) i.id: i.qty};
    expect(after[several.id], before[several.id]! - take);
    for (final id in before.keys.where((id) => id != several.id)) {
      expect(after[id], before[id], reason: id);
    }
    // Undo puts it back.
    await tester.tap(find.byKey(const ValueKey('toast-undo')));
    await tester.pumpAndSettle();
    expect({for (final i in c2.read(homeProvider).requireValue.items) i.id: i.qty}, before);
  });

  testWidgets('"뭐 해 먹지" in the search box suggests dishes', (tester) async {
    await pumpApp(tester, prefs: ko, home: sampleHome(ko: true));
    await tester.enterText(find.byKey(const ValueKey('home-search')), '뭐 해 먹지?');
    await tester.pumpAndSettle();
    expect(find.byType(RecipeCard), findsWidgets);
    expect(find.byKey(const ValueKey('recipes-more')), findsOneWidget);
  });

  testWidgets('the use-first sheet leads to dishes using what goes soon', (tester) async {
    await pumpApp(tester, prefs: ko, home: sampleHome(ko: true));
    await tester.tap(find.byKey(const ValueKey('tile-use-first')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cook-line')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cook-line')));
    await tester.pumpAndSettle();
    expect(find.byType(RecipesScreen), findsOneWidget);
  });
}
