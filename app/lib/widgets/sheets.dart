import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../data/home_store.dart';
import '../design/theme.dart';
import '../design/tokens.g.dart';
import '../l10n/app_localizations.dart';
import '../features/spaces/space_actions.dart';
import 'app_icons.dart';
import 'inventory_slot.dart';

/// Snackbar after a change, with a 5-second Undo instead of a confirm dialog.
void showUndo(BuildContext context, WidgetRef ref, String message) {
  final l = AppLocalizations.of(context);
  final controller = ref.read(homeProvider.notifier);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(label: l.undo, onPressed: controller.undo),
      ),
    );
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// "Living room › TV stand" style path text.
String pathText(List<String> parts) => parts.join(' › ');

/// Grabber + title row shared by bottom sheets.
class SheetHeader extends StatelessWidget {
  const SheetHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = HfColors.of(context);
    return Column(
      children: [
        const SizedBox(height: AppSpace.sm),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.sm, AppSpace.xs),
          child: Row(
            children: [
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
              ?trailing,
            ],
          ),
        ),
      ],
    );
  }
}

/// Choose a storage spot, grouped by room (rooms first, then places outside).
/// [exclude] marks the spot things are moving from; [onlySpaceId] limits the
/// list to one room. Rooms without a spot offer to make one. Returns the id.
Future<String?> pickStorage(BuildContext context, {required String title, String? exclude, String? onlySpaceId}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _StoragePicker(title: title, exclude: exclude, onlySpaceId: onlySpaceId),
  );
}

class _StoragePicker extends ConsumerWidget {
  const _StoragePicker({required this.title, this.exclude, this.onlySpaceId});

  final String title;
  final String? exclude;
  final String? onlySpaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final t = Theme.of(context).textTheme;
    final d = ref.watch(homeProvider).requireValue;
    final spaces = spacesInOrder(d).where((s) => onlySpaceId == null || s.id == onlySpaceId).toList();
    final recent = onlySpaceId == null ? recentContainerIds(d).where((id) => id != exclude).toList() : const <String>[];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.94,
      builder: (context, scroll) => Column(
        children: [
          SheetHeader(title),
          Expanded(
            child: spaces.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppSpace.xl),
                    child: Text(l.noStorageYet, style: t.bodyMedium),
                  )
                : ListView(
                    controller: scroll,
                    padding: EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.xl + MediaQuery.viewPaddingOf(context).bottom),
                    children: [
                      if (recent.isNotEmpty) ...[
                        Text(l.recentPlaces, style: t.labelLarge?.copyWith(color: c.mutedFg)),
                        const SizedBox(height: AppSpace.sm),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final id in recent) ...[
                                ActionChip(
                                  avatar: storageGlyph(d.container(id)!, size: 18, color: c.accentInk),
                                  label: Text(pathText(d.pathOf(id))),
                                  onPressed: () => Navigator.pop(context, id),
                                ),
                                const SizedBox(width: AppSpace.sm),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpace.md),
                      ],
                      for (final space in spaces) ...[
                        _RoomHeader(space: space),
                        LayoutBuilder(
                          builder: (context, box) {
                            final w = (box.maxWidth - AppSpace.sm) / 2;
                            return Wrap(
                              spacing: AppSpace.sm,
                              runSpacing: AppSpace.sm,
                              children: [
                                // Shelves, drawers and boxes too; furniture split into sections is not a place itself.
                                for (final s in placesIn(d, space.id))
                                  SizedBox(
                                    width: w,
                                    child: _SpotCard(
                                      storage: s,
                                      label: pathText(d.pathOf(s.id).skip(1).toList()),
                                      isSource: s.id == exclude,
                                    ),
                                  ),
                                SizedBox(
                                  width: w,
                                  child: _NewSpotCard(
                                    onTap: () async {
                                      final s = await addStorageFlow(context, ref, space.id);
                                      if (s != null && context.mounted) Navigator.pop(context, s.id);
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: AppSpace.lg),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Room name with its icon in the room colour (green, or persimmon outside).
class _RoomHeader extends ConsumerWidget {
  const _RoomHeader({required this.space});

  final Space space;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final (bg, ink) = space.outside ? (c.primarySoft, c.primaryInk) : (c.secondarySoft, c.secondaryInk);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Center(child: spaceGlyph(space, size: 17, color: ink)),
          ),
          const SizedBox(width: AppSpace.sm),
          Flexible(
            child: Text(space.name, style: Theme.of(context).textTheme.titleSmall, overflow: TextOverflow.ellipsis),
          ),
          if (space.outside) ...[
            const SizedBox(width: AppSpace.sm),
            Text(l.outsideHome, style: AppType.label.copyWith(fontSize: 11, color: ink)),
          ],
        ],
      ),
    );
  }
}

/// A storage spot as a small card: icon, name, count, and a peek at its items.
class _SpotCard extends ConsumerWidget {
  const _SpotCard({required this.storage, required this.label, required this.isSource});

  final Storage storage;

  /// Path inside the room ("TV stand › Left drawer").
  final String label;
  final bool isSource;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final t = Theme.of(context).textTheme;
    final items = ref.watch(homeProvider).requireValue.itemsIn(storage.id)..sort((a, b) => a.slot.compareTo(b.slot));
    return Opacity(
      opacity: isSource ? 0.5 : 1,
      child: Material(
        color: c.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: c.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isSource ? null : () => Navigator.pop(context, storage.id),
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.sm + 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(9)),
                      child: Center(child: storageGlyph(storage, size: 17, color: c.accentInk)),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: t.labelLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
                          Text(isSource ? l.hereNow : l.itemsCount(items.length), style: t.bodySmall?.copyWith(fontSize: 11), maxLines: 1),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
                SizedBox(
                  height: 22,
                  child: Row(
                    children: [
                      for (final i in items.take(4)) ...[
                        ItemThumb(category: i.category, photoPath: i.photoPath, iconKey: i.icon, size: 22),
                        const SizedBox(width: 4),
                      ],
                      if (items.length > 4) Text('+${items.length - 4}', style: AppType.code.copyWith(fontSize: 11, color: c.mutedFg)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NewSpotCard extends StatelessWidget {
  const _NewSpotCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        height: 84,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: c.border, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 18, color: c.mutedFg),
            const SizedBox(width: 4),
            Flexible(
              child: Text(l.newStorageHere, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: c.mutedFg)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quantity popup: 1 / half / all chips plus a stepper.
/// Returns the chosen quantity, 0 for "deselect", or null when dismissed.
Future<int?> pickQuantity(BuildContext context, {required String name, required int max, int? initial}) {
  return showModalBottomSheet<int>(
    context: context,
    builder: (context) => _QtyPicker(name: name, max: max, initial: initial ?? max),
  );
}

class _QtyPicker extends StatefulWidget {
  const _QtyPicker({required this.name, required this.max, required this.initial});

  final String name;
  final int max;
  final int initial;

  @override
  State<_QtyPicker> createState() => _QtyPickerState();
}

class _QtyPickerState extends State<_QtyPicker> {
  late int qty = widget.initial.clamp(1, widget.max);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final half = (widget.max / 2).floor().clamp(1, widget.max);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(l.howMany(widget.name)),
            Text(l.youHave(widget.max), style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpace.md),
            Wrap(
              spacing: AppSpace.sm,
              children: [
                ChoiceChip(label: Text(l.qtyOne), selected: qty == 1, onSelected: (_) => setState(() => qty = 1)),
                if (widget.max > 2)
                  ChoiceChip(label: Text(l.qtyHalf(half)), selected: qty == half, onSelected: (_) => setState(() => qty = half)),
                ChoiceChip(
                  label: Text(l.qtyAll(widget.max)),
                  selected: qty == widget.max,
                  onSelected: (_) => setState(() => qty = widget.max),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            QtyStepper(value: qty, min: 1, max: widget.max, onChanged: (v) => setState(() => qty = v)),
            const SizedBox(height: AppSpace.lg),
            FilledButton(onPressed: () => Navigator.pop(context, qty), child: Text(l.choose)),
            TextButton(onPressed: () => Navigator.pop(context, 0), child: Text(l.deselect)),
          ],
        ),
      ),
    );
  }
}

/// − value + with 48dp buttons.
class QtyStepper extends StatelessWidget {
  const QtyStepper({super.key, required this.value, required this.onChanged, this.min = 1, this.max = 9999});

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: l.decrease,
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 44),
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: AppType.code.copyWith(fontSize: 17, color: c.fg),
            ),
          ),
          IconButton(tooltip: l.increase, onPressed: value < max ? () => onChanged(value + 1) : null, icon: const Icon(Icons.add_rounded)),
        ],
      ),
    );
  }
}

/// Simple one-field text dialog (names). Returns the trimmed text or null.
Future<String?> askText(BuildContext context, {required String title, String initial = '', required String label}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) {
      final l = AppLocalizations.of(context);
      void submit() {
        final v = controller.text.trim();
        if (v.isNotEmpty) Navigator.pop(context, v);
      }

      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(labelText: label),
          onSubmitted: (_) => submit(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
          FilledButton(onPressed: submit, child: Text(l.save)),
        ],
      );
    },
  );
}

/// Yes/no dialog for destructive actions that cannot be undone.
Future<bool> confirm(BuildContext context, {required String title, required String body, required String action}) async {
  final l = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
          onPressed: () => Navigator.pop(context, true),
          child: Text(action),
        ),
      ],
    ),
  );
  return ok ?? false;
}
