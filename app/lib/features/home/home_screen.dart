import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../data/home_store.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/dday_badge.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fairy.dart';
import '../../widgets/inventory_slot.dart';
import '../../widgets/sheets.dart';
import '../../widgets/open_item.dart';
import '../search/search_results.dart';
import 'house_map.dart';
import '../spaces/space_actions.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// The one search box: names, initials, location codes, or a question for the fairy.
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = ref.watch(homeProvider).requireValue;
    final q = _query.text.trim();
    final today = DateTime.now();
    final urgent = byExpiry(d, today).where((e) => e.$2.isUrgent).toList();
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
            controller: _query,
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
            if (urgent.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.sm, AppSpace.sm),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(l.eatFirst(urgent.length), style: Theme.of(context).textTheme.titleSmall)),
                          TextButton(onPressed: () => context.push('/expiry'), child: Text(l.seeAll)),
                        ],
                      ),
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
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
