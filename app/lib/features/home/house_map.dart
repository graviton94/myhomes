import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../data/home_store.dart';
import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/app_icons.dart';
import '../../widgets/doodle.dart';
import '../../widgets/fit_text.dart';
import '../house/room_edit_screen.dart' show FurniturePainter;
import '../spaces/space_actions.dart';
import '../house/plan_editor.dart';

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
    final planned = plannedRooms(d);
    final rooms = d.spaces.where((s) => !s.outside && s.plan == null).toList();
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
              if (planned.isNotEmpty) ...[
                // The same map as the editor, only looking (user request,
                // docs/mockups/map-home.html): drag to look around, tap to
                // peek, hold to start editing with that piece picked.
                SizedBox(
                  height: (MediaQuery.sizeOf(context).height * 0.6).clamp(320.0, 640.0),
                  // Drags on the map move the map, not the page under it.
                  child: GestureDetector(
                    onVerticalDragUpdate: (_) {},
                    onHorizontalDragUpdate: (_) {},
                    child: HomeMapView(hits: hits, firstHit: firstHit),
                  ),
                ),
              ] else if (!searching && rooms.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpace.xs),
                  child: Material(
                    color: c.accentSoft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: ListTile(
                      key: const ValueKey('map-setup'),
                      leading: Icon(Icons.house_rounded, color: c.accentInk),
                      title: Text(l.mapSetup, style: AppType.label.copyWith(color: c.accentInk)),
                      subtitle: FitText(l.mapSetupBody, style: AppType.caption),
                      trailing: Icon(Icons.chevron_right_rounded, color: c.accentInk),
                      onTap: () => context.push('/house/setup'),
                    ),
                  ),
                ),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [column(cols[0]), column(cols[1])]),
              if (!searching)
                Padding(
                  padding: const EdgeInsets.all(AppSpace.xs),
                  child: OutlinedButton.icon(
                    key: const ValueKey('map-add-room'),
                    onPressed: () => addPlaceFlow(context, ref),
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

/// Rooms where they sit in the home, each with its furniture, boxes and spots.
/// The home map, only looking: the same canvas as the editor. Shown on Home
/// and, with what a search found lit up, on the 지도에서 보기 screen.
class HomeMapView extends ConsumerStatefulWidget {
  const HomeMapView({super.key, required this.hits, required this.firstHit});

  final Map<String, int> hits;
  final Map<String, String> firstHit;

  @override
  ConsumerState<HomeMapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<HomeMapView> {
  final _editor = GlobalKey<PlanEditorState>();

  @override
  void initState() {
    super.initState();
    if (widget.hits.isNotEmpty) _showHits();
  }

  @override
  void didUpdateWidget(HomeMapView old) {
    super.didUpdateWidget(old);
    if (!mapEquals(old.hits, widget.hits)) _showHits();
  }

  void _showHits() {
    // A search: the rooms holding what was found come into view (or the whole home again).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ed = _editor.currentState;
      if (!mounted || ed == null) return;
      if (widget.hits.isEmpty) return ed.fit();
      final d = ref.read(homeProvider).requireValue;
      final rooms = {
        for (final id in widget.hits.keys)
          if (d.container(id) case final s?) ?d.space(s.spaceId)?.plan,
      };
      if (rooms.isNotEmpty) ed.zoomTo(rooms.toList());
    });
  }

  /// What a tap opened below the map: a piece, or a room.
  String? _peekPiece, _peekRoom;

  void _edit({String? piece, String? room}) {
    setState(() => _peekPiece = _peekRoom = null);
    final q = piece != null ? '?pick=$piece&fur=1' : (room != null ? '?pick=$room' : '');
    context.push('/house/edit$q');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final d = ref.watch(homeProvider).requireValue;
    final rooms = {for (final s in plannedRooms(d)) s.id: s.plan!};
    final pieces = <String, PlanRect>{
      for (final e in rooms.entries)
        for (final s in floorStorages(d, e.key))
          if (s.plan case final p?) s.id: PlanRect(e.value.x + p.x, e.value.y + p.y, p.w, p.h),
    };
    final searching = widget.hits.isNotEmpty;
    int roomHits(String id) => d.containersIn(id).fold(0, (n, s) => n + (widget.hits[s.id] ?? 0));
    // Hits inside a drawer light up the furniture that holds it.
    final hits = <String, int>{};
    for (final e in widget.hits.entries) {
      final top = topStorageOf(d, e.key);
      hits[top] = (hits[top] ?? 0) + e.value;
    }
    final piece = _peekPiece == null ? null : d.container(_peekPiece!);
    final room = _peekRoom == null ? null : d.space(_peekRoom!);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Stack(
        children: [
          PlanEditor(
            key: _editor,
            keyPrefix: 'map-block',
            readOnly: true,
            plans: pieces,
            selected: null,
            extent: rooms.values.toList(),
            onSelect: (id) => setState(() {
              _peekPiece = id;
              _peekRoom = null;
            }),
            onChange: (_, _) {},
            onTapFloor: (x, y) {
              final hit = rooms.entries.where((e) => x >= e.value.x && x < e.value.right && y >= e.value.y && y < e.value.bottom).firstOrNull;
              setState(() {
                _peekRoom = hit?.key;
                _peekPiece = null;
              });
            },
            onHold: (id) => _edit(piece: id),
            under: [
              for (final e in rooms.entries)
                if (d.space(e.key) case final s?)
                  Positioned(
                    left: e.value.x * kPlanCell,
                    top: e.value.y * kPlanCell,
                    width: e.value.w * kPlanCell,
                    height: e.value.h * kPlanCell,
                    child: IgnorePointer(
                      child: Opacity(
                        key: ValueKey('map-room-${s.id}'),
                        opacity: searching && roomHits(s.id) == 0 ? 0.45 : 1,
                        child: CustomPaint(
                          foregroundPainter: _WallPainter(
                            roomHits(s.id) > 0 ? c.primary : (s.id == _peekRoom ? c.secondary : c.secondaryInk),
                            roomHits(s.id) > 0 || s.id == _peekRoom ? 4 : 2,
                          ),
                          painter: _PlanRoomPainter(
                            fill: s.icon == 'balcony' ? c.accentSoft : c.secondarySoft,
                            hit: roomHits(s.id) > 0 || s.id == _peekRoom,
                            hitColor: s.id == _peekRoom ? c.secondaryInk : c.primary,
                            seed: s.id.hashCode,
                          ),
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: DecoratedBox(
                                decoration: BoxDecoration(color: c.secondaryInk, borderRadius: BorderRadius.circular(6)),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  child: Text(s.name, style: AppType.caption.copyWith(fontSize: 10, color: c.card)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
            ],
            block: (id, r, on) {
              final s = d.container(id);
              if (s == null) return const SizedBox.shrink();
              final n = hits[id] ?? 0;
              return Opacity(
                opacity: searching && n == 0 ? 0.45 : 1,
                child: _Placed(storage: s, hits: n, firstHit: widget.firstHit[id], peeked: id == _peekPiece),
              );
            },
          ),
          Positioned(
            left: AppSpace.sm,
            top: AppSpace.sm,
            child: FilledButton.icon(
              key: const ValueKey('map-edit-shape'),
              style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
              onPressed: () => _edit(),
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: Text(l.mapEdit),
            ),
          ),
          Positioned(
            right: AppSpace.sm,
            top: AppSpace.sm,
            child: IconButton.filledTonal(
              key: const ValueKey('map-fit'),
              tooltip: l.planFit,
              onPressed: () => _editor.currentState?.fit(),
              icon: const Icon(Icons.fit_screen_rounded),
            ),
          ),
          if (piece != null || room != null)
            Positioned(
              left: AppSpace.sm,
              right: AppSpace.sm,
              bottom: AppSpace.sm,
              child: _Peek(
                key: const ValueKey('map-peek'),
                title: piece?.name ?? room!.name,
                where: piece == null ? null : d.space(piece.spaceId)?.name,
                detail: piece != null ? l.itemsCount(d.itemsIn(piece.id).length) : l.itemsCount(d.itemCountInSpace(room!.id)),
                onClose: () => setState(() => _peekPiece = _peekRoom = null),
                onEdit: () => _edit(piece: piece?.id, room: room?.id),
                onOpen: () {
                  setState(() => _peekPiece = _peekRoom = null);
                  if (piece != null) {
                    final first = widget.firstHit[piece.id];
                    context.push(first == null ? '/storage/${piece.id}' : '/space/${piece.spaceId}?item=$first');
                  } else {
                    context.push(room!.moving ? '/moving' : '/space/${room.id}');
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// The card a tap on the home map opens: what it is, how much it holds, and
/// 열기 (nothing opens by accident while looking around).
class _Peek extends StatelessWidget {
  const _Peek({super.key, required this.title, this.where, required this.detail, required this.onClose, required this.onOpen, required this.onEdit});

  final String title;
  final String? where;
  final String detail;
  final VoidCallback onClose, onOpen, onEdit;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    return Material(
      color: c.card,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: c.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.sm, AppSpace.xs, AppSpace.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  OneLine([where == null ? title : '$title · $where', title], style: AppType.label),
                  OneLine([detail], style: AppType.caption.copyWith(color: c.mutedFg)),
                ],
              ),
            ),
            IconButton(key: const ValueKey('map-peek-edit'), tooltip: l.mapEdit, onPressed: onEdit, icon: const Icon(Icons.edit_rounded)),
            FilledButton(key: const ValueKey('map-peek-open'), onPressed: onOpen, child: Text(l.planInfoOpen)),
            IconButton(key: const ValueKey('map-peek-close'), tooltip: l.planUnpick, onPressed: onClose, icon: const Icon(Icons.close_rounded)),
          ],
        ),
      ),
    );
  }
}

/// Furniture placed in a room, drawn from above where it stands.
class _Placed extends StatelessWidget {
  const _Placed({required this.storage, required this.hits, this.firstHit, this.peeked = false});

  final Storage storage;
  final int hits;
  final String? firstHit;
  final bool peeked;

  @override
  Widget build(BuildContext context) {
    final c = HfColors.of(context);
    final hit = hits > 0;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(border: peeked ? Border.all(color: c.primary, width: 3) : null),
      child: CustomPaint(
        painter: FurniturePainter(fill: hit ? c.primary : c.accentSoft, seed: storage.id.hashCode, bold: hit, width: 1.2),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  mapGlyph(storage, size: 11, color: hit ? c.onPrimary : c.accentInk),
                  const SizedBox(width: 2),
                  Text(
                    hit ? '${storage.name} $hits' : storage.name,
                    maxLines: 1,
                    style: AppType.caption.copyWith(fontSize: 9.5, color: hit ? c.onPrimary : c.accentInk, fontWeight: hit ? FontWeight.w800 : null),
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

/// A room's walls on the home map: plain and clear (user report: faint walls).
class _WallPainter extends CustomPainter {
  _WallPainter(this.color, this.width);

  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawRect(
    (Offset.zero & size).deflate(width / 2),
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width,
  );

  @override
  bool shouldRepaint(_WallPainter old) => old.color != color || old.width != width;
}

class _PlanRoomPainter extends CustomPainter {
  _PlanRoomPainter({required this.fill, required this.hit, required this.hitColor, required this.seed});

  final Color fill;
  final bool hit;
  final Color hitColor;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRect((Offset.zero & size).deflate(1.5));
    canvas.drawPath(path, Paint()..color = fill);
    Doodle.crayon(canvas, path, Doodle.line(hit ? hitColor : Doodle.ink, hit ? 3 : 1.6), wobble: 0.8, step: 3, seed: seed);
  }

  @override
  bool shouldRepaint(_PlanRoomPainter old) => old.fill != fill || old.hit != hit;
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
            onTap: () => context.push(space.moving ? '/moving' : '/space/${space.id}'),
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
                        child: FitLabel(space.name, style: AppType.label.copyWith(color: ink)),
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
                child: FitLabel(
                  storage.name,
                  twoLines: false,
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
