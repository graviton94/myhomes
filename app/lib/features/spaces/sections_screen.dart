import 'package:flutter/material.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/fit_text.dart';

/// "칸 · 서랍": a furniture's sections one per row, top to bottom, each with
/// rename and remove, and "+ 칸 추가" under them (user request: no list
/// typed with commas). Full screen, so the keyboard has room (CLAUDE.md).
/// [counts] are how many things each existing section holds.
Future<List<SectionRow>?> editSections(BuildContext context, {required String furniture, required List<SectionRow> rows, Map<String, int> counts = const {}}) =>
    Navigator.of(context, rootNavigator: true).push<List<SectionRow>>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => SectionsScreen(furniture: furniture, rows: rows, counts: counts),
      ),
    );

class SectionsScreen extends StatefulWidget {
  const SectionsScreen({super.key, required this.furniture, required this.rows, this.counts = const {}});

  final String furniture;
  final List<SectionRow> rows;
  final Map<String, int> counts;

  @override
  State<SectionsScreen> createState() => _SectionsScreenState();
}

class _Row {
  _Row(this.id, this.name);

  final String? id;
  String name;
  final key = UniqueKey();
}

class _SectionsScreenState extends State<SectionsScreen> {
  late final _rows = [for (final r in widget.rows) _Row(r.id, r.name)];
  _Row? _editing;
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _edit(_Row r) {
    _finish();
    setState(() {
      _editing = r;
      _text.text = r.name;
      _text.selection = TextSelection(baseOffset: 0, extentOffset: r.name.length);
    });
  }

  /// Ends renaming; an empty name puts the old one back.
  void _finish() {
    final r = _editing;
    if (r == null) return;
    final name = _text.text.trim();
    setState(() {
      if (name.isNotEmpty) r.name = name;
      _editing = null;
    });
  }

  void _add() {
    final r = _Row(null, AppLocalizations.of(context).sectionNumbered(_rows.length + 1));
    setState(() => _rows.add(r));
    _edit(r);
  }

  void _save() {
    _finish();
    Navigator.pop(context, [for (final r in _rows) (id: r.id, name: r.name)]);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close_rounded), tooltip: l.cancel, onPressed: () => Navigator.pop(context)),
        title: OneLine([l.sectionsTitle], style: t.titleLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.md, 0, AppSpace.md, AppSpace.xl),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.xs, 0, AppSpace.xs, AppSpace.sm),
            child: OneLine([l.sectionsOrder(widget.furniture), l.sectionsOrderShort], style: AppType.caption.copyWith(color: c.mutedFg)),
          ),
          for (final (i, r) in _rows.indexed)
            Container(
              key: ValueKey('section-row-$i'),
              margin: const EdgeInsets.only(bottom: AppSpace.sm),
              padding: const EdgeInsets.fromLTRB(AppSpace.sm, AppSpace.xs, AppSpace.xs, AppSpace.xs),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: identical(_editing, r) ? c.primary : c.border, width: 1.5),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: c.accentSoft,
                    child: Text('${i + 1}', style: AppType.label.copyWith(fontSize: 12, color: c.accentInk)),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: identical(_editing, r)
                        ? TextField(
                            key: ValueKey('section-field-$i'),
                            controller: _text,
                            autofocus: true,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _finish(),
                            decoration: const InputDecoration(isDense: true),
                          )
                        : GestureDetector(
                            onTap: () => _edit(r),
                            child: Row(
                              children: [
                                Flexible(child: OneLine([r.name], style: AppType.body)),
                                if ((widget.counts[r.id] ?? 0) > 0) ...[
                                  const SizedBox(width: AppSpace.xs),
                                  Text(l.itemsCount(widget.counts[r.id]!), style: AppType.caption.copyWith(color: c.mutedFg)),
                                ],
                              ],
                            ),
                          ),
                  ),
                  if (identical(_editing, r))
                    IconButton(
                      key: ValueKey('section-done-$i'),
                      tooltip: l.save,
                      icon: Icon(Icons.check_rounded, color: c.primary),
                      onPressed: _finish,
                    )
                  else ...[
                    IconButton(
                      key: ValueKey('section-edit-$i'),
                      tooltip: l.edit,
                      icon: Icon(Icons.edit_outlined, color: c.mutedFg, size: 20),
                      onPressed: () => _edit(r),
                    ),
                    if (_rows.length > 1)
                      IconButton(
                        key: ValueKey('section-remove-$i'),
                        tooltip: l.delete,
                        icon: Icon(Icons.delete_outline_rounded, color: c.mutedFg, size: 20),
                        onPressed: () => setState(() => _rows.remove(r)),
                      ),
                  ],
                ],
              ),
            ),
          OutlinedButton.icon(key: const ValueKey('section-add'), onPressed: _add, icon: const Icon(Icons.add_rounded), label: Text(l.sectionAdd)),
          if (_rows.any((r) => r.id != null) && widget.counts.values.any((n) => n > 0)) ...[
            const SizedBox(height: AppSpace.sm),
            FitText(l.sectionsRemoveNote, style: AppType.caption.copyWith(color: c.mutedFg)),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.sm),
          child: FilledButton(key: const ValueKey('sections-save'), onPressed: _save, child: Text(l.save)),
        ),
      ),
    );
  }
}
