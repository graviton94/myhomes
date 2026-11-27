import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../data/achievements.dart';
import '../../data/home_store.dart';
import '../../data/usage_stats.dart';
import '../../data/household.dart';
import '../../data/recipes.dart';
import '../../data/smart_suggest.dart';
import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/fairy.dart';
import '../../widgets/doodle.dart';
import '../../widgets/fairy_growth.dart';
import '../../widgets/fit_text.dart';
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

  // Searches, each counted once a little after typing stops: found something
  // or nothing (closed-test report: "found" only counted taps on a result,
  // so the totals read as if every search failed).
  final _counted = <String>{};
  Timer? _countTimer;
  String? _countPending;

  void _noteSearch(String q, {required bool found}) {
    final k = q.trim().toLowerCase();
    final key = '$found:$k';
    if (k.isEmpty || _counted.contains(key) || _countPending == key) return;
    _countPending = key;
    _countTimer?.cancel();
    _countTimer = Timer(const Duration(seconds: 2), () {
      // Still the same words on screen: that is what the search showed.
      if (mounted && widget.query.trim().toLowerCase() == k && _counted.add(key)) noteUsage(ref, found ? UsageCount.found : UsageCount.empty);
    });
  }

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
    _countTimer?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  // The fairy's server (which costs dust) is never asked on its own while
  // typing (user report: dust went while putting things away); only from
  // the "ask the fairy" button under "not found".
  void _schedule() => _debounce?.cancel();

  Future<void> _ask(String q) async {
    final d = ref.read(homeProvider).requireValue;
    final names = {for (final i in d.items) i.name}.take(400).toList();
    setState(() => _asking = true);
    final r = await ref.read(smartSuggestProvider).find(q, names);
    if (r != null) noteUsage(ref, UsageCount.fairy);
    if (!mounted) return;
    if (r != null) ref.invalidate(creditsProvider);
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
          // Past this month's fairy dust: say so; a tap opens where to get more.
          if (out)
            GestureDetector(
              key: const ValueKey('ai-quota'),
              onTap: () => context.push('/plus'),
              child: Container(
                margin: const EdgeInsets.only(top: AppSpace.md),
                padding: const EdgeInsets.all(AppSpace.md),
                decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(AppRadius.md)),
                child: Text('${l.aiToWordSearch}\n${l.aiQuotaSubscribe}', style: AppType.caption.copyWith(color: c.accentInk)),
              ),
            ),
          // Only at the moment dust is being used, and only when little is left.
          if (_askedFor != null || _asking)
            if (dustLeft(ref.watch(creditsProvider).value) case final dust? when dust.left <= 10)
              Container(
                key: const ValueKey('dust-low'),
                margin: const EdgeInsets.only(top: AppSpace.md),
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
                decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(AppRadius.md)),
                child: Row(
                  children: [
                    const DoodleDust(size: 18),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: OneLine([l.dustLow(dust.left)], style: AppType.label.copyWith(color: c.accentInk)),
                    ),
                  ],
                ),
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
      _noteSearch(q, found: true);
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
        _noteSearch(q, found: true);
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
          FairySays(l.fairyBuyAsk(term), pose: FairyPose.ask),
          _Action(intent: AskIntent.buy, name: term),
        ],
      );
    }
    final family = ref.watch(householdProvider).value;
    if (!_asking) _noteSearch(q, found: false);
    final said = FairySays(_asking ? l.searchThinking : l.fairyNotFound(term.isEmpty ? q : term), pose: _asking ? FairyPose.think : FairyPose.notfound);
    // Asking the fairy by description costs a dust: only when tapped, and
    // only for a signed-in person not asked about these words yet.
    final canAsk = !_asking && _askedFor != q && term.length >= 2 && dustLeft(ref.watch(creditsProvider).value) != null;
    final notFound = !canAsk
        ? said
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              said,
              Padding(
                padding: const EdgeInsets.only(top: AppSpace.sm),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    key: const ValueKey('ask-fairy-more'),
                    onPressed: () => _ask(q),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(child: OneLine([l.searchAskFairy, l.searchAskFairyShort])),
                        const SizedBox(width: AppSpace.xs),
                        DustCost(dustCost.find),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
    if (list.isEmpty) return FairySays(l.fairyCookNone, pose: FairyPose.notfound);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FairySays(l.fairyCookFound, pose: FairyPose.found),
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

class _List extends ConsumerWidget {
  const _List({required this.fairy, required this.found, required this.d, this.smart = false, this.intent = AskIntent.where});

  final String fairy;
  final List<Found> found;
  final HomeData d;
  final bool smart;
  final AskIntent intent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FairySays(fairy, pose: FairyPose.answer, smart: smart),
        if (intent == AskIntent.buy || intent == AskIntent.usedUp) _Action(intent: intent, name: found.first.item.name, item: found.first.item),
        if (plannedRooms(d).isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.sm),
            child: OutlinedButton.icon(
              key: const ValueKey('search-on-map'),
              onPressed: () => context.push('/where?items=${found.map((f) => f.item.id).join(',')}'),
              icon: const Icon(Icons.map_rounded),
              label: OneLine([l.searchOnMap]),
            ),
          ),
        const SizedBox(height: AppSpace.sm),
        for (final f in found)
          Card(
            margin: const EdgeInsets.only(bottom: AppSpace.sm),
            child: ListTile(
              leading: ItemThumb(category: f.item.category, photoPath: f.item.photoPath, iconKey: f.item.icon),
              title: Text(f.item.qty > 1 ? '${f.item.name} ×${f.item.qty}' : f.item.name),
              // A moving box says where it goes ("이사 상자 › 상자 5 · 주방에 갈 상자").
              subtitle: OneLine([
                if (d.container(f.item.containerId)?.goesTo case final room?) ...[
                  '${pathText(f.path)} · ${l.movingGoesTo(room)}',
                  '${pathText(f.path.skip(1).toList())} · ${l.movingGoesTo(room)}',
                ],
                pathText(f.path),
                pathText(f.path.skip(1).toList()),
              ]),
              trailing: Text(d.container(f.item.containerId)?.code ?? '', style: AppType.code.copyWith(color: c.mutedFg)),
              onTap: () {
                countAchievement(ref, Achievement.finder);
                openItem(context, d, f.item);
              },
            ),
          ),
      ],
    );
  }
}

/// The fairy's one line under the search box.
class FairySays extends StatelessWidget {
  const FairySays(this.text, {super.key, required this.pose, this.smart = false, this.below});

  final String text;

  /// More inside the bubble, under the line (the fairy's put-away card).
  final Widget? below;
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (smart) ...[Icon(Icons.auto_awesome_rounded, size: 16, color: c.primaryInk), const SizedBox(width: 6)],
                      Flexible(
                        child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: smart ? c.primaryInk : null)),
                      ),
                    ],
                  ),
                  ?below,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
