import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../data/home_store.dart';
import '../../data/smart_suggest.dart';
import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fairy.dart';
import '../../widgets/inventory_slot.dart';
import '../../widgets/sheets.dart';
import '../../widgets/open_item.dart';

/// Search by name (Korean initials work too), note or location code.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _query = TextEditingController();
  Timer? _debounce;

  /// Server match for the query in [_smartFor] ("이불" → "극세사 담요").
  String? _smartFor;
  Pick? _smart;

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onChanged() {
    setState(() {});
    _debounce?.cancel();
    final q = _query.text.trim();
    if (q.length < 2) return;
    _debounce = Timer(const Duration(milliseconds: 500), () => _askSmart(q));
  }

  Future<void> _askSmart(String q) async {
    final d = ref.read(homeProvider).requireValue;
    final names = {for (final i in d.items) i.name}.take(400).toList();
    final r = await ref.read(smartSuggestProvider).find(q, names);
    if (r == null || !mounted || _query.text.trim() != q) return;
    setState(() {
      _smartFor = q;
      _smart = r;
    });
  }

  /// "The fairy found it" card, or "Is it one of these?" chips when less sure.
  Widget? _smartCard(BuildContext context, HomeData d, String q, List<Found> found) {
    final pick = _smartFor == q ? _smart : null;
    if (pick == null) return null;
    final level = suggestLevel(pick.confidence);
    if (level == SuggestLevel.ignore) return null;
    if (found.isNotEmpty && found.first.item.name == pick.choice) return null;
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final t = Theme.of(context).textTheme;
    Item? itemNamed(String name) => d.items.where((i) => i.name == name).firstOrNull;
    final candidates = level == SuggestLevel.auto
        ? [pick.choice]
        : [
            for (final (name, p) in pick.top)
              if (suggestLevel(p) != SuggestLevel.ignore || name == pick.choice) name,
          ];
    return Card(
      margin: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, 0),
      color: c.primarySoft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.sm, AppSpace.md, AppSpace.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, size: 18, color: c.primaryInk),
                const SizedBox(width: 6),
                Text(level == SuggestLevel.auto ? l.smartFound : l.smartMaybe, style: t.titleSmall?.copyWith(color: c.primaryInk)),
              ],
            ),
            for (final name in candidates.take(3))
              if (itemNamed(name) case final item?)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ItemThumb(category: item.category, photoPath: item.photoPath, iconKey: item.icon),
                  title: Text(item.qty > 1 ? '${item.name} ×${item.qty}' : item.name),
                  subtitle: Text(pathText(d.pathOf(item.containerId)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () => openItem(context, d, item),
                ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final d = ref.watch(homeProvider).requireValue;
    final q = _query.text.trim();
    final found = searchItems(d, q);
    final smart = q.isEmpty ? null : _smartCard(context, d, q, found);

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
              children: [
                for (final n in names)
                  ActionChip(
                    label: Text(n),
                    onPressed: () {
                      _query.text = n;
                      _onChanged();
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
            Text(l.searchTip, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.mutedFg)),
          ],
        ),
      );
    } else if (found.isEmpty) {
      body = smart ?? EmptyState(pose: FairyPose.worry, title: l.noResultsTitle(q), body: l.noResultsBody);
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?smart,
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, 0),
            child: Text(l.resultsCount(found.length), style: Theme.of(context).textTheme.bodySmall),
          ),
          for (final f in found)
            ListTile(
              leading: ItemThumb(category: f.item.category, photoPath: f.item.photoPath, iconKey: f.item.icon),
              title: Text(f.item.qty > 1 ? '${f.item.name} ×${f.item.qty}' : f.item.name),
              subtitle: Text(pathText(f.path), maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Text(d.container(f.item.containerId)?.code ?? '', style: AppType.code.copyWith(color: c.mutedFg)),
              onTap: () => openItem(context, d, f.item),
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
              onChanged: (_) => _onChanged(),
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
