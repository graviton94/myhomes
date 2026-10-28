import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:homefairy_core/homefairy_core.dart';

import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../settings/settings.dart';
import '../../widgets/fairy.dart';
import '../../widgets/sheets.dart';

/// Three intro pages, shown once (and again from Settings).
class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen> {
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _finish() => ref.read(settingsProvider.notifier).setIntroSeen(true);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final pages = [
      (const _FindScene(), l.intro1Title, l.intro1Body),
      (const _PutScene(), l.intro2Title, l.intro2Body),
      (const _FamilyScene(), l.intro3Title, l.intro3Body),
    ];
    final last = _index == pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.sm),
                child: last ? const SizedBox(height: AppSize.touch) : TextButton(onPressed: _finish, child: Text(l.skip)),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  for (final (i, (scene, title, body)) in pages.indexed)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Re-keyed when the page comes into view, so its scene plays again.
                          Expanded(
                            child: KeyedSubtree(key: ValueKey('$i-${i == _index}'), child: scene),
                          ),
                          Text(title, style: Theme.of(context).textTheme.displaySmall),
                          const SizedBox(height: AppSpace.md),
                          Text(body, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: c.mutedFg)),
                          const SizedBox(height: AppSpace.xl),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, AppSpace.xl),
              child: Row(
                children: [
                  Semantics(
                    label: l.pageOf(_index + 1, pages.length),
                    child: Row(
                      children: [
                        for (var i = 0; i < pages.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: AppMotion.baseMs),
                            margin: const EdgeInsets.only(right: 6),
                            width: i == _index ? 22 : 8,
                            height: 8,
                            decoration: BoxDecoration(color: i == _index ? c.primary : c.border, borderRadius: BorderRadius.circular(4)),
                          ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size(132, 52)),
                    onPressed: last
                        ? _finish
                        : () => _pages.nextPage(duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic),
                    child: Text(last ? l.getStarted : l.next),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A scene plays in: the card rises, then the fairy hops in beside it.
class _Scene extends StatelessWidget {
  const _Scene({required this.card, required this.pose, required this.fairyAt});

  final Widget card;
  final FairyPose pose;
  final Alignment fairyAt;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    Widget enter(Widget child, {required int delayMs, required Offset from}) => still
        ? child
        : TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 520 + delayMs),
            curve: Interval(delayMs / (520 + delayMs), 1, curve: Curves.easeOutBack),
            builder: (context, t, child) => Opacity(
              opacity: t.clamp(0, 1),
              child: Transform.translate(offset: from * (1 - t), child: child),
            ),
            child: child,
          );
    // The fairy stands at the card's lower corner, half over its edge.
    final right = fairyAt.x > 0;
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 118),
            child: enter(card, delayMs: 0, from: const Offset(0, 24)),
          ),
          Positioned(
            right: right ? -12 : null,
            left: right ? null : -12,
            bottom: 0,
            child: enter(Fairy(pose, height: 150), delayMs: 260, from: Offset(right ? 40 : -40, 30)),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = HfColors.of(context);
    return Container(
      width: 290,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, spacing: AppSpace.sm, children: children),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, {this.on = false});

  final String text;
  final bool on;

  @override
  Widget build(BuildContext context) {
    final c = HfColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: on ? c.primarySoft : c.muted, borderRadius: BorderRadius.circular(99)),
      child: Text(
        text,
        style: AppType.caption.copyWith(color: on ? c.primaryInk : c.fg, fontWeight: on ? FontWeight.w700 : null),
      ),
    );
  }
}

/// Page 1: the search box answering "where are the batteries?".
class _FindScene extends StatelessWidget {
  const _FindScene();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    return _Scene(
      pose: FairyPose.found,
      fairyAt: const Alignment(0.95, 0.95),
      card: _Card(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: c.primary, width: 2),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              spacing: AppSpace.sm,
              children: [
                Icon(Icons.search_rounded, size: 20, color: c.mutedFg),
                Expanded(child: Text(l.introDemoQuery, style: AppType.body)),
                Icon(Icons.mic_none_rounded, size: 20, color: c.mutedFg),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.introDemoItem, style: AppType.label),
                Text(pathText([l.introDemoRoom, l.introDemoStorage, l.introDemoSpot]), style: AppType.caption.copyWith(color: c.mutedFg)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Page 2: one sentence split into name chips.
class _PutScene extends StatelessWidget {
  const _PutScene();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    return _Scene(
      pose: FairyPose.carry,
      fairyAt: const Alignment(-0.95, 0.95),
      card: _Card(
        children: [
          _Pill(pathText([l.introDemoRoom, l.introDemoStorage]), on: true),
          Text(l.introDemoSentence, style: AppType.body.copyWith(color: c.mutedFg)),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final i in parseItemSentence(l.introDemoSentence)) _Pill(i.qty > 1 ? '${i.name} ×${i.qty}' : i.name)],
          ),
        ],
      ),
    );
  }
}

/// Page 3: each family member fills their own room.
class _FamilyScene extends StatelessWidget {
  const _FamilyScene();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    Widget tile(String text, {bool invite = false}) => Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: invite ? c.accentSoft : c.secondarySoft, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Text(text, style: AppType.label.copyWith(color: invite ? c.accentInk : c.secondaryInk)),
    );
    return _Scene(
      pose: FairyPose.cheer,
      fairyAt: const Alignment(0.95, 0.95),
      card: _Card(
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpace.sm,
            crossAxisSpacing: AppSpace.sm,
            childAspectRatio: 2.6,
            children: [tile(l.introDemoFamily1), tile(l.introDemoFamily2), tile(l.introDemoFamily3), tile(l.introDemoInvite, invite: true)],
          ),
        ],
      ),
    );
  }
}
