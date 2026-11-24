import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../data/home_store.dart';
import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/chip_line.dart';
import '../../widgets/fairy.dart';
import '../../widgets/fit_text.dart';
import '../../widgets/name_ideas.dart';
import '../../widgets/sheets.dart';

/// Filling a new home by picking (user request: 20 things in the first five
/// minutes, nothing typed unless wanted). Spots per room, then things per
/// spot, then how many went in. Each step can be skipped; "+ 직접" adds a
/// name that is not on the list (core first_fill.dart).
class FillScreen extends ConsumerStatefulWidget {
  const FillScreen({super.key, this.thingsOnly = false});

  /// Straight to picking things (the home already has its spots).
  final bool thingsOnly;

  @override
  ConsumerState<FillScreen> createState() => _FillScreenState();
}

class _FillScreenState extends ConsumerState<FillScreen> {
  late int _step = widget.thingsOnly ? 1 : 0;

  // Step 1: picked spot names per room, and names added by hand.
  final _spots = <String, List<String>>{};
  final _ownSpots = <String, List<String>>{};
  // Step 2: how many of each thing per spot (0 = not picked).
  final _things = <String, Map<String, int>>{};
  final _ownThings = <String, List<String>>{};
  int _added = 0;
  bool _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    // The two most usual spots of each room start picked.
    for (final (room, ideas) in spotIdeasByRoom(ref.read(homeProvider).requireValue, ko: ideasInKorean(context))) {
      _spots[room.id] = ideas.take(2).toList();
    }
  }

  Future<void> _nextFromSpots() async {
    final picked = {for (final e in _spots.entries) if (e.value.isNotEmpty) e.key: e.value};
    if (picked.isNotEmpty) await ref.read(homeProvider.notifier).apply((d, ctx) => addSpots(d, ctx, picked));
    if (mounted) setState(() => _step = 1);
  }

  Future<void> _nextFromThings() async {
    final picked = {
      for (final e in _things.entries)
        e.key: [for (final t in e.value.entries) if (t.value > 0) ParsedItem(t.key, t.value)],
    };
    if (picked.values.any((v) => v.isNotEmpty)) {
      final n = await ref.read(homeProvider.notifier).apply<int>((d, ctx) => addThings(d, ctx, picked));
      _added += n ?? 0;
    }
    if (mounted) {
      setState(() {
        _things.clear();
        _ownThings.clear();
        _step = 2;
      });
    }
  }

  Future<void> _own(String title, void Function(String name) add) async {
    final l = AppLocalizations.of(context);
    final name = await askText(context, title: title, label: l.fillCustomLabel);
    if (name != null && name.trim().isNotEmpty && mounted) setState(() => add(cleanText(name)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = ref.watch(homeProvider).requireValue;
    final ko = ideasInKorean(context);
    final title = switch (_step) {
      0 => l.fillSpotsTitle,
      1 => l.fillThingsTitle,
      _ => l.fillDoneShort,
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpace.lg),
              child: Text(l.fillStep(_step + 1), style: Theme.of(context).textTheme.labelLarge),
            ),
          ),
        ],
      ),
      body: switch (_step) {
        0 => _spotsStep(context, d, ko),
        1 => _thingsStep(context, d, ko),
        _ => _doneStep(context, d),
      },
    );
  }

  Widget _bottom(String label, VoidCallback onPressed, {Key? key}) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.sm),
      child: SizedBox(width: double.infinity, child: FilledButton(key: key, onPressed: onPressed, child: Text(label))),
    ),
  );

  Widget _group(BuildContext context, String title, List<Widget> chips) {
    final c = HfColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.md),
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: c.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpace.sm),
          ChipLine(children: chips),
        ],
      ),
    );
  }

  Widget _ownChip(BuildContext context, Key key, VoidCallback onPressed) =>
      ActionChip(key: key, avatar: const Icon(Icons.add_rounded, size: 18), label: Text(AppLocalizations.of(context).fillCustom), onPressed: onPressed);

  Widget _spotsStep(BuildContext context, HomeData d, bool ko) {
    final l = AppLocalizations.of(context);
    final rooms = spotIdeasByRoom(d, ko: ko);
    final count = _spots.values.fold(0, (a, v) => a + v.length);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpace.lg),
            children: [
              FitText(l.fillSpotsBody, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppSpace.md),
              for (final (room, ideas) in rooms)
                _group(context, room.name, [
                  for (final name in {...ideas, ...?_ownSpots[room.id]})
                    FilterChip(
                      label: Text(name),
                      selected: _spots[room.id]?.contains(name) ?? false,
                      onSelected: (on) => setState(() {
                        final list = _spots.putIfAbsent(room.id, () => []);
                        on ? list.add(name) : list.remove(name);
                      }),
                    ),
                  _ownChip(context, ValueKey('fill-own-spot-${room.id}'), () => _own(l.fillCustomSpot(room.name), (name) {
                    _ownSpots.putIfAbsent(room.id, () => []).add(name);
                    _spots.putIfAbsent(room.id, () => []).add(name);
                  })),
                ]),
            ],
          ),
        ),
        _bottom(count == 0 ? l.fillSkip : l.fillMakeSpots(count), _nextFromSpots, key: const ValueKey('fill-next')),
      ],
    );
  }

  Widget _thingsStep(BuildContext context, HomeData d, bool ko) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final spots = thingIdeasBySpot(d, ko: ko);
    final count = _things.values.fold(0, (a, m) => a + m.values.where((q) => q > 0).length);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpace.lg),
            children: [
              FitText(l.fillThingsBody, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppSpace.md),
              for (final (spot, ideas) in spots)
                _group(context, pathText(d.pathOf(spot.id)), [
                  for (final name in {...ideas, ...?_ownThings[spot.id]})
                    () {
                      final q = _things[spot.id]?[name] ?? 0;
                      return FilterChip(
                        label: Text(q > 1 ? '$name ×$q' : name),
                        selected: q > 0,
                        selectedColor: c.secondarySoft,
                        // 1, 2, then off again.
                        onSelected: (_) => setState(() => _things.putIfAbsent(spot.id, () => {})[name] = (q + 1) % 3),
                      );
                    }(),
                  _ownChip(context, ValueKey('fill-own-thing-${spot.id}'), () => _own(l.fillCustomThing(spot.name), (name) {
                    _ownThings.putIfAbsent(spot.id, () => []).add(name);
                    _things.putIfAbsent(spot.id, () => {})[name] = 1;
                  })),
                ]),
            ],
          ),
        ),
        _bottom(count == 0 ? l.fillSkip : l.fillPutThings(count), _nextFromThings, key: const ValueKey('fill-next')),
      ],
    );
  }

  Widget _doneStep(BuildContext context, HomeData d) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final total = d.items.length;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Fairy(FairyPose.cheer, height: 140),
            const SizedBox(height: AppSpace.md),
            OneLine([l.fillDoneTitle(_added)], style: t.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: AppSpace.sm),
            FitText(l.fillDoneBody, style: t.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppSpace.xl),
            FilledButton(
              key: const ValueKey('fill-ask'),
              onPressed: () {
                final router = GoRouter.of(context);
                router.go('/');
                router.push('/ask');
              },
              child: Text(l.fillDoneAsk),
            ),
            const SizedBox(height: AppSpace.sm),
            TextButton(key: const ValueKey('fill-map'), onPressed: () => context.go('/'), child: Text(l.fillDoneMap)),
            if (total < 20) ...[
              const SizedBox(height: AppSpace.sm),
              OutlinedButton(
                key: const ValueKey('fill-more'),
                onPressed: () => setState(() => _step = 1),
                child: OneLine([l.fillDoneMore(20 - total), l.fillDoneMoreShort]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
