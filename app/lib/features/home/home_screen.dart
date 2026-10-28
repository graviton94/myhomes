import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../data/home_store.dart';
import '../../data/home_widget_sync.dart';
import '../../design/tokens.g.dart';
import '../../design/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../settings/settings.dart';
import '../../widgets/app_icons.dart';
import '../../widgets/dday_badge.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fairy.dart';
import '../../widgets/inventory_slot.dart';
import '../../widgets/sheets.dart';
import '../../widgets/open_item.dart';
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
    final settings = ref.watch(settingsProvider);
    // The home screen widget's search box: also when Home is built only now.
    final asked = ref.watch(searchRequestProvider);
    if (asked != _searchAsked) {
      _searchAsked = asked;
      WidgetsBinding.instance.addPostFrameCallback((_) => _searchFocus.requestFocus());
    }
    final urgent = byExpiry(d, today).where((e) => e.$2.isUrgent).toList();
    final returns = returnsDue(d, today).where((e) => e.$2.isUrgent).toList();
    final low = lowStock(d);
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
            const SizedBox(height: AppSpace.lg),
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
            const SizedBox(height: AppSpace.lg),
            if (settings.expiryOn && urgent.isNotEmpty)
              _Band(
                key: const ValueKey('band-expiry'),
                title: l.eatFirst(urgent.length),
                onSeeAll: () => context.push('/expiry'),
                children: [
                  for (final (item, status) in urgent.take(3))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: ItemThumb(category: item.category, photoPath: item.photoPath, iconKey: item.icon),
                      title: Text(item.qty > 1 ? '${item.name} ×${item.qty}' : item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(pathText(d.pathOf(item.containerId)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Padding(
                        padding: const EdgeInsets.only(right: AppSpace.sm),
                        child: DdayBadge(status),
                      ),
                      onTap: () => openItem(context, d, item),
                    ),
                ],
              ),
            if (settings.returnsOn && returns.isNotEmpty)
              _Band(
                key: const ValueKey('band-returns'),
                title: l.getBackCount(returns.length),
                onSeeAll: () => context.push('/expiry'),
                children: [
                  for (final (storage, status) in returns.take(3))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: storageGlyph(storage, size: 24, color: HfColors.of(context).accentInk),
                      title: Text(storage.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(l.itemsCount(d.itemsIn(storage.id).length), maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Padding(
                        padding: const EdgeInsets.only(right: AppSpace.sm),
                        child: ReturnBadge(status),
                      ),
                      onTap: () => context.push('/space/${storage.spaceId}'),
                    ),
                ],
              ),
            if (settings.lowStockOn && low.isNotEmpty)
              _Band(
                key: const ValueKey('band-low-stock'),
                title: l.runningLow(low.length),
                onSeeAll: () => context.push('/shopping'),
                children: [
                  for (final item in low.take(3))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: ItemThumb(category: item.category, photoPath: item.photoPath, iconKey: item.icon),
                      title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: FitText(l.shoppingNeed(item.qty, item.minQty!)),
                      onTap: () => openItem(context, d, item),
                    ),
                ],
              ),
            // The monthly report, under the map and its bands.
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('open-report'),
                onPressed: () => context.push('/report'),
                icon: const Icon(Icons.insert_chart_outlined_rounded),
                label: Text(l.reportOpen),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A short list under the map for a switched-on extra: use first, to get
/// back, running low. "See all" opens the full list.
class _Band extends StatelessWidget {
  const _Band({super.key, required this.title, required this.onSeeAll, required this.children});

  final String title;
  final VoidCallback onSeeAll;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.md),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.sm, AppSpace.sm),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleSmall)),
                TextButton(onPressed: onSeeAll, child: Text(AppLocalizations.of(context).seeAll)),
              ],
            ),
            ...children,
          ],
        ),
      ),
    ),
  );
}
