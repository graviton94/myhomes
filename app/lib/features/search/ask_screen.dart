import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../data/fairy_tally.dart';
import '../../data/home_store.dart';
import '../../data/voice.dart';
import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/fairy.dart';
import '../../widgets/fit_text.dart';
import '../../widgets/sheets.dart';
import 'search_results.dart';

/// Talking to the house fairy (user request: the search should look like
/// the fairy, and the keyboard must not hide the answer). A whole screen:
/// the input sits right above the keyboard, the answers scroll above it.
/// What was asked before stays as earlier turns.
class AskScreen extends ConsumerStatefulWidget {
  const AskScreen({super.key, this.initial, this.listen = false});

  /// Asked already (the home screen widget's search, a recipe link).
  final String? initial;

  /// Start with the microphone on.
  final bool listen;

  @override
  ConsumerState<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends ConsumerState<AskScreen> {
  final _query = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  final _earlier = <String>[];
  bool _listening = false;
  Timer? _settle;
  String? _tallied;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) _query.text = widget.initial!;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.listen) {
        _listen();
      } else {
        _focus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _settle?.cancel();
    _query.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _changed() {
    setState(() {});
    // One question counts once for the fairy's dust, after typing settles.
    _settle?.cancel();
    final q = _query.text.trim();
    if (q.isNotEmpty) _settle = Timer(const Duration(seconds: 2), () => _count(q));
  }

  void _count(String q) {
    if (_tallied == q) return;
    _tallied = q;
    unawaited(ref.read(fairyTallyProvider.notifier).used());
  }

  /// Keeps this question as an earlier turn and clears the box for the next.
  void _submit() {
    final q = _query.text.trim();
    if (q.isEmpty) return;
    _count(q);
    setState(() {
      _earlier.add(q);
      _query.clear();
    });
    _focus.requestFocus();
  }

  Future<void> _listen() async {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode == 'ko' ? 'ko_KR' : 'en_US';
    setState(() => _listening = true);
    final ok = await ref.read(voiceProvider).listen(locale, (words, done) {
      if (!mounted) return;
      if (words.isNotEmpty) _query.text = words;
      if (done) _listening = false;
      _changed();
    });
    if (!mounted) return;
    if (!ok) {
      setState(() => _listening = false);
      showMessage(context, l.voiceUnavailable);
    }
  }

  Future<void> _stopListening() async {
    await ref.read(voiceProvider).stop();
    if (mounted) setState(() => _listening = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final q = _query.text.trim();
    final turns = [..._earlier, if (q.isNotEmpty) q];
    return Scaffold(
      appBar: AppBar(title: Text(l.askTitle)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              key: const ValueKey('ask-answers'),
              controller: _scroll,
              reverse: true,
              padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.sm),
              children: [
                // Newest at the bottom, right above the box.
                for (final (i, t) in turns.reversed.indexed) _Turn(key: ValueKey('turn-${turns.length - i}-$t'), question: t),
                if (turns.isEmpty) _Hello(text: _listening ? l.voiceListening : l.askHello, listening: _listening),
              ],
            ),
          ),
          Material(
            color: c.card,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.sm, AppSpace.md, AppSpace.sm),
              child: TextField(
                key: const ValueKey('home-search'),
                controller: _query,
                focusNode: _focus,
                textInputAction: TextInputAction.search,
                onChanged: (_) => _changed(),
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hint: OneLine(
                    _listening ? [l.voiceListening] : [l.searchHint, l.searchHintShort],
                    style: Theme.of(context).inputDecorationTheme.hintStyle,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    borderSide: BorderSide(color: c.primary, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    borderSide: BorderSide(color: c.primary, width: 2.5),
                  ),
                  suffixIcon: q.isEmpty || _listening
                      ? IconButton(
                          key: const ValueKey('home-mic'),
                          tooltip: l.voiceSearch,
                          onPressed: _listening ? _stopListening : _listen,
                          icon: Icon(_listening ? Icons.mic_rounded : Icons.mic_none_rounded, color: c.primary),
                        )
                      : IconButton(
                          key: const ValueKey('ask-send'),
                          tooltip: l.askSend,
                          onPressed: _submit,
                          icon: Icon(Icons.arrow_upward_rounded, color: c.primary),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The fairy says what she can do before anything is asked.
class _Hello extends StatelessWidget {
  const _Hello({required this.text, this.listening = false});

  final String text;
  final bool listening;

  @override
  Widget build(BuildContext context) {
    final c = HfColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.xl),
      child: Column(
        children: [
          Fairy(listening ? FairyPose.listen : FairyPose.hello, height: 120),
          const SizedBox(height: AppSpace.md),
          FitText(text, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: c.mutedFg)),
        ],
      ),
    );
  }
}

/// One question and the fairy's answer: the matches (names and initials on the phone; a description goes to the
/// fairy's server only when those find nothing).
class _Turn extends StatelessWidget {
  const _Turn({super.key, required this.question});

  final String question;

  @override
  Widget build(BuildContext context) {
    final c = HfColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              margin: const EdgeInsets.only(left: AppSpace.xl, bottom: AppSpace.sm),
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
              decoration: BoxDecoration(
                color: c.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Text(question, style: TextStyle(color: c.onPrimary)),
            ),
          ),
          isPutSentence(question) ? _PutCard(sentence: question) : SearchResults(query: question),
        ],
      ),
    );
  }
}

/// "신발장에 넣을까요?": the fairy read a put-away sentence ("건전지 신발장에
/// 뒀어"). Nothing is saved until 넣기; 고치기 opens Put away with the sentence.
class _PutCard extends ConsumerStatefulWidget {
  const _PutCard({required this.sentence});

  final String sentence;

  @override
  ConsumerState<_PutCard> createState() => _PutCardState();
}

class _PutCardState extends ConsumerState<_PutCard> {
  String? _doneIn;

  Future<void> _put(PutSentence p) async {
    final l = AppLocalizations.of(context);
    final place = p.placeId!;
    final name = ref.read(homeProvider).requireValue.container(place)!.name;
    await ref.read(homeProvider.notifier).apply((d, ctx) => addItemsFromSentence(d, ctx, place, p.items));
    if (!mounted) return;
    setState(() => _doneIn = name);
    showUndo(context, ref, l.sentenceSaved(p.items.length, name));
  }

  void _fix(PutSentence p) {
    context.push(Uri(path: '/add', queryParameters: {'text': widget.sentence, 'storage': ?p.placeId}).toString());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final d = ref.watch(homeProvider).requireValue;
    final p = readPutSentence(d, widget.sentence);
    if (_doneIn != null) return FairySays(l.askPutDone(_doneIn!), pose: FairyPose.answer);
    final where = p.placeId == null ? null : pathText(d.pathOf(p.placeId!));
    if (p.items.isEmpty) return FairySays(l.askPutWhat, pose: FairyPose.ask);
    return FairySays(
      where == null ? l.askPutWhere : l.askPutConfirm(where),
      pose: FairyPose.ask,
      below: Padding(
        padding: const EdgeInsets.only(top: AppSpace.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpace.xs,
              runSpacing: AppSpace.xs,
              children: [
                for (final i in p.items)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: c.secondarySoft,
                    label: Text(i.qty > 1 ? '${i.name} ×${i.qty}' : i.name),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            Wrap(
              spacing: AppSpace.sm,
              children: [
                if (where != null) FilledButton(key: const ValueKey('ask-put'), onPressed: () => _put(p), child: Text(l.askPutDo)),
                OutlinedButton(key: const ValueKey('ask-put-fix'), onPressed: () => _fix(p), child: Text(where == null ? l.askPutPick : l.askPutFix)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
