import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../data/accounts.dart';
import '../data/growth.dart';
import '../data/home_store.dart';
import '../data/smart_suggest.dart';
import '../design/theme.dart';
import '../design/tokens.g.dart';
import '../l10n/app_localizations.dart';
import '../features/achievements/achievements_screen.dart';
import 'doodle.dart';
import 'fairy.dart';
import 'fit_text.dart';
import 'sheets.dart';

String stageName(AppLocalizations l, FairyStage s) => [l.stage0, l.stage1, l.stage2, l.stage3, l.stage4][s.index];
String _stageShort(AppLocalizations l, int i) => [l.stageShort0, l.stageShort1, l.stageShort2, l.stageShort3, l.stageShort4][i];

String taskText(AppLocalizations l, WeekTask t) => switch (t.kind) {
  WeekTaskKind.clearExpired => l.taskClearExpired(t.label ?? ''),
  WeekTaskKind.fillSpot => l.taskFillSpot(t.label ?? ''),
  WeekTaskKind.buyTwo => l.taskBuyTwo,
  WeekTaskKind.addFive => l.taskAddFive,
  WeekTaskKind.addDetail => l.taskAddDetail,
};

String stampText(AppLocalizations l, Stamp s) => switch (s) {
  Stamp.firstDrawer => l.stampFirstDrawer,
  Stamp.family => l.stampFamily,
  Stamp.fridgeKeeper => l.stampFridgeKeeper,
  Stamp.shopper => l.stampShopper,
  Stamp.warranty => l.stampWarranty,
  Stamp.photos => l.stampPhotos,
};

/// The one thing growth puts on the map screen: the stage's mark, its name
/// and the stars. Tapping opens the fairy's story.
class FairyBadge extends ConsumerWidget {
  const FairyBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = ref.watch(growthProvider);
    if (g == null) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final dust = dustLeft(ref.watch(creditsProvider).value);
    return Padding(
      padding: const EdgeInsets.only(right: AppSpace.xs),
      child: Material(
        color: c.secondarySoft,
        shape: const StadiumBorder(),
        child: InkWell(
          key: const ValueKey('fairy-badge'),
          customBorder: const StadiumBorder(),
          onTap: () => showFairySheet(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DoodleStageMark(g.stage.index, size: 20),
                const SizedBox(width: 4),
                Text(
                  '${_stageShort(l, g.stage.index)} · ${l.starsCount(g.stars)}',
                  style: AppType.caption.copyWith(color: c.secondaryInk, fontWeight: FontWeight.w700),
                ),
                // This month's fairy dust, always in sight.
                if (dust != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    key: const ValueKey('fairy-dust'),
                    padding: const EdgeInsets.fromLTRB(4, 1, 8, 1),
                    decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(99)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const DoodleDust(size: 15),
                        const SizedBox(width: 3),
                        Text(
                          '${dust.left}',
                          style: AppType.caption.copyWith(color: c.accentInk, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "요정 이야기": the stage, the way to the next one, this week's three
/// tasks and the stamps.
Future<void> showFairySheet(BuildContext context) =>
    showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (_) => const _FairySheet());

class _FairySheet extends ConsumerWidget {
  const _FairySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = ref.watch(growthProvider);
    if (g == null) return const SizedBox(height: 120);
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final t = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(l.growthTitle),
            Row(
              children: [
                const Fairy(FairyPose.carry, height: 72),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          DoodleStageMark(g.stage.index, size: 22),
                          const SizedBox(width: 4),
                          Flexible(child: FitText(stageName(l, g.stage), style: t.titleMedium)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      FitText(g.toNext == null ? l.growthTop : l.growthToNext(g.toNext!), style: t.bodySmall?.copyWith(color: c.mutedFg)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: g.progress, minHeight: 8, color: c.accent, backgroundColor: c.muted),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                for (var i = 0; i < 5; i++)
                  Expanded(
                    child: Text(
                      _stageShort(l, i),
                      textAlign: i == 0 ? TextAlign.start : (i == 4 ? TextAlign.end : TextAlign.center),
                      style: AppType.caption.copyWith(
                        color: i == g.stage.index ? c.accentInk : c.mutedFg,
                        fontWeight: i == g.stage.index ? FontWeight.w700 : null,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            const DustCard(),
            const SizedBox(height: AppSpace.md),
            FitText(g.weeksInRow > 0 ? '${l.growthWeek} · ${l.growthWeeks(g.weeksInRow)}' : l.growthWeek, style: t.titleSmall),
            for (final (i, task) in g.tasks.indexed)
              ListTile(
                key: ValueKey('week-task-$i'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(g.done[i] ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, color: g.done[i] ? c.secondary : c.mutedFg),
                title: Text(taskText(l, task), maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Text('+${task.stars}', style: AppType.label.copyWith(color: c.accentInk)),
              ),
            const SizedBox(height: AppSpace.sm),
            const AchievementsRow(),
          ],
        ),
      ),
    );
  }
}

/// Once, when the fairy reaches a new stage.
Future<void> showLevelUp(BuildContext context, WidgetRef ref) async {
  final g = ref.read(growthProvider);
  if (g == null) return;
  ref.read(growthProvider.notifier).celebrated();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheet) {
      final l = AppLocalizations.of(sheet);
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetHeader(''),
              const Fairy(FairyPose.cheer, height: 120),
              const SizedBox(height: AppSpace.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DoodleStageMark(g.stage.index, size: 28),
                  const SizedBox(width: 6),
                  Flexible(child: FitText(l.levelUpTitle(stageName(l, g.stage)), style: Theme.of(sheet).textTheme.titleLarge)),
                ],
              ),
              const SizedBox(height: 4),
              Text(l.levelUpBody(g.stars), textAlign: TextAlign.center),
              const SizedBox(height: AppSpace.lg),
              FilledButton(
                key: const ValueKey('level-up-share'),
                onPressed: () {
                  Navigator.pop(sheet);
                  showShareCard(context, ref);
                },
                child: Text(l.shareCard),
              ),
              const SizedBox(height: AppSpace.sm),
              OutlinedButton(key: const ValueKey('level-up-close'), onPressed: () => Navigator.pop(sheet), child: Text(l.close)),
            ],
          ),
        ),
      );
    },
  );
}

/// The share card: one picture with the fairy, this month's numbers and the
/// stage (no item names). Shown first, then sent as a PNG.
Future<void> showShareCard(BuildContext context, WidgetRef ref, {MonthReport? report}) async {
  final g = ref.read(growthProvider);
  if (g == null) return;
  final now = DateTime.now();
  final r = report ?? monthReport(ref.read(homeProvider).requireValue.log, now.year, now.month);
  final card = GlobalKey();
  await showDialog<void>(
    context: context,
    builder: (dialog) {
      final l = AppLocalizations.of(dialog);
      return Dialog(
        insetPadding: const EdgeInsets.all(AppSpace.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RepaintBoundary(
                key: card,
                child: _ShareCard(report: r, growth: g),
              ),
              const SizedBox(height: AppSpace.md),
              FilledButton.icon(
                key: const ValueKey('share-card-send'),
                icon: const Icon(Icons.ios_share_rounded),
                label: Text(l.shareCardSend),
                onPressed: () async {
                  final boundary = card.currentContext!.findRenderObject()! as RenderRepaintBoundary;
                  final image = await boundary.toImage(pixelRatio: 3);
                  final png = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
                  final file = File('${(await getTemporaryDirectory()).path}/homefairy-card.png');
                  await file.writeAsBytes(png);
                  await SharePlus.instance.share(ShareParams(files: [XFile(file.path, mimeType: 'image/png')]));
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ShareCard extends StatelessWidget {
  const _ShareCard({required this.report, required this.growth});

  final MonthReport report;
  final GrowthView growth;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final t = Theme.of(context).textTheme;
    final month = DateFormat.MMMM(Localizations.localeOf(context).toLanguageTag()).format(DateTime(report.year, report.month));
    Widget num(int n, String label) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
        decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(AppRadius.md)),
        child: Column(
          children: [
            Text('$n', style: t.titleLarge),
            FitText(label, style: AppType.caption),
          ],
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c.accentSoft, c.primarySoft]),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Fairy(FairyPose.found, height: 96),
          const SizedBox(height: AppSpace.xs),
          FitText(l.shareCardTitle(month), style: t.titleLarge),
          const SizedBox(height: AppSpace.sm),
          Row(
            children: [
              num(report.added, l.reportAdded),
              const SizedBox(width: AppSpace.xs),
              num(report.used, l.reportUsed),
              const SizedBox(width: AppSpace.xs),
              num(report.discarded, l.reportDiscarded),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DoodleStageMark(growth.stage.index, size: 20),
              const SizedBox(width: 4),
              Flexible(
                child: FitText(stageName(l, growth.stage), style: t.bodyMedium?.copyWith(color: c.mutedFg)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(l.appTitle, style: AppType.caption.copyWith(color: c.mutedFg)),
        ],
      ),
    );
  }
}

/// Fairy dust left: this month's (never below zero) plus what was bought.
/// [month] is this month's part alone, for the bar.
({int left, int month, int limit, bool shared, int bonus, bool plus})? dustLeft(FairyCredits? c) {
  if (c == null) return null;
  final month = (c.limit - c.used).clamp(0, c.limit);
  return (left: month + c.bonus, month: month, limit: c.limit, shared: c.shared, bonus: c.bonus, plus: c.plus);
}

/// "이번 달 요정 가루": how much is left, when it refills, what each feature
/// costs. A guest sees how to get it.
class DustCard extends ConsumerWidget {
  const DustCard({super.key, this.showMore = true});

  /// The "more dust" button (not on the screen it leads to).
  final bool showMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final dust = dustLeft(ref.watch(creditsProvider).value);
    final signedIn = ref.watch(accountProvider).value != null;
    final ink = AppType.label.copyWith(color: c.accentInk);
    if (dust == null) {
      if (signedIn) return const SizedBox.shrink();
      return Container(
        key: const ValueKey('dust-guest'),
        padding: const EdgeInsets.all(AppSpace.md),
        decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(AppRadius.md)),
        child: Row(
          children: [
            const DoodleDust(size: 22),
            const SizedBox(width: AppSpace.sm),
            Expanded(child: FitText(l.dustGuest, style: ink)),
          ],
        ),
      );
    }
    final now = DateTime.now();
    final refill = DateFormat.MMMd(Localizations.localeOf(context).toLanguageTag()).format(DateTime(now.year, now.month + 1));
    Widget cost(IconData icon, String what, int n) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: c.accentInk),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: OneLine([what], style: AppType.caption.copyWith(color: c.fg)),
          ),
          const DoodleDust(size: 13),
          const SizedBox(width: 2),
          Text('$n', style: ink),
        ],
      ),
    );
    return Container(
      key: const ValueKey('dust-card'),
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const DoodleDust(size: 20),
              const SizedBox(width: AppSpace.xs),
              Expanded(child: OneLine([l.dustMonth], style: ink)),
              Text(l.dustOf(dust.month, dust.limit), style: AppType.title.copyWith(color: c.accentInk, fontSize: 20)),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: dust.limit == 0 ? 0 : dust.month / dust.limit, minHeight: 8, color: c.accent, backgroundColor: c.card),
          ),
          const SizedBox(height: AppSpace.sm),
          FitText(l.dustRefill(dust.limit, refill), style: AppType.caption.copyWith(color: c.accentInk)),
          cost(Icons.manage_search_rounded, l.dustCostFind, dustCost.find),
          cost(Icons.receipt_long_rounded, l.dustCostReceipt, dustCost.receipt),
          cost(Icons.photo_camera_rounded, l.dustCostPhoto, dustCost.photo),
          const SizedBox(height: AppSpace.sm),
          FitText(l.dustFree, style: AppType.caption.copyWith(color: c.mutedFg)),
          if (dust.bonus > 0) ...[
            const SizedBox(height: AppSpace.sm),
            OneLine([l.dustBought(dust.bonus)], style: ink),
          ],
          if (showMore) const SizedBox(height: AppSpace.sm),
          // More dust: Plus or a pack, in the store.
          if (showMore)
            OutlinedButton(
              key: const ValueKey('dust-more'),
              onPressed: () {
                Navigator.of(context).maybePop();
                context.push('/plus');
              },
              child: OneLine([dust.plus ? l.plusOpenHave : l.plusOpen]),
            ),
        ],
      ),
    );
  }
}

/// "✦ 5" next to a button that spends fairy dust.
class DustCost extends StatelessWidget {
  const DustCost(this.n, {super.key, this.color});

  final int n;
  final Color? color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const DoodleDust(size: 15),
      const SizedBox(width: 2),
      Text('$n', style: AppType.label.copyWith(color: color)),
    ],
  );
}

/// After a fairy feature: how much dust it took and what is left.
Future<void> showDustSpent(BuildContext context, WidgetRef ref, int spent) async {
  final l = AppLocalizations.of(context);
  final left = dustLeft(await ref.refresh(creditsProvider.future))?.left;
  if (left != null && context.mounted) showMessage(context, l.dustSpent(spent, left));
}
