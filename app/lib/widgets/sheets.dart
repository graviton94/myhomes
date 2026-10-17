import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../data/home_store.dart';
import '../design/theme.dart';
import '../design/tokens.g.dart';
import '../l10n/app_localizations.dart';
import 'app_icons.dart';

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

/// Lists every storage spot grouped by space. Returns the chosen storage id.
/// [exclude] hides one storage (the source when moving).
Future<String?> pickStorage(BuildContext context, {required String title, String? exclude}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    builder: (context) => _StoragePicker(title: title, exclude: exclude),
  );
}

class _StoragePicker extends ConsumerWidget {
  const _StoragePicker({required this.title, this.exclude});

  final String title;
  final String? exclude;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final d = ref.watch(homeProvider).requireValue;
    final recent = recentContainerIds(d).where((id) => id != exclude).toList();
    final t = Theme.of(context).textTheme;

    Widget tile(Storage s) => ListTile(
      leading: Icon(storageIcon(s), color: HfColors.of(context).accentInk),
      title: Text(pathText(d.pathOf(s.id))),
      subtitle: Text(l.itemsCount(d.itemsIn(s.id).length)),
      trailing: Text(s.code, style: AppType.code.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      onTap: () => Navigator.of(context).pop(s.id),
    );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      builder: (context, scroll) => Column(
        children: [
          SheetHeader(title),
          Expanded(
            child: d.containers.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppSpace.xl),
                    child: Text(l.noStorageYet, style: t.bodyMedium),
                  )
                : ListView(
                    controller: scroll,
                    children: [
                      if (recent.isNotEmpty) ...[_Label(l.recentPlaces), for (final id in recent) tile(d.container(id)!), const Divider()],
                      for (final space in spacesInOrder(d)) ...[
                        _Label(space.outside ? '${l.outsideHome} · ${space.name}' : space.name),
                        for (final s in d.containers.where((c) => c.spaceId == space.id && c.id != exclude)) tile(s),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.xs),
    child: Text(text, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
  );
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
