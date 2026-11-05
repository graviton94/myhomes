/// The shopping list: things below their minimum amount, plus lines added by
/// hand. Ticking a line means it was bought: it goes straight into the home.
library;

import 'hangul.dart';
import 'features.dart';
import 'icons.dart';
import 'model.dart';
import 'ops.dart';

/// One line on the list.
class ShopLine {
  const ShopLine({required this.name, required this.qty, this.item, this.entry});

  final String name;

  /// How many to buy.
  final int qty;

  /// The item it refills, if it is in the home already.
  final Item? item;

  /// The hand-added line, if it is one.
  final ToBuy? entry;

  String get key => entry?.id ?? 'low:${item!.id}';
}

/// Hand-added lines first (oldest first), then things running low that no
/// hand-added line already covers.
List<ShopLine> shoppingList(HomeData d) {
  final out = <ShopLine>[
    for (final b in d.toBuy) ShopLine(name: b.name, qty: b.qty, item: b.itemId == null ? null : d.item(b.itemId!), entry: b),
  ];
  final covered = {for (final b in d.toBuy) ?b.itemId};
  for (final i in lowStock(d)) {
    if (!covered.contains(i.id)) out.add(ShopLine(name: i.name, qty: i.minQty! - i.qty, item: i));
  }
  return out;
}

/// "살 것 추가": [name] × [qty]. A thing already in the home (same name) is
/// linked, so buying it refills that stack; adding the same thing twice adds up.
HomeData addToBuy(HomeData d, Ctx ctx, String name, {int qty = 1, String? by}) {
  final clean = cleanText(name).trim();
  if (clean.isEmpty) return d;
  final same = d.toBuy.where((b) => b.name.toLowerCase() == clean.toLowerCase()).firstOrNull;
  if (same != null) {
    return d.copyWith(toBuy: [for (final b in d.toBuy) b.id == same.id ? b.copyWith(qty: b.qty + qty) : b]);
  }
  final item = d.items.where((i) => i.name.toLowerCase() == clean.toLowerCase()).toList()..sort((a, b) => b.qty.compareTo(a.qty));
  return d.copyWith(
    toBuy: [
      ...d.toBuy,
      ToBuy(id: ctx.newId(), name: clean, qty: qty < 1 ? 1 : qty, itemId: item.firstOrNull?.id, by: by ?? ctx.by, addedAt: ctx.now()),
    ],
  );
}

/// Takes a hand-added line off the list without buying it.
HomeData removeToBuy(HomeData d, String entryId) => d.copyWith(toBuy: d.toBuy.where((b) => b.id != entryId).toList());

/// Where a bought thing goes: where it already is, else the last place
/// something was put, else null (ask).
String? placeFor(HomeData d, ShopLine line) {
  final item = line.item == null ? null : d.item(line.item!.id);
  if (item != null) return item.containerId;
  return recentContainerIds(d, limit: 1).firstOrNull;
}

/// Bought [bought] of [line] (all of it when null): puts them into the home
/// at [containerId] and takes them off the list (what is left stays on it).
/// Returns the data and the id of the stack they went into.
Result<String> buyLine(HomeData d, Ctx ctx, ShopLine line, {required String containerId, int? bought}) {
  final n = (bought ?? line.qty).clamp(1, 1 << 30);
  var x = d;
  final item = line.item == null ? null : x.item(line.item!.id);
  String id;
  if (item != null && item.containerId == containerId) {
    x = adjustQty(x, ctx, item.id, n);
    id = item.id;
  } else {
    final made = addItem(
      x,
      ctx,
      containerId: containerId,
      name: item?.name ?? line.name,
      category: item?.category ?? guessCategory(line.name) ?? ItemCategory.other,
      qty: n,
      icon: item?.icon ?? iconsFromName(line.name).firstOrNull,
      returns: item?.returns,
    );
    x = made.data;
    id = made.value.id;
  }
  final e = line.entry;
  if (e != null) {
    final left = e.qty - n;
    x = x.copyWith(
      toBuy: [
        for (final b in x.toBuy)
          if (b.id != e.id) b else if (left > 0) b.copyWith(qty: left),
      ],
    );
  }
  return Result(x, id);
}

/// Things just put in another way (a receipt, a barcode): the same names come
/// off the hand-added list by the number put in. Returns the data and the
/// names that came off.
Result<List<String>> settleToBuy(HomeData d, Map<String, int> put) {
  final off = <String>[];
  final left = <ToBuy>[];
  for (final b in d.toBuy) {
    final n = put.entries.where((e) => e.key.toLowerCase() == b.name.toLowerCase()).fold(0, (s, e) => s + e.value);
    if (n == 0) {
      left.add(b);
      continue;
    }
    off.add(b.name);
    if (b.qty > n) left.add(b.copyWith(qty: b.qty - n));
  }
  return Result(d.copyWith(toBuy: left), off);
}
