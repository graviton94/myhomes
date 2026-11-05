import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../data/home_store.dart';
import '../../data/household.dart';
import '../../data/recipes.dart';
import '../../data/smart_suggest.dart';
import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/fairy.dart';
import '../recipes/recipes_screen.dart';
import '../../widgets/inventory_slot.dart';
import '../../widgets/open_item.dart';
import '../../widgets/sheets.dart';

/// Strips question words so "건전지 어디 있어?" / "where are the batteries"
/// become a search term.
String searchTermOf(String question) => askOf(question).term;

/// What Home shows under its search box while something is typed: the
/// fairy's one-line answer, then the matches. Names, Korean initials and
/// location codes are found on the phone; only when they find nothing does
/// the fairy's server get asked what the words mean ("열 날 때 먹는 약" →
/// 타이레놀), after typing pauses.
class SearchResults extends ConsumerStatefulWidget {
  const SearchResults({super.key, required this.query});

  final String query;

  /// Typing pause before the server is asked.
  static const askAfter = Duration(milliseconds: 800);

  @override
  ConsumerState<SearchResults> createState() => _SearchResultsState();
}

class _SearchResultsState extends ConsumerState<SearchResults> {
  Timer? _debounce;
  String? _askedFor;
  Pick? _smart;
  bool _asking = false;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(SearchResults old) {
    super.didUpdateWidget(old);
    if (old.query != widget.query) _schedule();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _schedule() {
    _debounce?.cancel();
    final term = searchTermOf(widget.query);
    final d = ref.read(homeProvider).requireValue;
    if (term.length < 2 || searchItems(d, term).isNotEmpty || askOf(widget.query).intent == AskIntent.cook) return;
    _debounce = Timer(SearchResults.askAfter, () => _ask(widget.query.trim()));
  }

  Future<void> _ask(String q) async {
    final d = ref.read(homeProvider).requireValue;
    final names = {for (final i in d.items) i.name}.take(400).toList();
    setState(() => _asking = true);
    final r = await ref.read(smartSuggestProvider).find(q, names);
    if (!mounted) return;
    setState(() {
      _asking = false;
      if (widget.query.trim() == q) {
        _askedFor = q;
        _smart = r;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    return ValueListenableBuilder<bool>(
      valueListenable: ref.watch(smartSuggestProvider).outOfQuota,
      builder: (context, out, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Past today's AI allowance: say so, and offer the subscription.
          if (out)
            Container(
              key: const ValueKey('ai-quota'),
              margin: const EdgeInsets.only(top: AppSpace.md),
              padding: const EdgeInsets.all(AppSpace.md),
              decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Text('${l.aiToWordSearch}\n${l.aiQuotaSubscribe}', style: AppType.caption.copyWith(color: c.accentInk)),
            ),
          _results(context),
        ],
      ),
    );
  }

  Widget _results(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = ref.watch(homeProvider).requireValue;
    final q = widget.query.trim();
    final ask = askOf(q);
    final term = ask.term;
    // "뭐 해 먹지": dishes from the food at home, not a thing to find.
    if (ask.intent == AskIntent.cook) return _CookIdeas(term: term);
    final found = searchItems(d, term);

    if (found.isNotEmpty) {
      return _List(fairy: _fairyLine(l, ask.intent, found), found: found, d: d, intent: ask.intent);
    }
    final pick = _askedFor == q ? _smart : null;
    // With the server's "does it mean any of our things?" answer: yes above
    // 0.7, maybe between, no below 0.3. Older servers: the pick's confidence.
    final fits = pick?.fits;
    final level = pick == null
        ? SuggestLevel.ignore
        : fits == null
        ? suggestLevel(pick.confidence)
        : fits >= 0.7
        ? SuggestLevel.auto
        : fits >= 0.3
        ? SuggestLevel.chips
        : SuggestLevel.ignore;
    if (pick != null && level != SuggestLevel.ignore) {
      final names = level == SuggestLevel.auto
          ? [pick.choice]
          : [
              for (final (name, p) in pick.top)
                if (suggestLevel(p) != SuggestLevel.ignore || name == pick.choice) name,
            ];
      final hits = [
        for (final name in names.take(3))
          for (final i in d.items.where((i) => i.name == name)) Found(i, d.pathOf(i.containerId)),
      ];
      if (hits.isNotEmpty) {
        return _List(
          fairy: level == SuggestLevel.auto ? l.smartFound : l.smartMaybe,
          found: hits,
          d: d,
          smart: true,
          intent: level == SuggestLevel.auto ? ask.intent : AskIntent.where,
        );
      }
    }
    // Something new to buy: it can go on the list without being in the home.
    if (ask.intent == AskIntent.buy && term.isNotEmpty && !_asking) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FairySays(l.fairyBuyAsk(term), pose: FairyPose.found),
          _Action(intent: AskIntent.buy, name: term),
        ],
      );
    }
    final family = ref.watch(householdProvider).value;
    final notFound = _FairySays(
      _asking ? l.searchThinking : l.fairyNotFound(term.isEmpty ? q : term),
      pose: _asking ? FairyPose.found : FairyPose.worry,
    );
    // In a shared home, nobody's phone knew it: ask the people instead.
    if (_asking || family == null || family.members.length < 2 || term.isEmpty) return notFound;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        notFound,
        Padding(
          padding: const EdgeInsets.only(top: AppSpace.sm),
          child: Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              key: const ValueKey('ask-family'),
              icon: const Icon(Icons.campaign_outlined),
              label: Text(l.askFamily),
              onPressed: () async {
                final ok = await ref.read(householdsProvider).askFamily(term);
                if (context.mounted) showMessage(context, ok ? l.askedFamily : l.familyProblemOffline);
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// The fairy's line for things found: how many there are when asked.
String _fairyLine(AppLocalizations l, AskIntent intent, List<Found> found) {
  final name = found.first.item.name;
  final same = found.where((f) => f.item.name == name);
  return switch (intent) {
    AskIntent.howMany => l.fairyHowMany(same.fold<int>(0, (n, f) => n + f.item.qty), name),
    AskIntent.buy => l.fairyBuyAsk(name),
    AskIntent.usedUp => l.fairyUsedAsk(name),
    AskIntent.where || AskIntent.cook => l.fairyFoundCount(found.length),
  };
}

/// The fairy's dishes for "뭐 해 먹지" ("두부로 뭐 해 먹지": with tofu), top three.
class _CookIdeas extends ConsumerWidget {
  const _CookIdeas({required this.term});

  final String term;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final list = withTerm(ref.watch(cookIdeasProvider), term);
    if (list.isEmpty) return _FairySays(l.fairyCookNone, pose: FairyPose.worry);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FairySays(l.fairyCookFound, pose: FairyPose.found),
        const SizedBox(height: AppSpace.sm),
        for (final m in list.take(3)) RecipeCard(m),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            key: const ValueKey('recipes-more'),
            onPressed: () => context.push(Uri(path: '/recipes', queryParameters: term.isEmpty ? null : {'with': term}).toString()),
            child: Text(l.recipesMore),
          ),
        ),
      ],
    );
  }
}

/// "Put it on the list?" / "Mark it used up?": the fairy proposes, the
/// person confirms with one tap.
class _Action extends ConsumerWidget {
  const _Action({required this.intent, required this.name, this.item});

  final AskIntent intent;
  final String name;
  final Item? item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final home = ref.read(homeProvider.notifier);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.sm),
      child: Align(
        alignment: Alignment.centerRight,
        child: FilledButton.icon(
          key: ValueKey('fairy-${intent.name}'),
          icon: Icon(intent == AskIntent.buy ? Icons.add_shopping_cart_rounded : Icons.remove_rounded),
          label: Text(intent == AskIntent.buy ? l.fairyBuyDo : l.fairyUsedDo),
          onPressed: () async {
            if (intent == AskIntent.buy) {
              await home.apply((d, ctx) => addToBuy(d, ctx, item?.name ?? name));
              if (context.mounted) showUndo(context, ref, l.fairyBuyDone(item?.name ?? name));
            } else if (item != null) {
              await home.apply((d, ctx) => useUpItems(d, ctx, [item!.id]));
              if (context.mounted) showUndo(context, ref, l.usedUpName(item!.name));
            }
          },
        ),
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.fairy, required this.found, required this.d, this.smart = false, this.intent = AskIntent.where});

  final String fairy;
  final List<Found> found;
  final HomeData d;
  final bool smart;
  final AskIntent intent;

  @override
  Widget build(BuildContext context) {
    final c = HfColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FairySays(fairy, pose: FairyPose.found, smart: smart),
        if (intent == AskIntent.buy || intent == AskIntent.usedUp)
          _Action(intent: intent, name: found.first.item.name, item: found.first.item),
        const SizedBox(height: AppSpace.sm),
        for (final f in found)
          Card(
            margin: const EdgeInsets.only(bottom: AppSpace.sm),
            child: ListTile(
              leading: ItemThumb(category: f.item.category, photoPath: f.item.photoPath, iconKey: f.item.icon),
              title: Text(f.item.qty > 1 ? '${f.item.name} ×${f.item.qty}' : f.item.name),
              subtitle: Text(pathText(f.path), maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Text(d.container(f.item.containerId)?.code ?? '', style: AppType.code.copyWith(color: c.mutedFg)),
              onTap: () => openItem(context, d, f.item),
            ),
          ),
      ],
    );
  }
}

/// The fairy's one line under the search box.
class _FairySays extends StatelessWidget {
  const _FairySays(this.text, {required this.pose, this.smart = false});

  final String text;
  final FairyPose pose;
  final bool smart;

  @override
  Widget build(BuildContext context) {
    final c = HfColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Fairy(pose, height: 52),
          const SizedBox(width: AppSpace.sm),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 10),
              decoration: BoxDecoration(
                color: smart ? c.primarySoft : c.card,
                border: Border.all(color: smart ? c.primarySoft : c.border),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.md),
                  topRight: Radius.circular(AppRadius.md),
                  bottomRight: Radius.circular(AppRadius.md),
                  bottomLeft: Radius.circular(4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (smart) ...[Icon(Icons.auto_awesome_rounded, size: 16, color: c.primaryInk), const SizedBox(width: 6)],
                  Flexible(
                    child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: smart ? c.primaryInk : null)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
