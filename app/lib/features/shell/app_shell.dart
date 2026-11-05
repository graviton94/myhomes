import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';
import 'package:intl/intl.dart';

import '../../data/home_store.dart';
import '../../data/home_widget_sync.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/header_line.dart';
import '../../widgets/layers.dart';
import '../../widgets/sheets.dart';

enum AppTab { home, spaces, expiry, family }

/// Whether opening the app may ask about things ("가위는 다 사용했나요?").
/// Tests switch it off unless they test the questions.
final asksOnOpenProvider = Provider<bool>((ref) => true);

/// The three tabs: the house map (with the one search box), putting things
/// away, family. The megaphone line with Settings sits above them.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> with WidgetsBindingObserver {
  StreamSubscription<Uri?>? _taps;
  bool _asking = false;

  @override
  void initState() {
    super.initState();
    // The home screen widget's search box opens Home with the cursor in search.
    final homeScreen = ref.read(homeScreenWidgetProvider);
    _taps = homeScreen.taps.listen(_opened);
    homeScreen.launchedFrom().then(_opened);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _askBack());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _askBack();
  }

  /// Something taken out a while ago ("가위는 다 사용했나요?"): asked once,
  /// on opening the app, in a sheet over whatever is on screen.
  Future<void> _askBack() async {
    if (_asking || !mounted || !ref.read(asksOnOpenProvider)) return;
    _asking = true;
    try {
      final d = await ref.read(homeProvider.future);
      final ask = nextAsk(d, DateTime.now());
      if (ask == null || !mounted) return;
      final (kind, item) = ask;
      final l = AppLocalizations.of(context);
      final home = ref.read(homeProvider.notifier);
      final locale = Localizations.localeOf(context).toLanguageTag();
      if (kind == AskKind.expired) {
        final answer = await askQuestion<int>(
          context,
          title: l.askExpiredTitle(item.name),
          detail: l.askExpiredDetail(DateFormat.MMMd(locale).format(item.expiresOn!)),
          answers: [Answer(0, l.askExpiredUsed), Answer(1, l.askExpiredThrown), Answer(2, l.askExpiredStill)],
        );
        if (!mounted) return;
        switch (answer) {
          case 0:
            await home.apply((d, ctx) => useUpItems(d, ctx, [item.id]));
          case 1:
            await home.apply((d, ctx) => discardItems(d, ctx, [item.id]));
          default:
            await home.apply((d, ctx) => stillUsing(d, ctx, item.id));
        }
        return;
      }
      final time = DateFormat.jm(locale).format(item.inUseSince!);
      final answer = await askQuestion<int>(
        context,
        title: l.askBackTitle(item.name),
        detail: l.askBackDetail(pathText(d.pathOf(item.containerId)), time),
        answers: [Answer(0, l.askBackYes), Answer(1, l.askBackStill), Answer(2, l.askBackElsewhere)],
      );
      if (!mounted) return;
      switch (answer) {
        case 0:
          await home.apply((d, ctx) => putBack(d, ctx, item.id));
        case 2:
          final to = await pickStorage(context, title: l.putWhere, exclude: item.containerId);
          if (to == null) {
            await home.apply((d, ctx) => stillUsing(d, ctx, item.id));
          } else {
            await home.apply((d, ctx) => moveItems(putBack(d, ctx, item.id), ctx, {item.id: item.qty}, to));
          }
        default:
          // "Still using" or closed: ask again tomorrow at the earliest.
          await home.apply((d, ctx) => stillUsing(d, ctx, item.id));
      }
    } finally {
      _asking = false;
    }
  }

  void _opened(Uri? uri) {
    if (!mounted || uri?.host != 'search') return;
    widget.shell.goBranch(0);
    ref.read(searchRequestProvider.notifier).ask();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _taps?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shell = widget.shell;
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: Column(
        children: [
          // The megaphone line and Settings stay put on every tab.
          const SafeArea(bottom: false, child: HeaderLine()),
          Expanded(
            child: MediaQuery.removePadding(context: context, removeTop: true, child: shell),
          ),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline)),
        ),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
          destinations: [
            NavigationDestination(icon: const Icon(Icons.map_outlined), selectedIcon: const Icon(Icons.map_rounded), label: l.navMap),
            NavigationDestination(
              icon: const Icon(Icons.add_box_outlined),
              selectedIcon: const Icon(Icons.add_box_rounded),
              label: l.navPut,
            ),
            NavigationDestination(
              icon: const Icon(Icons.group_outlined),
              selectedIcon: const Icon(Icons.group_rounded),
              label: l.navFamily,
            ),
          ],
        ),
      ),
    );
  }
}
