import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'data/home_store.dart';
import 'features/expiry/expiry_screen.dart';
import 'features/home/home_screen.dart';
import 'features/item/item_form_screen.dart';
import 'features/item/sentence_add_screen.dart';
import 'features/onboarding/intro_screen.dart';
import 'features/onboarding/login_screen.dart';
import 'features/onboarding/splash_screen.dart';
import 'features/search/search_screen.dart';
import 'features/settings/design_sample_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/shell/app_shell.dart';
import 'features/shell/tab_placeholder.dart';
import 'features/spaces/space_board.dart';
import 'features/storage/storage_screen.dart';
import 'settings/settings.dart';
import 'widgets/fairy.dart';

/// Re-runs the router's redirect when settings or loading state change.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(settingsProvider, (_, _) => notifyListeners());
    ref.listen(
      homeProvider.select((s) => s.hasValue),
      (_, _) => notifyListeners(),
    );
  }
}

const _entryRoutes = {'/splash', '/intro', '/login'};

final routerProvider = Provider.family<GoRouter, String>((
  ref,
  initialLocation,
) {
  final refresh = _RouterRefresh(ref);
  StatefulShellBranch branch(String path, Widget screen) => StatefulShellBranch(
    routes: [GoRoute(path: path, builder: (context, state) => screen)],
  );

  final router = GoRouter(
    initialLocation: initialLocation,
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      // Remember where we were headed so the loading screen hands it back.
      final from =
          state.uri.queryParameters['from'] ??
          (_entryRoutes.contains(loc) ? null : state.uri.toString());
      String withFrom(String path) => from == null || from == '/'
          ? path
          : '$path?from=${Uri.encodeComponent(from)}';
      if (!ref.read(homeProvider).hasValue) {
        return loc == '/splash' ? null : withFrom('/splash');
      }
      final s = ref.read(settingsProvider);
      final gate = !s.introSeen ? '/intro' : (!s.started ? '/login' : null);
      if (gate != null) return loc == gate ? null : withFrom(gate);
      if (_entryRoutes.contains(loc)) return from ?? '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/intro', builder: (context, state) => const IntroScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          branch('/', const HomeScreen()),
          branch('/spaces', const SpaceBoard()),
          branch('/search', const SearchScreen()),
          branch('/expiry', const ExpiryScreen()),
          branch(
            '/family',
            const TabPlaceholder(tab: AppTab.family, pose: FairyPose.hello),
          ),
        ],
      ),
      GoRoute(
        path: '/space/:id',
        builder: (context, state) => SpaceBoard(
          initialSpaceId: state.pathParameters['id']!,
          highlightItemId: state.uri.queryParameters['item'],
        ),
      ),
      GoRoute(
        path: '/storage/:id',
        builder: (context, state) => StorageScreen(
          storageId: state.pathParameters['id']!,
          startInSelectMode: state.uri.queryParameters['select'] == '1',
        ),
      ),
      GoRoute(
        path: '/add',
        builder: (context, state) =>
            SentenceAddScreen(storageId: state.uri.queryParameters['storage']),
      ),
      GoRoute(
        path: '/item/new',
        builder: (context, state) => ItemFormScreen(
          storageId: state.uri.queryParameters['storage'],
          slot: int.tryParse(state.uri.queryParameters['slot'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/item/:id/edit',
        builder: (context, state) =>
            ItemFormScreen(itemId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'design',
            builder: (context, state) => const DesignSampleScreen(),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
