import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../settings/settings.dart';
import '../../widgets/fairy.dart';

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
      (FairyPose.found, l.intro1Title, l.intro1Body),
      (FairyPose.carry, l.intro2Title, l.intro2Body),
      (FairyPose.worry, l.intro3Title, l.intro3Body),
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
                  for (final (pose, title, body) in pages)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Center(child: Fairy(pose, height: 220))),
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
                            decoration: BoxDecoration(
                              color: i == _index ? c.primary : c.border,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size(132, 52)),
                    onPressed: last
                        ? _finish
                        : () => _pages.nextPage(
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOutCubic,
                            ),
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
