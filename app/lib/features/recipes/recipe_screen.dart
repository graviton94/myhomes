import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../data/achievements.dart';
import '../../data/home_store.dart';
import '../../data/recipes.dart';
import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/fit_text.dart';
import '../../widgets/layers.dart';
import '../../widgets/sheets.dart';
import 'recipes_screen.dart';

/// One dish: photo, what goes in (with amounts, and what is at home), every
/// step in full, and "만들었어요", which takes out only what was used.
class RecipeScreen extends ConsumerWidget {
  const RecipeScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final t = Theme.of(context).textTheme;
    final recipes = ref.watch(recipesProvider).value;
    final r = recipes?.where((r) => r.id == id).firstOrNull;
    if (r == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: recipes == null ? const CircularProgressIndicator() : Text(l.recipesEmptyTitle)),
      );
    }
    final d = ref.watch(homeProvider).requireValue;
    final m = matchRecipe(d, r, DateTime.now());
    final staples = r.ingredients.where((i) => i.staple).toList();
    final muted = AppType.caption.copyWith(color: c.mutedFg);

    return Scaffold(
      appBar: AppBar(title: OneLine([r.name], style: t.titleLarge, minScale: 0.8)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.xl),
        children: [
          AspectRatio(aspectRatio: 4 / 3, child: RecipePhoto(r.photo)),
          const SizedBox(height: AppSpace.md),
          OneLine([
            [kindLabel(l, r.kind), r.way, if (r.kcal != null) '${r.kcal}kcal'].where((s) => s.isNotEmpty && s != '기타').join(' · '),
          ], style: muted),
          const SizedBox(height: AppSpace.md),
          Text(l.recipeIngredients, style: t.titleSmall),
          for (final ing in r.ingredients.where((i) => !i.staple)) _IngredientRow(ing: ing, item: m.uses[ing]),
          if (staples.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.sm),
              child: OneLine([
                l.recipeStaples(staples.length, staples.map((i) => i.name).join(' · ')),
                l.recipeStaplesShort(staples.length),
              ], style: muted),
            ),
          if (m.missing.isNotEmpty) ...[
            const SizedBox(height: AppSpace.md),
            OutlinedButton.icon(
              key: const ValueKey('recipe-buy-missing'),
              icon: const Icon(Icons.add_shopping_cart_rounded),
              label: FitText(l.recipeBuyMissing(m.missing.length)),
              onPressed: () async {
                final home = ref.read(homeProvider.notifier);
                await home.apply((d, ctx) {
                  var out = d;
                  for (final i in m.missing) {
                    out = addToBuy(out, ctx, i.name);
                  }
                  return out;
                });
                if (context.mounted) showUndo(context, ref, l.recipeBuyDone(m.missing.length));
              },
            ),
          ],
          const SizedBox(height: AppSpace.lg),
          Text(l.recipeSteps(r.steps.length), style: t.titleSmall),
          for (final (n, step) in r.steps.indexed) _Step(n: n + 1, text: step, photo: n < r.stepPhotos.length ? r.stepPhotos[n] : null),
          if (r.tip != null) ...[
            const SizedBox(height: AppSpace.md),
            Container(
              padding: const EdgeInsets.all(AppSpace.md),
              decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Prose('${l.recipeTip} · ${r.tip!}', style: AppType.caption.copyWith(color: c.accentInk, height: 1.5)),
            ),
          ],
          const SizedBox(height: AppSpace.md),
          Text(l.recipeSource, style: muted),
        ],
      ),
      bottomNavigationBar: m.uses.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.sm),
                child: FilledButton(
                  key: const ValueKey('recipe-cooked'),
                  onPressed: () => _cooked(context, ref, m),
                  child: Text(l.recipeCooked),
                ),
              ),
            ),
    );
  }

  Future<void> _cooked(BuildContext context, WidgetRef ref, RecipeMatch m) async {
    final l = AppLocalizations.of(context);
    final picks = await showCookSheet(context, m);
    if (picks == null || !context.mounted) return;
    final home = ref.read(homeProvider.notifier);
    final ranOut = await home.apply<List<String>>((d, ctx) => cook(d, ctx, picks)) ?? const [];
    await countAchievement(ref, Achievement.cook);
    if (!context.mounted) return;
    showActionToast(
      context,
      message: l.cookDone,
      actions: [
        if (ranOut.isNotEmpty)
          ToastAction(id: 'to-buy', l.cookToBuy, () async {
            await home.apply((d, ctx) {
              var out = d;
              for (final name in ranOut) {
                out = addToBuy(out, ctx, name);
              }
              return out;
            });
          }),
        ToastAction(id: 'undo', l.undo, home.undo),
      ],
    );
  }
}

/// The source's kinds in the app's words ("국&찌개" → "국·찌개").
String kindLabel(AppLocalizations l, String kind) => switch (kind) {
  '반찬' => l.recipeKindSide,
  '국&찌개' => l.recipeKindSoup,
  '밥' || '일품' => l.recipeKindMeal,
  '후식' => l.recipeKindDessert,
  _ => kind,
};

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({required this.ing, required this.item});

  final Ingredient ing;
  final Item? item;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final have = item != null;
    return Container(
      key: ValueKey('ing-${ing.key}'),
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OneLine([ing.name], style: AppType.body),
                if (ing.amount != null) OneLine([ing.amount!], style: AppType.caption.copyWith(color: c.mutedFg)),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          if (have) Icon(Icons.check_rounded, size: 16, color: c.secondaryInk),
          Text(
            have ? l.recipeHave(item!.qty) : l.recipeMissing,
            style: AppType.caption.copyWith(color: have ? c.secondaryInk : c.primaryInk, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// A numbered step, in full, broken only between words; its photo under it.
class _Step extends StatelessWidget {
  const _Step({required this.n, required this.text, this.photo});

  final int n;
  final String text;
  final String? photo;

  @override
  Widget build(BuildContext context) {
    final c = HfColors.of(context);
    return Container(
      key: ValueKey('step-$n'),
      padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: c.primarySoft,
            child: Text('$n', style: AppType.label.copyWith(color: c.primaryInk, fontSize: 13)),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Prose(text, style: AppType.body.copyWith(height: 1.55)),
                if (photo != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpace.sm),
                    child: RecipePhoto(photo, height: 180, hideWhenMissing: true),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "얼마나 썼어요?": for each thing at home the dish uses, 안 씀 · 조금 · 다 씀,
/// first guessed from the recipe's amounts; "조금" of several gets a − +
/// (0: one was opened, none taken out).
Future<Map<String, CookPick>?> showCookSheet(BuildContext context, RecipeMatch m) {
  final picks = <String, CookPick>{for (final e in m.uses.entries) e.value.id: guessCookPick(e.key, e.value)};
  // One row per thing (two ingredients can be the same thing).
  final items = {for (final i in m.uses.values) i.id: i}.values.toList();
  return showModalBottomSheet<Map<String, CookPick>>(
    context: context,
    isScrollControlled: true,
    builder: (sheet) {
      final l = AppLocalizations.of(sheet);
      final c = HfColors.of(sheet);
      return StatefulBuilder(
        builder: (sheet, setState) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheet).height * 0.85),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SheetHeader(l.cookAsk),
                  OneLine([l.cookAskDetail], style: AppType.caption.copyWith(color: c.mutedFg)),
                  for (final item in items) ...[
                    const SizedBox(height: AppSpace.md),
                    Row(
                      children: [
                        Expanded(child: OneLine([item.name], style: AppType.label)),
                        Text(l.cookHave(item.qty), style: AppType.caption.copyWith(color: c.mutedFg)),
                      ],
                    ),
                    const SizedBox(height: AppSpace.xs),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<CookUse>(
                        key: ValueKey('cook-${item.id}'),
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(value: CookUse.none, label: Text(l.cookNone)),
                          ButtonSegment(value: CookUse.some, label: Text(l.cookSome)),
                          ButtonSegment(value: CookUse.all, label: Text(l.cookAll)),
                        ],
                        selected: {picks[item.id]!.use},
                        onSelectionChanged: (s) => setState(() {
                          final use = s.first;
                          picks[item.id] = CookPick(use, 0);
                        }),
                      ),
                    ),
                    if (picks[item.id]!.use == CookUse.some && item.qty > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpace.xs),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                l.cookTake,
                                textAlign: TextAlign.end,
                                style: AppType.caption.copyWith(color: c.mutedFg),
                              ),
                            ),
                            const SizedBox(width: AppSpace.sm),
                            QtyStepper(
                              key: ValueKey('cook-take-${item.id}'),
                              value: picks[item.id]!.take,
                              // 0: opened, nothing taken out.
                              min: 0,
                              max: item.qty - 1,
                              onChanged: (v) => setState(() => picks[item.id] = CookPick(CookUse.some, v)),
                            ),
                          ],
                        ),
                      ),
                  ],
                  const SizedBox(height: AppSpace.lg),
                  FilledButton(key: const ValueKey('cook-done'), onPressed: () => Navigator.pop(sheet, picks), child: Text(l.cookTakeOut)),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
