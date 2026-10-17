import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../data/home_store.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/sheets.dart';

/// Picking several items (with quantities) and moving, taking out or using
/// them up together. Shared by the room board and the single storage screen.
mixin PickSelection<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool selecting = false;

  /// item id -> chosen quantity.
  final picks = <String, int>{};

  HomeController get _home => ref.read(homeProvider.notifier);

  int get pickedTotal => picks.values.fold(0, (a, b) => a + b);

  void startSelect() => setState(() => selecting = true);

  void endSelect() => setState(() {
    selecting = false;
    picks.clear();
  });

  /// Drops picks whose item is gone (moved, used up, undone).
  void prunePicks(HomeData d) => picks.removeWhere((id, _) => d.item(id) == null);

  Future<void> togglePick(Item item) async {
    if (!selecting) setState(() => selecting = true);
    if (item.qty == 1) {
      setState(() => picks.containsKey(item.id) ? picks.remove(item.id) : picks[item.id] = 1);
      return;
    }
    final q = await pickQuantity(context, name: item.name, max: item.qty, initial: picks[item.id]);
    if (q == null || !mounted) return;
    setState(() => q == 0 ? picks.remove(item.id) : picks[item.id] = q);
  }

  Future<void> moveSelectedTo(String to) async {
    final l = AppLocalizations.of(context);
    final p = Map.of(picks);
    final total = pickedTotal;
    final name = _home.data.container(to)!.name;
    await _home.apply((d, ctx) => moveItems(d, ctx, p, to));
    if (!mounted) return;
    endSelect();
    showUndo(context, ref, l.movedTo(total, name));
  }

  Future<void> moveSelectedPicking({String? exclude}) async {
    final l = AppLocalizations.of(context);
    final to = await pickStorage(context, title: l.moveToWhere, exclude: exclude);
    if (to != null && mounted) await moveSelectedTo(to);
  }

  Future<void> takeOutSelected() async {
    final l = AppLocalizations.of(context);
    final p = Map.of(picks);
    final total = pickedTotal;
    await _home.apply((d, ctx) => useItems(d, ctx, p));
    if (!mounted) return;
    endSelect();
    showUndo(context, ref, l.tookOut(total));
  }

  Future<void> useUpSelected() async {
    final l = AppLocalizations.of(context);
    final ids = picks.keys.toList();
    await _home.apply((d, ctx) => useUpItems(d, ctx, ids));
    if (!mounted) return;
    endSelect();
    showUndo(context, ref, l.usedUpKinds(ids.length));
  }

  /// Move… / Take out / Used up.
  Widget selectionButtons(BuildContext context, {String? exclude}) {
    final l = AppLocalizations.of(context);
    final none = picks.isEmpty;
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: none ? null : () => moveSelectedPicking(exclude: exclude),
            icon: const Icon(Icons.swap_horiz_rounded),
            label: Text(l.actionMove),
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: OutlinedButton(onPressed: none ? null : takeOutSelected, child: Text(l.actionTakeOut)),
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: OutlinedButton(onPressed: none ? null : useUpSelected, child: Text(l.usedUp)),
        ),
      ],
    );
  }
}
