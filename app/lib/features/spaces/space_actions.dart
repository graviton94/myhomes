import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../data/home_store.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/sheets.dart';

/// Asks for a room name, creates the space and opens it.
Future<void> addSpaceFlow(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  final name = await askText(context, title: l.addSpace, label: l.spaceNameHint);
  if (name == null || !context.mounted) return;
  final space = await ref.read(homeProvider.notifier).apply<Space>((d, ctx) => addSpace(d, ctx, name));
  if (space != null && context.mounted) context.push('/space/${space.id}');
}

/// Name + grid size (rows x cols). Returns null when cancelled.
Future<({String name, int rows, int cols})?> askStorage(
  BuildContext context, {
  required String title,
  String name = '',
  int rows = 3,
  int cols = 4,
}) {
  return showDialog<({String name, int rows, int cols})>(
    context: context,
    builder: (context) => _StorageDialog(title: title, name: name, rows: rows, cols: cols),
  );
}

class _StorageDialog extends StatefulWidget {
  const _StorageDialog({required this.title, required this.name, required this.rows, required this.cols});

  final String title;
  final String name;
  final int rows;
  final int cols;

  @override
  State<_StorageDialog> createState() => _StorageDialogState();
}

class _StorageDialogState extends State<_StorageDialog> {
  late final _name = TextEditingController(text: widget.name);
  late int rows = widget.rows;
  late int cols = widget.cols;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final v = _name.text.trim();
    if (v.isEmpty) return;
    Navigator.pop(context, (name: v, rows: rows, cols: cols));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget sizeRow(String label, int value, int max, ValueChanged<int> set) => Row(
          children: [
            Expanded(child: Text(label)),
            QtyStepper(value: value, min: 1, max: max, onChanged: (v) => setState(() => set(v))),
          ],
        );
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: widget.name.isEmpty,
            decoration: InputDecoration(labelText: l.storageNameHint),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpace.lg),
          sizeRow(l.gridRows, rows, 12, (v) => rows = v),
          const SizedBox(height: AppSpace.sm),
          sizeRow(l.gridCols, cols, 8, (v) => cols = v),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(onPressed: _submit, child: Text(l.save)),
      ],
    );
  }
}
