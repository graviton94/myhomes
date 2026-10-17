import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../data/home_store.dart';
import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/dday_badge.dart';
import '../../widgets/fairy.dart';
import '../../widgets/app_icons.dart';
import '../../widgets/inventory_slot.dart';
import '../../widgets/sheets.dart';

Future<void> showFairyChat(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => const FractionallySizedBox(heightFactor: 0.82, child: FairyChatSheet()),
);

/// Strips question words so "건전지 어디 있어?" / "where are the batteries"
/// become a search term. Phase 1 answers from the on-device search; the AI
/// model plugs in here later without changing the screen.
String searchTermOf(String question) {
  var q = question.trim().toLowerCase();
  for (final p in [
    RegExp(r'^(where(\s+is|\s+are|’s|\x27s)?|find|look\s+for)\s+(the\s+|my\s+)?'),
    RegExp(r'\s*(은|는|이|가)?\s*(어디\s*(에)?\s*(있어|있지|있나요|있어요|뒀더라|둬어)?|찾아\s*(줘|주세요)?)\s*\??$'),
    RegExp(r'[?？!.]+$'),
  ]) {
    q = q.replaceAll(p, '');
  }
  return q.trim();
}

class _Msg {
  const _Msg.fairy(this.text, {this.found = const [], this.dated = const []}) : mine = false;
  const _Msg.mine(this.text) : mine = true, found = const [], dated = const [];

  final bool mine;
  final String text;
  final List<Found> found;
  final List<(Item, ExpiryStatus)> dated;
}

class FairyChatSheet extends ConsumerStatefulWidget {
  const FairyChatSheet({super.key});

  @override
  ConsumerState<FairyChatSheet> createState() => _FairyChatSheetState();
}

class _FairyChatSheetState extends ConsumerState<FairyChatSheet> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _msgs = <_Msg>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_msgs.isEmpty) {
      final l = AppLocalizations.of(context);
      final d = ref.read(homeProvider).requireValue;
      final urgent = byExpiry(d, DateTime.now()).where((e) => e.$2.isUrgent).length;
      _msgs.add(_Msg.fairy(urgent > 0 ? l.fairyGreetingUrgent(urgent) : l.fairyGreeting));
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _say(_Msg mine, _Msg reply) {
    setState(() => _msgs.addAll([mine, reply]));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
      }
    });
  }

  void _ask(String text) {
    final l = AppLocalizations.of(context);
    final d = ref.read(homeProvider).requireValue;
    final term = searchTermOf(text);
    if (term.isEmpty) return;
    final found = searchItems(d, term);
    _input.clear();
    _say(
      _Msg.mine(text.trim()),
      found.isEmpty ? _Msg.fairy(l.fairyNotFound(term)) : _Msg.fairy(l.fairyFoundCount(found.length), found: found),
    );
  }

  void _thisWeek() {
    final l = AppLocalizations.of(context);
    final d = ref.read(homeProvider).requireValue;
    final list = byExpiry(d, DateTime.now()).where((e) => e.$2.daysLeft <= 7).toList();
    _say(
      _Msg.mine(l.chipThisWeek),
      list.isEmpty ? _Msg.fairy(l.fairyNothingThisWeek) : _Msg.fairy(l.fairyThisWeek(list.length), dated: list),
    );
  }

  void _runningLow() {
    final l = AppLocalizations.of(context);
    final d = ref.read(homeProvider).requireValue;
    final low = d.items.where((i) => i.qty <= 1 && i.category != ItemCategory.food).toList();
    _say(
      _Msg.mine(l.chipRunningLow),
      low.isEmpty
          ? _Msg.fairy(l.fairyNothingLow)
          : _Msg.fairy(l.fairyLow(low.length), found: [for (final i in low) Found(i, d.pathOf(i.containerId))]),
    );
  }

  void _howTo() {
    final l = AppLocalizations.of(context);
    _say(_Msg.mine(l.chipHowTo), _Msg.fairy(l.fairyHowTo));
  }

  void _open(String storageId) {
    Navigator.of(context).pop();
    context.push('/storage/$storageId');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.xs, AppSpace.sm),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: c.primarySoft,
                child: ClipOval(
                  child: OverflowBox(
                    maxWidth: 70,
                    maxHeight: 80,
                    alignment: const Alignment(0.05, -0.2),
                    child: Fairy(FairyPose.hello, height: 80),
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.fairyName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 19)),
                    Text(l.fairySubtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              IconButton(tooltip: l.close, onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
            ],
          ),
        ),
        Divider(color: c.border),
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.all(AppSpace.lg),
            children: [for (final m in _msgs) _Bubble(m, onOpen: _open)],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
          child: Row(
            children: [
              ActionChip(label: Text(l.chipThisWeek), onPressed: _thisWeek),
              const SizedBox(width: AppSpace.sm),
              ActionChip(label: Text(l.chipRunningLow), onPressed: _runningLow),
              const SizedBox(width: AppSpace.sm),
              ActionChip(label: Text(l.chipHowTo), onPressed: _howTo),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.sm, AppSpace.md + MediaQuery.viewInsetsOf(context).bottom),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _ask,
                  decoration: InputDecoration(hintText: l.askFairyHint),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              IconButton.filled(tooltip: l.send, onPressed: () => _ask(_input.text), icon: const Icon(Icons.arrow_upward_rounded)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bubble extends ConsumerWidget {
  const _Bubble(this.m, {required this.onOpen});

  final _Msg m;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final t = Theme.of(context).textTheme;
    final d = ref.watch(homeProvider).requireValue;
    const r = Radius.circular(AppRadius.lg);
    final mine = m.mine;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpace.md),
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.md + 2, vertical: AppSpace.sm + 2),
        decoration: BoxDecoration(
          color: mine ? c.primary : c.card,
          border: mine ? null : Border.all(color: c.border),
          borderRadius: BorderRadius.only(
            topLeft: r,
            topRight: r,
            bottomLeft: mine ? r : const Radius.circular(4),
            bottomRight: mine ? const Radius.circular(4) : r,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m.text, style: t.bodyMedium?.copyWith(color: mine ? c.onPrimary : c.fg)),
            for (final f in m.found.take(6))
              _ResultRow(
                thumb: ItemThumb(category: f.item.category, photoPath: f.item.photoPath, icon: iconFor(f.item.icon), size: 36),
                title: '${f.item.name} · ${l.qtyShort(f.item.qty)}',
                subtitle: pathText(f.path),
                action: l.goSee,
                onTap: () => onOpen(f.item.containerId),
              ),
            for (final (item, status) in m.dated.take(8))
              _ResultRow(
                thumb: ItemThumb(category: item.category, photoPath: item.photoPath, icon: iconFor(item.icon), size: 36),
                title: item.name,
                subtitle: pathText(d.pathOf(item.containerId)),
                trailing: DdayBadge(status),
                onTap: () => onOpen(item.containerId),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.thumb, required this.title, required this.subtitle, required this.onTap, this.action, this.trailing});

  final Widget thumb;
  final String title;
  final String subtitle;
  final String? action;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSize.touch),
          child: Row(
            children: [
              thumb,
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: t.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(subtitle, style: t.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              ?trailing,
              if (action != null)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpace.xs),
                  child: Text(action!, style: t.labelMedium?.copyWith(color: HfColors.of(context).link)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
