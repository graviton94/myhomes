import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../data/achievements.dart';
import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/chip_line.dart';
import '../../widgets/fairy_growth.dart';
import '../../widgets/fit_text.dart';
import '../../widgets/medal.dart';
import '../../widgets/sheets.dart';

String achName(AppLocalizations l, Achievement a) => switch (a) {
  Achievement.home => l.achHome,
  Achievement.drawers => l.achDrawers,
  Achievement.things => l.achThings,
  Achievement.finder => l.achFinder,
  Achievement.fridge => l.achFridge,
  Achievement.thrifty => l.achThrifty,
  Achievement.bought => l.achBought,
  Achievement.family => l.achFamily,
  Achievement.moves => l.achMoves,
  Achievement.cook => l.achCook,
  Achievement.moving => l.achMoving,
  Achievement.warranty => l.achWarranty,
  Achievement.streak => l.achStreak,
  Achievement.photos => l.achPhotos,
  Achievement.dated => l.achDated,
};

String achHow(AppLocalizations l, Achievement a) => switch (a) {
  Achievement.home => l.achHomeHow,
  Achievement.drawers => l.achDrawersHow,
  Achievement.things => l.achThingsHow,
  Achievement.finder => l.achFinderHow,
  Achievement.fridge => l.achFridgeHow,
  Achievement.thrifty => l.achThriftyHow,
  Achievement.bought => l.achBoughtHow,
  Achievement.family => l.achFamilyHow,
  Achievement.moves => l.achMovesHow,
  Achievement.cook => l.achCookHow,
  Achievement.moving => l.achMovingHow,
  Achievement.warranty => l.achWarrantyHow,
  Achievement.streak => l.achStreakHow,
  Achievement.photos => l.achPhotosHow,
  Achievement.dated => l.achDatedHow,
};

String medalName(AppLocalizations l, Medal m) => switch (m) {
  Medal.gold => l.medalGold,
  Medal.silver => l.medalSilver,
  Medal.bronze || Medal.none => l.medalBronze,
};

/// The four groups on the screen.
enum AchKind {
  all({}),
  home({Achievement.home, Achievement.drawers, Achievement.photos, Achievement.dated, Achievement.warranty}),
  find({Achievement.things, Achievement.finder, Achievement.moves}),
  care({Achievement.fridge, Achievement.thrifty, Achievement.bought, Achievement.cook}),
  together({Achievement.family, Achievement.moving, Achievement.streak});

  const AchKind(this.items);

  final Set<Achievement> items;

  bool has(Achievement a) => items.isEmpty || items.contains(a);
}

String _kindName(AppLocalizations l, AchKind k) => switch (k) {
  AchKind.all => l.achKindAll,
  AchKind.home => l.achKindHome,
  AchKind.find => l.achKindFind,
  AchKind.care => l.achKindCare,
  AchKind.together => l.achKindTogether,
};

/// "업적": how many medals of all, the groups, and every medal.
class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  AchKind _kind = AchKind.all;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final s = ref.watch(achievementsProvider);
    if (s == null) return Scaffold(appBar: AppBar(title: Text(l.achTitle)));
    final shown = [
      for (final v in s.all)
        if (_kind.has(v.a)) v,
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.achTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.xl),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: c.card,
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                SizedBox.square(
                  dimension: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(value: s.got / s.total, strokeWidth: 6, color: c.accent, backgroundColor: c.muted),
                      Text('${s.got}', style: AppType.title.copyWith(fontSize: 18)),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OneLine([l.achCount(s.got, s.total)], style: AppType.label),
                      OneLine([
                        l.achSummary(s.count(Medal.gold), s.count(Medal.silver), s.count(Medal.bronze)),
                      ], style: AppType.caption.copyWith(color: c.mutedFg)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),
          ChipLine(
            children: [
              for (final k in AchKind.values)
                ChoiceChip(
                  key: ValueKey('ach-kind-${k.name}'),
                  label: Text(_kindName(l, k)),
                  selected: _kind == k,
                  onSelected: (_) => setState(() => _kind = k),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          LayoutBuilder(
            builder: (context, box) {
              final w = (box.maxWidth - AppSpace.sm * 2) / 3;
              return Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.md,
                children: [for (final v in shown) SizedBox(width: w, child: _MedalCell(v))],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MedalCell extends StatelessWidget {
  const _MedalCell(this.v);

  final AchievementView v;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    return InkWell(
      key: ValueKey('ach-${v.a.name}'),
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () => showAchievementDetail(context, v),
      child: Column(
        children: [
          MedalView(achievement: v.a, medal: v.medal, size: 72),
          OneLine(
            [achName(l, v.a)],
            textAlign: TextAlign.center,
            style: AppType.label.copyWith(color: v.medal == Medal.none ? c.mutedFg : c.fg),
            minScale: 0.78,
          ),
          if (v.next != null) Text(l.achProgress(v.value, v.next!), style: AppType.caption.copyWith(color: c.mutedFg)),
        ],
      ),
    );
  }
}

/// One achievement: its medal, what it asks, and each step.
Future<void> showAchievementDetail(BuildContext context, AchievementView v) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheet) {
      final l = AppLocalizations.of(sheet);
      final c = HfColors.of(sheet);
      final steps = v.a.steps;
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetHeader(achName(l, v.a)),
              Center(
                child: MedalView(achievement: v.a, medal: v.medal, size: 112),
              ),
              const SizedBox(height: AppSpace.sm),
              FitText(
                achHow(l, v.a),
                textAlign: TextAlign.center,
                style: AppType.body.copyWith(color: c.mutedFg),
              ),
              if (steps.length > 1) ...[
                const SizedBox(height: AppSpace.md),
                Row(
                  children: [
                    for (final (i, step) in steps.indexed) ...[
                      if (i > 0) const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                          decoration: BoxDecoration(
                            color: v.medal.index > i ? c.secondarySoft : c.card,
                            border: Border.all(color: v.medal.index == i ? c.primary : c.border, width: v.medal.index == i ? 2 : 1),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Column(
                            children: [
                              MedalView(achievement: v.a, medal: Medal.values[i + 1], size: 44),
                              Text(medalName(l, Medal.values[i + 1]), style: AppType.label),
                              Text('$step', style: AppType.caption.copyWith(color: c.mutedFg)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              if (v.next != null) ...[
                const SizedBox(height: AppSpace.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: v.value / v.next!, minHeight: 8, color: c.accent, backgroundColor: c.muted),
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  l.achProgress(v.value, v.next!),
                  textAlign: TextAlign.center,
                  style: AppType.caption.copyWith(color: c.mutedFg),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

/// A new medal (or a step up): shown once, with its stars.
Future<void> showAchievementGot(BuildContext context, WidgetRef ref, AchievementView v) async {
  await celebrated(ref, v);
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheet) {
      final l = AppLocalizations.of(sheet);
      final c = HfColors.of(sheet);
      Widget pill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(99)),
        child: Text(text, style: AppType.label.copyWith(color: c.accentInk)),
      );
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.lg),
          child: Column(
            key: const ValueKey('ach-got'),
            mainAxisSize: MainAxisSize.min,
            children: [
              SheetHeader(l.achGot),
              MedalView(achievement: v.a, medal: v.medal, size: 132),
              const SizedBox(height: AppSpace.sm),
              Text(achName(l, v.a), style: Theme.of(sheet).textTheme.headlineSmall),
              const SizedBox(height: AppSpace.xs),
              FitText(
                achHow(l, v.a),
                textAlign: TextAlign.center,
                style: AppType.body.copyWith(color: c.mutedFg),
              ),
              const SizedBox(height: AppSpace.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: AppSpace.sm,
                children: [pill(l.achStars(medalStars)), pill(l.achMedal(medalName(l, v.medal)))],
              ),
              const SizedBox(height: AppSpace.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('ach-share'),
                  onPressed: () {
                    Navigator.pop(sheet);
                    showShareCard(context, ref);
                  },
                  child: Text(l.shareCard),
                ),
              ),
              TextButton(onPressed: () => Navigator.pop(sheet), child: Text(l.close)),
            ],
          ),
        ),
      );
    },
  );
}

/// In the fairy's story sheet: medals so far and the way to all of them.
class AchievementsRow extends ConsumerWidget {
  const AchievementsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final s = ref.watch(achievementsProvider);
    if (s == null) return const SizedBox.shrink();
    final earned = [
      for (final v in s.all)
        if (v.medal != Medal.none) v,
    ]..sort((a, b) => b.medal.index.compareTo(a.medal.index));
    final closest = [
      for (final v in s.all)
        if (v.next != null) v,
    ]..sort((a, b) => (a.next! - a.value).compareTo(b.next! - b.value));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: OneLine([l.achCount(s.got, s.total)], style: Theme.of(context).textTheme.titleSmall)),
            TextButton(
              key: const ValueKey('ach-all'),
              onPressed: () {
                Navigator.of(context).maybePop();
                context.push('/achievements');
              },
              child: Text(l.achSeeAll),
            ),
          ],
        ),
        if (earned.isEmpty)
          FitText(l.achNone, style: AppType.caption.copyWith(color: c.mutedFg))
        else
          Row(
            children: [
              for (final v in earned.take(4))
                Expanded(
                  child: Center(
                    child: MedalView(achievement: v.a, medal: v.medal, size: 60),
                  ),
                ),
              for (var i = earned.length; i < 4; i++) const Expanded(child: SizedBox()),
            ],
          ),
        if (closest.isNotEmpty) ...[
          const SizedBox(height: AppSpace.xs),
          OneLine([
            l.achNext(achName(l, closest.first.a), closest.first.next! - closest.first.value),
          ], style: AppType.caption.copyWith(color: c.mutedFg)),
        ],
      ],
    );
  }
}
