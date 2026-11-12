import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';
import 'package:intl/intl.dart';

import '../../data/home_store.dart';
import '../../data/smart_suggest.dart';
import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/header_line.dart';
import '../../widgets/icon_chooser.dart';
import '../../widgets/inventory_slot.dart';
import '../../widgets/fit_text.dart';
import '../../widgets/layers.dart';
import 'valuable_page.dart';
import '../../widgets/photo_picker.dart';
import '../../widgets/sheets.dart';
import '../../widgets/chip_line.dart';

part 'item_form_parts.dart';

/// Add a new item (with [storageId] and optional [slot]) or edit [itemId].
class ItemFormScreen extends ConsumerStatefulWidget {
  const ItemFormScreen({super.key, this.storageId, this.slot, this.itemId, this.initialName, this.barcode});

  final String? storageId;
  final int? slot;
  final String? itemId;

  /// From a scanned barcode: the product name (if known) and the code itself.
  final String? initialName;
  final String? barcode;

  @override
  ConsumerState<ItemFormScreen> createState() => _ItemFormScreenState();
}

enum _Due { none, d3, w1, m1, custom }

class _ItemFormScreenState extends ConsumerState<ItemFormScreen> {
  final _name = TextEditingController();
  final _note = TextEditingController();
  ItemCategory _category = ItemCategory.other;
  int _qty = 1;

  /// Minimum amount for the shopping list; null = not kept in stock.
  int? _minQty;

  /// Comes back after use; null follows the category.
  bool? _returns;

  /// Warranty, price and a photo of the receipt (the valuables list).
  Valuable _valuable = (warrantyUntil: null, price: null, proofPath: null);

  /// "더 적기" fields opened by their tile.
  bool _showMin = false, _showNote = false;
  DateTime? _expires;
  String? _photo;

  /// Hand-picked icon; null follows the name.
  String? _icon;
  String? _storageId;
  int? _slot;
  bool _nameMissing = false;

  /// The person chose the category; suggestions stop changing it.
  bool _categoryTouched = false;

  /// Server suggestion for the name currently typed ([_smartFor]).
  String? _smartFor;
  Pick? _smartIcon;
  bool _smartApplied = false;
  Timer? _debounce;

  Item? get _editing => widget.itemId == null ? null : ref.read(homeProvider).requireValue.item(widget.itemId!);

  @override
  void initState() {
    super.initState();
    _storageId = widget.storageId;
    _slot = widget.slot;
    if (widget.initialName != null) {
      _name.text = widget.initialName!;
      _category = guessCategory(widget.initialName!) ?? ItemCategory.food;
    }
    final item = _editing;
    if (item != null) {
      _openedAt = item.updatedAt;
      _load(item);
    }
  }

  /// When the open item was last changed; a later change came from elsewhere (family).
  DateTime? _openedAt;

  void _load(Item item) {
    _name.text = item.name;
    _note.text = item.note;
    _category = item.category;
    _qty = item.qty;
    _minQty = item.minQty;
    _returns = item.returns;
    _valuable = (warrantyUntil: item.warrantyUntil, price: item.price, proofPath: item.proofPath);
    _expires = item.expiresOn;
    _photo = item.photoPath;
    _icon = item.icon;
    _storageId = item.containerId;
    _categoryTouched = true;
  }

  Pick? get _smartIconNow => _smartFor == _name.text.trim() ? _smartIcon : null;

  void _onNameChanged(String value) {
    final name = value.trim();
    setState(() {
      _nameMissing = false;
      _smartApplied = false;
      if (!_categoryTouched) _category = guessCategory(name) ?? ItemCategory.other;
    });
    _debounce?.cancel();
    // The word list knows most names; the server (which costs credits) is
    // only asked about the rest.
    if (name.length < 2 || guessCategory(name) != null) return;
    _debounce = Timer(const Duration(milliseconds: 600), () => _askSmart(name));
  }

  Future<void> _askSmart(String name) async {
    final r = await ref.read(smartSuggestProvider).classify(name);
    if (r == null || !mounted || _name.text.trim() != name) return;
    setState(() {
      _smartFor = name;
      _smartIcon = r.icon;
      final cat = r.category;
      final known = ItemCategory.values.where((c) => c.name == cat?.choice).firstOrNull;
      if (!_categoryTouched && known != null && cat != null && suggestLevel(cat.confidence) == SuggestLevel.auto) {
        _category = known;
        _smartApplied = true;
      }
      if (_icon == null && r.icon != null && suggestLevel(r.icon!.confidence) == SuggestLevel.auto) _smartApplied = true;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  Future<void> _setDue(_Due due) async {
    final t = _today;
    DateTime? date;
    switch (due) {
      case _Due.none:
        date = null;
      case _Due.d3:
        date = t.add(const Duration(days: 3));
      case _Due.w1:
        date = t.add(const Duration(days: 7));
      case _Due.m1:
        date = DateTime(t.year, t.month + 1, t.day);
      case _Due.custom:
        date = await showDatePicker(
          context: context,
          initialDate: _expires ?? t.add(const Duration(days: 7)),
          firstDate: t.subtract(const Duration(days: 365)),
          lastDate: t.add(const Duration(days: 365 * 10)),
        );
        if (date == null) return;
    }
    setState(() {
      _expires = date;
    });
  }

  /// The square's menu: photo (camera or album), remove it, or change the icon.
  Future<void> _squareMenu() async {
    final l = AppLocalizations.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHeader(l.photo),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l.takePhoto),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l.chooseFromGallery),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            if (_photo != null)
              ListTile(
                leading: const Icon(Icons.hide_image_outlined),
                title: Text(l.removePhoto),
                onTap: () => Navigator.pop(context, 'remove'),
              ),
            ListTile(
              key: const ValueKey('square-icon'),
              leading: const Icon(Icons.apps_rounded),
              title: Text(l.changeIcon),
              onTap: () => Navigator.pop(context, 'icon'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    switch (choice) {
      case 'remove':
        setState(() => _photo = null);
      case 'icon':
        final k = await pickIcon(context, selected: effectiveIcon(_icon, _name.text, smart: _smartIconNow));
        if (k != null && mounted) setState(() => _icon = k);
      default:
        final path = await photoFrom(ref, camera: choice == 'camera');
        if (path != null && mounted) setState(() => _photo = path);
    }
  }

  Future<void> _chooseValuable() async {
    final v = await editValuable(context, _valuable);
    if (v != null && mounted) setState(() => _valuable = v);
  }

  /// 기한: quick choices in a sheet, or a date from the calendar.
  Future<void> _chooseDue() async {
    final l = AppLocalizations.of(context);
    final due = await askQuestion<_Due>(
      context,
      title: l.useBy,
      answers: [
        Answer(_Due.custom, l.duePick),
        Answer(_Due.d3, l.dueDays(3)),
        Answer(_Due.w1, l.dueWeek),
        Answer(_Due.m1, l.dueMonth),
        Answer(_Due.none, l.dueNone),
      ],
    );
    if (due != null) await _setDue(due);
  }

  /// 분류: the eleven kinds in a sheet, four to a row, and whether it comes back after use.
  Future<void> _chooseCategory(Map<ItemCategory, String> categories) async {
    final l = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, setSheet) {
          void pick(ItemCategory k) {
            setState(() {
              _category = k;
              _categoryTouched = true;
            });
            setSheet(() {});
          }

          final rows = [for (var i = 0; i < categories.length; i += 4) categories.entries.skip(i).take(4).toList()];
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SheetHeader(l.category),
                  for (final row in rows) ...[
                    Row(
                      children: [
                        for (var i = 0; i < 4; i++) ...[
                          if (i > 0) const SizedBox(width: AppSpace.xs),
                          Expanded(
                            child: i >= row.length
                                ? const SizedBox()
                                : _CategoryTile(
                                    category: row[i].key,
                                    label: row[i].value,
                                    selected: _category == row[i].key,
                                    onTap: () => pick(row[i].key),
                                  ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpace.xs),
                  ],
                  SwitchListTile(
                    key: const ValueKey('item-returns'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.returnsLabel),
                    value: _returns ?? useKindOf(_category) == UseKind.returned,
                    onChanged: (v) {
                      setState(() => _returns = v);
                      setSheet(() {});
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _changePlace() async {
    final l = AppLocalizations.of(context);
    final id = await pickStorage(context, title: l.putWhere);
    if (id != null) {
      setState(() {
        _storageId = id;
        _slot = null;
      });
    }
  }

  /// Saves; returns false when something required is missing.
  Future<bool> _save() async {
    final l = AppLocalizations.of(context);
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameMissing = true);
      return false;
    }
    final storageId = _storageId;
    if (storageId == null) {
      showMessage(context, l.chooseAPlace);
      return false;
    }
    final home = ref.read(homeProvider.notifier);
    final editing = _editing;
    if (editing == null) {
      await home.apply<Item>(
        (d, ctx) => addItem(
          d,
          ctx,
          containerId: storageId,
          name: name,
          slot: _slot,
          category: _category,
          qty: _qty,
          expiresOn: _expires,
          photoPath: _photo,
          icon: effectiveIcon(_icon, name, smart: _smartIconNow),
          note: _note.text.trim(),
          minQty: _minQty,
          barcode: widget.barcode,
          returns: _returns,
          warrantyUntil: _valuable.warrantyUntil,
          price: _valuable.price,
          proofPath: _valuable.proofPath,
        ),
      );
    } else {
      await home.apply((d, ctx) {
        var x = d;
        if (storageId != editing.containerId) x = moveItems(x, ctx, {editing.id: editing.qty}, storageId);
        final cur = x.item(editing.id);
        if (cur == null) return x;
        return editItem(
          x,
          ctx,
          Item(
            id: cur.id,
            containerId: cur.containerId,
            slot: cur.slot,
            name: name,
            category: _category,
            qty: _qty,
            expiresOn: _expires,
            photoPath: _photo,
            icon: effectiveIcon(_icon, name, smart: _smartIconNow),
            note: _note.text.trim(),
            minQty: _minQty,
            barcode: cur.barcode,
            returns: _returns,
            inUseSince: cur.inUseSince,
            askedAt: cur.askedAt,
            warrantyUntil: _valuable.warrantyUntil,
            price: _valuable.price,
            proofPath: _valuable.proofPath,
            updatedAt: cur.updatedAt,
          ),
        );
      });
    }
    return true;
  }

  Future<void> _saveAndClose() async {
    if (await _save() && mounted) context.canPop() ? context.pop() : context.go('/');
  }

  Future<void> _saveAndNext() async {
    final l = AppLocalizations.of(context);
    final name = _name.text.trim();
    if (!await _save() || !mounted) return;
    showMessage(context, l.addedName(name));
    setState(() {
      _name.clear();
      _note.clear();
      _qty = 1;
      _minQty = null;
      _returns = null;
      _valuable = (warrantyUntil: null, price: null, proofPath: null);
      _photo = null;
      _icon = null;
      _slot = null;
      _nameMissing = false;
      _categoryTouched = false;
      _smartFor = null;
      _smartIcon = null;
      _smartApplied = false;
    });
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final item = _editing;
    if (item == null) return;
    await ref.read(homeProvider.notifier).apply((d, ctx) => removeItem(d, ctx, item.id));
    if (!mounted) return;
    showUndo(context, ref, l.deletedName(item.name));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final t = Theme.of(context).textTheme;
    final d = ref.watch(homeProvider).requireValue;
    final editing = widget.itemId != null;
    // Someone else (family) changed or removed this item while it is open here.
    final now = editing ? d.item(widget.itemId!) : null;
    final changedElsewhere = now != null && _openedAt != null && now.updatedAt != _openedAt ? now : null;
    final goneElsewhere = editing && now == null;
    final names = recentNames(d).where((n) => n.toLowerCase() != _name.text.trim().toLowerCase()).take(6).toList();
    final storage = _storageId == null ? null : d.container(_storageId!);
    final dateText = _expires == null ? null : DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).format(_expires!);

    final categories = {
      ItemCategory.food: l.categoryFood,
      ItemCategory.household: l.categoryHousehold,
      ItemCategory.tools: l.categoryTools,
      ItemCategory.medicine: l.categoryMedicine,
      ItemCategory.clothes: l.categoryClothes,
      ItemCategory.electronics: l.categoryElectronics,
      ItemCategory.papers: l.categoryPapers,
      ItemCategory.hobby: l.categoryHobby,
      ItemCategory.kids: l.categoryKids,
      ItemCategory.pets: l.categoryPets,
      ItemCategory.other: l.categoryOther,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? l.editItem : l.addItem),
        actions: [
          if (editing) IconButton(tooltip: l.delete, onPressed: _delete, icon: const Icon(Icons.delete_outline_rounded)),
          const SettingsButton(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.xs, AppSpace.lg, AppSpace.xl),
        children: [
          if (changedElsewhere != null || goneElsewhere)
            Card(
              key: const ValueKey('item-changed-elsewhere'),
              color: c.accentSoft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.sm, AppSpace.sm, AppSpace.sm),
                child: Row(
                  children: [
                    Expanded(child: FitText(goneElsewhere ? l.itemGoneElsewhere : l.itemChangedElsewhere(changedElsewhere!.qty))),
                    if (!goneElsewhere)
                      TextButton(
                        onPressed: () => setState(() {
                          _openedAt = changedElsewhere!.updatedAt;
                          _load(changedElsewhere);
                        }),
                        child: Text(l.itemReload),
                      ),
                  ],
                ),
              ),
            ),
          // The square left of the name is the icon (set by the name) or the
          // photo; tapping it takes a photo or changes the icon.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconSquare(
                key: const ValueKey('item-square'),
                photoPath: _photo,
                iconKey: effectiveIcon(_icon, _name.text, smart: _smartIconNow),
                category: _category,
                onTap: _squareMenu,
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: TextField(
                  controller: _name,
                  autofocus: !editing,
                  textInputAction: TextInputAction.next,
                  onChanged: _onNameChanged,
                  decoration: InputDecoration(labelText: l.itemName, errorText: _nameMissing ? l.nameRequired : null),
                ),
              ),
            ],
          ),
          if (_smartApplied && _smartFor == _name.text.trim()) ...[
            const SizedBox(height: AppSpace.xs),
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, size: 16, color: c.primaryInk),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(l.smartApplied, style: t.bodySmall?.copyWith(color: c.primaryInk)),
                ),
              ],
            ),
          ],
          if (!editing && names.isNotEmpty) ...[
            const SizedBox(height: AppSpace.sm),
            ChipLine(
              children: [
                for (final n in names)
                  ActionChip(
                    label: Text(n),
                    onPressed: () => setState(() {
                      _name.text = n;
                      _nameMissing = false;
                      final same = d.items.where((i) => i.name.toLowerCase() == n.toLowerCase()).firstOrNull;
                      if (same != null) {
                        _category = same.category;
                        _categoryTouched = true;
                        _icon = same.icon;
                      }
                    }),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpace.lg),
          _Row(
            key: const ValueKey('item-place'),
            icon: Icons.inventory_2_outlined,
            text: storage == null ? l.chooseAPlace : pathText(d.pathOf(storage.id)),
            onTap: _changePlace,
          ),
          const SizedBox(height: AppSpace.sm),
          _Row(
            key: const ValueKey('item-qty'),
            icon: Icons.tag_rounded,
            text: l.shopQty(_qty),
            onTap: () => showQtyToast(
              context,
              ToastQty(label: l.quantity, question: l.formQtyQuestion, value: _qty, max: 999, onDone: (v) => setState(() => _qty = v)),
            ),
          ),
          _Section(l.moreDetails),
          // Fixed tiles, three to a row; each opens only its own field.
          for (final row in _rowsOf3([
            ('more-due', Icons.calendar_month_rounded, l.useBy, dateText ?? l.dueNone, _chooseDue),
            (
              'more-min',
              Icons.low_priority_rounded,
              l.minQty,
              _minQty == null ? l.dueNone : l.shopQty(_minQty!),
              () => setState(() => _showMin = true),
            ),
            (
              'more-note',
              Icons.sticky_note_2_outlined,
              l.note,
              _note.text.trim().isEmpty ? l.dueNone : _note.text.trim(),
              () => setState(() => _showNote = true),
            ),
            ('more-category', categoryIcon(_category), l.category, categories[_category]!, () => _chooseCategory(categories)),
            (
              'more-valuable',
              Icons.verified_user_outlined,
              l.valuable,
              _valuable.warrantyUntil != null
                  ? DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).format(_valuable.warrantyUntil!)
                  : (_valuable.price != null ? l.won(NumberFormat.decimalPattern().format(_valuable.price)) : l.dueNone),
              _chooseValuable,
            ),
          ])) ...[
            Row(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpace.xs),
                  Expanded(
                    child: i >= row.length
                        ? const SizedBox()
                        : _MoreTile(key: ValueKey(row[i].$1), icon: row[i].$2, label: row[i].$3, value: row[i].$4, onTap: row[i].$5),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpace.xs),
          ],
          if (_showMin || _minQty != null) ...[
            const SizedBox(height: AppSpace.md),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.minQty, style: t.titleSmall),
                      FitText(l.minQtyHint, style: t.bodySmall?.copyWith(color: c.mutedFg)),
                    ],
                  ),
                ),
                if (_minQty == null)
                  TextButton(key: const ValueKey('min-qty-set'), onPressed: () => setState(() => _minQty = 1), child: Text(l.minQtySet))
                else ...[
                  QtyStepper(key: const ValueKey('min-qty'), value: _minQty!, onChanged: (v) => setState(() => _minQty = v)),
                  IconButton(tooltip: l.minQtyNone, onPressed: () => setState(() => _minQty = null), icon: const Icon(Icons.close_rounded)),
                ],
              ],
            ),
          ],
          if (_showNote || _note.text.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpace.md),
            TextField(
              key: const ValueKey('item-note'),
              controller: _note,
              minLines: 1,
              maxLines: 4,
              autofocus: _showNote && _note.text.isEmpty,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(labelText: l.note, hintText: l.noteHint),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.sm),
          child: Row(
            children: [
              if (!editing) ...[
                Expanded(
                  child: OutlinedButton(onPressed: _saveAndNext, child: Text(l.saveAndNext)),
                ),
                const SizedBox(width: AppSpace.sm),
              ],
              Expanded(
                child: FilledButton(onPressed: _saveAndClose, child: Text(l.save)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
