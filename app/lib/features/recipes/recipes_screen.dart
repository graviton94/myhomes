import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../data/recipes.dart';
import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/chip_line.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fairy.dart';
import '../../widgets/fit_text.dart';
import '../../widgets/inventory_slot.dart';

/// "뭐 해 먹지": dishes the food at home makes, best first, under five fixed
/// filters. [term] narrows to dishes using that food ("두부로 뭐 해 먹지").
class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key, this.term});

  final String? term;

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  RecipeKind _kind = RecipeKind.all;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final all = withTerm(ref.watch(cookIdeasProvider), widget.term);
    final list = all.where((m) => _kind.has(m.recipe)).toList();
    final loading = ref.watch(recipesProvider).isLoading;
    return Scaffold(
      appBar: AppBar(title: Text(l.recipesTitle)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : all.isEmpty
          ? Center(
              child: SingleChildScrollView(
                child: EmptyState(pose: FairyPose.worry, title: l.recipesEmptyTitle, body: l.recipesEmptyBody),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.xl),
              children: [
                ChipLine(
                  children: [
                    for (final k in RecipeKind.values)
                      ChoiceChip(
                        key: ValueKey('recipe-kind-${k.name}'),
                        label: Text(kindName(l, k)),
                        selected: _kind == k,
                        onSelected: (_) => setState(() => _kind = k),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
                for (final m in list) RecipeCard(m),
                const SizedBox(height: AppSpace.md),
                Text(l.recipeSource, style: AppType.caption.copyWith(color: HfColors.of(context).mutedFg)),
              ],
            ),
    );
  }
}

/// Matches that use [term]'s food, or all of them without one.
List<RecipeMatch> withTerm(List<RecipeMatch> all, String? term) {
  final t = term?.trim() ?? '';
  if (t.isEmpty) return all;
  final ing = Ingredient(t, t);
  return [
    for (final m in all)
      if (m.uses.values.any((i) => sameFood(foodKey(i), ing) || sameFood(t, Ingredient(i.name, foodKey(i))))) m,
  ];
}

String kindName(AppLocalizations l, RecipeKind k) => switch (k) {
  RecipeKind.all => l.recipeKindAll,
  RecipeKind.side => l.recipeKindSide,
  RecipeKind.soup => l.recipeKindSoup,
  RecipeKind.meal => l.recipeKindMeal,
  RecipeKind.dessert => l.recipeKindDessert,
};

/// One dish in a list: photo, name, what is at home and missing, and the
/// food that should go first.
class RecipeCard extends StatelessWidget {
  const RecipeCard(this.match, {super.key});

  final RecipeMatch match;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final r = match.recipe;
    final urgent = match.urgent(DateTime.now()).map((i) => i.name).toSet().toList();
    final have = match.missing.isEmpty ? l.recipeHaveAll(match.uses.length) : l.recipeHaveMissing(match.uses.length, match.missing.length);
    return Card(
      key: ValueKey('recipe-${r.id}'),
      margin: const EdgeInsets.only(bottom: AppSpace.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => context.push('/recipe/${r.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.sm),
          child: Row(
            children: [
              RecipePhoto(r.photo, size: 56),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OneLine([r.name], style: AppType.label, minScale: 0.8),
                    OneLine([have], style: AppType.caption.copyWith(color: c.mutedFg)),
                    if (urgent.isNotEmpty)
                      OneLine([
                        for (var n = urgent.length; n > 0; n--) l.recipeUrgent(urgent.take(n).join(' · ')),
                      ], style: AppType.caption.copyWith(color: c.primaryInk, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The source's photo, fetched when shown; a food mark when there is none or
/// it cannot be fetched.
class RecipePhoto extends StatelessWidget {
  const RecipePhoto(this.url, {super.key, this.size, this.height, this.hideWhenMissing = false});

  final String? url;
  final double? size;
  final double? height;

  /// A step's photo: nothing at all when it cannot be fetched.
  final bool hideWhenMissing;

  /// Photos that could not be fetched, so a list that scrolls them back in
  /// does not try (and show a loading box) again.
  static final _failed = <String>{};

  @override
  Widget build(BuildContext context) {
    final c = HfColors.of(context);
    final w = size;
    final h = height ?? size;
    Widget mark() => Container(
      width: w,
      height: h,
      color: c.muted,
      alignment: Alignment.center,
      child: ItemThumb(category: ItemCategory.food, size: (h ?? 56) * 0.6),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: url == null || _failed.contains(url)
          ? (hideWhenMissing && url != null ? const SizedBox.shrink() : mark())
          : Image.network(
              url!,
              width: w,
              height: h,
              fit: BoxFit.cover,
              cacheWidth: w == null ? 1080 : (w * 3).round(),
              errorBuilder: (_, _, _) {
                _failed.add(url!);
                return hideWhenMissing ? const SizedBox.shrink() : mark();
              },
              loadingBuilder: (context, child, p) => p == null ? child : mark(),
            ),
    );
  }
}
