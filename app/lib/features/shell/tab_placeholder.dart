import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fairy.dart';
import 'app_shell.dart';

/// Empty state for tabs that arrive in later builds.
class TabPlaceholder extends StatelessWidget {
  const TabPlaceholder({super.key, required this.tab, required this.pose});

  final AppTab tab;
  final FairyPose pose;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final (String title, String heading, String body) = switch (tab) {
      AppTab.spaces => (l.navSpaces, l.spacesEmptyTitle, l.spacesEmptyBody),
      AppTab.search => (l.navSearch, l.searchEmptyTitle, l.searchEmptyBody),
      AppTab.expiry => (l.navExpiry, l.expiryEmptyTitle, l.expiryEmptyBody),
      AppTab.family => (l.navFamily, l.familyEmptyTitle, l.familyEmptyBody),
      AppTab.home => (l.navHome, l.homeEmptyTitle, l.homeEmptyBody),
    };
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: SingleChildScrollView(child: EmptyState(pose: pose, title: heading, body: body))),
    );
  }
}
