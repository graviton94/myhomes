import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/home/home_screen.dart';
import 'features/settings/design_sample_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/shell/app_shell.dart';
import 'features/shell/tab_placeholder.dart';
import 'widgets/fairy.dart';

GoRouter buildRouter({String initialLocation = '/'}) {
  StatefulShellBranch branch(String path, Widget screen) => StatefulShellBranch(
        routes: [GoRoute(path: path, builder: (context, state) => screen)],
      );

  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          branch('/', const HomeScreen()),
          branch('/spaces', const TabPlaceholder(tab: AppTab.spaces, pose: FairyPose.sleep)),
          branch('/search', const TabPlaceholder(tab: AppTab.search, pose: FairyPose.found)),
          branch('/expiry', const TabPlaceholder(tab: AppTab.expiry, pose: FairyPose.worry)),
          branch('/family', const TabPlaceholder(tab: AppTab.family, pose: FairyPose.hello)),
        ],
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(path: 'design', builder: (context, state) => const DesignSampleScreen()),
        ],
      ),
    ],
  );
}
