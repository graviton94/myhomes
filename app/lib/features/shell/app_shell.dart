import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/home_widget_sync.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/header_line.dart';

enum AppTab { home, spaces, expiry, family }

/// The three tabs: the house map (with the one search box), putting things
/// away, family. The megaphone line with Settings sits above them.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  StreamSubscription<Uri?>? _taps;

  @override
  void initState() {
    super.initState();
    // The home screen widget's search box opens Home with the cursor in search.
    final homeScreen = ref.read(homeScreenWidgetProvider);
    _taps = homeScreen.taps.listen(_opened);
    homeScreen.launchedFrom().then(_opened);
  }

  void _opened(Uri? uri) {
    if (!mounted || uri?.host != 'search') return;
    widget.shell.goBranch(0);
    ref.read(searchRequestProvider.notifier).ask();
  }

  @override
  void dispose() {
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
