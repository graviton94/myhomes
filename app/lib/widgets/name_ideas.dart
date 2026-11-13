import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../data/home_store.dart';
import '../data/recipes.dart';
import '../design/theme.dart';
import '../design/tokens.g.dart';
import 'chip_line.dart';

/// Names to tap under a name field (core name_ideas.dart): the person's own
/// names in green, others plain. A tap puts the name in the field, where it
/// can still be changed. Nothing shows when there is nothing to offer.
class NameIdeasLine extends StatefulWidget {
  const NameIdeasLine({super.key, required this.controller, required this.ideas, this.mine = const {}, this.onPicked});

  final TextEditingController controller;
  final List<String> Function(String typed) ideas;
  final Set<String> mine;
  final ValueChanged<String>? onPicked;

  @override
  State<NameIdeasLine> createState() => _NameIdeasLineState();
}

class _NameIdeasLineState extends State<NameIdeasLine> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final c = HfColors.of(context);
    final ideas = widget.ideas(widget.controller.text);
    if (ideas.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.sm),
      child: ChipLine(
        children: [
          for (final n in ideas)
            ActionChip(
              key: ValueKey('idea-$n'),
              label: Text(n),
              backgroundColor: widget.mine.contains(n) ? c.secondarySoft : c.card,
              side: BorderSide(color: widget.mine.contains(n) ? Colors.transparent : c.border),
              labelStyle: AppType.label.copyWith(color: widget.mine.contains(n) ? c.secondaryInk : c.fg, fontSize: 14),
              onPressed: () {
                widget.controller.value = TextEditingValue(
                  text: n,
                  selection: TextSelection.collapsed(offset: n.length),
                );
                widget.onPicked?.call(n);
              },
            ),
        ],
      ),
    );
  }
}

/// Whether names are offered in Korean.
bool ideasInKorean(BuildContext context) => Localizations.localeOf(context).languageCode == 'ko';

/// Every thing name the app knows for searching while typing: its word list
/// and, in Korean, the recipe ingredients.
List<String> thingPool(WidgetRef ref, bool ko) => [
  ...thingWords(ko: ko),
  if (ko) ...{
    for (final r in ref.read(recipesProvider).value ?? const <Recipe>[])
      for (final i in r.ingredients) i.key,
  },
];

/// Ideas for a thing going into [storageId]: my names, what usually goes in
/// that kind of spot (minus what is there), then the word list.
List<String> Function(String) thingIdeas(BuildContext context, WidgetRef ref, String? storageId) {
  final ko = ideasInKorean(context);
  final d = ref.read(homeProvider).requireValue;
  final spot = storageId == null ? null : d.container(storageId);
  final key = spot == null ? null : (spot.icon ?? iconsFromName(spot.name).firstOrNull);
  final usual = key == null ? const <String>[] : (ko ? storageItemIdeas[key]?.$1 : storageItemIdeas[key]?.$2) ?? const <String>[];
  final mine = myThingNames(d);
  final pool = thingPool(ref, ko);
  final there = storageId == null ? const <String>[] : d.itemsIn(storageId).map((i) => i.name).toList();
  return (typed) => nameIdeas(typed: typed, mine: mine, usual: usual, pool: pool, skip: there);
}

/// Ideas for a storage spot in [spaceId], numbered when one is already there.
List<String> Function(String) storageIdeas(BuildContext context, WidgetRef ref, String spaceId) {
  final ko = ideasInKorean(context);
  final d = ref.read(homeProvider).requireValue;
  final room = d.space(spaceId);
  final key = room == null ? null : (room.icon ?? iconsFromName(room.name).firstOrNull);
  final usual = key == null ? const <String>[] : (ko ? roomStorageIdeas[key]?.$1 : roomStorageIdeas[key]?.$2) ?? const <String>[];
  final taken = d.containers.where((c) => c.spaceId == spaceId).map((c) => c.name).toList();
  return (typed) => placeIdeas(typed: typed, usual: usual, taken: taken);
}

/// Ideas for a new room, numbered when the home already has one.
List<String> Function(String) roomNameIdeas(BuildContext context, WidgetRef ref) {
  final ko = ideasInKorean(context);
  final d = ref.read(homeProvider).requireValue;
  final taken = d.spaces.map((s) => s.name).toList();
  return (typed) => placeIdeas(typed: typed, usual: ko ? roomIdeas.$1 : roomIdeas.$2, taken: taken);
}
