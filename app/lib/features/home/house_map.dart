import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../data/home_store.dart';
import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/app_icons.dart';
import '../spaces/space_actions.dart';

/// The top-level storage spot (furniture, box on the floor, spot) that holds
/// [containerId], so a find inside a drawer lights up the whole wardrobe.
String topStorageOf(HomeData d, String containerId) {
  var s = d.container(containerId);
  while (s?.parentId != null) {
    s = d.container(s!.parentId!);
  }
  return s?.id ?? containerId;
}

/// Our home at a glance: each room is a green block holding its furniture,
/// boxes and spots as honey blocks. Places outside the home sit in a strip
/// below. While searching, blocks holding a match turn persimmon with a count.
/// Room positions come from the floor plan later (step 5); until then rooms
/// fill two columns, shortest first.
class HouseMap extends ConsumerWidget {
  const HouseMap({super.key, this.hits = const {}, this.firstHit = const {}});

  /// Top-level storage id -> number of matching items.
  final Map<String, int> hits;

  /// Top-level storage id -> one matching item, flashed when opened.
  final Map<String, String> firstHit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final d = ref.watch(homeProvider).requireValue;
    final rooms = d.spaces.where((s) => !s.outside).toList();
    final outside = d.spaces.where((s) => s.outside).toList();
    final searching = hits.isNotEmpty;

    // Two columns; each room goes under the shorter one (height ~ how much it holds).
    final cols = [<Space>[], <Space>[]];
    final heights = [0, 0];
    for (final r in rooms) {
      final i = heights[0] <= heights[1] ? 0 : 1;
      cols[i].add(r);
      heights[i] += 2 + (d.containersIn(r.id).length + 1) ~/ 2;
    }

    Widget column(List<Space> list) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (final r in list) _Room(space: r, hits: hits, firstHit: firstHit, dimmed: searching)],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpace.sm),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: c.border, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [column(cols[0]), column(cols[1])]),
              if (!searching)
                Padding(
                  padding: const EdgeInsets.all(AppSpace.xs),
                  child: OutlinedButton.icon(
                    key: const ValueKey('map-add-room'),
                    onPressed: () => addSpaceFlow(context, ref),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l.addSpace),
                  ),
                ),
            ],
          ),
        ),
        if (outside.isNotEmpty) ...[
          const SizedBox(height: AppSpace.sm),
          Text(l.mapOutside, style: AppType.label.copyWith(color: c.primaryInk)),
          const SizedBox(height: AppSpace.xs),
          for (final o in outside) _Room(space: o, hits: hits, firstHit: firstHit, dimmed: searching),
        ],
      ],
    );
  }
}

class _Room extends ConsumerWidget {
  const _Room({required this.space, required this.hits, required this.firstHit, required this.dimmed});

  final Space space;
  final Map<String, int> hits;
  final Map<String, String> firstHit;
  final bool dimmed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final d = ref.watch(homeProvider).requireValue;
    final storages = d.containersIn(space.id);
    final roomHits = storages.fold(0, (n, s) => n + (hits[s.id] ?? 0));
    final (bg, ink) = space.outside ? (c.primarySoft, c.primaryInk) : (c.secondarySoft, c.secondaryInk);
    final quiet = dimmed && roomHits == 0;
    return Padding(
      padding: const EdgeInsets.all(AppSpace.xs),
      child: Opacity(
        opacity: quiet ? 0.45 : 1,
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            key: ValueKey('map-room-${space.id}'),
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: () => context.push('/space/${space.id}'),
            child: Container(
              padding: const EdgeInsets.all(AppSpace.sm),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: roomHits > 0 ? c.primary : ink.withValues(alpha: 0.35), width: roomHits > 0 ? 2.5 : 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      spaceGlyph(space, size: 18, color: ink),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          space.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.label.copyWith(color: ink),
                        ),
                      ),
                      Text('${d.itemCountInSpace(space.id)}', style: AppType.caption.copyWith(color: ink)),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xs),
                  if (storages.isEmpty)
                    Text(l.mapEmptyRoom, style: AppType.caption.copyWith(color: ink.withValues(alpha: 0.8)))
                  else
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [for (final s in storages) _Block(storage: s, hits: hits[s.id] ?? 0, firstHit: firstHit[s.id])],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One piece of furniture, box or spot inside a room block.
class _Block extends ConsumerWidget {
  const _Block({required this.storage, required this.hits, this.firstHit});

  final Storage storage;
  final int hits;
  final String? firstHit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = HfColors.of(context);
    final hit = hits > 0;
    final (bg, fg) = hit ? (c.primary, c.onPrimary) : (c.accentSoft, c.accentInk);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        key: ValueKey('map-block-${storage.id}'),
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.push(firstHit == null ? '/space/${storage.spaceId}' : '/space/${storage.spaceId}?item=$firstHit'),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 140),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: hit ? c.primaryInk : c.accent.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              storageGlyph(storage, size: 14, color: fg),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  storage.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.caption.copyWith(fontSize: 11.5, color: fg, fontWeight: hit ? FontWeight.w700 : null),
                ),
              ),
              if (hit) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(color: c.onPrimary, borderRadius: BorderRadius.circular(99)),
                  child: Text(
                    '$hits',
                    style: AppType.caption.copyWith(fontSize: 11, color: c.primaryInk, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
