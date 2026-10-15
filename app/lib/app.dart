import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'design/theme.dart';
import 'l10n/app_localizations.dart';
import 'router.dart';
import 'settings/settings.dart';

class HomeFairyApp extends ConsumerStatefulWidget {
  const HomeFairyApp({super.key, this.initialLocation = '/'});

  /// Lets tests open a specific screen.
  final String initialLocation;

  @override
  ConsumerState<HomeFairyApp> createState() => _HomeFairyAppState();
}

class _HomeFairyAppState extends ConsumerState<HomeFairyApp> {
  late final GoRouter _router = buildRouter(initialLocation: widget.initialLocation);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: settings.themeMode,
      locale: settings.language.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: _router,
    );
  }
}
