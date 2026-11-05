import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/home_store.dart';
import '../../data/smart_suggest.dart';
import '../../data/receipt_reader.dart';
import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/app_icons.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fairy.dart';
import '../../widgets/fit_text.dart';
import '../../widgets/header_line.dart';
import '../../widgets/sheets.dart';
import '../../widgets/chip_line.dart';

/// One line read off the receipt, as the person adjusts it.
class _Line {
  _Line(ReceiptItem item) : name = TextEditingController(text: item.name), qty = item.qty;

  final TextEditingController name;
  int qty;
  bool on = true;
}

/// A receipt photo becomes several things at once: the phone reads the text
/// (nothing is sent), rules keep the things bought, the person checks the
/// list and picks where they go.
class ReceiptScreen extends ConsumerStatefulWidget {
  const ReceiptScreen({super.key, this.storageId});

  final String? storageId;

  @override
  ConsumerState<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends ConsumerState<ReceiptScreen> {
  List<_Line>? _lines;
  bool _reading = false;

  /// The fairy tidying the list: null not yet, false working, true done.
  bool? _tidied;
  bool _nothing = false;
  String? _place;

  @override
  void initState() {
    super.initState();
    _place = widget.storageId ?? recentPlaces(ref.read(homeProvider).requireValue, limit: 1).firstOrNull;
  }

  @override
  void dispose() {
    for (final line in _lines ?? const <_Line>[]) {
      line.name.dispose();
    }
    super.dispose();
  }

  Future<void> _take(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, maxWidth: 2000);
    if (picked == null || !mounted) return;
    setState(() => _reading = true);
    final rows = await ref.read(receiptReaderProvider).read(picked.path);
    if (!mounted) return;
    final items = rows == null ? const <ReceiptItem>[] : parseReceipt(rows);
    setState(() {
      _reading = false;
      _nothing = items.isEmpty;
      _lines = [for (final i in items) _Line(i)];
    });
  }

  /// For tests and the share sheet: rows already read.
  @visibleForTesting
  void showRows(List<String> rows) => setState(() {
    final items = parseReceipt(rows);
    _nothing = items.isEmpty;
    _lines = [for (final i in items) _Line(i)];
  });

  /// Asks the fairy to judge each line (product or not, which name, which
  /// home thing it refills). Code decides from the answers: lines very
  /// unlikely to be products are unticked, likely refills take the home's
  /// name so they join that stack.
  Future<void> _tidy() async {
    final lines = _lines;
    if (lines == null || lines.isEmpty) return;
    final l = AppLocalizations.of(context);
    final homeNames = {for (final i in ref.read(homeProvider).requireValue.items) i.name};
    final asks = [
      for (final line in lines) (names: nameCandidates(line.name.text.trim()), like: similarNames(homeNames, line.name.text.trim())),
    ];
    setState(() => _tidied = false);
    final picks = await ref.read(smartSuggestProvider).receipt(asks);
    if (!mounted) return;
    if (picks == null) {
      setState(() => _tidied = null);
      showMessage(context, l.receiptTidyFailed);
      return;
    }
    setState(() {
      _tidied = true;
      for (final (i, p) in picks.indexed) {
        final line = lines[i];
        if (p.keep < 0.3) line.on = false;
        final name = p.same >= 0.7 && p.item != null ? p.item! : p.name;
        if (name.isNotEmpty) line.name.text = name;
      }
    });
  }

  Future<void> _pickPlace() async {
    final id = await pickStorage(context, title: AppLocalizations.of(context).addWhere);
    if (id != null) setState(() => _place = id);
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final place = _place;
    if (place == null) {
      showMessage(context, l.sentenceNoPlace);
      return;
    }
    final picked = [
      for (final line in _lines ?? const <_Line>[])
        if (line.on && line.name.text.trim().isNotEmpty) ParsedItem(line.name.text.trim(), line.qty),
    ];
    if (picked.isEmpty) return;
    final name = ref.read(homeProvider).requireValue.container(place)!.name;
    var off = const <String>[];
    await ref.read(homeProvider.notifier).apply((d, ctx) {
      // What was bought comes off the shopping list too.
      final r = settleToBuy(addItemsFromSentence(d, ctx, place, picked).data, {for (final p in picked) p.name: p.qty});
      off = r.value;
      return r.data;
    });
    if (!mounted) return;
    final saved = l.sentenceSaved(picked.length, name);
    showUndo(context, ref, off.isEmpty ? saved : '$saved · ${l.shopTookOff(off.length)}');
    context.canPop() ? context.pop() : context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final t = Theme.of(context).textTheme;
    final d = ref.watch(homeProvider).requireValue;
    final lines = _lines;
    final count = lines?.where((x) => x.on).length ?? 0;
    final place = _place != null && d.container(_place!) != null ? _place : null;

    return Scaffold(
      appBar: AppBar(title: Text(l.receiptTitle), actions: const [SettingsButton()]),
      body: _reading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppSpace.md),
                  Text(l.receiptReading),
                ],
              ),
            )
          : lines == null || lines.isEmpty
          ? Center(
              child: SingleChildScrollView(
                child: EmptyState(
                  pose: FairyPose.carry,
                  title: _nothing ? l.receiptNothingTitle : l.receiptTitle,
                  body: _nothing ? l.receiptNothingBody : l.receiptBody,
                  action: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton.icon(
                        key: const ValueKey('receipt-camera'),
                        onPressed: () => _take(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: Text(l.receiptTake),
                      ),
                      const SizedBox(height: AppSpace.sm),
                      OutlinedButton.icon(
                        onPressed: () => _take(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(l.chooseFromGallery),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.xs, AppSpace.lg, AppSpace.xl),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: FitText(
                        _tidied == true ? l.receiptTidied : l.receiptFound(lines.length),
                        style: t.bodySmall?.copyWith(color: _tidied == true ? c.primaryInk : c.mutedFg),
                      ),
                    ),
                    if (_tidied != true)
                      TextButton.icon(
                        key: const ValueKey('receipt-tidy'),
                        onPressed: _tidied == false ? null : _tidy,
                        icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                        label: Text(_tidied == false ? l.receiptTidying : l.receiptTidy),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
                for (final (i, line) in lines.indexed)
                  Card(
                    key: ValueKey('receipt-line-$i'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
                      child: Row(
                        children: [
                          Checkbox(value: line.on, onChanged: (v) => setState(() => line.on = v ?? false)),
                          Expanded(
                            child: TextField(
                              controller: line.name,
                              enabled: line.on,
                              decoration: const InputDecoration(
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: AppSpace.sm),
                              ),
                            ),
                          ),
                          // Compact, so the name keeps the width.
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: l.decrease,
                            onPressed: line.qty > 1 ? () => setState(() => line.qty--) : null,
                            icon: const Icon(Icons.remove_rounded, size: 20),
                          ),
                          SizedBox(
                            width: 28,
                            child: Text('${line.qty}', textAlign: TextAlign.center, style: AppType.label),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: l.increase,
                            onPressed: () => setState(() => line.qty++),
                            icon: const Icon(Icons.add_rounded, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpace.lg),
                Text(l.addWhere, style: t.titleSmall),
                const SizedBox(height: AppSpace.sm),
                ChipLine(
                  children: [
                    if (place != null)
                      ChoiceChip(
                        avatar: storageGlyph(d.container(place)!, size: 18, color: c.primaryInk),
                        label: Text(pathText(d.pathOf(place))),
                        selected: true,
                        showCheckmark: false,
                        onSelected: (_) {},
                      ),
                    ActionChip(
                      avatar: Icon(Icons.travel_explore_rounded, size: 18, color: c.mutedFg),
                      label: Text(l.sentencePickOther),
                      onPressed: _pickPlace,
                    ),
                  ],
                ),
              ],
            ),
      bottomNavigationBar: lines == null || lines.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.sm),
                child: FilledButton.icon(
                  key: const ValueKey('receipt-save'),
                  onPressed: count == 0 ? null : _save,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l.sentenceSave(count)),
                ),
              ),
            ),
    );
  }
}
