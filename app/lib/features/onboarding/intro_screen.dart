import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../settings/settings.dart';
import '../../widgets/fairy.dart';
import '../../widgets/sheets.dart';
import '../../widgets/fit_text.dart';

/// Four intro pages, shown once (and again from Settings): each a picture
/// of the real app with the fairy on top, two lines of title, two of body.
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
      (_Art(color: c.accentSoft, child: const _WelcomeScene()), l.introWelcomeTitle, l.introWelcomeBody),
      (_Art(color: c.secondarySoft, child: const _MapScene()), l.introMapTitle, l.introMapBody),
      (_Art(color: c.primarySoft, child: const _FindScene()), l.introFindTitle, l.introFindBody),
      (_Art(color: c.accentSoft, child: const _CareScene()), l.introCareTitle, l.introCareBody),
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
                          const SizedBox(height: AppSpace.lg),
                          FitText(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(height: 1.3)),
                          const SizedBox(height: AppSpace.sm),
                          FitText(body, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: c.mutedFg)),
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

/// The coloured panel each page's picture sits on.
class _Art extends StatelessWidget {
  const _Art({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: AppSpace.sm),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppRadius.xl)),
    alignment: Alignment.center,
    padding: const EdgeInsets.all(AppSpace.md),
    child: child,
  );
}

/// Page 1: the fairy says hello, with three promises.
class _WelcomeScene extends StatelessWidget {
  const _WelcomeScene();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    Widget promise(IconData icon, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpace.sm,
      children: [
        Icon(icon, size: 18, color: c.accentInk),
        Flexible(
          child: OneLine([text], style: AppType.label.copyWith(color: c.accentInk)),
        ),
      ],
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Flexible(child: Fairy(FairyPose.hello, height: 150)),
        const SizedBox(height: AppSpace.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
          decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              promise(Icons.lock_open_rounded, l.introPromise1),
              promise(Icons.phone_android_rounded, l.introPromise2),
              promise(Icons.people_alt_rounded, l.introPromise3),
            ],
          ),
        ),
      ],
    );
  }
}

/// Page 2: a small floor plan with its rooms and spots; the fairy carries a box.
class _MapScene extends StatelessWidget {
  const _MapScene();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    Widget spot(IconData icon, String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: c.accentSoft,
        border: Border.all(color: c.accent),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [
          Icon(icon, size: 11, color: c.accentInk),
          Text(text, style: AppType.caption.copyWith(fontSize: 10, color: c.accentInk)),
        ],
      ),
    );
    Widget room(String name, {List<Widget> spots = const [], bool hi = false}) => Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: c.secondarySoft,
        border: Border.all(color: hi ? c.primary : c.fg, width: 2),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 3,
        children: [
          Text(name, style: AppType.label.copyWith(fontSize: 11, color: c.secondaryInk)),
          Wrap(spacing: 3, runSpacing: 3, children: spots),
        ],
      ),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 270,
          height: 170,
          padding: const EdgeInsets.all(AppSpace.sm),
          decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Column(
            spacing: 4,
            children: [
              Expanded(
                child: Row(
                  spacing: 4,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: room(l.roomMaster)),
                    Expanded(child: room(l.roomKitchen, spots: [spot(Icons.kitchen_rounded, l.introDemoFridge)])),
                    Expanded(child: room(l.roomBath)),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  spacing: 4,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 2, child: room(l.introDemoRoom, hi: true, spots: [spot(Icons.tv_rounded, l.introDemoStorage)])),
                    Expanded(child: room(l.roomRoom)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Positioned(right: -22, bottom: -34, child: Fairy(FairyPose.carry, height: 96)),
      ],
    );
  }
}

/// Page 3: "where are the scissors?" and the answer, with its place.
class _FindScene extends StatelessWidget {
  const _FindScene();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpace.sm,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 10),
                decoration: BoxDecoration(
                  color: c.card,
                  border: Border.all(color: c.primary, width: 2),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  spacing: AppSpace.sm,
                  children: [
                    Icon(Icons.search_rounded, size: 20, color: c.mutedFg),
                    Expanded(child: OneLine([l.introDemoAsk], style: AppType.body)),
                    Icon(Icons.mic_rounded, size: 20, color: c.primary),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(AppSpace.md),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4))],
                ),
                child: Row(
                  spacing: AppSpace.sm,
                  children: [
                    Icon(Icons.content_cut_rounded, color: c.accentInk),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.introDemoScissors, style: AppType.label),
                          OneLine([
                            pathText([l.introDemoRoom, l.introDemoStorage, l.introDemoSpot]),
                          ], style: AppType.caption.copyWith(color: c.mutedFg)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
        const Positioned(left: -10, bottom: -24, child: Fairy(FairyPose.found, height: 104)),
      ],
    );
  }
}

/// Page 4: three reminders: a date, something running out, something lent.
class _CareScene extends StatelessWidget {
  const _CareScene();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    Widget note(String badge, Color bg, Color ink, String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm + 2, vertical: AppSpace.sm),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(
        spacing: AppSpace.sm,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
            child: Text(
              badge,
              style: AppType.caption.copyWith(fontSize: 11, color: ink, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: OneLine([text], style: AppType.caption.copyWith(color: c.fg)),
          ),
        ],
      ),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpace.sm,
            children: [
              note(l.introCareBadge1, c.primarySoft, c.primaryInk, l.introCareLine1),
              note(l.introCareBadge2, c.accentSoft, c.accentInk, l.introCareLine2),
              note(l.introCareBadge3, c.secondarySoft, c.secondaryInk, l.introCareLine3),
              const SizedBox(height: 56),
            ],
          ),
        ),
        const Positioned(right: -14, bottom: -26, child: Fairy(FairyPose.cheer, height: 100)),
      ],
    );
  }
}
