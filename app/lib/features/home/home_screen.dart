import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';
import 'package:intl/intl.dart';

import '../../data/home_store.dart';
import '../../data/home_widget_sync.dart';
import '../../design/tokens.g.dart';
import '../../design/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fairy.dart';
import '../search/search_results.dart';
import 'house_map.dart';
import '../spaces/space_actions.dart';
import '../../widgets/fit_text.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// The one search box: names, initials, location codes, or a question for the fairy.
  final _query = TextEditingController();
  final _searchFocus = FocusNode();
  int _searchAsked = 0;

  @override
  void dispose() {
    _searchFocus.dispose();
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = ref.watch(homeProvider).requireValue;
    final q = _query.text.trim();
    final today = DateTime.now();
    // The home screen widget's search box: also when Home is built only now.
    final asked = ref.watch(searchRequestProvider);
    if (asked != _searchAsked) {
      _searchAsked = asked;
      WidgetsBinding.instance.addPostFrameCallback((_) => _searchFocus.requestFocus());
    }
    final urgent = byExpiry(d, today).where((e) => e.$2.isUrgent).toList();
    final returns = returnsDue(d, today).where((e) => e.$2.isUrgent).toList();
    // Matches light up their furniture on the map.
    final hits = <String, int>{};
    final firstHit = <String, String>{};
    if (q.isNotEmpty) {
      for (final f in searchItems(d, searchTermOf(q))) {
        final top = topStorageOf(d, f.item.containerId);
        hits[top] = (hits[top] ?? 0) + 1;
        firstHit.putIfAbsent(top, () => f.item.id);
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.myHome)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.xs, AppSpace.lg, 112),
        children: [
          TextField(
            key: const ValueKey('home-search'),
            controller: _query,
            focusNode: _searchFocus,
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: l.searchHint,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: q.isEmpty
                  ? null
                  : IconButton(tooltip: l.clear, onPressed: () => setState(_query.clear), icon: const Icon(Icons.close_rounded)),
            ),
          ),
          if (q.isNotEmpty) ...[
            if (hits.isNotEmpty) ...[const SizedBox(height: AppSpace.md), HouseMap(hits: hits, firstHit: firstHit)],
            SearchResults(query: q),
          ] else ...[
            const SizedBox(height: AppSpace.md),
            // Four fixed tiles, no sideways scrolling: a number and a short name.
            Row(
              children: [
                for (final (i, tile) in [
                  ('tile-use-first', urgent.length, l.tileUseFirst, '/expiry'),
                  ('tile-shopping', shoppingList(d).length, l.tileShopping, '/shopping'),
                  ('tile-returns', returns.length, l.tileReturns, '/expiry'),
                  ('tile-report', null, l.tileReport(DateFormat.MMM(Localizations.localeOf(context).toLanguageTag()).format(today)), '/report'),
                ].indexed) ...[
                  if (i > 0) const SizedBox(width: AppSpace.xs),
                  Expanded(
                    child: _Tile(key: ValueKey(tile.$1), count: tile.$2, label: tile.$3, onTap: () => context.push(tile.$4)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpace.md),
            if (d.spaces.isEmpty)
              Card(
                child: EmptyState(
                  pose: FairyPose.carry,
                  title: l.homeEmptyTitle,
                  body: l.homeEmptyBody,
                  action: FilledButton.icon(
                    onPressed: () => addSpaceFlow(context, ref),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l.addSpace),
                  ),
                ),
              )
            else
              const HouseMap(),
          ],
        ],
      ),
    );
  }
}

/// One of the four tiles under the search box: a number over a short name
/// (the report tile has no number).
class _Tile extends StatelessWidget {
  const _Tile({super.key, required this.count, required this.label, required this.onTap});

  final int? count;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = HfColors.of(context);
    final t = Theme.of(context).textTheme;
    final busy = (count ?? 0) > 0;
    return Material(
      color: busy ? c.secondarySoft : c.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md), side: BorderSide(color: c.border)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (count == null)
                Icon(Icons.insert_chart_outlined_rounded, size: 22, color: c.fg)
              else
                Text('$count', style: t.titleLarge?.copyWith(color: busy ? c.secondaryInk : c.mutedFg, height: 1.1)),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: FitText(label, style: t.labelSmall?.copyWith(color: c.fg, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
