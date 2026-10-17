import 'package:flutter/material.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../design/theme.dart';
import '../design/tokens.g.dart';
import '../l10n/app_localizations.dart';
import 'app_icons.dart';
import 'sheets.dart';

/// The icon to save: the one picked by hand, else the best match for [name].
String? effectiveIcon(String? picked, String name) => picked ?? iconsFromName(name).firstOrNull;

/// One row of suggested icons for [name] plus "More" for the full set.
/// [picked] is the hand-picked key (null = follow the name).
class IconChooser extends StatelessWidget {
  const IconChooser({super.key, required this.name, required this.kind, required this.picked, required this.onPicked, this.category});

  final String name;
  final IconKind kind;
  final ItemCategory? category;
  final String? picked;
  final ValueChanged<String?> onPicked;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final current = effectiveIcon(picked, name);
    final options = suggestIcons(name, kind, category: category);
    if (current != null && !options.contains(current)) options.insert(0, current);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final k in options.take(7)) ...[
            _IconDot(iconKey: k, selected: k == current, onTap: () => onPicked(k == current && picked != null ? null : k)),
            const SizedBox(width: AppSpace.sm),
          ],
          ActionChip(
            avatar: const Icon(Icons.apps_rounded, size: 18),
            label: Text(l.moreIcons),
            onPressed: () async {
              final k = await pickIcon(context, selected: current);
              if (k != null) onPicked(k);
            },
          ),
        ],
      ),
    );
  }
}

class _IconDot extends StatelessWidget {
  const _IconDot({required this.iconKey, required this.selected, required this.onTap, this.size = 44});

  final String iconKey;
  final bool selected;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = HfColors.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? c.primarySoft : c.muted,
        shape: CircleBorder(side: BorderSide(color: selected ? c.primary : Colors.transparent, width: 2)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: glyph(iconKey, Icons.category_rounded, size: size * 0.5, color: selected ? c.primaryInk : c.mutedFg),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full icon grid, grouped. Returns the chosen key or null.
Future<String?> pickIcon(BuildContext context, {String? selected}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
      final l = AppLocalizations.of(context);
      final t = Theme.of(context).textTheme;
      final names = {
        'rooms': l.iconGroupRooms,
        'furniture': l.iconGroupFurniture,
        'food': l.iconGroupFood,
        'household': l.iconGroupHousehold,
        'tools': l.iconGroupTools,
        'health': l.iconGroupHealth,
        'clothes': l.iconGroupClothes,
        'family': l.iconGroupFamily,
        'pets': l.iconGroupPets,
        'devices': l.iconGroupDevices,
        'papers': l.iconGroupPapers,
        'hobby': l.iconGroupHobby,
      };
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.94,
        builder: (context, scroll) => Column(
          children: [
            SheetHeader(l.chooseIcon),
            Expanded(
              child: ListView(
                controller: scroll,
                // Clear the phone's navigation bar so the last row is not cut off.
                padding: EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.xl + MediaQuery.viewPaddingOf(context).bottom),
                children: [
                  for (final g in iconGroups.entries) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpace.md, bottom: AppSpace.sm),
                      child: Text(names[g.key] ?? g.key, style: t.labelLarge),
                    ),
                    Wrap(
                      spacing: AppSpace.sm,
                      runSpacing: AppSpace.sm,
                      children: [
                        for (final k in g.value)
                          _IconDot(iconKey: k, selected: k == selected, onTap: () => Navigator.pop(context, k), size: 48),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
