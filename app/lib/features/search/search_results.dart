import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../data/home_store.dart';
import '../../data/smart_suggest.dart';
import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/fairy.dart';
import '../../widgets/inventory_slot.dart';
import '../../widgets/open_item.dart';
import '../../widgets/sheets.dart';

/// Strips question words so "건전지 어디 있어?" / "where are the batteries"
/// become a search term.
String searchTermOf(String question) {
  var q = question.trim().toLowerCase();
  for (final p in [
    RegExp(r'^(where(\s+is|\s+are|’s|\x27s)?|find|look\s+for)\s+(the\s+|my\s+)?'),
    RegExp(r'\s*(은|는|이|가)?\s*(어디\s*(에)?\s*(있어|있지|있나요|있어요|뒀더라|둬어|있니)?|어딨어|찾아\s*(줘|주세요)?)\s*\??$'),
    RegExp(r'[?？!.]+$'),
  ]) {
    q = q.replaceAll(p, '');
  }
  return q.trim();
}

/// What Home shows under its search box while something is typed: the
/// fairy's one-line answer, then the matches. Names, Korean initials and
/// location codes are found on the phone; only when they find nothing does
/// the fairy's server get asked what the words mean ("열 날 때 먹는 약" →
/// 타이레놀), after typing pauses.
class SearchResults extends ConsumerStatefulWidget {
  const SearchResults({super.key, required this.query});

  final String query;

  /// Typing pause before the server is asked.
  static const askAfter = Duration(milliseconds: 800);

  @override
  ConsumerState<SearchResults> createState() => _SearchResultsState();
}

class _SearchResultsState extends ConsumerState<SearchResults> {
  Timer? _debounce;
  String? _askedFor;
  Pick? _smart;
  bool _asking = false;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(SearchResults old) {
    super.didUpdateWidget(old);
    if (old.query != widget.query) _schedule();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _schedule() {
    _debounce?.cancel();
    final term = searchTermOf(widget.query);
    final d = ref.read(homeProvider).requireValue;
    if (term.length < 2 || searchItems(d, term).isNotEmpty) return;
    _debounce = Timer(SearchResults.askAfter, () => _ask(widget.query.trim()));
  }

  Future<void> _ask(String q) async {
    final d = ref.read(homeProvider).requireValue;
    final names = {for (final i in d.items) i.name}.take(400).toList();
    setState(() => _asking = true);
    final r = await ref.read(smartSuggestProvider).find(q, names);
    if (!mounted) return;
    setState(() {
      _asking = false;
      if (widget.query.trim() == q) {
        _askedFor = q;
        _smart = r;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    return ValueListenableBuilder<bool>(
      valueListenable: ref.watch(smartSuggestProvider).outOfQuota,
      builder: (context, out, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Past today's AI allowance: say so, and offer the subscription.
          if (out)
            Container(
              key: const ValueKey('ai-quota'),
              margin: const EdgeInsets.only(top: AppSpace.md),
              padding: const EdgeInsets.all(AppSpace.md),
              decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Text('${l.aiToWordSearch}\n${l.aiQuotaSubscribe}', style: AppType.caption.copyWith(color: c.accentInk)),
            ),
          _results(context),
        ],
      ),
    );
  }

  Widget _results(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = ref.watch(homeProvider).requireValue;
    final q = widget.query.trim();
    final term = searchTermOf(q);
    final found = searchItems(d, term);

    if (found.isNotEmpty) {
      return _List(fairy: l.fairyFoundCount(found.length), found: found, d: d);
    }
    final pick = _askedFor == q ? _smart : null;
    final level = pick == null ? SuggestLevel.ignore : suggestLevel(pick.confidence);
    if (pick != null && level != SuggestLevel.ignore) {
      final names = level == SuggestLevel.auto
          ? [pick.choice]
          : [
              for (final (name, p) in pick.top)
                if (suggestLevel(p) != SuggestLevel.ignore || name == pick.choice) name,
            ];
      final hits = [
        for (final name in names.take(3))
          for (final i in d.items.where((i) => i.name == name)) Found(i, d.pathOf(i.containerId)),
      ];
      if (hits.isNotEmpty) {
        return _List(fairy: level == SuggestLevel.auto ? l.smartFound : l.smartMaybe, found: hits, d: d, smart: true);
      }
    }
    return _FairySays(
      _asking ? l.searchThinking : l.fairyNotFound(term.isEmpty ? q : term),
      pose: _asking ? FairyPose.found : FairyPose.worry,
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.fairy, required this.found, required this.d, this.smart = false});

  final String fairy;
  final List<Found> found;
  final HomeData d;
  final bool smart;

  @override
  Widget build(BuildContext context) {
    final c = HfColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FairySays(fairy, pose: FairyPose.found, smart: smart),
        const SizedBox(height: AppSpace.sm),
        for (final f in found)
          Card(
            margin: const EdgeInsets.only(bottom: AppSpace.sm),
            child: ListTile(
              leading: ItemThumb(category: f.item.category, photoPath: f.item.photoPath, iconKey: f.item.icon),
              title: Text(f.item.qty > 1 ? '${f.item.name} ×${f.item.qty}' : f.item.name),
              subtitle: Text(pathText(f.path), maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Text(d.container(f.item.containerId)?.code ?? '', style: AppType.code.copyWith(color: c.mutedFg)),
              onTap: () => openItem(context, d, f.item),
            ),
          ),
      ],
    );
  }
}

/// The fairy's one line under the search box.
class _FairySays extends StatelessWidget {
  const _FairySays(this.text, {required this.pose, this.smart = false});

  final String text;
  final FairyPose pose;
  final bool smart;

  @override
  Widget build(BuildContext context) {
    final c = HfColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Fairy(pose, height: 52),
          const SizedBox(width: AppSpace.sm),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 10),
              decoration: BoxDecoration(
                color: smart ? c.primarySoft : c.card,
                border: Border.all(color: smart ? c.primarySoft : c.border),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.md),
                  topRight: Radius.circular(AppRadius.md),
                  bottomRight: Radius.circular(AppRadius.md),
                  bottomLeft: Radius.circular(4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (smart) ...[Icon(Icons.auto_awesome_rounded, size: 16, color: c.primaryInk), const SizedBox(width: 6)],
                  Flexible(
                    child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: smart ? c.primaryInk : null)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
