import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';
import 'package:intl/intl.dart';

import '../../data/achievements.dart';
import '../../data/home_store.dart';
import '../../data/recipes.dart';
import '../../data/home_widget_sync.dart';
import '../../design/tokens.g.dart';
import '../../design/theme.dart';
import '../../l10n/app_localizations.dart';
import '../achievements/achievements_screen.dart';
import '../../widgets/app_icons.dart';
import '../../widgets/dday_badge.dart';
import '../../widgets/inventory_slot.dart';
import '../../widgets/open_item.dart';
import '../../widgets/sheets.dart';
import '../../data/growth.dart';
import '../shell/app_shell.dart' show asksOnOpenProvider;
import '../../widgets/doodle.dart';
import '../../widgets/fairy_growth.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fairy.dart';
import 'house_map.dart';
import '../spaces/space_actions.dart';
import '../../widgets/fit_text.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _searchAsked = 0;
  bool _celebrating = false;

  /// "두부 · 우유 쓰는 요리 ›" on top of the use-first list, when a dish uses
  /// food that should go soon.
  Widget? _cookLine(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final now = DateTime.now();
    final names = <String>{
      for (final m in ref.read(cookIdeasProvider))
        for (final i in m.urgent(now)) i.name,
    }.take(2).toList();
    if (names.isEmpty) return null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.sm),
      child: Material(
        color: c.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          key: const ValueKey('cook-line'),
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () {
            Navigator.pop(context);
            context.push('/recipes');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
            child: Row(
              children: [
                Expanded(
                  child: OneLine([
                    for (var n = names.length; n > 0; n--) l.cookWith(names.take(n).join(' · ')),
                    l.cookIdeas,
                  ], style: AppType.label.copyWith(color: c.accentInk)),
                ),
                Icon(Icons.chevron_right_rounded, color: c.accentInk),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// A short list in a sheet over the map, with "see all" for the full screen.
  Future<void> _listSheet({required String title, required List<Widget> rows}) {
    final l = AppLocalizations.of(context);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (sheet, scroll) => Column(
          children: [
            SheetHeader(
              title,
              trailing: TextButton(
                onPressed: () {
                  Navigator.pop(sheet);
                  context.push('/expiry');
                },
                child: Text(l.seeAll),
              ),
            ),
            Expanded(
              child: rows.isEmpty
                  ? Center(
                      child: Text(l.historyEmpty, style: TextStyle(color: HfColors.of(context).mutedFg)),
                    )
                  : ListView(
                      controller: scroll,
                      padding: EdgeInsets.only(bottom: MediaQuery.viewPaddingOf(sheet).bottom),
                      children: rows,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = ref.watch(homeProvider).requireValue;
    final today = DateTime.now();
    // The home screen widget's search box: also when Home is built only now.
    // A new stage: the fairy says so once.
    if (ref.read(asksOnOpenProvider) && (ref.watch(growthProvider)?.leveledUp ?? false)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && (ref.read(growthProvider)?.leveledUp ?? false)) showLevelUp(context, ref);
      });
    }
    // A new medal: celebrated once, one at a time, after any level-up.
    else if (ref.read(asksOnOpenProvider) && (ref.watch(achievementsProvider)?.fresh.isNotEmpty ?? false)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final fresh = ref.read(achievementsProvider)?.fresh ?? const [];
        if (mounted && !_celebrating && fresh.isNotEmpty) {
          _celebrating = true;
          showAchievementGot(context, ref, fresh.first).whenComplete(() => _celebrating = false);
        }
      });
    }
    final asked = ref.watch(searchRequestProvider);
    if (asked.n != _searchAsked) {
      _searchAsked = asked.n;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.push(Uri(path: '/ask', queryParameters: {'q': ?asked.text, if (asked.listen) 'listen': '1'}).toString());
      });
    }
    final urgent = byExpiry(d, today).where((e) => e.$2.isUrgent).toList();
    final returns = returnsDue(d, today).where((e) => e.$2.isUrgent).toList();
    return Scaffold(
      appBar: AppBar(title: Text(l.myHome), actions: const [FairyBadge()]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.xs, AppSpace.lg, 112),
        children: [
          const _AskBar(),
          ...[
            const SizedBox(height: AppSpace.md),
            // Four fixed tiles, no sideways scrolling: a number and a short name.
            Row(
              children: [
                for (final (i, tile) in [
                  ('tile-use-first', urgent.length, l.tileUseFirst, '/expiry'),
                  ('tile-shopping', shoppingList(d).length, l.tileShopping, '/shopping'),
                  ('tile-returns', returns.length, l.tileReturns, '/expiry'),
                  (
                    'tile-report',
                    null,
                    l.tileReport(DateFormat.MMM(Localizations.localeOf(context).toLanguageTag()).format(today)),
                    '/report',
                  ),
                ].indexed) ...[
                  if (i > 0) const SizedBox(width: AppSpace.xs),
                  Expanded(
                    child: _Tile(
                      key: ValueKey(tile.$1),
                      count: tile.$2,
                      label: tile.$3,
                      // The two short lists open as a sheet over the map; shopping and
                      // the report have their own screens (actions, a whole page).
                      onTap: switch (tile.$1) {
                        'tile-use-first' => () => _listSheet(
                          title: l.eatFirst(urgent.length),
                          rows: [
                            ?_cookLine(context),
                            for (final (item, status) in urgent)
                              ListTile(
                                leading: ItemThumb(category: item.category, photoPath: item.photoPath, iconKey: item.icon),
                                title: Text(
                                  item.qty > 1 ? '${item.name} ×${item.qty}' : item.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(pathText(d.pathOf(item.containerId)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                trailing: DdayBadge(status),
                                onTap: () {
                                  Navigator.pop(context);
                                  openItem(context, d, item);
                                },
                              ),
                          ],
                        ),
                        'tile-returns' => () => _listSheet(
                          title: l.getBackCount(returns.length),
                          rows: [
                            for (final (storage, status) in returns)
                              ListTile(
                                leading: storageGlyph(storage, size: 24, color: HfColors.of(context).accentInk),
                                title: Text(storage.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                                subtitle: Text(l.itemsCount(d.itemsIn(storage.id).length), maxLines: 1, overflow: TextOverflow.ellipsis),
                                trailing: ReturnBadge(status),
                                onTap: () {
                                  Navigator.pop(context);
                                  context.push('/space/${storage.spaceId}');
                                },
                              ),
                          ],
                        ),
                        _ => () => context.push(tile.$4),
                      },
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpace.md),
            if (d.spaces.isEmpty)
              Card(
                child: EmptyState(
                  pose: FairyPose.carry,
                  title: l.homeEmptyTitle,
                  body: l.homeEmptyBody,
                  // The floor plan first: one pick makes every room (user request).
                  action: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FilledButton.icon(
                        key: const ValueKey('home-empty-plan'),
                        onPressed: () => context.push('/house/setup'),
                        icon: const Icon(Icons.home_rounded),
                        label: Text(l.homeEmptyPlan),
                      ),
                      TextButton(
                        key: const ValueKey('home-empty-room'),
                        onPressed: () => addSpaceFlow(context, ref),
                        child: Text(l.homeEmptyOneRoom),
                      ),
                    ],
                  ),
                ),
              )
            else
              const HouseMap(),
          ],
        ],
      ),
    );
  }
}

/// One of the four tiles under the search box: a number over a short name
/// (the report tile has no number).
class _Tile extends StatelessWidget {
  const _Tile({super.key, required this.count, required this.label, required this.onTap});

  final int? count;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = HfColors.of(context);
    final t = Theme.of(context).textTheme;
    final busy = (count ?? 0) > 0;
    return Material(
      color: busy ? c.secondarySoft : c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (count == null)
                const DoodleReport(size: 26)
              else
                Text('$count', style: t.titleLarge?.copyWith(color: busy ? c.secondaryInk : c.mutedFg, height: 1.1)),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: FitText(
                  label,
                  style: t.labelSmall?.copyWith(color: c.fg, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "집요정에게 물어보세요": the fairy's bubble at the top of Home (user
/// request: the search did not look like the fairy at all). Opens the
/// whole-screen talk, where the keyboard hides nothing.
class _AskBar extends StatelessWidget {
  const _AskBar();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final t = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(AppRadius.xl);
    return Semantics(
      button: true,
      label: l.askBarTitle,
      child: Material(
        color: c.card,
        shape: RoundedRectangleBorder(borderRadius: radius, side: BorderSide(color: c.primary, width: 2.5)),
        child: InkWell(
          key: const ValueKey('home-ask'),
          borderRadius: radius,
          onTap: () => context.push('/ask'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.sm, AppSpace.sm, AppSpace.sm, AppSpace.sm),
            child: Row(
              children: [
                const Fairy(FairyPose.hello, height: 52),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OneLine([l.askBarTitle], style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      OneLine([l.askBarExample, l.askBarExampleShort], style: t.bodySmall?.copyWith(color: c.mutedFg)),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                IconButton.filled(
                  key: const ValueKey('home-ask-mic'),
                  tooltip: l.voiceSearch,
                  onPressed: () => context.push('/ask?listen=1'),
                  icon: const Icon(Icons.mic_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
