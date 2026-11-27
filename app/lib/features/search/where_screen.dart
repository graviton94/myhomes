import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../data/home_store.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/fit_text.dart';
import '../home/house_map.dart';

/// 지도에서 보기: what a search found, lit up on the home map, the view moved
/// to the rooms that hold it (user request: show where things are on the map).
class WhereScreen extends ConsumerWidget {
  const WhereScreen({super.key, required this.itemIds});

  final List<String> itemIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final d = ref.watch(homeProvider).requireValue;
    final items = [for (final id in itemIds) ?d.items.where((i) => i.id == id).firstOrNull];
    final hits = <String, int>{};
    final first = <String, String>{};
    for (final i in items) {
      final top = topStorageOf(d, i.containerId);
      hits[top] = (hits[top] ?? 0) + 1;
      first.putIfAbsent(top, () => i.id);
    }
    final name = items.isEmpty ? '' : items.first.name;
    return Scaffold(
      appBar: AppBar(title: OneLine([l.whereTitle(name), l.whereShort])),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.sm),
          child: plannedRooms(d).isEmpty ? Center(child: Text(l.whereNoMap)) : HomeMapView(hits: hits, firstHit: first),
        ),
      ),
    );
  }
}
