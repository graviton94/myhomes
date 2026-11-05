import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../data/achievements.dart';
import '../../data/home_store.dart';
import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/chip_line.dart';
import '../../widgets/fit_text.dart';
import '../../widgets/inventory_slot.dart';
import '../../widgets/layers.dart';
import '../../widgets/sheets.dart';
import '../spaces/space_actions.dart';

/// The moving boxes: one card per numbered box (where it goes, how many
/// things), and how far the unpacking is.
class MovingScreen extends ConsumerWidget {
  const MovingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final d = ref.watch(homeProvider).requireValue;
    final space = movingSpace(d);
    if (space == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l.movingFinished)),
      );
    }
    final boxes = movingBoxes(d);
    final p = movingProgress(d);
    final things = boxes.fold(0, (n, b) => n + d.itemsIn(b.id).length);
    return Scaffold(
      appBar: AppBar(
        title: Text(space.name),
        actions: [
          PopupMenuButton<String>(
            key: const ValueKey('moving-menu'),
            onSelected: (_) => finishMovingFlow(context, ref, ask: false),
            itemBuilder: (context) => [PopupMenuItem(value: 'finish', child: Text(l.movingFinish))],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.xl),
        children: [
          OneLine([
            p.done == 0 ? l.movingSummary(boxes.length, things) : l.movingProgress(p.done, p.total),
          ], style: AppType.caption.copyWith(color: c.mutedFg)),
          if (p.done > 0) ...[
            const SizedBox(height: AppSpace.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: p.total == 0 ? 0 : p.done / p.total,
                minHeight: 8,
                color: c.secondary,
                backgroundColor: c.muted,
              ),
            ),
          ],
          const SizedBox(height: AppSpace.md),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpace.sm,
            crossAxisSpacing: AppSpace.sm,
            childAspectRatio: 1.35,
            children: [
              for (final b in boxes) _BoxCard(box: b, count: d.itemsIn(b.id).length),
              _AddBoxCard(
                onTap: () async {
                  final r = await ref
                      .read(homeProvider.notifier)
                      .apply<Storage>((d, ctx) => addMovingBox(d, ctx, l.boxName(nextBoxNumber(d))));
                  if (r != null && context.mounted) context.push('/moving/box/${r.id}');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BoxCard extends StatelessWidget {
  const _BoxCard({required this.box, required this.count});

  final Storage box;
  final int count;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final done = box.unpacked;
    final (bg, ink) = done ? (c.secondarySoft, c.secondaryInk) : (c.accentSoft, c.accentInk);
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: ink, width: 1.5),
      ),
      child: InkWell(
        key: ValueKey('moving-box-${box.id}'),
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => context.push('/moving/box/${box.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${box.number ?? ''}', style: AppType.display.copyWith(color: ink, fontSize: 28, height: 1)),
              Row(
                children: [
                  if (done || box.goesTo != null) ...[
                    Icon(done ? Icons.check_rounded : Icons.arrow_forward_rounded, size: 16, color: ink),
                    const SizedBox(width: 2),
                  ],
                  Expanded(
                    child: OneLine([done ? l.movingUnpacked : (box.goesTo ?? l.movingNoRoom)], style: AppType.label.copyWith(color: ink)),
                  ),
                ],
              ),
              OneLine([l.itemsCount(count)], style: AppType.caption.copyWith(color: c.mutedFg)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddBoxCard extends StatelessWidget {
  const _AddBoxCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    return Material(
      color: c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: c.border, width: 1.5),
      ),
      child: InkWell(
        key: const ValueKey('moving-add-box'),
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: c.mutedFg),
              const SizedBox(width: AppSpace.xs),
              Text(l.movingAddBox, style: AppType.label.copyWith(color: c.mutedFg)),
            ],
          ),
        ),
      ),
    );
  }
}

/// One box: its number to write on it, the room it goes to, what is inside.
/// Packing: from home or written new. Unpacking: pick things and give them a
/// place, or put the whole box down in a room.
class MovingBoxScreen extends ConsumerStatefulWidget {
  const MovingBoxScreen({super.key, required this.boxId});

  final String boxId;

  @override
  ConsumerState<MovingBoxScreen> createState() => _MovingBoxScreenState();
}

class _MovingBoxScreenState extends ConsumerState<MovingBoxScreen> {
  final _picked = <String>{};

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final d = ref.watch(homeProvider).requireValue;
    final box = d.container(widget.boxId);
    if (box == null || !isMovingBox(d, box)) {
      return Scaffold(appBar: AppBar(), body: const SizedBox.shrink());
    }
    final items = d.itemsIn(box.id);
    _picked.removeWhere((id) => !items.any((i) => i.id == id));
    final rooms = [
      for (final s in spacesInOrder(d))
        if (!s.outside) s.name,
    ];
    final home = ref.read(homeProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text(box.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.xl),
        children: [
          Container(
            key: const ValueKey('moving-number'),
            padding: const EdgeInsets.symmetric(vertical: AppSpace.md, horizontal: AppSpace.md),
            decoration: BoxDecoration(
              color: c.accentSoft,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: c.accentInk, width: 2),
            ),
            child: Column(
              children: [
                Text('${box.number ?? ''}', style: AppType.display.copyWith(color: c.accentInk, fontSize: 56, height: 1)),
                const SizedBox(height: AppSpace.xs),
                OneLine(
                  [box.goesTo == null ? l.movingWriteHint : l.movingGoesTo(box.goesTo!), l.movingWriteHint],
                  textAlign: TextAlign.center,
                  style: AppType.label.copyWith(color: c.accentInk),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),
          if (rooms.isNotEmpty) ...[
            Text(l.movingGoesToLabel, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpace.xs),
            ChipLine(
              children: [
                for (final r in rooms)
                  ChoiceChip(
                    key: ValueKey('goes-to-$r'),
                    label: Text(r),
                    selected: box.goesTo == r,
                    onSelected: (on) => home.apply((d, ctx) => setGoesTo(d, box.id, on ? r : null)),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.md),
          ],
          Text(l.movingInside(items.length), style: Theme.of(context).textTheme.titleSmall),
          for (final i in items)
            CheckboxListTile(
              key: ValueKey('moving-item-${i.id}'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _picked.contains(i.id),
              onChanged: (on) => setState(() => on == true ? _picked.add(i.id) : _picked.remove(i.id)),
              secondary: ItemThumb(category: i.category, photoPath: i.photoPath, iconKey: i.icon, size: 32),
              title: OneLine([i.qty > 1 ? '${i.name} ×${i.qty}' : i.name]),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.sm),
          child: _picked.isNotEmpty
              ? FilledButton(
                  key: const ValueKey('moving-unpack'),
                  onPressed: () => _unpack(box),
                  child: FitText(l.movingUnpackPicked(_picked.length)),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            key: const ValueKey('moving-pack-home'),
                            onPressed: () => Navigator.of(
                              context,
                              rootNavigator: true,
                            ).push(MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => _PackScreen(boxId: box.id))),
                            child: FitText(l.movingPackFromHome),
                          ),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Expanded(
                          child: OutlinedButton(
                            key: const ValueKey('moving-pack-new'),
                            onPressed: () => context.push('/item/new?storage=${box.id}'),
                            child: FitText(l.movingPackNew),
                          ),
                        ),
                      ],
                    ),
                    if (items.isNotEmpty)
                      TextButton(
                        key: const ValueKey('moving-place-whole'),
                        onPressed: () => _placeWhole(box),
                        child: Text(l.movingPlaceWhole),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _unpack(Storage box) async {
    final l = AppLocalizations.of(context);
    final to = await pickStorage(context, title: l.movingUnpackWhere, exclude: box.id);
    if (to == null || !mounted) return;
    final d = ref.read(homeProvider).requireValue;
    final picks = {for (final id in _picked) id: d.item(id)!.qty};
    await ref.read(homeProvider.notifier).apply((d, ctx) => unpack(d, ctx, box.id, picks, to));
    setState(_picked.clear);
    if (mounted) await _maybeDone();
  }

  Future<void> _placeWhole(Storage box) async {
    final at = await pickBoxPlace(context, box);
    if (at == null || !mounted) return;
    await ref.read(homeProvider.notifier).apply((d, ctx) => placeBox(d, box.id, spaceId: at.$1, parentId: at.$2));
    if (!mounted) return;
    final router = GoRouter.of(context);
    await _maybeDone();
    if (mounted && router.canPop()) router.pop();
  }

  /// After the last box: once, whether to clear the boxes and empty spots.
  Future<void> _maybeDone() async {
    final d = ref.read(homeProvider).requireValue;
    if (movingSpace(d) == null || boxesToUnpack(d).isNotEmpty) return;
    await finishMovingFlow(context, ref, ask: true);
  }
}

/// Ends the move. [ask]: after the last box ("상자를 다 풀었어요"); otherwise
/// from the menu, refused while boxes still hold things.
Future<void> finishMovingFlow(BuildContext context, WidgetRef ref, {required bool ask}) async {
  final l = AppLocalizations.of(context);
  final d = ref.read(homeProvider).requireValue;
  final left = boxesToUnpack(d).length;
  if (left > 0) {
    showMessage(context, l.movingFinishBlocked(left));
    return;
  }
  final clear = await askQuestion<bool>(
    context,
    title: ask ? l.movingDoneTitle : l.movingFinish,
    detail: l.movingDoneBody,
    answers: [Answer(true, l.movingDoneClear), Answer(false, l.movingDoneKeep)],
  );
  if (clear != true || !context.mounted) return;
  await ref.read(homeProvider.notifier).apply((d, ctx) => finishMoving(d, clearEmpty: true));
  await countAchievement(ref, Achievement.moving);
  if (!context.mounted) return;
  showUndo(context, ref, l.movingFinished);
  context.go('/');
}

/// "집에서 담기": things already in the home, found by name, ticked and moved
/// into the box together.
class _PackScreen extends ConsumerStatefulWidget {
  const _PackScreen({required this.boxId});

  final String boxId;

  @override
  ConsumerState<_PackScreen> createState() => _PackScreenState();
}

class _PackScreenState extends ConsumerState<_PackScreen> {
  final _query = TextEditingController();
  final _picked = <String>{};

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
    final box = d.container(widget.boxId)!;
    final moving = movingSpace(d)?.id;
    final q = _query.text.trim();
    final all = [
      for (final i in d.items)
        if (d.container(i.containerId)?.spaceId != moving) i,
    ];
    final ids = q.isEmpty ? null : {for (final f in searchItems(d, q)) f.item.id};
    final list = [
      for (final i in all)
        if (ids == null || ids.contains(i.id)) i,
    ];
    return Scaffold(
      appBar: AppBar(title: OneLine([l.movingPackTitle(box.name)], style: Theme.of(context).textTheme.titleLarge)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.sm),
            child: TextField(
              key: const ValueKey('pack-search'),
              controller: _query,
              decoration: InputDecoration(hintText: l.movingPackSearch, prefixIcon: const Icon(Icons.search_rounded)),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Text(l.movingPackEmpty, style: TextStyle(color: c.mutedFg)),
                  )
                : ListView(
                    children: [
                      for (final i in list)
                        CheckboxListTile(
                          key: ValueKey('pack-${i.id}'),
                          controlAffinity: ListTileControlAffinity.leading,
                          value: _picked.contains(i.id),
                          onChanged: (on) => setState(() => on == true ? _picked.add(i.id) : _picked.remove(i.id)),
                          title: OneLine([i.qty > 1 ? '${i.name} ×${i.qty}' : i.name]),
                          subtitle: OneLine([
                            pathText(d.pathOf(i.containerId)),
                            pathText(d.pathOf(i.containerId).skip(1).toList()),
                          ], style: AppType.caption.copyWith(color: c.mutedFg)),
                        ),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.sm + MediaQuery.viewInsetsOf(context).bottom),
          child: FilledButton(
            key: const ValueKey('pack-do'),
            onPressed: _picked.isEmpty
                ? null
                : () async {
                    final picks = {for (final id in _picked) id: d.item(id)!.qty};
                    await ref.read(homeProvider.notifier).apply((d, ctx) => moveItems(d, ctx, picks, box.id));
                    if (context.mounted) Navigator.pop(context);
                  },
            child: FitText(l.movingPackDo(_picked.length, box.name)),
          ),
        ),
      ),
    );
  }
}
