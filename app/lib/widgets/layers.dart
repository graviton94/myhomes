// Layers above the screen, so the screen itself stays simple: a question
// sheet, a toast with its own actions (and a − + inside), and a tip shown once.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design/theme.dart';
import '../design/tokens.g.dart';
import '../l10n/app_localizations.dart';
import '../settings/settings.dart';
import 'fit_text.dart';
import 'hf_icons.g.dart';
import 'sheets.dart';

/// One answer in [askQuestion]. The first answer is drawn as the main one.
class Answer<T> {
  const Answer(this.value, this.label);

  final T value;
  final String label;
}

/// A short question in a bottom sheet ("가위는 다 사용했나요?") with one
/// full-width button per answer. Returns the answer, or null when dismissed.
Future<T?> askQuestion<T>(BuildContext context, {required String title, String? detail, required List<Answer<T>> answers}) {
  return showModalBottomSheet<T>(
    context: context,
    builder: (context) {
      final t = Theme.of(context).textTheme;
      final c = HfColors.of(context);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetHeader(title),
              if (detail != null) ...[FitText(detail, style: t.bodySmall?.copyWith(color: c.mutedFg)), const SizedBox(height: AppSpace.md)],
              for (final (i, a) in answers.indexed) ...[
                if (i > 0) const SizedBox(height: AppSpace.sm),
                i == 0
                    ? FilledButton(key: ValueKey('answer-$i'), onPressed: () => Navigator.pop(context, a.value), child: Text(a.label))
                    : OutlinedButton(key: ValueKey('answer-$i'), onPressed: () => Navigator.pop(context, a.value), child: Text(a.label)),
              ],
            ],
          ),
        ),
      );
    },
  );
}

/// A button in an [showActionToast].
class ToastAction {
  const ToastAction(this.label, this.onPressed);

  final String label;
  final VoidCallback onPressed;
}

/// The − + a toast can open in place ("두부 몇 모 샀어요?").
class ToastQty {
  const ToastQty({
    required this.label,
    required this.question,
    required this.value,
    this.min = 1,
    required this.max,
    this.note,
    required this.onDone,
  });

  /// The button that opens it ("수량").
  final String label;
  final String question;
  final int value;
  final int min;
  final int max;

  /// A line under the stepper for the chosen value ("남은 1모는 장보기에 둬요").
  final String? Function(int value)? note;
  final ValueChanged<int> onDone;
}

/// A toast after something was done, with its own buttons: [qty] first (it
/// opens a − + inside the toast), then [actions] (넣을 곳, 되돌리기 ...).
void showActionToast(BuildContext context, {required String message, ToastQty? qty, List<ToastAction> actions = const []}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 6),
        content: _ToastBody(
          message: message,
          buttons: [
            if (qty != null)
              ToastAction(qty.label, () {
                messenger
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      duration: const Duration(minutes: 1),
                      content: _QtyToast(qty: qty, messenger: messenger),
                    ),
                  );
              }),
            ...actions.map(
              (a) => ToastAction(a.label, () {
                messenger.hideCurrentSnackBar();
                a.onPressed();
              }),
            ),
          ],
        ),
      ),
    );
}

class _ToastBody extends StatelessWidget {
  const _ToastBody({required this.message, required this.buttons});

  final String message;
  final List<ToastAction> buttons;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).snackBarTheme.actionTextColor ?? Theme.of(context).colorScheme.inversePrimary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(message),
        if (buttons.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              for (final b in buttons)
                TextButton(
                  key: ValueKey('toast-${b.label}'),
                  style: TextButton.styleFrom(foregroundColor: ink, visualDensity: VisualDensity.compact),
                  onPressed: b.onPressed,
                  child: Text(b.label),
                ),
            ],
          ),
      ],
    );
  }
}

class _QtyToast extends StatefulWidget {
  const _QtyToast({required this.qty, required this.messenger});

  final ToastQty qty;
  final ScaffoldMessengerState messenger;

  @override
  State<_QtyToast> createState() => _QtyToastState();
}

class _QtyToastState extends State<_QtyToast> {
  late int value = widget.qty.value.clamp(widget.qty.min, widget.qty.max);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final q = widget.qty;
    final note = q.note?.call(value);
    final onToast = Theme.of(context).snackBarTheme.contentTextStyle?.color ?? Colors.white;
    final ink = Theme.of(context).snackBarTheme.actionTextColor ?? Theme.of(context).colorScheme.inversePrimary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(q.question),
        const SizedBox(height: AppSpace.xs),
        Row(
          children: [
            IconButton(
              key: const ValueKey('toast-minus'),
              color: onToast,
              disabledColor: onToast.withValues(alpha: 0.3),
              onPressed: value > q.min ? () => setState(() => value--) : null,
              icon: const Icon(Icons.remove_rounded),
            ),
            Text(
              '$value',
              key: const ValueKey('toast-qty'),
              style: TextStyle(color: onToast, fontSize: 20, fontWeight: FontWeight.w700),
            ),
            IconButton(
              key: const ValueKey('toast-plus'),
              color: onToast,
              disabledColor: onToast.withValues(alpha: 0.3),
              onPressed: value < q.max ? () => setState(() => value++) : null,
              icon: const Icon(Icons.add_rounded),
            ),
            const Spacer(),
            TextButton(
              key: const ValueKey('toast-done'),
              style: TextButton.styleFrom(foregroundColor: ink),
              onPressed: () {
                widget.messenger.hideCurrentSnackBar();
                q.onDone(value);
              },
              child: Text(l.choose),
            ),
          ],
        ),
        if (note != null) Text(note, style: TextStyle(color: onToast.withValues(alpha: 0.75), fontSize: 13)),
      ],
    );
  }
}

/// A tip shown until the person closes it, once per [id] ("tip.storage").
class OnceTip extends ConsumerStatefulWidget {
  const OnceTip({super.key, required this.id, required this.text});

  final String id;
  final String text;

  @override
  ConsumerState<OnceTip> createState() => _OnceTipState();
}

class _OnceTipState extends ConsumerState<OnceTip> {
  String get _key => 'tip.${widget.id}';

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(prefsProvider);
    if (prefs.getBool(_key) ?? false) return const SizedBox.shrink();
    final c = HfColors.of(context);
    final t = Theme.of(context).textTheme;
    return Container(
      key: ValueKey('tip-${widget.id}'),
      margin: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      padding: const EdgeInsets.only(left: AppSpace.md),
      decoration: BoxDecoration(color: c.secondarySoft, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Row(
        children: [
          Icon(HfIcons.lightbulb, size: 16, color: c.secondaryInk),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: FitText(widget.text, style: t.bodySmall?.copyWith(color: c.secondaryInk)),
          ),
          IconButton(
            tooltip: AppLocalizations.of(context).close,
            onPressed: () async {
              await prefs.setBool(_key, true);
              if (mounted) setState(() {});
            },
            icon: Icon(Icons.close_rounded, size: 18, color: c.secondaryInk),
          ),
        ],
      ),
    );
  }
}
