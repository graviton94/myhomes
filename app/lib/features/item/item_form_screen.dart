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
import '../../settings/settings.dart';
import '../../widgets/header_line.dart';
import '../../widgets/icon_chooser.dart';
import '../../widgets/inventory_slot.dart';
import '../../widgets/photo_picker.dart';
import '../../widgets/sheets.dart';

/// Add a new item (with [storageId] and optional [slot]) or edit [itemId].
class ItemFormScreen extends ConsumerStatefulWidget {
  const ItemFormScreen({super.key, this.storageId, this.slot, this.itemId});

  final String? storageId;
  final int? slot;
  final String? itemId;

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
  DateTime? _expires;
  _Due _due = _Due.none;
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
    final item = _editing;
    if (item != null) {
      _name.text = item.name;
      _note.text = item.note;
      _category = item.category;
      _qty = item.qty;
      _minQty = item.minQty;
      _expires = item.expiresOn;
      _due = item.expiresOn == null ? _Due.none : _Due.custom;
      _photo = item.photoPath;
      _icon = item.icon;
      _storageId = item.containerId;
      _categoryTouched = true;
    }
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
    if (name.length < 2) return;
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
      _due = due;
      _expires = date;
    });
  }

  Future<void> _pickPhoto() async {
    final r = await choosePhoto(context, ref, hasPhoto: _photo != null);
    if (r != null && mounted) setState(() => _photo = r.path);
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
    final names = recentNames(d).where((n) => n.toLowerCase() != _name.text.trim().toLowerCase()).take(6).toList();
    final storage = _storageId == null ? null : d.container(_storageId!);
    final settings = ref.watch(settingsProvider);
    final expiryOn = settings.expiryOn, lowStockOn = settings.lowStockOn;
    final dateText = _expires == null ? null : DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).format(_expires!);

    final categories = {
      ItemCategory.food: l.categoryFood,
      ItemCategory.household: l.categoryHousehold,
      ItemCategory.tools: l.categoryTools,
      ItemCategory.medicine: l.categoryMedicine,
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
          PhotoBox(photoPath: _photo, onTap: _pickPhoto, height: 168, label: l.addPhotoOptional),
          const SizedBox(height: AppSpace.lg),
          TextField(
            controller: _name,
            autofocus: !editing,
            textInputAction: TextInputAction.next,
            onChanged: _onNameChanged,
            decoration: InputDecoration(labelText: l.itemName, errorText: _nameMissing ? l.nameRequired : null),
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
            _ChipRow(
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
          _Section(l.icon),
          IconChooser(
            name: _name.text,
            kind: IconKind.item,
            category: _category,
            picked: _icon,
            smart: _smartIconNow,
            onPicked: (k) => setState(() => _icon = k),
          ),
          _Section(l.category),
          Row(
            children: [
              for (final (i, e) in categories.entries.indexed) ...[
                if (i > 0) const SizedBox(width: AppSpace.xs),
                Expanded(
                  child: _CategoryTile(
                    category: e.key,
                    label: e.value,
                    selected: _category == e.key,
                    onTap: () => setState(() {
                      _category = e.key;
                      _categoryTouched = true;
                    }),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          Row(
            children: [
              Expanded(child: Text(l.quantity, style: t.titleSmall)),
              QtyStepper(value: _qty, onChanged: (v) => setState(() => _qty = v)),
            ],
          ),
          if (lowStockOn) ...[
            const SizedBox(height: AppSpace.md),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.minQty, style: t.titleSmall),
                      Text(l.minQtyHint, style: t.bodySmall?.copyWith(color: c.mutedFg)),
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
          // Shown while the extra is on, and for things that already have a date.
          if (expiryOn || _expires != null) ...[
            _Section(l.useBy),
            _ChipRow(
              children: [
                ChoiceChip(label: Text(l.dueNone), selected: _due == _Due.none, onSelected: (_) => _setDue(_Due.none)),
                ChoiceChip(label: Text(l.dueDays(3)), selected: _due == _Due.d3, onSelected: (_) => _setDue(_Due.d3)),
                ChoiceChip(label: Text(l.dueWeek), selected: _due == _Due.w1, onSelected: (_) => _setDue(_Due.w1)),
                ChoiceChip(label: Text(l.dueMonth), selected: _due == _Due.m1, onSelected: (_) => _setDue(_Due.m1)),
                ChoiceChip(
                  avatar: const Icon(Icons.event_rounded, size: 18),
                  label: Text(l.duePick),
                  selected: _due == _Due.custom,
                  onSelected: (_) => _setDue(_Due.custom),
                ),
              ],
            ),
            if (dateText != null) ...[
              const SizedBox(height: AppSpace.xs),
              Text(l.useByDate(dateText), style: t.bodySmall?.copyWith(color: c.mutedFg)),
            ],
          ],
          _Section(l.place),
          Material(
            color: c.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: BorderSide(color: c.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _changePlace,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.md),
                child: Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, color: c.primaryInk),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(storage == null ? l.chooseAPlace : pathText(d.pathOf(storage.id)), style: t.bodyLarge),
                          if (storage != null) Text(storage.code, style: AppType.code.copyWith(color: c.mutedFg)),
                        ],
                      ),
                    ),
                    Text(l.change, style: t.labelLarge?.copyWith(color: c.link)),
                  ],
                ),
              ),
            ),
          ),
          _Section(l.note),
          TextField(
            controller: _note,
            minLines: 1,
            maxLines: 4,
            decoration: InputDecoration(hintText: l.noteHint),
          ),
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

/// One line of chips that scrolls sideways instead of wrapping.
class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    clipBehavior: Clip.none,
    child: Row(
      children: [
        for (final (i, w) in children.indexed) ...[if (i > 0) const SizedBox(width: AppSpace.sm), w],
      ],
    ),
  );
}

/// Icon over label; five of these share one row.
class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.label, required this.selected, required this.onTap});

  final ItemCategory category;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = HfColors.of(context);
    final (bg, ink) = categoryColors(context, category);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? bg : c.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: selected ? c.primary : c.border, width: selected ? 2 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 68,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(categoryIcon(category), color: selected ? ink : c.mutedFg, size: 24),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: selected ? ink : c.fg, fontWeight: FontWeight.w700),
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

class _Section extends StatelessWidget {
  const _Section(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpace.lg, bottom: AppSpace.sm),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );
}
