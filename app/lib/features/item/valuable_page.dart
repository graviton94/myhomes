import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/photo_picker.dart';

/// What the valuable page hands back.
typedef Valuable = ({DateTime? warrantyUntil, int? price, String? proofPath});

/// "보증 · 영수증": the warranty's last day, the price and a photo of the
/// receipt or warranty card. Its own screen, so the number keyboard has room.
Future<Valuable?> editValuable(BuildContext context, Valuable now) => Navigator.of(
  context,
  rootNavigator: true,
).push<Valuable>(MaterialPageRoute(fullscreenDialog: true, builder: (_) => _ValuablePage(now)));

class _ValuablePage extends ConsumerStatefulWidget {
  const _ValuablePage(this.now);

  final Valuable now;

  @override
  ConsumerState<_ValuablePage> createState() => _ValuablePageState();
}

class _ValuablePageState extends ConsumerState<_ValuablePage> {
  late DateTime? _until = widget.now.warrantyUntil;
  late String? _proof = widget.now.proofPath;
  late final _price = TextEditingController(text: widget.now.price?.toString() ?? '');

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  Future<void> _pickDate() async {
    final t = _today;
    final d = await showDatePicker(
      context: context,
      initialDate: _until ?? DateTime(t.year + 1, t.month, t.day),
      firstDate: DateTime(t.year - 5),
      lastDate: DateTime(t.year + 15),
    );
    if (d != null) setState(() => _until = d);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final today = _today;
    // Four fixed choices: no sideways scrolling.
    final choices = [
      (l.warranty1y, () => setState(() => _until = DateTime(today.year + 1, today.month, today.day))),
      (l.warranty2y, () => setState(() => _until = DateTime(today.year + 2, today.month, today.day))),
      (l.duePick, _pickDate),
      (l.dueNone, () => setState(() => _until = null)),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.valuableTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.lg),
        children: [
          Text(l.warrantyUntil, style: t.titleSmall),
          const SizedBox(height: AppSpace.xs),
          Text(
            _until == null ? l.dueNone : DateFormat.yMMMd(locale).format(_until!),
            key: const ValueKey('warranty-date'),
            style: t.bodyLarge,
          ),
          const SizedBox(height: AppSpace.sm),
          Row(
            children: [
              for (final (i, (label, onTap)) in choices.indexed) ...[
                if (i > 0) const SizedBox(width: AppSpace.xs),
                Expanded(
                  child: OutlinedButton(
                    key: ValueKey('warranty-$i'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
                    onPressed: onTap,
                    child: FittedBox(child: Text(label)),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          TextField(
            key: const ValueKey('valuable-price'),
            controller: _price,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: l.price, suffixText: l.priceHint),
          ),
          const SizedBox(height: AppSpace.lg),
          Text(l.proof, style: t.titleSmall),
          const SizedBox(height: AppSpace.sm),
          PhotoBox(
            photoPath: _proof,
            height: 160,
            label: l.proofAdd,
            onTap: () async {
              final r = await choosePhoto(context, ref, hasPhoto: _proof != null, keepLarge: true);
              if (r != null && mounted) setState(() => _proof = r.path);
            },
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.sm + MediaQuery.viewInsetsOf(context).bottom),
          child: FilledButton(
            key: const ValueKey('valuable-done'),
            onPressed: () => Navigator.pop(context, (warrantyUntil: _until, price: int.tryParse(_price.text.trim()), proofPath: _proof)),
            child: Text(l.done),
          ),
        ),
      ),
    );
  }
}
