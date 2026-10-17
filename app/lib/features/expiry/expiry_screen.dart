import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../data/home_store.dart';
import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/dday_badge.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fairy.dart';
import '../../widgets/app_icons.dart';
import '../../widgets/inventory_slot.dart';
import '../../widgets/sheets.dart';
import '../../widgets/open_item.dart';

/// Everything with a use-by date: past, within 3 days, later.
class ExpiryScreen extends ConsumerWidget {
  const ExpiryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final d = ref.watch(homeProvider).requireValue;
    final all = byExpiry(d, DateTime.now());
    final returns = returnsDue(d, DateTime.now());
    final groups = [
      (l.groupOverdue, all.where((e) => e.$2.daysLeft < 0).toList()),
      (l.groupSoon, all.where((e) => e.$2.daysLeft >= 0 && e.$2.isUrgent).toList()),
      (l.groupLater, all.where((e) => !e.$2.isUrgent).toList()),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l.navExpiry)),
      body: all.isEmpty && returns.isEmpty
          ? Center(
              child: SingleChildScrollView(
                child: EmptyState(pose: FairyPose.cheer, title: l.expiryEmptyTitle, body: l.expiryEmptyBody),
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: AppSpace.xl),
              children: [
                if (returns.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.xs),
                    child: Text('${l.groupReturns} · ${returns.length}', style: Theme.of(context).textTheme.titleSmall),
                  ),
                  for (final (storage, status) in returns)
                    ListTile(
                      leading: Icon(storageIcon(storage), color: HfColors.of(context).accentInk),
                      title: Text(storage.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        '${pathText(d.pathOf(storage.id))} · ${l.itemsCount(d.itemsIn(storage.id).length)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: ReturnBadge(status),
                      onTap: () => context.push('/space/${storage.spaceId}'),
                    ),
                ],
                for (final (title, list) in groups)
                  if (list.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.xs),
                      child: Text('$title · ${list.length}', style: Theme.of(context).textTheme.titleSmall),
                    ),
                    for (final (item, status) in list)
                      ListTile(
                        leading: ItemThumb(category: item.category, photoPath: item.photoPath, icon: iconFor(item.icon)),
                        title: Text(item.qty > 1 ? '${item.name} ×${item.qty}' : item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(pathText(d.pathOf(item.containerId)), maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: DdayBadge(status),
                        onTap: () => openItem(context, d, item),
                      ),
                  ],
              ],
            ),
    );
  }
}
