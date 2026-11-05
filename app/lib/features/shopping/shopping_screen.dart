import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../data/home_store.dart';
import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fairy.dart';
import '../../widgets/header_line.dart';
import '../../widgets/inventory_slot.dart';
import '../../widgets/layers.dart';
import '../../widgets/sheets.dart';

/// What to buy: lines added by hand, then things running low. Ticking a line
/// means it was bought: it goes straight into its place, and a toast offers
/// the amount, the place and undo. No "in the cart" step in between.
class ShoppingScreen extends ConsumerWidget {
  const ShoppingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final d = ref.watch(homeProvider).requireValue;
    final list = shoppingList(d);

    return Scaffold(
      appBar: AppBar(title: Text(l.shoppingTitle), actions: const [SettingsButton()]),
      body: list.isEmpty
          ? Center(
              child: SingleChildScrollView(
                child: EmptyState(pose: FairyPose.cheer, title: l.shoppingEmptyTitle, body: l.shoppingEmptyBody),
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
              children: [
                for (final line in list)
                  _Line(
                    key: ValueKey('shop-${line.key}'),
                    line: line,
                    where: line.item != null && d.container(line.item!.containerId) != null
                        ? pathText(d.pathOf(line.item!.containerId))
                        : (line.entry == null ? l.shopLow : l.shopNew),
                    low: line.entry == null,
                    color: c.mutedFg,
                    onBought: () => _bought(context, ref, line),
                    onRemove: line.entry == null ? null : () => _remove(context, ref, line.entry!),
                  ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.sm),
          child: FilledButton.icon(
            key: const ValueKey('shop-add'),
            onPressed: () => _add(context, ref),
            icon: const Icon(Icons.add_rounded),
            label: Text(l.shopAdd),
          ),
        ),
      ),
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final got = await Navigator.of(
      context,
      rootNavigator: true,
    ).push<(String, int)>(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const _AddToBuy()));
    if (got == null) return;
    await ref.read(homeProvider.notifier).apply((d, ctx) => addToBuy(d, ctx, got.$1, qty: got.$2));
  }

  Future<void> _remove(BuildContext context, WidgetRef ref, ToBuy entry) async {
    final l = AppLocalizations.of(context);
    await ref.read(homeProvider.notifier).apply((d, ctx) => removeToBuy(d, entry.id));
    if (context.mounted) showUndo(context, ref, l.shopRemoved(entry.name));
  }

  /// Ticked: into its place now, then a toast for the details.
  Future<void> _bought(BuildContext context, WidgetRef ref, ShopLine line) async {
    final l = AppLocalizations.of(context);
    final home = ref.read(homeProvider.notifier);
    var to = placeFor(home.data, line);
    to ??= await pickStorage(context, title: l.addWhere);
    if (to == null || !context.mounted) return;
    final at = to;

    late void Function(int n, String id) toast;

    Future<void> put(int n) async {
      String? id;
      await home.apply((d, ctx) {
        final r = buyLine(d, ctx, line, containerId: at, bought: n);
        id = r.value;
        return r.data;
      });
      if (!context.mounted) return;
      toast(n, id!);
    }

    toast = (int n, String id) {
      showActionToast(
        context,
        message: l.shopPutIn(n, line.name, pathText(home.data.pathOf(at))),
        qty: line.qty > 1
            ? ToastQty(
                label: l.quantity,
                question: l.shopHowMany(line.name),
                value: n,
                max: line.qty,
                note: (v) => v < line.qty ? l.shopLeft(line.qty - v) : null,
                onDone: (v) async {
                  if (v == n) return;
                  await home.undo();
                  await put(v);
                },
              )
            : null,
        actions: [
          ToastAction(l.shopPlace, () async {
            final moveTo = await pickStorage(context, title: l.addWhere, exclude: at);
            if (moveTo == null) return;
            await home.apply((d, ctx) => moveItems(d, ctx, {id: n}, moveTo));
          }),
          ToastAction(l.undo, home.undo),
        ],
      );
    };

    await put(line.qty);
  }
}

class _Line extends StatelessWidget {
  const _Line({
    super.key,
    required this.line,
    required this.where,
    required this.low,
    required this.color,
    required this.onBought,
    this.onRemove,
  });

  final ShopLine line;
  final String where;
  final bool low;
  final Color color;
  final VoidCallback onBought;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final item = line.item;
    final tile = ListTile(
      leading: Checkbox(key: ValueKey('buy-${line.key}'), value: false, onChanged: (_) => onBought()),
      title: Row(
        children: [
          ItemThumb(
            category: item?.category ?? guessCategory(line.name) ?? ItemCategory.other,
            photoPath: item?.photoPath,
            iconKey: item?.icon ?? iconsFromName(line.name).firstOrNull,
            size: 32,
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(child: Text(line.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
          Text(l.shopQty(line.qty), style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(left: 40),
        child: Text(
          where,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: color),
        ),
      ),
      onTap: onBought,
    );
    if (onRemove == null) return tile;
    // Hand-added lines can be swiped away without buying them.
    return Dismissible(key: ValueKey('swipe-${line.key}'), onDismissed: (_) => onRemove!(), child: tile);
  }
}

/// "살 것 추가": a name and how many, on its own screen so the keyboard has room.
class _AddToBuy extends StatefulWidget {
  const _AddToBuy();

  @override
  State<_AddToBuy> createState() => _AddToBuyState();
}

class _AddToBuyState extends State<_AddToBuy> {
  final _name = TextEditingController();
  int _qty = 1;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _done() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context, (name, _qty));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.shopAdd)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.lg),
        children: [
          TextField(
            key: const ValueKey('to-buy-name'),
            controller: _name,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(labelText: l.shopAddName),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _done(),
          ),
          const SizedBox(height: AppSpace.lg),
          Row(
            children: [
              Expanded(child: Text(l.quantity, style: t.titleSmall)),
              QtyStepper(value: _qty, onChanged: (v) => setState(() => _qty = v)),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.sm + MediaQuery.viewInsetsOf(context).bottom),
          child: FilledButton(
            key: const ValueKey('to-buy-save'),
            onPressed: _name.text.trim().isEmpty ? null : _done,
            child: Text(l.shopAddButton),
          ),
        ),
      ),
    );
  }
}
