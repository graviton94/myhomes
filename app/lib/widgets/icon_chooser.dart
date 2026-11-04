import 'package:flutter/material.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../design/theme.dart';
import '../design/tokens.g.dart';
import '../l10n/app_localizations.dart';
import '../data/smart_suggest.dart';
import 'app_icons.dart';

/// The icon to save: the one picked by hand, else a confident suggestion from
/// the server ([smart]), else the best rule match for [name].
String? effectiveIcon(String? picked, String name, {Pick? smart}) {
  if (picked != null) return picked;
  if (smart != null && appIcons.containsKey(smart.choice) && suggestLevel(smart.confidence) == SuggestLevel.auto) {
    return smart.choice;
  }
  return iconsFromName(name).firstOrNull;
}

/// One row of suggested icons for [name] plus "More" for the full set.
/// [picked] is the hand-picked key (null = follow the name).
class IconChooser extends StatelessWidget {
  const IconChooser({
    super.key,
    required this.name,
    required this.kind,
    required this.picked,
    required this.onPicked,
    this.category,
    this.smart,
  });

  final String name;
  final IconKind kind;
  final ItemCategory? category;
  final String? picked;
  final ValueChanged<String?> onPicked;

  /// Server suggestion for this name; its likely icons come first.
  final Pick? smart;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final current = effectiveIcon(picked, name, smart: smart);
    final fromServer = [
      if (smart != null)
        for (final (k, p) in smart!.top)
          if (appIcons.containsKey(k) && suggestLevel(p) != SuggestLevel.ignore) k,
    ];
    final options = [...fromServer, ...suggestIcons(name, kind, category: category).where((k) => !fromServer.contains(k))];
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
  const _IconDot({super.key, required this.iconKey, required this.selected, required this.onTap, this.size = 44});

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

/// Full icon list with a search box, on its own screen so the keyboard has
/// room. Returns the chosen key or null.
Future<String?> pickIcon(BuildContext context, {String? selected}) => Navigator.of(context, rootNavigator: true)
    .push<String>(MaterialPageRoute(fullscreenDialog: true, builder: (_) => _IconPicker(selected: selected)));

class _IconPicker extends StatefulWidget {
  const _IconPicker({this.selected});

  final String? selected;

  @override
  State<_IconPicker> createState() => _IconPickerState();
}

class _IconPickerState extends State<_IconPicker> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final c = HfColors.of(context);
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
      'kids': l.iconGroupKids,
    };
    final q = _query.text.trim();
    final found = searchIcons(q).where(appIcons.containsKey).toList();
    Widget dots(List<String> keys) => Wrap(
      spacing: AppSpace.sm,
      runSpacing: AppSpace.sm,
      children: [
        for (final k in keys)
          _IconDot(key: ValueKey('icon-$k'), iconKey: k, selected: k == widget.selected, onTap: () => Navigator.pop(context, k), size: 48),
      ],
    );
    return Scaffold(
      appBar: AppBar(title: Text(l.chooseIcon)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.sm),
            child: TextField(
              controller: _query,
              decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded), hintText: l.searchIconsHint),
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.xl),
              children: [
                if (q.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.sm),
                  if (found.isEmpty)
                    Text(l.noIconsFound, style: t.bodyMedium?.copyWith(color: c.mutedFg))
                  else
                    dots(found),
                ] else
                  for (final g in iconGroups.entries) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpace.md, bottom: AppSpace.sm),
                      child: Text(names[g.key] ?? g.key, style: t.labelLarge),
                    ),
                    dots(g.value),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
