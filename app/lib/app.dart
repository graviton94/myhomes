import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/household.dart';
import 'data/reminders.dart';
import 'design/theme.dart';
import 'l10n/app_localizations.dart';
import 'router.dart';
import 'settings/settings.dart';
import 'widgets/keep_words.dart';

class HomeFairyApp extends ConsumerWidget {
  const HomeFairyApp({super.key, this.initialLocation = '/splash'});

  /// Lets tests open a specific screen.
  final String initialLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    ref.watch(reminderSyncProvider);
    ref.watch(familyAlertSyncProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: settings.themeMode,
      locale: settings.language.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: [
        const KeepWordsDelegate(),
        ...AppLocalizations.localizationsDelegates.where((d) => d != AppLocalizations.delegate),
      ],
      routerConfig: ref.watch(routerProvider(initialLocation)),
      // Every screen and sheet stays clear of the phone's bottom navigation bar
      // (gesture bar or buttons); app bars already clear the status bar.
      builder: (context, child) => ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(top: false, child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
