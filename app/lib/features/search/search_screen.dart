import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../data/home_store.dart';
import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fairy.dart';
import '../../widgets/app_icons.dart';
import '../../widgets/inventory_slot.dart';
import '../../widgets/sheets.dart';

/// Search by name (Korean initials work too), note or location code.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final d = ref.watch(homeProvider).requireValue;
    final q = _query.text.trim();
    final found = searchItems(d, q);

    Widget body;
    if (d.items.isEmpty) {
      body = EmptyState(pose: FairyPose.sleep, title: l.searchEmptyTitle, body: l.searchEmptyBody);
    } else if (q.isEmpty) {
      final names = recentNames(d);
      body = Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.recentItems, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpace.sm),
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.xs,
              children: [for (final n in names) ActionChip(label: Text(n), onPressed: () => setState(() => _query.text = n))],
            ),
            const SizedBox(height: AppSpace.lg),
            Text(l.searchTip, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.mutedFg)),
          ],
        ),
      );
    } else if (found.isEmpty) {
      body = EmptyState(pose: FairyPose.worry, title: l.noResultsTitle(q), body: l.noResultsBody);
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, 0),
            child: Text(l.resultsCount(found.length), style: Theme.of(context).textTheme.bodySmall),
          ),
          for (final f in found)
            ListTile(
              leading: ItemThumb(category: f.item.category, photoPath: f.item.photoPath, icon: iconFor(f.item.icon)),
              title: Text(f.item.qty > 1 ? '${f.item.name} ×${f.item.qty}' : f.item.name),
              subtitle: Text(pathText(f.path), maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Text(d.container(f.item.containerId)?.code ?? '', style: AppType.code.copyWith(color: c.mutedFg)),
              onTap: () => context.push('/storage/${f.item.containerId}'),
            ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.navSearch)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpace.xl),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.xs, AppSpace.lg, 0),
            child: TextField(
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
          ),
          body,
        ],
      ),
    );
  }
}
